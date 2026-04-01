
#Load packages
library(coda)
library(ggmap)
library(ggplot2)
library(gtools)
library(mapdata)
library(maps)
library(nimble)
library(parallel)   
library(raster) 
library(reshape2)                                                            
library(sp)
library(zoo) 

                
this_cluster <- makeCluster(4)

source("make_spatial_polygons_ICCAT_2018.r")  #make the spatial boxes for the model

#Read acoustic detections file
acoustic<-read.delim("abft_ac_detects_2026jan5.csv",sep=",",header=T)  
acoustic$ddate<-as.Date(acoustic$ping_detection,'%Y-%m-%d %H:%M:%S')
acoustic$tdate<-as.Date(acoustic$tagdate,'%Y-%m-%d %H:%M:%S')

acoustic<-acoustic[!(acoustic$eventid=="511901201"), ]   #remove tag from suspected dead fish
acoustic<-acoustic[order(acoustic$eventid), ]
acoustic$toppid<-substr(acoustic$eventid,1,7)

#Read satellite tag tracks
sat.tags<-read.table("abft_ssm_wgsl_detects_2025mar21.txt",sep="\t",head=T)
sat.tags$sdate<-as.Date(sat.tags$datetime,'%m/%d/%Y %H:%M')


#Read meta-data
meta_data<-read.delim("abft_acoustic_dep_plus_all_doubles_2026jan7.txt",sep="\t",head=T)
meta_data$fish_recaptured[is.na(meta_data$fish_recaptured)]<-rep(0,times=length(meta_data$fish_recaptured[is.na(meta_data$fish_recaptured)]))

#use tags deployed until end 2023 for survival analysis (2026)  
meta_data<-meta_data[as.POSIXlt(strptime(meta_data$taggingdate,'%m/%d/%Y'))<as.POSIXlt(strptime("01/01/2024",'%m/%d/%Y')),]
meta_data$toppid<-substr(meta_data$eventid,1,7)
meta_data$idend<-substr(meta_data$eventid,8,9)

meta_data$pop_step<-as.numeric((as.POSIXlt(strptime(meta_data$recpopdate,'%m/%d/%Y'))-as.POSIXlt(strptime(meta_data$taggingdate,'%m/%d/%Y'))))/365.24*6
meta_data$dyear<-strptime(meta_data$taggingdate, '%m/%d/%Y')$year+1900
meta_data$taggingdate<-as.Date(meta_data$taggingdate,'%m/%d/%Y')
meta_data$recpopdate<-as.Date(meta_data$recpopdate,format='%m/%d/%Y')


################################################################################################
#Assign age at release using Richards growth function from Ailloud et al 2017

#1) CFL to SFL from Table 3 of Rodriguez-Marin et al 2015
c.alpha<-1.8575
c.beta<-0.9606
meta_data$SFL<-c.alpha+c.beta*meta_data$dep_length

#2) SFL to age using Richards growth function from Ailloud et al 2017

A1<-0
A2<-34

#Richards
p<- -0.12
K<- 0.22
L1<-33.0
L2<-270.6

meta_data$tagging_age<- log(1 - (meta_data$SFL^p - L1^p) / (L2^p - L1^p)*(1 - exp(-K*(A2 - A1)))) / -K + A1
#set ages with length > 270.96 (L2) to 34 (note some lengths in data higher than this...)
meta_data$tagging_age[which(is.na(meta_data$tagging_age))]<- log(1 - (L2^p - L1^p) / (L2^p - L1^p)*(1 - exp(-K*(A2 - A1)))) / -K + A1



#####################################################################################################

#Assign recaptures to model areas

#4 areas 
#1) GSL
#2) W Atlantic
#3) Gulf of Mexico
#4) E Atlantic and Med

rcoords <- cbind(Longitude = as.numeric(as.character(meta_data$recpoplon[!is.na(meta_data$recpoplon)])),
                 Latitude = as.numeric(as.character(meta_data$recpoplat[!is.na(meta_data$recpoplat)])))
REC_SP <- SpatialPointsDataFrame(rcoords, data = data.frame(meta_data$eventid[!is.na(meta_data$recpoplon)]), proj4string = CRS("+init=epsg:3021"))

