#
#
#State-space model for survival estimation
#
#

dHMM_ac <- nimbleFunction(
run = function(x = double(1), 
                 probInit = double(1), # vector of initial states
                 probObs = double(3), #observation matrix
                 probTrans = double(3), # transition matrix
                 nstates=double(0),
                 len = double(0, default = 0), # number of sampling occasions
                 log = integer(0, default = 0)) {
    alpha <- probInit[1:nstates] # * probObs[1:2,x[1]] == 1 due to conditioning on first detection
    for (t in 2:len) {
      alpha[1:nstates] <- (alpha[1:nstates] %*% probTrans[1:nstates,(t-1),1:nstates]) * probObs[1:nstates,t,x[t]]
      #print(paste0(t," ",alpha[1:nstates]))
    }
    logL <- log(sum(alpha[1:nstates]))
    returnType(double(0))
    if (log) return(logL)
    return(exp(logL))
  }
)

rHMM_ac <- nimbleFunction(
  run = function(n = integer(),
                 probInit = double(1),
                 probObs = double(3),
                 probTrans = double(3),
                 nstates=double(0),
                 len = double(0, default = 0)) {
    returnType(double(1))
    z <- numeric(len)
    z[1] <- rcat(n = 1, prob = probInit[1:nstates]) # all individuals alive at t = 0
    y <- z
    y[1] <- z[1] # all individuals are detected at t = 0
    for (t in 2:len){
      # state at t given state at t-1
      z[t] <- rcat(n = 1, prob = probTrans[z[t-1],t,1:nstates]) 
      # observation at t given state at t
      y[t] <- rcat(n = 1, prob = probObs[z[t],t,1:nstates]) 
    }
    return(y)
  })
  
assign('dHMM_ac', dHMM_ac, .GlobalEnv)
assign('rHMM_ac', rHMM_ac, .GlobalEnv)

