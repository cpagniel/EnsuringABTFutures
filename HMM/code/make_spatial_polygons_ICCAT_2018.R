#make model spatial areas based on ICCAT 7 boxes                                                           
# 7 area 2018 area definitions

AreaDefs <- vector("list", length = 7)

# GOM_7
AreaDefs[[1]]<-data.frame(x=c(-100,-95,-88,-80,-80,-85,-100),
                           y=c(20, 17, 20, 20, 25, 35, 35))

# WATL_7
AreaDefs[[2]]<-data.frame(x=c(-70,-95,-88,-80,-80,-85,-70,-55,-55,-60,-70,-80,-100,-100,-45,-45,-30,-30,-25,-25,-70),
                           y=c(0,16.5,20, 20, 25,35,45,45,50,55,55,50,60,80,80,10,10,5,5,-50,-50))

# GSL_7
AreaDefs[[3]]<-data.frame(x=c(-70,-55,-55,-60,-70),
                           y=c(45,  45, 50, 55, 55))

# SATL_7
AreaDefs[[4]]<-data.frame(x=c(-30,-45,-45,-5,-5,20,20, -25,-25,-30), 
                           y=c(10, 10,  40,40,30,30,-50,-50,5,  5))

# NATL_7
AreaDefs[[5]]<-data.frame(x=c(-30,-15,-15,45,45,-45,-45,-30),
                           y=c( 50, 50, 60,60,80, 80, 40, 40))

# EATL_7
AreaDefs[[6]]<-data.frame(x=c(-30,-30,-15,-15,15,15,5,-5), 
                           y=c(40,50,50,60,60,50,50,40))

# MED_7
AreaDefs[[7]]<-data.frame(x=c(-5,45,45,5,-5),
                           y=c(30,30,50,50,40))


AreaNames<-c("GOM","WATL","GSL","SATL","NATL","EATL","MED")

ind<-1:7
cols<-rep(c("#ff000040","#00ff0040","#0000ff40","#00000040","#ff00ff40"),10)

map(xlim=c(-100,50),ylim=c(-50,80))
abline(v=(-20:20)*10,col='grey')
abline(h=(-20:20)*10,col='grey')
abline(v=0,col="red")
abline(h=0,col="red")

for(i in 1:length(AreaNames[ind])){
  polygon(AreaDefs[[ind[i]]],col=cols[i])
  text(mean(AreaDefs[[ind[i]]]$x),mean(AreaDefs[[ind[i]]]$y),AreaNames[ind[i]],col='white',font=2,cex=0.8)         
}


gsl<-Polygon(AreaDefs[[3]])
gsls<-Polygons(list(gsl),1)
sp.gsl = SpatialPolygons(list(gsls))
proj4string(sp.gsl) =CRS("+init=epsg:3021") #CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
data<-data.frame(f=99.9)
gsldf<-SpatialPolygonsDataFrame(sp.gsl,data)

gom<-Polygon(AreaDefs[[1]])
goms<-Polygons(list(gom),1)
sp.gom = SpatialPolygons(list(goms))
proj4string(sp.gom) =CRS("+init=epsg:3021") 
data<-data.frame(f=99.9)
gomdf<-SpatialPolygonsDataFrame(sp.gom,data)

nes<-Polygon(AreaDefs[[2]])
ness<-Polygons(list(nes),1)
sp.nes = SpatialPolygons(list(ness))
proj4string(sp.nes) =CRS("+init=epsg:3021") 
data<-data.frame(f=99.9)
nesdf<-SpatialPolygonsDataFrame(sp.nes,data)


SEATLMED<-matrix(c(-25,-25,-30,-30,-45,-45,45,45,15,15,45,45,20,20,-25,
                -50,5,5,10,10,80,80,60,60,50,50,30,30,-50,-50),nrow=15,ncol=2)
w<-Polygon(SEATLMED)
ws<-Polygons(list(w),1)
sp.w = SpatialPolygons(list(ws))
proj4string(sp.w) =CRS("+init=epsg:3021") 
data<-data.frame(f=99.9)
wdf<-SpatialPolygonsDataFrame(sp.w,data)