REC_GSLmember <- sp::over(REC_SP,sp.gsl,fn = NULL)  
REC_NEmember <- sp::over(REC_SP,sp.nes,fn = NULL) 
REC_Wmember <- sp::over(REC_SP,sp.w,fn = NULL)  
REC_GOMmember <- sp::over(REC_SP,sp.gom,fn = NULL)  

meta_data[is.na(REC_GSLmember) & is.na(REC_NEmember) & is.na(REC_Wmember) &is.na(REC_GOMmember), ]   #Check for positions outside

meta_data$area<-numeric(dim(meta_data)[1])    

meta_data$area[!is.na(meta_data$recpoplon)][!(is.na(REC_GSLmember))]<-1
meta_data$area[!is.na(meta_data$recpoplon)][!(is.na(REC_NEmember))]<-2
meta_data$area[!is.na(meta_data$recpoplon)][!(is.na(REC_GOMmember))]<-3
meta_data$area[!is.na(meta_data$recpoplon)][!(is.na(REC_Wmember))]<-4

#####################################################################################################
sat_dat<-meta_data[meta_data$tagtype=="satellite" & meta_data$idend=="00",] #meta data for satellite tags (2 sat tags end in 01, not in satellite data file)
ac_dat<-meta_data[meta_data$tagtype=="acoustic",] #(2 tags end in 02)
bothdata<-ac_dat[ac_dat$toppid %in% sat_dat$toppid,] #meta data for acoustic tags, double tagged fish
acdata<-ac_dat[!(ac_dat$toppid %in% sat_dat$toppid),] #meta data for acoustic tags, single tagged (acoustic only) fish
ac_only<-acdata

sat.tags$modelid<-match(sat.tags$toppid,bothdata$toppid)
bothlist<-bothdata$toppid
ac_list<-ac_only$toppid

ac_with_data<-unique(acoustic$toppid)[!unique(acoustic$toppid) %in% bothlist]
#acoustic only tags with no acoustic hits
ac_no_data<-ac_list[!ac_list %in% ac_with_data]
#to run without no data acoustic tags:
#ac_list<-ac_list[ac_list %in% ac_data]

#recaps
recap_both<-bothdata[bothdata$fish_recaptured==1,]
recap_ac<-acdata[acdata$fish_recaptured,]

both_inds<-match(recap_both$toppid,bothlist)
ac_inds<-match(recap_ac$toppid,ac_list)

########################################################################################################
#Assign acoustic detections to model areas
sp_data<-acoustic

coords <- cbind(Longitude = as.numeric(as.character(sp_data$receiver_lon)),
                Latitude = as.numeric(as.character(sp_data$receiver_lat)))
T_SP <- SpatialPointsDataFrame(coords, data = data.frame(sp_data$site), proj4string = CRS("+init=epsg:3021"))

GSLmember <- sp::over(T_SP,sp.gsl,fn = NULL)  #Assign model areas to the acoustic detections  NA or 1
NEmember <- sp::over(T_SP,sp.nes,fn = NULL) 
Wmember <- sp::over(T_SP,sp.w,fn = NULL)  
GOMmember <- sp::over(T_SP,sp.gom,fn = NULL) 
#MEDmember <- sp::over(T_SP,sp.med,fn = NULL)   

acoustic[is.na(GSLmember) & is.na(NEmember) & is.na(Wmember) & is.na(GOMmember), ]   #Check for stations outside model boxes

acoustic$area<-numeric(dim(acoustic)[1])
acoustic$area[!is.na(GSLmember)]<-1
acoustic$area[!is.na(NEmember)]<-2
acoustic$area[!is.na(GOMmember)]<-3
acoustic$area[!is.na(Wmember)]<-4

#table(acoustic$area, useNA="always")

#Assign satellite tag loactions to model areas

scoords <- cbind(Longitude = as.numeric(as.character(sat.tags$lon180)),
                 Latitude = as.numeric(as.character(sat.tags$lat)))
SAT_SP <- SpatialPointsDataFrame(scoords, data = data.frame(sat.tags$modelid), proj4string = CRS("+init=epsg:3021"))