survCode<-nimbleCode({ 
# STATES (X)

# 1 alive in area 1, both tags
# 2 alive in area 1, acoustic only 
# 3 alive in area 1, satellite + non func ac 

# 4 alive in area 2, both tags
# 5 alive in area 2, acoustic only 
# 6 alive in area 2, satellite + non func ac 

# 7 alive in area 3, both tags
# 8 alive in area 3, acoustic only 
# 9 alive in area 3, satellite + non func ac 

# 10 alive in area 4, both tags
# 11 alive in area 4, acoustic only 
# 12 alive in area 4, satellite + non func ac 

# 13 recaptured area 1
# 14 recaptured area 2
# 15 recaptured area 3
# 16 recaptured area 4
 
# 17 alive no func tag area 1
# 18 alive no func tag area 2
# 19 alive no func tag area 3
# 20 alive no func tag area 4

# 21 dead natural mortality, tagging mort, emigrated etc.



#new 2022 F priors from Kurota et al table 5 9+ age group, CV x 2 
#for(y in 1:years){
#   for(a in 1:3){
#   #F.yr[y,1]~dlnorm(-1.81,8.8)       #prior for year and area-block specific instantaneous fishing mortality (annual)
#   F.yr[y,1,a]~dlnorm(-2.5,2) 
#   F[y,1,a]<-F.yr[y,1,a]/yrsteps
#  
#   #F.yr[y,2]~dlnorm(-1.12,9.5)       #prior for year and area-block specific instantaneous fishing mortality (annual)
#   F.yr[y,2,a]~dlnorm(-2.5,2)    
#   F[y,2,a]<-F.yr[y,2,a]/yrsteps
#}

for(a in 1:F_zones){
   mueF[a]~dlnorm(-2.5,2)   #median fishing mortality rate zone a
   LF[1:years,a]~dmnorm(muLogF[1:years,a],tauLF[1:years,1:years])
}

for(t in 1:years){
   for(a in 1:F_zones){
      F.yr[t,a]<-exp(LF[t,a])
      F.step[t,a]<-F.yr[t,a]/yrsteps
      F[t,a,1]<-F.step[t,a]
      F[t,a,2]<-F.step[t,a]*gamma.age2 
      F[t,a,3]<-F.step[t,a]*gamma.age3  
      muLogF[t,a]<-log(mueF[a])-0.5/TLF
   }          
   covF[t,t]<-1/TLF
   
   for(a in 1:nareas){
      p.detect.ac[a,t]~dbeta(1,1) #prior for area and year specific acoustic detection probabilities
   }

}
for(t in 1:(years-1)){
   for(k in (t+1):years){
      covF[t,k]<-covF[t,t]*pow(F_autoc,abs(t-k))
      covF[k,t]<-covF[t,k]
   }
}          

CVF~dunif(0.01,0.7)
TLF<-1/log(CVF*CVF+1)
F_autoc~dunif(0.1,0.9)
tauLF[1:years,1:years]<-inverse(covF[1:years,1:years])

#priors for age effects, class 2 and 3 relative to class 1
gamma.age2~dlnorm(0,10)
gamma.age3~dlnorm(0,10) 
 



p.detect.sat~T(dbeta(97.5,2.5),0.95, )  #prior for sat tag detection probability

o_sigma[1]~T(dlnorm(-0.69,5),,1)       #prior for spread of tag transmission life around programmed/expected life (acoustic tags)
o_delta~T(dlnorm(1,2),1,)
o_sigma[2]<-o_sigma[1]*o_delta

k_sigma[1]~T(dlnorm(-0.69,5),,1)       #prior for spread of tag transmission life around programmed/expected life (satellite tags)
k_delta~T(dlnorm(1,2),1,)
k_sigma[2]<-k_sigma[1]*k_delta

satlife~dlnorm(1.79,2)  #prior for satellite tag life (1 year)

for(a in 1:3){
M.yr[a]~dlnorm(-2.28,4)  #prior for annual instantaneous natural mortality M[3] prior from
 #Kurota et al #tau 111.7
 M[a]<-M.yr[a]/yrsteps
   
   for(y in 1:years){
   Z[y,1,a]<-F[y,1,a]+M[a]   #total mortality in 1 time step   #year, zone, age
   Z[y,2,a]<-F[y,2,a]+M[a]   #total mortality in 1 time step
   }
}


M.yrX~dlnorm(-2.28,4)  #M prior


M.tag~dbeta(2.5,47.5)    #prior for tagging related mortality
M.tagX~dbeta(2.5,47.5)

M.tag.ac<-M.tag          #2021 try setting these equal for single or double tagged fish
#M.tag.ac~dbeta(2.5,47.5)
#M.tag.acX~dbeta(2.5,47.5)

p.report.tag[1]~dbeta(1,1)  #prior for tag reporting rate (fishery recaptures)
#p.report.tag[2]~dbeta(1,1)
p.report.tag[2]<-p.report.tag[1]

#seasonal movement rates prior (Dirichlet)
for(i in 1:nseas){
    for(k in 1:nareas){
       for(j in 1:nareas){
             alpha[i,j,k]~dbeta(20,20)
            delta[i,j,k]~dgamma(alpha[i,j,k],1)
				    theta[i,j,k]<-delta[i,j,k]/sum(delta[i,j,1:nareas])
        }
    }
}

for(j in 1:maxsteps_all){
  for(k in 1:F_zones){
    for(a in 1:3){
      phi[j,k,a]<-exp(-Z[yr[j],k,a])  #phi=survival
      phi_ac[j,k,a]<-phi[j,k,a]
    }
  }
  for(i in 1:N){ 
     epsilon[i,j]<-equals(j,t_rel[i])*(1-M.tag)+(1-equals(j,t_rel[i])) #survival from tagging mort
  }
  for(i in 1:N_ac){ 
     epsilon_ac[i,j]<-equals(j,t_rel_ac[i])*(1-M.tag.ac)+(1-equals(j,t_rel_ac[i]))
  }
}


kappa_sat~dbeta(3,17) #mean 0.15

for(i in 1:N){   #loop over double tagged fish
  taglife[i]~dlnorm(taglife_exp[i],25)
  
  omega[i,1]<-1/(1+exp(-o_sigma[1]*(1-taglife[i])))
  kappa[i,1]<-kappa_sat
  
  for(j in 2:maxsteps){  
    #omega[i,j]<-1/(1+exp(-o_sigma*(j-taglife[i])))   #prob that ac tag stops transmitting after j time steps
    omega[i,j]<-step(j-taglife[i])*1/(1+exp(-o_sigma[2]*(j-taglife[i])))+(1-step(j-taglife[i]))*1/(1+exp(-o_sigma[1]*(j-taglife[i])))   #prob that ac tag stops transmitting after j time steps
    
    #kappa[i,j]<-1/(1+exp(-k_sigma*(j-satlife)))      #prob that sat tag stops transmitting after j time steps   
    kappa[i,j]<-step(j-satlife)*1/(1+exp(-k_sigma[2]*(j-satlife)))+(1-step(j-satlife))*1/(1+exp(-k_sigma[1]*(j-satlife)))  
  }
}

for(i in 1:N_ac){        #loop over single (acoustic) tagged fish
  
  taglife_ac[i]~dlnorm(taglife_exp_ac[i],25)
  
  omega_ac[i,1]<-1/(1+exp(-o_sigma[1]*(1-taglife_ac[i])))
  for(j in 2:maxsteps_ac){  
    #omega_ac[i,j]<-1/(1+exp(-o_sigma*(j-taglife_ac[i])))
    omega_ac[i,j]<-step(j-taglife_ac[i])*1/(1+exp(-o_sigma[2]*(j-taglife_ac[i])))+(1-step(j-taglife_ac[i]))*1/(1+exp(-o_sigma[1]*(j-taglife_ac[i])))   #prob that ac tag stops transmitting after j time steps
    
  }
}


for(i in 1:N){   #loop over double-tagged individuals

    #assign probabilities for each initial state
    for(k in 1:nstates){
        Pr0[i,k]<-equals(a_rel[i],k)
    }
  
#    #fill remaining cells with 0
#    for(j in 1:(t_rel[i]-1)){
#    
#       # alive[i,j]<-0
#    
#        for(ii in 1:nstates){
#            for(jj in 1:nstates){
#                px[ii,i,j,jj]<-0   
#            }
#            for(jj in 1:nstates_obs){
#            p_obs[ii,i,j,jj]<-0
#            }
#       } 
#    }

 #   alive[i,t_rel[i]] ~ dcat(Pr0[i,1:nstates])  #draw state for time step of release

    for(ii in 1:nstates){
        for(jj in 1:nstates_obs){
            p_obs[ii,i,t_rel[i],jj]<-0
        }
    } 

   yboth[i,t_rel[i]:maxsteps] ~ dHMM_ac(probInit = Pr0[i,1:nstates], 
                    probObs = p_obs[1:nstates,i,t_rel[i]:maxsteps,1:nstates_obs], # observation matrix
                    probTrans = px[1:nstates,i,t_rel[i]:maxsteps,1:nstates], # transition matrix
                    nstates=nstates,   
                    len = maxsteps-t_rel[i]+1) # nb of sampling occasions
                    
    for(j in t_rel[i]:maxsteps){     
     

      #State transitions px    
        
        #from both tags
        
        for(a in 1:nareas){
           for(aa in 1:nareas){
        
              px[(1+(a-1)*nstates_alive_obs),i,j,(1+(aa-1)*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*(1-omega[i,(j-t_rel[i]+1)])*(1-kappa[i,(j-t_rel[i]+1)])      #2 tags -> 2 tags
      
              px[(1+(a-1)*nstates_alive_obs),i,j,(2+(aa-1)*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*(1-omega[i,(j-t_rel[i]+1)])*kappa[i,(j-t_rel[i]+1)]          #lose sat tag
		   
              px[(1+(a-1)*nstates_alive_obs),i,j,(3+(aa-1)*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*omega[i,(j-t_rel[i]+1)]*(1-kappa[i,(j-t_rel[i]+1)])               #lose acoustic tag
       
              px[(1+(a-1)*nstates_alive_obs),i,j,(aa+nareas*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*(1-phi[j,zone[aa],cl[sat.age[i,j]]])*epsilon[i,j]*(F[yr[j],zone[aa],cl[sat.age[i,j]]]/Z[yr[j],zone[aa],cl[sat.age[i,j]]])                                        #recapt area aa
              
              px[(1+(a-1)*nstates_alive_obs),i,j,(aa+nareas*nareas)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*omega[i,(j-t_rel[i]+1)]*kappa[i,(j-t_rel[i]+1)]         #lose both tags

              #from acoustic tag only 
         px[(2+(a-1)*nstates_alive_obs),i,j,(1+(aa-1)*nstates_alive_obs)] <- 0
	       px[(2+(a-1)*nstates_alive_obs),i,j,(2+(aa-1)*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*(1-omega[i,(j-t_rel[i]+1)])
         px[(2+(a-1)*nstates_alive_obs),i,j,(3+(aa-1)*nstates_alive_obs)] <- 0
        
         px[(2+(a-1)*nstates_alive_obs),i,j,(aa+nareas*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*(1-phi[j,zone[aa],cl[sat.age[i,j]]])*epsilon[i,j]*(F[yr[j],zone[aa],cl[sat.age[i,j]]]/Z[yr[j],zone[aa],cl[sat.age[i,j]]])   
          px[(2+(a-1)*nstates_alive_obs),i,j,(aa+nareas*nareas)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*omega[i,(j-t_rel[i]+1)]        
         
         #from sat tag only
         px[(3+(a-1)*nstates_alive_obs),i,j,(1+(aa-1)*nstates_alive_obs)] <- 0
         px[(3+(a-1)*nstates_alive_obs),i,j,(2+(aa-1)*nstates_alive_obs)] <- 0
         px[(3+(a-1)*nstates_alive_obs),i,j,(3+(aa-1)*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*(1-kappa[i,(j-t_rel[i]+1)])        
         px[(3+(a-1)*nstates_alive_obs),i,j,(aa+nareas*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*(1-phi[j,zone[aa],cl[sat.age[i,j]]])*epsilon[i,j]*(F[yr[j],zone[aa],cl[sat.age[i,j]]]/Z[yr[j],zone[aa],cl[sat.age[i,j]]]) 
         px[(3+(a-1)*nstates_alive_obs),i,j,(aa+nareas*nareas)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]*kappa[i,(j-t_rel[i]+1)] 
                                
         }
}
#from recaptured (all go to dead bin)
for(a in (nareas*nstates_alive_obs+1):(nareas*nstates_alive_obs+nareas)){
    
     for(aa in 1:(nareas*nstates_alive+nareas)){
       px[a,i,j,aa] <- 0
     }
     px[a,i,j,(nareas*nstates_alive+nareas+1)] <- 1
}              
         
     for(a in 1:nareas){
           for(aa in 1:nareas){         
                                                                                          
         #from no tag
         px[(a+nareas*nareas),i,j,(1+(aa-1)*nstates_alive_obs)] <- 0     #to states 1-12
		     px[(a+nareas*nareas),i,j,(2+(aa-1)*nstates_alive_obs)] <- 0
		     px[(a+nareas*nareas),i,j,(3+(aa-1)*nstates_alive_obs)] <- 0
              
         px[(a+nareas*nareas),i,j,(aa+nareas*nstates_alive_obs)] <- theta[yrseas[s[j]],a,aa]*(1-phi[j,zone[aa],cl[sat.age[i,j]]])*epsilon[i,j]*(F[yr[j],zone[aa],cl[sat.age[i,j]]]/Z[yr[j],zone[aa],cl[sat.age[i,j]]])   #recaptures
         
         px[(a+nareas*nareas),i,j,(aa+nareas*nareas)] <- theta[yrseas[s[j]],a,aa]*phi[j,zone[aa],cl[sat.age[i,j]]]*epsilon[i,j]
       } #aa

        #2 tags to dead 
        px[(1+(a-1)*nstates_alive_obs),i,j,21] <-theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,1]*phi[j,zone[1],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,2]*phi[j,zone[2],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,3]*phi[j,zone[3],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,4]*phi[j,zone[4],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[1],cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[2],cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[3],cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[4],cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])
        
        #acoustic tag to dead 
        px[(2+(a-1)*nstates_alive_obs),i,j,21] <-theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,1]*phi[j,zone[1],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,2]*phi[j,zone[2],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,3]*phi[j,zone[3],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,4]*phi[j,zone[4],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[1],cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[2],cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[3],cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[4],cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])
        
        #satellite tag to dead 
        px[(3+(a-1)*nstates_alive_obs),i,j,21] <-theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,1]*phi[j,zone[1],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,2]*phi[j,zone[2],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,3]*phi[j,zone[3],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,4]*phi[j,zone[4],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[1],cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[2],cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[3],cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[4],cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])
        
        #no functioning tag to dead                                                
        px[(a+nareas*nareas),i,j,21] <-theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(M[cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,1]*phi[j,zone[1],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,2]*phi[j,zone[2],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,3]*phi[j,zone[3],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,4]*phi[j,zone[4],cl[sat.age[i,j]]]*(1-epsilon[i,j])+theta[yrseas[s[j]],a,1]*(1-phi[j,zone[1],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[1],cl[sat.age[i,j]]]/Z[yr[j],zone[1],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi[j,zone[2],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[2],cl[sat.age[i,j]]]/Z[yr[j],zone[2],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi[j,zone[3],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[3],cl[sat.age[i,j]]]/Z[yr[j],zone[3],cl[sat.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi[j,zone[4],cl[sat.age[i,j]]])*(1-epsilon[i,j])*(F[yr[j],zone[4],cl[sat.age[i,j]]]/Z[yr[j],zone[4],cl[sat.age[i,j]]])            
        
}  #a 

#from dead (trasition prob to other states = 0)
for(a in nstates:nstates){
    px[a,i,j,a] <- 1  #diagonal dead
    for(aa in 1:(a-1)){
       px[a,i,j,aa] <- 0
    }
}

#for(k in 1:nstates){
#    pxsum[k,i,j]<-sum(px[k,i,j,1:nstates])
#}                                                                                                                                
       
}   #j


    for (j in (t_rel[i]+1):maxsteps) {     

      
      pop_step[i,j]~dbern(kappa[i,(j-t_rel[i]+1)])  #observation model for sat tag pop-up date  
      #pop_stepX[i,j]~dbern(kappa[i,(j-t_rel[i]+1)])  
      
      #alive[i,j] ~ dcat(px[alive[i,(j-1)], i,(j-1),1:nstates])     ## STATE EQUATION ##  	# draw X(j) given X(j-1)

#########################################################################################################


        #define observation probabilities, 1st index of p_obs is true state
        #1,4,7,10 both tags detected areas 1-4
        #2,5,8,11 acoustic tag only detected areas 1-4
        #3,6,9,12 satelite tag only detected areas 1-4
        #13-16 recaptured areas 1-4
        #17 not detected          
        
        #state= both tags
        
        for(a in 1:nareas){  #state index = 1,4,7,10   
           #ac and sat detection
           p_obs[((a-1)*nstates_alive_obs+1),i,j,((a-1)*nstates_alive_obs+1)] <- p.detect.ac[a,yr[j]]*p.detect.sat
           #ac only detection
           p_obs[((a-1)*nstates_alive_obs+1),i,j,((a-1)*nstates_alive_obs+2)] <- p.detect.ac[a,yr[j]]*(1-p.detect.sat)
           #sat only detection
           p_obs[((a-1)*nstates_alive_obs+1),i,j,((a-1)*nstates_alive_obs+3)] <-(1-p.detect.ac[a,yr[j]])*p.detect.sat 
           #no detection
           p_obs[((a-1)*nstates_alive_obs+1),i,j,(nareas*nstates_alive+1)] <- (1-p.detect.ac[a,yr[j]])*(1-p.detect.sat)         
        
           #fill in the 0s
           for(aa in 1:((a-1)*nstates_alive_obs)){
              p_obs[((a-1)*nstates_alive_obs+1),i,j,aa]<-0.00001
           }
           for(aa in ((a-1)*nstates_alive_obs+4):(nareas*nstates_alive)){
              p_obs[((a-1)*nstates_alive_obs+1),i,j,aa]<-0.00001
           }
        }                                                                
        
        #state = acoustic tag only                                                                  
        for(a in 1:nareas){   #state index = 2,5,8,11          
           p_obs[((a-1)*nstates_alive_obs+2),i,j,((a-1)*nstates_alive_obs+2)] <- p.detect.ac[a,yr[j]]
           for(aa in 1:((a-1)*nstates_alive_obs+1)){
              p_obs[((a-1)*nstates_alive_obs+2),i,j,aa] <- 0.00001
           }
           for(aa in ((a-1)*nstates_alive_obs+3):(nareas*nstates_alive)){
              p_obs[((a-1)*nstates_alive_obs+2),i,j,aa] <- 0.00001
           }
        p_obs[((a-1)*nstates_alive_obs+2),i,j,(nareas*nstates_alive+1)] <- 1-p.detect.ac[a,yr[j]]
        }
        
        #state = sat tag only                                                                 
        for(a in 1:nareas){   #state index = 3,6,9,12 
           p_obs[((a-1)*nstates_alive_obs+3),i,j,((a-1)*nstates_alive_obs+3)] <- p.detect.sat   #diagonal
           for(aa in 1:((a-1)*nstates_alive_obs+2)){
              p_obs[((a-1)*nstates_alive_obs+3),i,j,aa] <- 0.00001      
           }
           for(aa in ((a-1)*nstates_alive_obs+4):(nareas*nstates_alive)){
              p_obs[((a-1)*nstates_alive_obs+3),i,j,aa] <- 0.00001       
           }
        p_obs[((a-1)*nstates_alive_obs+3),i,j,(nareas*nstates_alive+1)] <- 1-p.detect.sat
        }
        
        #state = recaptured                                                                 
        for(a in 1:nareas){ #state index = 13:16
           p_obs[(a+nareas*nstates_alive_obs),i,j,(a+nareas*nstates_alive_obs)] <- p.report.tag[zone[a]]
           for(aa in 1:(a+nareas*nstates_alive_obs-1)){
              p_obs[(a+nareas*nstates_alive_obs),i,j,aa] <- 0.00001
           }
           for(aa in (a+nareas*nstates_alive_obs+1):(nareas*nstates_alive)){
              p_obs[(a+nareas*nstates_alive_obs),i,j,aa] <- 0.00001
           }
        p_obs[(a+nareas*nstates_alive_obs),i,j,(nareas*nstates_alive+1)] <- 1-p.report.tag[zone[a]]
        }
                
        #state = no functioning tag 
        for(a in 1:nareas){
           for(aa in 1:(nareas*nstates_alive)){
              p_obs[(a+nareas*nareas),i,j,aa] <- 0.00001
		       }
           p_obs[(a+nareas*nareas),i,j,nstates_obs] <- 1 
        }
 
        
        #state = both tags shed or dead

        for(aa in 1:(nareas*nstates_alive)){
              p_obs[nstates,i,j,aa] <- 0.00001
        }
        p_obs[nstates,i,j,nstates_obs] <- 1 

           
        #tag_obs[((i-1)*maxsteps+j)] ~ dcat(p_obs[alive[i,j],i,j,1:nstates_obs])
        #tag_obsX[i,j] ~ dcat(p_obs[alive[i,j],i,j,1:nstates_obs])


    }
}

################################################# Acoustic only tuna ################################################################
#states
#1 alive with tag in area 1
#2 alive with tag in area 2
#3 alive with tag in area 3
#4 alive with tag in area 4

#5 recaptured area 1
#6 recaptured area 2
#7 recaptured area 3
#8 recaptured area 4

#9 alive, non-functioning tag area 1
#10 alive, non-functioning tag area 2
#11 alive, non-functioning tag area 3
#12 alive, non-functioning tag area 4

#13 dead natural mortality, emigrated


for(i in 1:N_ac){   #loop over single tagged fish

    # probabilities for each initial state

    for(k in 1:nstates_ac){
        Pr0_ac[i,k]<-equals(a_rel_ac[i],k)
    }


    #fill remaining cells with 0
    for(j in 1:(t_rel_ac[i]-1)){

        #alive_ac[i,j]<-0

        for(ii in 1:nstates_ac){
            for(jj in 1:nstates_ac){
                px_ac[ii,i,j,jj]<-0
            }
            for(jj in 1:nstates_obs_ac){
                p_obs_ac[ii,i,j,jj]<-0
            }
        }
    }

   # alive_ac[i,t_rel_ac[i]] ~ dcat(Pr0_ac[i,1:nstates_ac])

    for(ii in 1:nstates_ac){
        for(jj in 1:nstates_obs_ac){
            p_obs_ac[ii,i,t_rel_ac[i],jj]<-0
        }
    }
    
    yac[i,t_rel_ac[i]:maxsteps_ac] ~ dHMM_ac(probInit = Pr0_ac[i,1:nstates_ac], 
                    probObs = p_obs_ac[1:nstates_ac,i,t_rel_ac[i]:maxsteps_ac,1:nstates_obs_ac], # observation matrix
                    probTrans = px_ac[1:nstates_ac,i,t_rel_ac[i]:maxsteps_ac,1:nstates_ac], # transition matrix
                    nstates=nstates_ac,   
                    len = maxsteps_ac-t_rel_ac[i]+1) # nb of sampling occasions

    for(j in t_rel_ac[i]:maxsteps_ac){

        #from alive with acoustic tag
        for(a in 1:nareas){
            for(aa in 1:nareas){
            px_ac[a,i,j,aa] <- theta[yrseas[s[j]],a,aa]*phi_ac[j,zone[aa],cl[ac.age[i,j]]]*epsilon_ac[i,j]*(1-omega_ac[i,(j-t_rel_ac[i]+1)])
            px_ac[a,i,j,(aa+nareas)] <-theta[yrseas[s[j]],a,aa]*(1-phi_ac[j,zone[aa],cl[ac.age[i,j]]])*epsilon_ac[i,j]*(F[yr[j],zone[aa],cl[ac.age[i,j]]]/Z[yr[j],zone[aa],cl[ac.age[i,j]]])    #recaptured
            px_ac[a,i,j,(aa+2*nareas)] <- theta[yrseas[s[j]],a,aa]*phi_ac[j,zone[aa],cl[ac.age[i,j]]]*epsilon_ac[i,j]*omega_ac[i,(j-t_rel_ac[i]+1)] #alive tag dead
		        }

        px_ac[a,i,j,nstates_ac]<-theta[yrseas[s[j]],a,1]*(1-phi_ac[j,zone[1],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[1],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi_ac[j,zone[2],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[2],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi_ac[j,zone[3],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[3],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi_ac[j,zone[4],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[4],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,1]*(1-phi_ac[j,zone[1],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[1],cl[ac.age[i,j]]]/Z[yr[j],zone[1],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi_ac[j,zone[2],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[2],cl[ac.age[i,j]]]/Z[yr[j],zone[2],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi_ac[j,zone[3],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[3],cl[ac.age[i,j]]]/Z[yr[j],zone[3],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi_ac[j,zone[4],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[4],cl[ac.age[i,j]]]/Z[yr[j],zone[4],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,1]*phi_ac[j,zone[1],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])+theta[yrseas[s[j]],a,2]*phi_ac[j,zone[2],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])+theta[yrseas[s[j]],a,3]*phi_ac[j,zone[3],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])+theta[yrseas[s[j]],a,4]*phi_ac[j,zone[4],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])

        }

        #from recaptured
        for(a in (nareas+1):(nareas*2)){

            for(aa in 1:(nareas*3)){
               px_ac[a,i,j,aa] <- 0
             }
             px_ac[a,i,j,(nareas*3+1)] <- 1
        }

       #from alive with non-functioning tag
        for(a in 1:nareas){
            for(aa in 1:nareas){
            px_ac[(a+nareas*2),i,j,aa] <- 0
            px_ac[(a+nareas*2),i,j,(aa+nareas)] <-theta[yrseas[s[j]],a,aa]*(1-phi_ac[j,zone[aa],cl[ac.age[i,j]]])*epsilon_ac[i,j]*(F[yr[j],zone[aa],cl[ac.age[i,j]]]/Z[yr[j],zone[aa],cl[ac.age[i,j]]])    #recaptured
            px_ac[(a+nareas*2),i,j,(aa+2*nareas)] <- theta[yrseas[s[j]],a,aa]*phi_ac[j,zone[aa],cl[ac.age[i,j]]]*epsilon_ac[i,j]
		        }

        px_ac[(a+nareas*2),i,j,nstates_ac]<-theta[yrseas[s[j]],a,1]*(1-phi_ac[j,zone[1],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[1],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi_ac[j,zone[2],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[2],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi_ac[j,zone[3],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[3],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi_ac[j,zone[4],cl[ac.age[i,j]]])*(M[cl[ac.age[i,j]]]/Z[yr[j],zone[4],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,1]*(1-phi_ac[j,zone[1],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[1],cl[ac.age[i,j]]]/Z[yr[j],zone[1],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,2]*(1-phi_ac[j,zone[2],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[2],cl[ac.age[i,j]]]/Z[yr[j],zone[2],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,3]*(1-phi_ac[j,zone[3],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[3],cl[ac.age[i,j]]]/Z[yr[j],zone[3],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,4]*(1-phi_ac[j,zone[4],cl[ac.age[i,j]]])*(1-epsilon_ac[i,j])*(F[yr[j],zone[4],cl[ac.age[i,j]]]/Z[yr[j],zone[4],cl[ac.age[i,j]]])+theta[yrseas[s[j]],a,1]*phi_ac[j,zone[1],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])+theta[yrseas[s[j]],a,2]*phi_ac[j,zone[2],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])+theta[yrseas[s[j]],a,3]*phi_ac[j,zone[3],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])+theta[yrseas[s[j]],a,4]*phi_ac[j,zone[4],cl[ac.age[i,j]]]*(1-epsilon_ac[i,j])
        }

       #from dead

        px_ac[nstates_ac,i,j,nstates_ac] <- 1   #diagonal
        for(aa in 1:(nstates_ac-1)){
           px_ac[nstates_ac,i,j,aa] <- 0
        }

      #  for(k in 1:nstates_ac){
#           pxsum_ac[k,i,j]<-sum(px_ac[k,i,j,1:nstates_ac])
#        }
    } #j

 #   for (j in 1:t_rel_ac[i]){
#       tag_obs_acX[i,j]<-0
#    }
    for (j in (t_rel_ac[i]+1):maxsteps_ac){

    #    alive_ac[i,j] ~ dcat(px_ac[alive_ac[i,(j-1)], i,(j-1),1:nstates_ac])     ## STATE EQUATION ##  	# draw X(j) given X(j-1)

####################################################################################################################################

# Observation states
#1 alive with tag in area 1
#2 alive with tag in area 2
#3 alive with tag in area 3
#4 alive with tag in area 4

#5 recaptured area 1
#6 recaptured area 2
#7 recaptured area 3
#8 recaptured area 4

#9 dead, or alive with no tag any area

#define observation probabilities

        #state=alive with acoustic tag

        for(a in 1:nareas){
           p_obs_ac[a,i,j,a] <- p.detect.ac[a,yr[j]]
           for(aa in 1:(a-1)){
              p_obs_ac[a,i,j,aa] <- 0.00001
           }
           for(aa in (a+1):(nstates_obs_ac-1)){
              p_obs_ac[a,i,j,aa] <- 0.00001
           }
           p_obs_ac[a,i,j,nstates_obs_ac] <- 1-p.detect.ac[a,yr[j]]
        }

        #state=recaptured

		    for(a in (nareas+1):(nareas*2)){
           p_obs_ac[a,i,j,a] <- p.report.tag[zone[a-nareas]]
           for(aa in 1:(a-1)){
              p_obs_ac[a,i,j,aa] <- 0.00001
           }
           p_obs_ac[a,i,j,nstates_obs_ac] <- 1-p.report.tag[zone[a-nareas]]
        }
        for(a in (nareas+1):(nareas*2-1)){
           for(aa in (a+1):(nstates_obs_ac-1)){
              p_obs_ac[a,i,j,aa] <- 0.00001
           }
        }  
        

        #state= non-functioning tag

        for(a in (2*nareas+1):(3*nareas)){
           for(aa in 1:(nstates_obs_ac-1)){
              p_obs_ac[a,i,j,aa] <- 0.00001
		       }
           p_obs_ac[a,i,j,nstates_obs_ac] <- 1
        }


        #state both tags shed or dead
        for(aa in 1:(nstates_obs_ac-1)){
              p_obs_ac[nstates_ac,i,j,aa] <- 0.00001
        }
        p_obs_ac[nstates_ac,i,j,nstates_obs_ac] <- 1

    #    tag_obs_ac[((i-1)*maxsteps_ac+j)] ~ dcat(p_obs_ac[alive_ac[i,j],i,j,1:nstates_obs_ac])
    #    tag_obs_acX[i,j] ~ dcat(p_obs_ac[alive_ac[i,j],i,j,1:nstates_obs_ac])
    }

}
   
})   #Nimble