SAT_GSLmember <- sp::over(SAT_SP,sp.gsl,fn = NULL)  #Assign model areas to the sat tag detections  NA or 1
SAT_NEmember <- sp::over(SAT_SP,sp.nes,fn = NULL) 
SAT_Wmember <- sp::over(SAT_SP,sp.w,fn = NULL)  
SAT_GOMmember <- sp::over(SAT_SP,sp.gom,fn = NULL)
#SAT_MEDmember <- sp::over(SAT_SP,sp.med,fn = NULL)  

sat.tags[is.na(SAT_GSLmember) & is.na(SAT_NEmember) & is.na(SAT_Wmember) &is.na(SAT_GOMmember), ]   #Check for positions outside

sat.tags$area<-numeric(dim(sat.tags)[1])      #Assign sat tag tracks to model areas

sat.tags$area[!is.na(SAT_GSLmember)]<-1
sat.tags$area[!is.na(SAT_NEmember)]<-2
sat.tags$area[!is.na(SAT_GOMmember)]<-3
sat.tags$area[!is.na(SAT_Wmember)]<-4

#check final positions
latlast<-aggregate(sat.tags$lat,by=list(sat.tags$toppid),tail,1)
longlast<-aggregate(sat.tags$lon180,by=list(sat.tags$toppid),tail,1)

datfirst<-aggregate(sat.tags$sdate,by=list(sat.tags$toppid),head,1)
datlast<-aggregate(sat.tags$sdate,by=list(sat.tags$toppid),tail,1)
satlarge<-as.numeric(datlast$x-datfirst$x)

scoords <- cbind(Longitude = as.numeric(as.character(longlast$x)),
                 Latitude = as.numeric(as.character(latlast$x)))
SAT_SP_final <- SpatialPointsDataFrame(scoords, data = data.frame(latlast$Group.1), proj4string = CRS("+init=epsg:3021"))
f_GSLmember <- sp::over(SAT_SP_final,sp.gsl,fn = NULL)  #Assign model areas to the sat tag detections  NA or 1
f_NEmember <- sp::over(SAT_SP_final,sp.nes,fn = NULL) 
f_Wmember <- sp::over(SAT_SP_final,sp.w,fn = NULL)  
f_GOMmember <- sp::over(SAT_SP_final,sp.gom,fn = NULL)

final_area<-numeric(length(latlast$Group.1))
final_area[!is.na(f_GSLmember)]<-1
final_area[!is.na(f_NEmember)]<-2
final_area[!is.na(f_GOMmember)]<-3
final_area[!is.na(f_Wmember)]<-4
#table(final_area, useNA="always")


################################################################################

year_steps<-6   #time steps per year
startdate<-"2009-09-01"   #First timestep in model    

min(acdata$taggingdate,bothdata$taggingdate)
#1 "2009-10-18 CEST"
tagdate<-meta_data$taggingdate

#set up dates max dates for the analysis
tag_step<-floor((as.yearmon(tagdate)-as.yearmon(startdate))*year_steps+1)      #time step of tagging

#acoustic only tags
max_date_ac<-max(as.Date(acoustic$ddate[substr(acoustic$eventid,1,7) %in% ac_list]),as.Date(acdata$recpopdate),na.rm=T)
#"2018-04-19 12:49:34 CEST"
max_step_ac<-round((as.yearmon(max_date_ac)-as.yearmon(startdate))*year_steps+1)

#acoustic and satellite tag
max_date_sat<-max(as.Date(acoustic$ddate[substr(acoustic$eventid,1,7) %in% bothlist]),as.Date(bothdata$recpopdate),na.rm=T)  
# "2018-03-22 00:46:00 CET"

max_step<-round((as.yearmon(max_date_sat)-as.yearmon(startdate))*year_steps+1)
################################################################################
################## M a k e    o b s e r v a t i o n    m a t r i c e s #############
################################################################################
#Acoustic and satellite tag
#acoustic observation takes precedence if they are different

#time step 1 Sept-Oct 2009 
#time step 2 Nov-Dec 2009 etc.

tsteps<-as.yearmon(startdate)+((1:(max_step+1))/year_steps)-1/year_steps
step_dates<-as.Date(strptime(format(tsteps, "%d/%m/%Y"),'%d/%m/%Y'))

tagcount<-1

diffdat<-data.frame(ncomps=numeric,ndiffs=numeric,ind=numeric,tstep=numeric)

combined<-array(0,dim=c(length(bothlist)*max_step,3))
combined[ ,1]<-rep(1:length(bothlist),each=max_step)
combined[ ,2]<-rep(1:max(max_step),times=length(bothlist))
count<-numeric(4)

pop_step1<-array(0,dim=c(length(bothlist),max_step))

for(i in 1:length(bothlist)){
  print(i)
  
  if(!(is.na(sat_dat$recpopdate[sat_dat$toppid==bothlist[i]]))){
    popdate<-as.Date(sat_dat$recpopdate[sat_dat$toppid==bothlist[i]],'%m/%d/%Y')
  }
  
  for(j in 1:(length(step_dates)-1)){
    iind<-(tagcount-1)*max_step+j
    
    tagsub<-subset(acoustic,acoustic$toppid==bothlist[i] & acoustic$ddate>=step_dates[j] & acoustic$ddate<step_dates[(j+1)])
    satsub<-subset(sat.tags,sat.tags$toppid==bothlist[i] & sat.tags$sdate>=step_dates[j] & sat.tags$sdate<step_dates[(j+1)])
    
    
    if(!(is.na(sat_dat$recpopdate[sat_dat$toppid==bothlist[i]]))){
      if(popdate>=step_dates[j] & popdate<step_dates[(j+1)]){
        pop_step1[i,j]<-1
      }
    }
    
    if(dim(tagsub)[1]==0 & dim(satsub)[1]==0){
      
      combined[iind,3]<-17 #no observations
      
    } else if(dim(tagsub)[1]>0 & dim(satsub)[1]==0){  #acoustic only
      
      #count<-table(factor(tagsub$area,levels=1:4))
      t1<-table(tagsub$area,as.numeric(format(tagsub$ddate,"%j")))
      count<-table(factor(as.numeric(rownames(t1)[apply(t1,2,which.max)]),levels=1:4))
    omax<-which(as.numeric(count)==max(as.numeric(count)))
    
    if(length(omax)==1){ 

      if(which.max(count)==1){
            combined[iind,3]<-2   #area 1
        } else if(which.max(count)==2){
            combined[iind,3]<-5      #area 2
        } else if(which.max(count)==3){
            combined[iind,3]<-8   #area 3
        } else if(which.max(count)==4){
            combined[iind,3]<-11      #area 4
        }
    } else {
    tagsub1<-subset(tagsub,tagsub$area %in% omax)
    combined[iind,3]<-tagsub1$area[tagsub1$ping_detection==min(tagsub1$ping_detection)]*3-1
    }
      
    }else if(dim(tagsub)[1]==0 & dim(satsub)[1]>0){  #sat only
      
      count<-table(factor(satsub$area,levels=1:4))
      omax<-which(as.numeric(count)==max(as.numeric(count)))
      
      if(length(omax)==1){
      if(which.max(count)==1){
        combined[iind,3]<-3   #area 1
      } else if(which.max(count)==2){
        combined[iind,3]<-6      #area 2
      } else if(which.max(count)==3){
        combined[iind,3]<-9   #area 3
      } else if(which.max(count)==4){
        combined[iind,3]<-12      #area 4
      }
    } else {
    satsub1<-subset(satsub,satsub$area %in% omax)
    combined[iind,3]<-satsub1$area[satsub1$sdate==min(satsub1$sdate)]*3
    }
      
    }else if(dim(tagsub)[1]>0 & dim(satsub)[1]>0){  #both tags
      
      
      t1<-table(tagsub$area,as.numeric(format(tagsub$ddate,"%j")))
      t2<-table(satsub$area,as.numeric(format(satsub$sdate,"%j")))
      
      #Find the area of greatest occupancy (most days, acoustic takes preference if both obs on same day)
      days<-unique(c(as.numeric(format(satsub$sdate,"%j")),as.numeric(format(tagsub$ddate,"%j"))))
      nobs.both<-numeric(length(days))
      nobs.both[match(colnames(t2),days)]<-as.numeric(rownames(t2)[apply(t2,2,which.max)])
      nobs.both[match(colnames(t1),days)]<-as.numeric(rownames(t1)[apply(t1,2,which.max)])  #replace with acoustic obs where available
    
      count<-table(factor(nobs.both,levels=1:4))
      omax<-which(as.numeric(count)==max(as.numeric(count)))
  
      nobs1<-numeric(length(days))
      nobs2<-numeric(length(days))
      
      nobs1[match(colnames(t1),days)]<-as.numeric(rownames(t1)[apply(t1,2,which.max)])  #acoustic obs where available
      nobs2[match(colnames(t2),days)]<-as.numeric(rownames(t2)[apply(t2,2,which.max)])  #sat
      
      count1<-table(factor(nobs1,levels=1:4))
      count2<-table(factor(nobs2,levels=1:4))
      
      #for review 7 Feb how many daily sat and acoustic tag area observations differ
      
      matches<-as.numeric(colnames(t2)[which(colnames(t2) %in% colnames(t1))]) #days with both obs types
      a1<-as.numeric(rownames(t2)[apply(t2,2,which.max)])[which(colnames(t2) %in% colnames(t1))] #sat tags daily area for days with both obs type
      a2<-as.numeric(rownames(t1)[apply(t1,2,which.max)])[which(colnames(t1) %in% colnames(t2))] #ac tags daily area for days with both obs type
      diffs<-length(which(a1!=a2))
      comps<-length(matches)
      diffdat<-rbind(diffdat,c(comps,diffs,i,j))
      
      ac.max<- count1[names(count1)==omax]
      sat.max<- count2[names(count2)==omax]
      

      if(length(omax)==1){ 
        
      if(ac.max>sat.max){
        tt<-"ac"
      } else if(ac.max==sat.max){
        tt<-"both"
      } else {
        tt<-"sat"
      }
      
      if(tt=="sat"){  #most observation days from satellite tag
        if(any(nobs1==omax)){  #sat and ac obs in same area
        
          if(which.max(count)==1){
             combined[iind,3]<-1   #area 1
          } else if(which.max(count)==2){
             combined[iind,3]<-4      #area 2
          } else if(which.max(count)==3){
             combined[iind,3]<-7   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-10      #area 4
          }
        } else { #no ac obs in max occ area -> sat only
          if(which.max(count)==1){
            combined[iind,3]<-3   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-6      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-9   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-12      #area 4
          }
          
        }
      } else if(tt=="both"){  #sat and ac have equal number of obs days in max occupancy area
   
          if(which.max(count)==1){
            combined[iind,3]<-1   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-4      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-7   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-10      #area 4
          }

      } else { #most observation days from acoustic tag
        
        if(any(nobs2==omax)){  #sat and ac obs in same area  
          if(which.max(count)==1){
            combined[iind,3]<-1   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-4      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-7   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-10      #area 4
          }
        } else {                       #acoustic only
          if(which.max(count)==1){
            combined[iind,3]<-2   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-5      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-8   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-11      #area 4
          }
          
        } 
      } #tt/ac 
      
      } else {  #length(omax) > 1
    sobs<-nobs.both[nobs.both %in% omax]
    sdays<-days[nobs.both %in% omax]
    omax1<-sobs[sdays==min(sdays)]
    
    ac.max<- count1[names(count1)==omax1]
    sat.max<- count2[names(count2)==omax1]
    
    if(ac.max>sat.max){
      tt<-"ac"
    } else if(ac.max==sat.max){
      tt<-"both"
    } else {
      tt<-"sat"
    }
      
      if(tt=="sat"){  #most observation days from satellite tag
        if(any(nobs1==omax1)){  #sat and ac obs in same area
          
          if(which.max(count)==1){
            combined[iind,3]<-1   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-4      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-7   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-10      #area 4
          }
        } else { #no ac obs in max occ area -> sat only
          if(which.max(count)==1){
            combined[iind,3]<-3   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-6      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-9   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-12      #area 4
          }
          
        }
      } else if(tt=="both"){  #sat and ac have equal number of obs days in max occupancy area
        
        if(which.max(count)==1){
          combined[iind,3]<-1   #area 1
        } else if(which.max(count)==2){
          combined[iind,3]<-4      #area 2
        } else if(which.max(count)==3){
          combined[iind,3]<-7   #area 3
        } else if(which.max(count)==4){
          combined[iind,3]<-10      #area 4
        }
        
      } else { #most observation days from acoustic tag
        
        if(any(nobs2==omax1)){  #sat and ac obs in same area  
          if(which.max(count)==1){
            combined[iind,3]<-1   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-4      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-7   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-10      #area 4
          }
        } else {                       #acoustic only
          if(which.max(count)==1){
            combined[iind,3]<-2   #area 1
          } else if(which.max(count)==2){
            combined[iind,3]<-5      #area 2
          } else if(which.max(count)==3){
            combined[iind,3]<-8   #area 3
          } else if(which.max(count)==4){
            combined[iind,3]<-11      #area 4
          }
          
        } 
      } #tt/ac 
    
    }  #sobs length > 1
    
    } 
    if(bothdata$fish_recaptured[which(bothlist==bothlist[i])]==1){
      if(bothdata$recpopdate[which(bothlist==bothlist[i])]>=step_dates[j] & bothdata$recpopdate[which(bothlist==bothlist[i])]<step_dates[(j+1)]){
        if(bothdata$area[which(bothlist==bothlist[i])]==1){
          combined[iind,3]<-13
        } else if(bothdata$area[which(bothlist==bothlist[i])]==2){
          combined[iind,3]<-14
        } else if(bothdata$area[which(bothlist==bothlist[i])]==3){
          combined[iind,3]<-15
        } else if(bothdata$area[which(bothlist==bothlist[i])]==4){
          combined[iind,3]<-16
        }
        
        
      }  
    }
    
  }   #j
  if(any(pop_step1[i,]==1)){
    p1<-which(pop_step1[i,]==1)[1]
    pop_step1[i,(p1+1):max_step]<-NA
  } else{
    pop_step1[i,1:max_step]<-NA 
  }
  
  
  tagcount<-tagcount+1
}

###################################################################################################################
###################################################################################################################
#Acoustic tags only
#set up a vector of 2 months boundaries  
tsteps<-as.yearmon(startdate)+((1:(max_step_ac+1))/year_steps)-1/year_steps
step_dates<-as.Date(strptime(format(tsteps, "%d/%m/%Y"),'%d/%m/%Y'))

detections<-array(0,dim=c(length(ac_list)*max(max_step_ac),3))
detections[ ,1]<-rep(1:length(ac_list),each=max(max_step_ac))
detections[ ,2]<-rep(1:max(max_step_ac),times=length(ac_list))

#loop over the tags and timesteps.  If there are any detections in that time step for that tag, assign the detection area based on area with the most observation days. 

#time step 1 Oct 2009 etc.
count<-numeric(4)
tagcount<-1

for(i in 1:length(ac_list)){
  print(i)
  for(j in 1:(length(step_dates)-1)){
    
    iind<-(tagcount-1)*max_step_ac+j
    
    tagsub<-subset(acoustic,acoustic$toppid==ac_list[i] & acoustic$ddate>=step_dates[j] & acoustic$ddate<step_dates[(j+1)])
    if(dim(tagsub)[1]==0){
      
      detections[iind,3]<-9
      
    } else {
      
      
      #count<-table(factor(tagsub$area,levels=1:4))
      t1<-table(tagsub$area,as.numeric(format(tagsub$ddate,"%j")))
      count<-table(factor(as.numeric(rownames(t1)[apply(t1,2,which.max)]),levels=1:4))
    omax<-which(as.numeric(count)==max(as.numeric(count)))
    
    if(length(omax)==1){ 
      if(which.max(count)==1){
        detections[iind,3]<-1   #area 1
      } else if(which.max(count)==2){
        detections[iind,3]<-2      #area 2
      } else if(which.max(count)==3){
        detections[iind,3]<-3   #area 3
      } else if(which.max(count)==4){
        detections[iind,3]<-4      #area 4
      }
    } else {
      tagsub1<-subset(tagsub,tagsub$area %in% omax)
      detections[iind,3]<-tagsub1$area[tagsub1$ping_detection==min(tagsub1$ping_detection)]
    }
      
      
    }
    
    
    if(acdata$fish_recaptured[which(acdata$toppid==ac_list[i])]==1){
      if(acdata$recpopdate[which(acdata$toppid==ac_list[i])]>=step_dates[j] & acdata$recpopdate[which(acdata$toppid==ac_list[i])]<step_dates[(j+1)]){
        if(acdata$area[which(acdata$toppid==ac_list[i])]==1){
          detections[iind,3]<-5
        } else if(acdata$area[which(acdata$toppid==ac_list[i])]==2){
          detections[iind,3]<-6
        } else if(acdata$area[which(acdata$toppid==ac_list[i])]==3){
          detections[iind,3]<-7
        } else if(acdata$area[which(acdata$toppid==ac_list[i])]==4){
          detections[iind,3]<-8
        }
      }
    }
    
  } #j
  
  tagcount<-tagcount+1
}

sat_rel<-floor((as.yearmon(bothdata$taggingdate)-as.yearmon(startdate))*year_steps+1) 
taglife<-bothdata$est_taglife
pop_step<-pop_step1

ac_rel<-floor((as.yearmon(acdata$taggingdate)-as.yearmon(startdate))*year_steps+1) 
taglife_ac<-acdata$est_taglife

#tags released in North Carolina
nctags<-c("5113001", "5113002", "5113003", "5113004", "5121063","5121069")

#which(ac_list %in% nctags)
#which(bothlist %in% nctags)

rel_area<-rep(1,times=length(bothlist))
rel_area[which(bothlist %in% nctags)]<-4  

rel_area_ac<-rep(1,times=length(ac_list))
rel_area_ac[which(ac_list %in% nctags)]<-2  

sat.combined<-combined  
acoustic_only<-detections  

##Make age matrices

sat.age<-array(NA,dim=c(length(bothlist),max(sat.combined[,2],acoustic_only[,2])))
ac.age<-array(NA,dim=c(length(ac_list),max(sat.combined[,2],acoustic_only[,2])))

coords1<-cbind(1:length(sat_rel),sat_rel)
coords2<-cbind(1:length(ac_rel),ac_rel)
sat.age[coords1]<-bothdata$tagging_age
ac.age[coords2]<-acdata$tagging_age

for(i in 1:length(sat_rel)){
  for(j in (sat_rel[i]+1):max(sat.combined[,2],acoustic_only[,2])){
  sat.age[i,j]<- sat.age[i,(j-1)]+1/year_steps
  }
}

for(i in 1:length(ac_rel)){
  for(j in (ac_rel[i]+1):max(sat.combined[,2],acoustic_only[,2])){
    ac.age[i,j]<- ac.age[i,(j-1)]+1/year_steps
  }
}

sat.age<-trunc(sat.age)
ac.age<-trunc(ac.age)

max.age<-max(sat.age,ac.age,na.rm=T)

#Function to run model with parallel MCMC chains
run_survCode <- function(seed,sdata,sconsts,sinits) {
library(nimble)

source("HMM_ABT.R")

#parallel
survModel <- nimbleModel(code = survCode,
                          data = sdata,
                          constants = sconsts,
                          inits = sinits,calculate=FALSE)

parnames<-c("M.yr","M.tag","p.detect.ac","p.detect.sat","F.yr","theta","satlife","taglife","taglife_ac","o_sigma","k_sigma","p.report.tag","kappa_sat","F","gamma.age2","gamma.age3","F_autoc","CVF")

nimbleOptions(MCMCenableWAIC = TRUE)
survConf <- configureMCMC(survModel, print=TRUE, useConjugacy = FALSE, monitors = parnames)   #useConjugacy = FALSE
sMCMC <- buildMCMC(survConf) # uncompiled R code

Csurv <- compileNimble(survModel,showCompilerOutput = TRUE)
CsurvMCMC <- compileNimble(sMCMC, project = survModel)
results <- runMCMC(CsurvMCMC, niter = 160000, nburnin = 80000, thin=100, setSeed = seed, WAIC=TRUE)  

return(results)
}

yrs<-as.numeric(format(step_dates,"%Y"))
years<-length(unique(yrs[1:(length(step_dates)-1)]))
nseas<-6
nareas<-4

make_seasons<-function(minseas,slength){
qrel<-minseas
svec<-c(qrel:nseas)
while(length(svec)<slength){
   svec<-c(svec,1:nseas)
}
svec<-svec[1:slength]
return(svec)
}


survConsts<-list(N=length(unique(sat.combined[,1])),N_ac=length(unique(acoustic_only[,1])),
                 nareas=nareas,nstates_alive=4,nstates_alive_obs=3,nstates=21,nstates_obs=17,nstates_ac=13,nstates_obs_ac=9,
                 yrsteps=year_steps,s=make_seasons(5,length(step_dates)),yr=yrs[1:length(step_dates)]-(min(yrs)-1),
                 years=years,t_rel=sat_rel,t_rel_ac=ac_rel,maxsteps=max(sat.combined[,2]),maxsteps_ac=max(acoustic_only[,2]),
                 maxsteps_all=max(sat.combined[,2],acoustic_only[,2]),nseas=nseas,yrseas=c(1,2,3,4,5,6),F_zones=2,
                 zone=c(1,1,1,2),a_rel=rel_area,a_rel_ac=rel_area_ac,sat.age=sat.age,ac.age=ac.age,cl=c(rep(1,times=13),rep(2,times=7),rep(3,times=max.age-20)))

colnames(detections)<-c("ind","tstep","obs")
yac<-acast(data.frame(detections), ind~tstep, value.var="obs")
colnames(yac)<-NULL

colnames(combined)<-c("ind","tstep","obs")
yboth<-acast(data.frame(combined), ind~tstep, value.var="obs")
colnames(yboth)<-NULL

survData<-list(taglife_exp=log(taglife/365.24*year_steps),taglife_exp_ac=log(taglife_ac/365.24*year_steps),tag_obs=sat.combined[,3],tag_obs_ac=acoustic_only[,3],pop_step=pop_step,yboth=yboth,yac=yac)  

make.inits <- function(){list(M.yr=rlnorm(3,-2.28,0.20),p.detect.ac=array(runif(nareas*years,0.10,0.90),dim=c(nareas,years)),p.detect.sat=runif(1,0.951,0.999),o_sigma=c(rbeta(1,2,1),NA),k_sigma=c(rbeta(1,2,1),NA),satlife=rlnorm(1,1.79,5),M.tag=rbeta(1,10,190),M.tag.ac=rbeta(1,10,190),p.report.tag=runif(2,0.50,0.99),kappa_sat=rbeta(1,9,51),kappa_ac=rbeta(1,5,55),k_delta=runif(1,1.1,3),o_delta=runif(1,1.1,3),mueF=rlnorm(2,-2.5,0.20),CVF=runif(1,0.1,0.5),F_autoc=runif(1,0.2,0.8),gamma.age2=rlnorm(1,0,0.20),gamma.age3=rlnorm(1,0,0.20))}  

survInits<-make.inits()
ptm<-proc.time()
chain_output <- parLapply(cl = this_cluster, X = 1:2, 
                          fun = run_survCode, 
                          sdata = survData,sconsts=survConsts,sinits=survInits)

# It's good practice to close the cluster when you're done with it.
stopCluster(this_cluster)
print(proc.time()-ptm)

#par(mfrow = c(2,1))
#for (i in 1:2) {
#  this_output <- chain_output[[i]]
#  plot(this_output[,"M.yr"], type = "l", ylab = 'b',ylim=c(0.10,0.25))
#}save(chain_output,file="ABFT_ac_sat_chain_output.RData")

v1 <- mcmc(chain_output[[1]]$samples)
v2 <- mcmc(chain_output[[2]]$samples)
chains<-mcmc.list(list(v1,v2)) 

gelman.diag(chains[,"M.yr[1]"])
