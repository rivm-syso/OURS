# -*- coding: utf-8 -*-
"""
Created on Thu Sep 12 12:16:59 2019

@author: Arnold Koopman

Todo:
    - meer sporen
"""

import argparse
import math
import json
import os
import numpy as np
from scipy import stats

MCgrootte = 33*333;    # streven: 333
np.random.seed(1235);  # fixeren laatste decimaal in de output

def deformule(Bron,FEM,Hgebouw,Overig):
    
    global VmaxMus,VmaxVars,VmaxDirs,VmaxFdoms, VtopMus,VtopVars,VtopDirs,VtopFdoms
    global Vmax_funderingMus,Vmax_funderingVars,Vmax_funderingDirs,Vmax_funderingFdoms
    global Vrms_maaiveldMus,Vrms_maaiveldVars,  VperMus,VperVars,  Varcoefs
    
    def Bronkracht(Bron,Idx, stijfheidsratioZ,stijfheidsratioX, covar_sZ,covar_sX, V):
        
        FzMcArray = np.ones([MCgrootte,6]);
        FxMcArray = np.ones([MCgrootte,6]);   
        sZmcArray = np.zeros([MCgrootte,6]);
        sXmcArray = np.zeros([MCgrootte,6]);
        sZmcArray = np.random.multivariate_normal(stijfheidsratioZ,covar_sZ,MCgrootte);
        sXmcArray = np.random.multivariate_normal(stijfheidsratioX,covar_sX,MCgrootte);
        sZmcArray[np.where(sZmcArray<0)] = 0;
        sXmcArray[np.where(sXmcArray<0)] = 0;
        sZmcArray[np.where(sZmcArray>1)] = 1;
        sXmcArray[np.where(sXmcArray>1)] = 1;
        for bron in range(2):
            Refbron = Bron[Idx[bron]];
            Vref = np.array(Refbron["Vref"]); # 1
            FZ0  = np.array(Refbron["FZ0"]);  # 1x6
            FZ1  = np.array(Refbron["FZ1"]);  # 1x6
            FX0  = np.array(Refbron["FX0"]);  # 1x6
            FX1  = np.array(Refbron["FX1"]);  # 1x6
            n0   = np.array(Refbron["n0"]);   # 1
            n1   = np.array(Refbron["n1"]);   # 1
            dFZ0 = np.array(Refbron["dFZ0"]);  # 1x6  varcoef
            dFZ1 = np.array(Refbron["dFZ1"]);  # 1x6  varcoef
            dFX0 = np.array(Refbron["dFX0"]);  # 1x6  varcoef
            dFX1 = np.array(Refbron["dFX1"]);  # 1x6  varcoef
            dn0  = np.array(Refbron["dn0"]);   # 1    std of minmax
            dn1  = np.array(Refbron["dn1"]);   # 1    std of minmax       
            FZ0[np.where(FZ0==0)] = 1;
            FZ1[np.where(FZ1==0)] = 1;
            FX0[np.where(FX0==0)] = 1;
            FX1[np.where(FX1==0)] = 1;
            # eigenlijk hier covars maken van dF
            n0mcArray = np.random.normal(n0,dn0,MCgrootte);
            n1mcArray = np.random.normal(n1,dn1,MCgrootte);
            FZ0mcArray = montecarloMetCovariantieLognormaal(FZ0,dFZ0,MCgrootte);
            FX0mcArray = montecarloMetCovariantieLognormaal(FX0,dFX0,MCgrootte);      
            FZ1mcArray = montecarloMetCovariantieLognormaal(FZ1,dFZ1,MCgrootte);
            FX1mcArray = montecarloMetCovariantieLognormaal(FX1,dFX1,MCgrootte);    
            for mc in range(MCgrootte):
#                FZ0mc = FZ0 * np.random.lognormal(0,dFZ0);
#                FX0mc = FX0 * np.random.lognormal(0,dFX0);
#                FZ1mc = FZ1 * np.random.lognormal(0,dFZ1);
#                FX1mc = FX1 * np.random.lognormal(0,dFX1);
                sz   = bron + ((-1)**bron)*sZmcArray[mc]; # s resp (1-s)
                sx   = bron + ((-1)**bron)*sXmcArray[mc]; # s resp (1-s)
                TFZ1 = shiftspectrum(FZ1mcArray[mc],Vref,V);
                TFX1 = shiftspectrum(FX1mcArray[mc],Vref,V);
                FzMcArray[mc,:] = FzMcArray[mc,:] + sz * (FZ0mcArray[mc]*(V/Vref)**n0mcArray[mc] + TFZ1*(V/Vref)**n1mcArray[mc] );
                FxMcArray[mc,:] = FxMcArray[mc,:] + sx * (FX0mcArray[mc]*(V/Vref)**n0mcArray[mc] + TFX1*(V/Vref)**n1mcArray[mc] );  
        Fz  = np.mean(FzMcArray, axis=0); # 1x6    
        Fx  = np.mean(FxMcArray, axis=0); # 1x6  
        muZ  = 1e3*Fz;  # in Bronbestand staan kN, om mooie getallen rond 1 te krijgen
        muX  = 1e3*Fx;
        varZ = np.std(FzMcArray, axis=0)/Fz;
        varX = np.std(FxMcArray, axis=0)/Fx;
    
        # covar maken met maximaal verband tussen banden
        covZ = np.sqrt(np.ones([6,6]) * np.transpose(varZ[np.newaxis]) * varZ); # @ np.diag(var_c);
        #covZ = covZ* np.transpose(muZ[np.newaxis]) * muZ;
        covX = np.sqrt(np.ones([6,6]) * np.transpose(varX[np.newaxis]) * varX); # @ np.diag(var_c);
        #covX = covX* np.transpose(muX[np.newaxis]) * muX;
        Verdeling = {'muZ':muZ, 'covZ':covZ,  'muX':muX, 'covX':covX};
        return Verdeling
    
    
    def Stijfheidsratio(FEM,Bron,Idx):
        hoog           = Idx[0];
        laag           = Idx[1];   #np.array(Bodem["Y"]); 
        BronHoog       = Bron[hoog];
        BronLaag       = Bron[laag];
        ZoHoog         = np.array(BronHoog["Zo"]);
        ZoLaag         = np.array(BronLaag["Zo"]);
        Yo             = np.array(FEM["Yo"]);
        Yo_ratio       = np.array(FEM["Yo_ratio"]);
        YHoog_ratio    = np.array(BronHoog["Y_ratio"]);
        YLaag_ratio    = np.array(BronLaag["Y_ratio"]);
    
        varZoHoog      = np.array(BronHoog["dZo"]);
        varZoLaag      = np.array(BronLaag["dZo"]);
        varYo          = np.array(FEM["var_Yo"]);
        varYo_ratio    = np.array(FEM["var_Yo_ratio"]);
        varYHoog_ratio = np.array(BronHoog["dY_ratio"]);
        varYLaag_ratio = np.array(BronLaag["dY_ratio"]);
    
        # controle op lege banden in Yo
        legebanden          = np.where(Yo==0); 
        Yo[legebanden]       = 1e-11;
        Yo_ratio[legebanden] = 1; 
        
#        # covars van vars maken
#        covYo       = np.ones([6,6]) * np.transpose(varYo[np.newaxis]) * varYo; # maximale relaties tussen banden
#        covYo_ratio = np.ones([6,6]) * np.transpose(varYo_ratio[np.newaxis]) * varYo_ratio; # maximale relaties tussen banden
#        
#        # covariantiecoefficienten weer covariantie matrix
#        covarYo       = np.sign(covYo)       * Yo*np.transpose([Yo]) * covYo**2;
#        covarYo_ratio = np.sign(covYo_ratio) * Yo_ratio*np.transpose([Yo_ratio]) * covYo_ratio**2;

        YoMC       = montecarloMetCovariantieLognormaal(Yo,       varYo,       MCgrootte);
        Yo_ratioMC = montecarloMetCovariantieNormaal   (Yo_ratio, varYo_ratio, MCgrootte); 
        
        ZoHoogMC      = montecarloMetCovariantieLognormaal(ZoHoog,      varZoHoog,      MCgrootte);
        ZoLaagMC      = montecarloMetCovariantieLognormaal(ZoLaag,      varZoLaag,      MCgrootte);
        YHoog_ratioMC = montecarloMetCovariantieLognormaal(YHoog_ratio, varYHoog_ratio, MCgrootte);
        YLaag_ratioMC = montecarloMetCovariantieLognormaal(YLaag_ratio, varYLaag_ratio, MCgrootte);
        
        # fix 8 maart 2020, vanwege overgang van lognormal naar multivariate.normal
        YoMC[np.where(YoMC<=0)]             = 1e-11;
        Yo_ratioMC[np.where(Yo_ratioMC<=0)] = .1;
        ZoHoogMC[np.where(ZoHoogMC<=0)] = 1e7;
        ZoLaagMC[np.where(ZoLaagMC<=0)] = 1e6;
        YHoog_ratioMC[np.where(YHoog_ratioMC<=0)] = .1;
        YLaag_ratioMC[np.where(YLaag_ratioMC<=0)] = .1;
        
        stijfheidsratioZ = np.zeros([MCgrootte,6]);
        stijfheidsratioX = np.zeros([MCgrootte,6]);  
        for mc in range(MCgrootte):
#            ZoHoogmc      = ZoHoog      * np.random.lognormal(0,varZoHoog);
#            ZoLaagmc      = ZoLaag      * np.random.lognormal(0,varZoLaag);
#            #Yomc          = np.random.multivariate_normal(Yo,      covarYo);
#            #Yo_ratiomc    = np.random.multivariate_normal(Yo_ratio,covarYo_ratio);
#            YHoog_ratiomc = YHoog_ratio * np.random.lognormal(0,varYHoog_ratio);
#            YLaag_ratiomc = YLaag_ratio * np.random.lognormal(0,varYLaag_ratio);
            ZoLaagmc = ZoLaagMC[mc];
            ZoHoogmc = ZoHoogMC[mc];
            YHoog_ratiomc = YHoog_ratioMC[mc];
            YLaag_ratiomc = YLaag_ratioMC[mc];
            stijfheidsratioZ[mc,:] = -np.log(YoMC[mc] * ZoLaagmc) / np.log(ZoHoogmc / ZoLaagmc);
            stijfheidsratioX[mc,:] = -np.log(YoMC[mc] * ZoLaagmc * Yo_ratioMC[mc] / YLaag_ratiomc) / np.log(ZoHoogmc / ZoLaagmc * YLaag_ratiomc / YHoog_ratiomc);
        
        stijfheidsratioX[np.where(stijfheidsratioX<0)] = 0;
        stijfheidsratioZ[np.where(stijfheidsratioZ<0)] = 0;
        stijfheidsratioX[np.where(stijfheidsratioX>1)] = 1;
        stijfheidsratioZ[np.where(stijfheidsratioZ>1)] = 1;
        muZ  = np.mean(stijfheidsratioZ,axis=0);
        muX  = np.mean(stijfheidsratioX,axis=0);
#        varZ = np.std (stijfheidsratioZ,axis=0)/abs(muZ);
#        varX = np.std (stijfheidsratioX,axis=0)/abs(muX);
        covarZ = np.cov(stijfheidsratioZ,rowvar=False);
        covarX = np.cov(stijfheidsratioX,rowvar=False);
        Verdeling = {'muZ':muZ, 'covarZ':covarZ,  'muX':muX, 'covarX':covarX};
        return Verdeling
    
    
    def Vloer(Vmu,Vvar,Hmu,Hcovar):   # de statistiek!
        # Vvar is een variantie
        # Hcovar is een covariantiecoefficient (raar ding)
        Hcovar =  (Hmu*np.transpose([Hmu])) * np.sign(Hcovar) * Hcovar**2;
        covHiViHjVj = np.zeros([6,6]);
        for i1 in range(6):
            for i2 in range(6):
                if i1==i2:
                    covHiViHjVj[i1,i1] = Hmu[i1]**2*Hcovar[i1,i1]*(Vvar[i1]+Vmu[i1]**2)**2 + Vmu[i1]**2*Vvar[i1]*(Hcovar[i1,i1]+Hmu[i1]**2)**2; # + 4*Hmu[i1]**2*Hcovar[i1,i1]*Vmu[i1]**2*Vvar[i1];
                else:
                    covHiViHjVj[i1,i2] = Hmu[i1]*Hmu[i2]*(Vvar[i1]+Vmu[i1]**2)*(Vvar[i2]+Vmu[i2]**2)*Hcovar[i1,i2];
        sigmaSum = np.sqrt(sum(sum(4*covHiViHjVj)));  # was: 4*cov
        muBand = np.zeros(6);
        for i1 in range(6):
            muBand[i1] = (Vmu[i1]**2 + Vvar[i1])*(Hmu[i1]**2 + Hcovar[i1,i1]) ;
        muSum          = sum(muBand);
        sigma          = sigmaSum/(2*np.sqrt(muSum));
        mu             = np.sqrt(muSum - sigma**2);
        dominanteBand  = np.argmax(muBand);
        var            = sigma/mu;
        Verdeling = {'mu':mu, 'sigma':sigma, 'dominanteBand': dominanteBand, 'var': var};
        return Verdeling
    
    
    def RSSmetCovarNormaal(Hmu,Hcovar):   # de statistiek!
        # invoer: gemiddelde Hmu en covariatiecoefficient van een normaal verdeelde H
        # uitvoer: mediaan, standaard deviatie (wortel variantie) en variatiecoefficient van RMS
        Hcovar =  (Hmu*np.transpose([Hmu])) * np.sign(Hcovar) * Hcovar**2;
        covHiViHjVj = np.zeros([6,6]);
        for i1 in range(6):
            for i2 in range(6):
                if i1==i2:
                    covHiViHjVj[i1,i1] = Hmu[i1]**2*Hcovar[i1,i1];  # was: Hmu[i1]**2*Hcovar[i1,i1]
                else:
                    covHiViHjVj[i1,i2] = Hmu[i1]*Hmu[i2]*Hcovar[i1,i2];  # was Hmu[i1]*Hmu[i2]*Hcovar[i1,i2]
        sigmaSum = np.sqrt(sum(sum(4*covHiViHjVj)));
        muBand = np.zeros(6);
        for i1 in range(6):
            muBand[i1] = Hmu[i1]**2 + Hcovar[i1,i1] ;
        muSum          = sum(muBand);
        sigma          = sigmaSum/(2*np.sqrt(muSum));
        mu             = np.sqrt(muSum - sigma**2);
        dominanteBand  = np.argmax(muBand);        
        var = sigma/mu;
        mu = mu/np.sqrt(1+var**2);  # mediaan dus
        Verdeling = {'mu':mu, 'sigma':sigma, 'dominanteBand': dominanteBand, 'var': var};
        return Verdeling

    def VloerLognormaal(Vmul,Vvarl,Hmu,Hcovar):   # de statistiek!
        # Vvarl is een variantie van een lognormaal verdeelde V
        # Hcovar is een covariantiecoefficient (raar ding) van een normaal verdeelde H
        Vmul[np.where(Vmul==0)]=1e-20;  # conditionering van de input, blijkt dat soms een band leeg is.
        
        # V naar normale verdeling brengen, met schaling naar mu = 0;
        Vvar = np.log(1+Vvarl/Vmul**2);
#        Vmu  = np.log(Vmul) - Vvar/2;   # er van uitgaande dat Vmul een gemiddelde is en geen mediaan
        # V2mu  = Vmul**2 * (1 + 2*Vmu + 2*Vmu**2 + Vmu**3 + .25*Vmu**4 + Vvar*(2 + 3*Vmu + 1.5*Vmu**2) + .75*Vvar**2 ); # checken!
        V2mu  = Vmul**2 * np.exp(Vvar);
        #V2mu = np.exp(2*Vmu+2*Vvar);
        #V2var = Vmul**4 * Vvar * (4 + 16*Vmu + 28*Vmu**2 + 28*Vmu**3 + 17*Vmu**4 + 6*Vmu**5 + Vmu**6);    #   (4 + 16*Vmu**2 + 9*Vmu**4 + Vmu**6);
#        Taylor = 2 + 4*Vmu + 4*Vmu**2 + (8/3)*Vmu**3 + (5/4)*Vmu**4 + (15/36)*Vmu**5 + (7/72)*Vmu**6 + (1/72)*Vmu**7;   
#        V2var = Vmul**4 * Vvar * Taylor**2; 
        
        V2var = 4*Vvarl*Vmul**2 + 2*Vvarl**2; 
        
        Hcovar =  (Hmu*np.transpose([Hmu])) * np.sign(Hcovar) * Hcovar**2;
        covHiViHjVj = np.zeros([6,6]);
        for i1 in range(6):
            for i2 in range(6):
                if i1==i2:
                    covHiViHjVj[i1,i1] = 4 * Hmu[i1]**2      * Hcovar[i1,i1] * V2mu[i1]**2     +   V2var[i1] * (Hcovar[i1,i1]+Hmu[i1]**2)**2; # + 4*Hmu[i1]**2*Hcovar[i1,i1]*Vmu[i1]**2*Vvar[i1];
                else:
                    covHiViHjVj[i1,i2] = 4 * Hmu[i1]*Hmu[i2] * Hcovar[i1,i2] * V2mu[i1]*V2mu[i2];
        sigmaSum = np.sqrt(sum(sum(covHiViHjVj)));  # was: 4*cov
        muBand = np.zeros(6);
        for i1 in range(6):
            muBand[i1] = V2mu[i1] * (Hmu[i1]**2 + Hcovar[i1,i1]) ;
        muSum          = sum(muBand);
        #lvaSum = np.log(1+(sigmaSum/muSum)**2);
        #lmuSum = np.log(muSum) - lvaSum/2;
        #mu     = np.exp(lmuSum/2 + lvaSum/8);
        sigma          = np.sqrt(sigmaSum**2/(4*muSum) + sigmaSum**4/(32*muSum**3) );
        dominanteBand  = np.argmax(muBand);
        
#        mu             = np.sqrt(muSum - sigma**2);
#        var            = sigma/mu;
#        mu             = mu/np.sqrt(1+var**2);  # mediaan dus
        # bovenstaande gaat mis bij var>1, daarom anders:
        mu  = np.sqrt(np.sum(Vmul**2*Hmu**2));  # directe bepaling van mediaan,   # directe bepaling van mediaan, deze formule nog afleiden!
        gem = mu*np.sqrt((1+np.sqrt(1+4*sigma**2/mu**2))/2);  # lelijke formule, kan dit niet beter?
        var = sigma/gem;         
 
        # ten behoeve van bepaling bijdrage H, de sigma van covH = 0:
        sigmaSum = np.sqrt(sum(V2var*Hmu**4));
        muSum    = sum(V2mu*Hmu**2);
        varV   = np.sqrt(sigmaSum**2/(4*muSum) + sigmaSum**4/(32*muSum**3) ) / gem;
        varH   = np.sqrt(abs(var**2 - varV**2)) * np.sign(var**2 - varV**2);
        
        Verdeling = {'mu':mu, 'sigma':sigma, 'dominanteBand': dominanteBand, 'var': var, 'varV': varV, 'varH': varH};
        return Verdeling
    
    def RSSmetCovarLognormaal(Ymu,Ycovar):   # de statistiek!
        # invoer: gemiddelde Ymu en covariatiecoefficient van een lognormaal verdeelde Y
        # uitvoer: mediaan, standaard deviatie (wortel variantie) en variatiecoefficient van RMS
        # bepalen van mu en covar van  normaal verdeelde variabel X (Y=exp(X))
        Ymu[np.where(Ymu==0)]=1e-20;  # conditionering van de input, blijkt dat soms een band leeg is.
        Xcovariantie = np.log(1+Ycovar**2);  # covariantiematrix
        Xva          = np.diagonal(Xcovariantie); 
        Xmu          = np.log(Ymu) - Xva/2;
        #Xmu          = - Xva/2;
        #Xmu          = np.zeros(6); # indien mediaan is aangeleverd, maar dan ook Ycovar niet op basis van Ymu
        # stap naar Y**2
        #Y2mu          = Ymu**2 * (1 + 2*Xmu + 2*Xmu**2 + Xmu**3 + .25*Xmu**4 + Xva*(2 + 3*Xmu + 1.5*Xmu**2) + .75*Xva**2 ); # checken!
        #Y2mu          = Ymu**2 * (1 - 2*Xmu + 2*Xmu**2 - (7/12)*Xmu**4 - (33/18)*Xmu**5 + (17/18)*Xmu**6 - (1/12)*Xmu**7 + (1/576)*Xmu**8 );
        #Y2mu          = Ymu**2 * np.exp(2*Xmu+2*Xva);
        #Y2mu          = Ymu**2 * np.exp(Xva);
        Y2mu          = np.exp(2*Xmu+2*Xva);
        Y2covariantie = (4*Ycovar**2 + 2*Ycovar**4 ) * (Ymu*np.transpose([Ymu]))**2;                  
#        Y2covariantie = np.zeros([6,6]);
#        Y3covariantie = np.zeros([6,6]);
#        for i1 in range(6):
#            for i2 in range(6):               
#                # Taylor = (2 + 4*Xmu[i1] + 3*Xmu[i1]**2 + Xmu[i1]**3) * (2 + 4*Xmu[i2] + 3*Xmu[i2]**2 + Xmu[i2]**3);      # (4 + 16*mum + 28*mum**2 + 28*mum**3 + 17*mum**4 + 6*mum**5 + mum**6);               
#                Taylor1 = 2 + 4*Xmu[i1] + 4*Xmu[i1]**2 + (8/3)*Xmu[i1]**3 + (5/4)*Xmu[i1]**4 + (15/36)*Xmu[i1]**5 + (7/72)*Xmu[i1]**6 + (1/72)*Xmu[i1]**7;  
#                Taylor2 = 2 + 4*Xmu[i2] + 4*Xmu[i2]**2 + (8/3)*Xmu[i2]**3 + (5/4)*Xmu[i2]**4 + (15/36)*Xmu[i2]**5 + (7/72)*Xmu[i2]**6 + (1/72)*Xmu[i2]**7;  
#                Y2covariantie[i1,i2] = (Ymu[i1]*Ymu[i2])**2 * Xcovariantie[i1,i2] * Taylor1 * Taylor2;  # was  * (4 + 16*mu2 + 9*mu2**2 + mu2**3 );
#                Y3covariantie[i1,i2] = (4*Ycovar[i1,i2]**2) * (Ymu[i1]*Ymu[i2])**2 + 2 * (Ycovar[i1,i2]**4) * (Ymu[i1]*Ymu[i2])**2;
        sigmaSum       = np.sqrt(sum(sum(Y2covariantie)));
        muSum          = np.sum(Y2mu);
        # we gaan er van uit dat dit resultaat ook weer lognormaal verdeeld is
        sigma          = np.sqrt(sigmaSum**2/(4*muSum) + sigmaSum**4/(32*muSum**3) );
        dominanteBand  = np.argmax(Y2mu);   
#        lvaSum         = np.log(1+(sigmaSum/muSum)**2);
#        lmuSum         = np.log(muSum) - lvaSum/2;
#        mu             = np.exp(lmuSum/2 + lvaSum/8);
#        var            = sigma/mu;
#        mu             = mu/np.sqrt(1+var**2);  # mediaan dus
        # bovenstaande gaat mis bij var>1, daarom anders:
        mu  = np.sqrt(np.sum(Ymu**2));  # directe bepaling van mediaan, 
        gem = mu*np.sqrt((1+np.sqrt(1+4*sigma**2/mu**2))/2);  # lelijke formule, kan dit niet beter?
        var = sigma/gem;
        Verdeling = {'mu':mu, 'sigma':sigma, 'dominanteBand': dominanteBand, 'var': var};
        return Verdeling
    
    
    def shiftspectrum(Yin,Vin,Vuit):
        shift=np.log2(Vuit/Vin);
        lengte=len(Yin);
        Y=np.zeros(lengte);
        heleshift=int(np.floor(shift));
        if heleshift>=0:
            Y[heleshift:lengte] = Yin[0:lengte-heleshift];
        else:
            Y[0:lengte+heleshift] = Yin[0-heleshift:lengte];
        fracshift=np.mod(shift,1);
        Ye  = Y**2;
        Ye2 = Ye*(1-fracshift);
        Ye2[1:lengte] = Ye2[1:lengte] + Ye[0:lengte-1]*fracshift;
        Yuit=np.sqrt(Ye2);
        return Yuit
    
    
    def CovariantProduct(X,cov_X,Y,cov_Y):  # X,Y,factor zijn vectoren  
        # cov_X is covariantiecoefficient (dus wortel van cov/mu^2, met teken)
        Xmatrix      = X * np.transpose(X[np.newaxis]);
        Ymatrix      = Y * np.transpose(Y[np.newaxis]);
        # echte covariantie:
    #    covariantieX = np.sign(cov_X) * cov_X**2 * Xmatrix;
    #    covariantieY = np.sign(cov_Y) * cov_Y**2 * Ymatrix;
    #    covariantieT = covariantieX*Ymatrix + covariantieY*Xmatrix + covariantieX*covariantieY;
        covariantieX = np.sign(cov_X) * cov_X**2;
        covariantieY = np.sign(cov_Y) * cov_Y**2;
        tekenX = np.sign(Xmatrix);
        tekenY = np.sign(Ymatrix);
        covariantieT = covariantieX + covariantieY + covariantieX * covariantieY;
        cov          = np.sign(covariantieT) * tekenX * tekenY * np.sqrt(np.abs(covariantieT));
        return cov
    
    
    def OutputSamenstellen(Index):
        
        global VmaxMus,VmaxVars,VmaxDirs,VmaxFdoms, VtopMus,VtopVars,VtopDirs,VtopFdoms
        global Vmax_funderingMus,Vmax_funderingVars,Vmax_funderingDirs,Vmax_funderingFdoms
        global Vrms_maaiveldMus,Vrms_maaiveldVars,  VperMus,VperVars,  Varcoefs
        
        if len(Index) > 0:
            VperSigs          = VperVars[Index] * VperMus[Index];
            # VperSig           = np.sqrt(np.sum(VperSigs**2 * VperMus[Index]**2,axis=0) / np.sum(1e-18 + VperMus[Index]**2 + VperSigs**2,axis=0)); # fout?
            VperSig           = np.sqrt(np.sum(VperSigs**2 * VperMus[Index]**2,axis=0) / np.sum(1e-18 + VperMus[Index]**2,axis=0));
            VperMu            = np.sqrt(np.sum(VperMus[Index]**2,axis=0) + np.sum(VperSigs**2,axis=0) - VperSig**2);
            
            VmaxMu            = np.max(VmaxMus[Index]);
            Imax              = Index[np.argmax(VmaxMus[Index])];  
            VmaxSig           = VmaxMu*VmaxVars[Imax];
            VmaxDir           = VmaxDirs[Imax];
            VmaxFdom          = VmaxFdoms[Imax]; 
            Varcoef           = Varcoefs[Imax,[6,7,8]]; # resp.: bron, bodem, gebouw; vanuit gebouwperspectief
            Varcoef_maaiveld  = Varcoefs[Imax,[0,1,2]]; # resp.: bronkracht, bron-bodem interactie, bodem; vanuit bodemperspectief
            Varcoef_fundering = Varcoefs[Imax,[3,4,5]]; # resp.: bron, bodem, bodem-gebouwinteractie; vanuit fundatieperspectief
            
            VtopMu            = np.max(VtopMus[Index]);
            Imax              = Index[np.argmax(VtopMus[Index])];  
            VtopSig           = VtopMu*VtopVars[Imax];
            VtopVd            = 1.6 * (VtopMu + 1.66*VtopSig);
            VtopDir           = VtopDirs[Imax];
            VtopFdom          = VtopFdoms[Imax];
            
            Vmax_funderingMu  = Vmax_funderingMus[Imax];
            Vmax_funderingSig = Vmax_funderingMu * Vmax_funderingVars[Imax];
            Vmax_funderingDir = Vmax_funderingDirs[Imax];
            Vmax_funderingFdom = Vmax_funderingFdoms[Imax];
            
            Vrms_maaiveldMu   = np.max(Vrms_maaiveldMus[Index]);
            Imax              = Index[np.argmax(Vrms_maaiveldMus[Index])];  
            Vrms_maaiveldSig  = Vrms_maaiveldVars[Imax] * Vrms_maaiveldMu;
            
            VmaxMu            = np.round(VmaxMu,            decimals=2);
            VmaxSig           = np.round(VmaxSig,           decimals=3);
            Vrms_maaiveldMu   = np.round(Vrms_maaiveldMu,   decimals=2);
            Vrms_maaiveldSig  = np.round(Vrms_maaiveldSig,  decimals=3);
            #stijfheidsratioZ  = np.round(stijfheidsratioZ,  decimals=2);
            VtopMu            = np.round(VtopMu,            decimals=2);
            VtopSig           = np.round(VtopSig,           decimals=3);
            VtopVd            = np.round(VtopVd,            decimals=2);
            VperMu            = np.round(VperMu,            decimals=3);
            VperSig           = np.round(VperSig,           decimals=4);
            Vmax_funderingMu  = np.round(Vmax_funderingMu,  decimals=2);
            Vmax_funderingSig = np.round(Vmax_funderingSig, decimals=3);
            Varcoef           = np.round(Varcoef,           decimals=2);
            Varcoef_maaiveld  = np.round(Varcoef_maaiveld,  decimals=2);
            Varcoef_fundering = np.round(Varcoef_fundering, decimals=2);
        else:
            VmaxMu            = np.zeros(1);
            VmaxSig           = np.zeros(1);
            Vrms_maaiveldMu   = np.zeros(1);
            Vrms_maaiveldSig  = np.zeros(1);
            #stijfheidsratioZ  = np.zeros(1);
            VtopMu            = np.zeros(1);
            VtopSig           = np.zeros(1);
            VtopVd            = np.zeros(1);
            VperMu            = np.zeros(3);
            VperSig           = np.zeros(3);
            Vmax_funderingMu  = np.zeros(1);
            Vmax_funderingSig = np.zeros(1);   
            Varcoef           = np.zeros(3);
            Varcoef_maaiveld  = np.zeros(3);
            Varcoef_fundering = np.zeros(3);
            VmaxDir           = '';
            VmaxFdom          = '';
            VtopDir           = '';
            VtopFdom          = '';
            Vmax_funderingDir = '';
            Vmax_funderingFdom = '';
            
        Maaiveld  = {'Vrms':           Vrms_maaiveldMu.item(0), 
                     'Vrms_sigma':     Vrms_maaiveldSig.item(0),
                     'variatiecoeffs': Varcoef_maaiveld.tolist()};          # op termijn hier baan-bodem interactie
        Fundering = {'Vmax':           Vmax_funderingMu.item(0),
                     'Vmax_sigma':     Vmax_funderingSig.item(0),
                     'Vtop':           VtopMu.item(0),
                     'Vtop_sigma':     VtopSig.item(0),
                     'Vtop_Vd':        VtopVd.item(0),
                     'Vtop_Dir':       VtopDir,
                     'Vtop_Fdom':      VtopFdom,
                     'Vmax_Dir':       Vmax_funderingDir,
                     'Vmax_Fdom':      Vmax_funderingFdom,
                     'variatiecoeffs': Varcoef_fundering.tolist()};
        Gebouw    = {'Vmax':           VmaxMu.item(0),       # tolist maakt van np array een gewone array ?
                     'Vmax_sigma':     VmaxSig.item(0),
                     'Vper':           VperMu.tolist(),
                     'Vper_sigma':     VperSig.tolist(),
                     'Vmax_Dir':       VmaxDir,
                     'Vmax_Fdom':      VmaxFdom,    
                     'variatiecoeffs': Varcoef.tolist()};
        
        Resultaten = {'Maaiveld': Maaiveld, 'Fundering': Fundering, 'Gebouw': Gebouw};  
           
        return Resultaten
    
    
    
    # HIER BEGINT HET !
    
    # def deformule(Bron,FEM,Hgebouw,Overig):
    # wat invoer uitpakken (rest gaat direct naar subfuncties)
    snelheid = np.array(Overig["snelheid"]);   # met lengte aantaltreintypes
    Vd       = np.array(Overig["Vd"]);         # boolean, switch
    R        = np.array(Overig["R"]);          # afstand, scalar
    CgeoZ    = np.array(Overig["CgeoZ"]);      # 1x6
    CgeoX    = np.array(Overig["CgeoX"]);      # 1x6
    scenarioKansen  = np.array(Overig["scenarioKansen"]);      # 1xiets
    aantaltreinenPW = np.array(Overig["aantaltreinenPerWeek"]); # per dagdeel, dus aantaltreintypes x 3
    if "treinklasse" in Overig:
        treinklasse = Overig["treinklasse"]; # met lengte aantaltreintypes
    else:
        treinklasse = [];
        print('Warning: treinklasses niet opgegeven, dus reizigers en goederen dan maar op 1 hoop')

    if "brontype" in Overig:
        brontype = Overig["brontype"]; # met lengte aantal afstanden, dus voorlopig 1
    else:
        brontype = 1;
        print('Warning: brontype niet opgegeven, dus we gaan uit van doorgaand spoor')

    # scenarioKansen wegen
    scenarioKansen = scenarioKansen/sum(scenarioKansen);

    # perceptieweging kiezen
    if Vd:   # tov Wn, waarmee bron al gewogen is
        dWk = np.array([0.56, 1.2 , 1.8,  2.3,  2.3,  2.1]);   # z richting
        dWd = np.array([0.95, 0.63, 0.44, 0.38, 0.37, 0.33]);  # x richting
    else:
        dWk = np.ones(6);
        dWd = np.ones(6);

    # aantaltreintypes bepalen
    aantaltreintypes    = len(snelheid);

    # lege invoer aanvullen met default waardes en berekeningen
    if not(isinstance(treinklasse,list)):
        treinklasse=[treinklasse];
    if len(treinklasse)==0:         
        treinklasse = [0];   # 0 = onbekend / alles, 1 = reizigers 2= goederen
    elif len(treinklasse)>1 and (0 in treinklasse):   # gekke situatie, mag niet
        exit(204) 
    if len(treinklasse)>1 and not(len(treinklasse)==aantaltreintypes):
        exit(205)

    # eerst Bron structure controleren, komt die overeen met snelheid array?
    if not(isinstance(Bron[0],list)):
        Bron=[Bron];
    if not(len(Bron)==aantaltreintypes):   # reparatiepogingen doen
        if len(Bron)==1: # dan blijkbaar zelfde trein bij verschillende snelheden
            for treinnr in range(aantaltreintypes-1):
                Bron.append(Bron[0]);
        elif  aantaltreintypes==1: # blijkbaar meerdere treintypes met zelfde snelheid
            aantaltreintypes = len(Bron);
            snelheid         = np.ones(aantaltreintypes)*snelheid;
        else:
            exit(201)

    totaalaantaltreinen = np.zeros(aantaltreintypes);      # per type
    aantaltreinen       = np.zeros([aantaltreintypes,3]);  # per type, per dagdeel
        
    if aantaltreintypes>1: 
        if np.ndim(aantaltreinenPW)==2:
            if np.size(aantaltreinenPW,axis=0)==aantaltreintypes and np.size(aantaltreinenPW,axis=1)==3:
                aantaltreinen       = aantaltreinenPW;
                totaalaantaltreinen = np.sum(aantaltreinen,axis=1); 
            elif np.size(aantaltreinenPW,axis=0)==1 or np.size(aantaltreinenPW,axis=1)==1: # vector of zelfs scalar
                aantaltreinenPW = aantaltreinenPW[0];  # bij de volgende if verder bestuderen.
            else: # something rotten in the state of Denmark
                exit(202)
        
        if np.ndim(aantaltreinenPW)<2: # probleem: geen 2D array maar een 1D of een scalar
            if len(aantaltreinenPW)==1: # scalar zelfs
                for treinnr in range(aantaltreintypes):
                    totaalaantaltreinen[treinnr] = aantaltreinenPW/aantaltreintypes; # ik interpreteer dat we aantal treinen maar moeten gaan verdelen
                    aantaltreinen[treinnr] = np.array([12,4,2])*totaalaantaltreinen[treinnr]/18;
            else: # array maar met wat er in?
                if len(aantaltreinenPW)==3 and not(aantaltreintypes==3): # array van dagdelen
                    for treinnr in range(aantaltreintypes):
                        aantaltreinen[treinnr] = aantaltreinenPW/aantaltreintypes;
                    totaalaantaltreinen = np.sum(aantaltreinen,axis=1);   
                elif len(aantaltreinenPW)==aantaltreintypes and not(aantaltreintypes==3): # array van treintupen
                    totaalaantaltreinen = aantaltreinenPW;
                    for treinnr in range(aantaltreintypes):
                        aantaltreinen[treinnr] = np.array([12,4,2])*totaalaantaltreinen[treinnr]/18;
                else:
                    exit(202)  # 3 getallen bij 3 treintypes, onduidelijk hoe te interpreteren    
    else:
        if np.ndim(aantaltreinenPW)<2: # repareren
            aantaltreinenPW = np.expand_dims(aantaltreinenPW,axis=0);
        if np.size(aantaltreinenPW,axis=1)==1:   # scalar, ik verdeel ze over de dagdelen, met reizigersritme
            totaalaantaltreinen[0] = aantaltreinenPW[0,0];
            aantaltreinen[0] = np.array([12,4,2])*aantaltreinenPW[0,0]/18;
        elif np.size(aantaltreinenPW,axis=1)==3:    # array van dagdelen
            totaalaantaltreinen[0] = np.sum(aantaltreinenPW[0]);
            aantaltreinen = aantaltreinenPW;
        else:
            exit(203) # verkeerde lengte van een input
    
    if isinstance(R, list):         # indien scalar, dan list van maken
        aantalafstanden = len(R);   # doen we nu nog nix mee, zal UI nu moeten doen
    else:
        R = [R];
        aantalafstanden = 1;
    if aantalafstanden>1:
        exit(206)
        
    aantalScenarios  = len(scenarioKansen);
    axi2lineExponent = (1-np.sqrt(2))/np.sqrt(8);
    if R[0]<25 or not brontype==1:
        axi2line = 1;
    else:
        axi2line = (25/R[0])**(axi2lineExponent);
        
#    if not brontype==1:
#        CgeoZ = 1.5*np.ones(6);   # komt uit Schadeprotocol
#        CgeoX = 1.5*np.ones(6);       
            
    VmaxMus             = np.zeros(aantaltreintypes);
    VmaxVars            = np.zeros(aantaltreintypes);
    VmaxDirs            = [];
    VmaxFdoms           = []; 
    VperMus             = np.zeros([aantaltreintypes,3]);
    VperVars            = np.zeros([aantaltreintypes,3]);
    VtopMus             = np.zeros(aantaltreintypes);
    VtopVars            = np.zeros(aantaltreintypes);
    VtopDirs            = [];
    VtopFdoms           = [];
    Vrms_maaiveldMus    = np.zeros(aantaltreintypes);
    Vrms_maaiveldVars   = np.zeros(aantaltreintypes);
    Vmax_funderingMus   = np.zeros(aantaltreintypes);
    Vmax_funderingVars  = np.zeros(aantaltreintypes);
    Vmax_funderingDirs  = [];
    Vmax_funderingFdoms = []; 
    # resp. Bronkracht, Bron-bodem interactie, Totale Bron, Bodem, Bodem-Gebouw, Totale gebouw:
    Varcoefs            = np.zeros([aantaltreintypes,9]);  
    
    for treintypenr in range(aantaltreintypes):
        BronInfo = Bron[treintypenr];
        # constanten:
        aantalBronnen    = len(BronInfo);    # aantal gevonden bronmetingen, grootte van Bron

        VmaxMuss             = np.zeros(aantalScenarios);
        VmaxVarss            = np.zeros(aantalScenarios);
        VmaxDirss            = [];
        VmaxFdomss           = []; 
        VperMuss             = np.zeros([3,aantalScenarios]);
        VperVarss            = np.zeros([3,aantalScenarios]);
        VtopMuss             = np.zeros(aantalScenarios);
        VtopVarss            = np.zeros(aantalScenarios);
        VtopDirss            = [];
        VtopFdomss           = [];
        Vrms_maaiveldMuss    = np.zeros(aantalScenarios);
        Vrms_maaiveldVarss   = np.zeros(aantalScenarios);
        Vmax_funderingMuss   = np.zeros(aantalScenarios);
        Vmax_funderingVarss  = np.zeros(aantalScenarios);
        Vmax_funderingDirss  = [];
        Vmax_funderingFdomss = []; 
        Varcoefss            = np.zeros([9,aantalScenarios]);
        
        for scenario in range(aantalScenarios):
            FEMscenario     = FEM[scenario];
            HgebouwScenario = Hgebouw[scenario];
            Y           = np.array(FEMscenario["Y"]);             # 1x6 uit FEM, naar ontvangpunt
            Y_ratio     = np.array(FEMscenario["Y_ratio"]);       # 1x6
            varY        = np.array(FEMscenario["var_Y"]);         # 6x6 covariantiecoefficient
            varY_ratio  = np.array(FEMscenario["var_Y_ratio"]);   # nog neit in gebruik
            
            # van covariantiecoefficienten echte covariantiematrices maken
            cov_Y       = np.ones([6,6]) * np.transpose(varY[np.newaxis]) * varY; # maximale relaties tussen banden
            cov_Y_ratio = np.ones([6,6]) * np.transpose(varY_ratio[np.newaxis]) * varY_ratio; # maximale relaties tussen banden

            
            # Eerst maar eens de brongegevens bepalen, door ze te kiezen uit de gemeten bronnen kiezen
            if aantalBronnen==1:    # dan kiezen we nu die meting, in feite zonder de bronkracht te modificeren
                BronIdxHoogLaag  = [0,0];
                sZ     = np.ones(6);
                sX     = np.ones(6);
                covar_sZ = np.zeros([6,6]);
                covar_sX = np.zeros([6,6]);
            elif aantalBronnen==2:
                BronIdxHoogLaag = [0,1];
                DictOut   = Stijfheidsratio(FEMscenario,BronInfo,BronIdxHoogLaag);  # structure: stijfheidsratio.x (1x6) stijfheidsratio.z (1x6)
                sZ        = DictOut['muZ'];
                sX        = DictOut['muX'];
                covar_sZ  = DictOut['covarZ'];
                covar_sX  = DictOut['covarX'];
            else:                    # >2 cases, we gaan per band de dichtstbij omliggende kiezen, wel tricky eigenlijk
                Yo   = np.array(FEMscenario["Yo"]);
                afstand = np.zeros(aantalBronnen);
                for i1 in range(aantalBronnen):
                   BronIn = BronInfo[i1];
                   Zo   = np.array(BronIn["Zo"]); 
                   afstand[i1] = np.mean(np.log(Yo[1:5]*Zo[1:5]));
                afstand = np.argsort(abs(afstand));
                BronIdxHoogLaag = afstand[range(2)];
#
#                   
#                teller = 0;
#                aantalmogelijkheden = int(math.factorial(aantalBronnen)/math.factorial(aantalBronnen-2)/2);
#                match = np.zeros(aantalmogelijkheden);
#                combi = [0 for y in range(aantalmogelijkheden)]
#                for i1 in range(aantalBronnen):
#                    for i2 in range(i1+1,aantalBronnen):
#                        DictOut = Stijfheidsratio(FEMscenario,BronInfo,[i1,i2]);
#                        sZ      = DictOut['muZ'];
#                        combi[teller] = [i1,i2];
#                        s       =  sZ[1:5];  # banden 1 en 6 gooi ik maar weg want wild en dominant
#                        # op zoek naar combi met ratio tussen 0 en 1 en zo dicht mogelijk bij 0 of 1,
#                        laagm = np.mean(abs(s)-(np.mean(s))) + np.mean(abs(s));       # zo dicht mogelijk bij 0
#                        hoogm = np.mean(abs(1-s)-(np.mean(1-s))) + np.mean(abs(1-s)); # zo dicht mogelijk bij 1
#                        match[teller] = min([laagm,hoogm]);
#                        teller = teller + 1 ;
#                print(match)
#                bestmatch = np.argmin(match);
#                BronIdxHoogLaag = combi[bestmatch];
#                print(BronIdxHoogLaag)
                DictOut   = Stijfheidsratio(FEMscenario,BronInfo,BronIdxHoogLaag);  # structure: stijfheidsratio.x (1x6) stijfheidsratio.z (1x6)
                sZ        = DictOut['muZ'];
                sX        = DictOut['muX'];
                covar_sZ  = DictOut['covarZ'];
                covar_sX  = DictOut['covarX'];
#            stijfheidsratioZ     = sZ;
#            stijfheidsratioX     = sX;
            
            # dan de bronkracht corrigeren cq vaststellen
            DictOut = Bronkracht(BronInfo,BronIdxHoogLaag,sZ,sX,covar_sZ,covar_sX,snelheid[treintypenr]);          # structure F:   F.x,F.z
            FZ      = DictOut['muZ'];
            FX      = DictOut['muX'];
            cov_FZ  = DictOut['covZ'];     # covariantiecoefficient
            cov_FX  = DictOut['covX'];

            # bepalen van totale onzekerheid in bron
            maxZ = np.sqrt(sum(FZ**2));    # 5% herstel van verlies door octaafbanddecompositie
            maxX = np.sqrt(sum(FX**2));    # en van meters/s naar mm/s
            if maxZ>=maxX:
                DictOut = RSSmetCovarLognormaal(FZ,cov_FZ);
            else:
                DictOut = RSSmetCovarLognormaal(FX,cov_FX);
            Varcoefss[1,scenario] = DictOut['var'];      # totale bron onzekerheid
            
            # F en Y samenbrengen tot Vrms_maaiveld (de kernformule)
            Vrms_maaiveldZ     = FZ * CgeoZ * Y *           axi2line;
            Vrms_maaiveldX     = FX * CgeoX * Y * Y_ratio * axi2line;
            cov_Vrms_maaiveldZ = CovariantProduct(FZ*CgeoZ, cov_FZ, Y*axi2line,         cov_Y);
            cov_Vrms_maaiveldX = CovariantProduct(FX*CgeoX, cov_FX, Y*axi2line*Y_ratio, cov_Y);
            
            # uitvoer van maaiveldniveau, tbv toekomstige regelgeving
            maxZ = np.sqrt(sum(Vrms_maaiveldZ**2))*1.05*1e3;    # 5% herstel van verlies door octaafbanddecompositie
            maxX = np.sqrt(sum(Vrms_maaiveldX**2))*1.05*1e3;    # en van meters/s naar mm/s
            if maxZ>=maxX:
                DictOut = RSSmetCovarLognormaal(Vrms_maaiveldZ,cov_Vrms_maaiveldZ);
#                Varcoefss[0,scenario] = np.sqrt(np.sum((np.diagonal(cov_FZ)*FZ)**2)/np.sum(FZ**2));
#                Varcoefss[1,scenario] = np.sqrt(np.sum((np.diagonal(cov_Vrms_maaiveldZ)*Vrms_maaiveldZ)**2)/np.sum(Vrms_maaiveldZ**2));
            else:
                DictOut = RSSmetCovarLognormaal(Vrms_maaiveldX,cov_Vrms_maaiveldX);
#                Varcoefss[0,scenario] = np.sqrt(np.sum((np.diagonal(cov_FX)*FX)**2)/np.sum(FX**2));
#                Varcoefss[1,scenario] = np.sqrt(np.sum((np.diagonal(cov_Vrms_maaiveldX)*Vrms_maaiveldX)**2)/np.sum(Vrms_maaiveldX**2));
            Vrms_maaiveldMuss[scenario]  = DictOut['mu'] * 1.05*1e3;
            Vrms_maaiveldVarss[scenario] = DictOut['var'];  
            
            # bijdrage bodemvoortplankng aan totale onzekerheid;
            Varcoefverschil = Vrms_maaiveldVarss[scenario]**2 - Varcoefss[1,scenario]**2;
            Varcoefss[2,scenario] = np.sign(Varcoefverschil) * np.sqrt(np.abs(Varcoefverschil));
            
            # combineren met Hgebouw tot Vrms_vloer
            # Vrms_vloer 1x4, resp. z1, z2, x1 en x2
            Vrms_vloerMu   = np.zeros(4);
            Vrms_vloerVar  = np.zeros(4);
            Vrms_overdrVar = np.zeros(4);
            Vrms_gebouwVar = np.zeros(4);
            Vrms_bronVar   = np.zeros(4);
            Vrms_bodemVar = np.zeros(4);
            
            DominanteBand = [0,0,0,0];
            var_Vrms_maaiveldZ = np.diagonal(cov_Vrms_maaiveldZ); # quick fix, liever straks de hele covar Vloer
            var_Vrms_maaiveldX = np.diagonal(cov_Vrms_maaiveldX);
            
            # Vertikale maaiveldtrillingen naar de vloer (3 paden)
            Vmu        =  Vrms_maaiveldZ * dWk;
            #Vvar   = (var_Vrms_maaiveldZ * dWk)**2;  # b9g question: dF en zo: 1 of 2 keer sig?  ik ga nu uit van 1 keer sig...
            Vvariantie =  (var_Vrms_maaiveldZ * Vmu)**2;
            # ten behoeve van bijdrage van bron aan onzekerheid
            Fmu        =  FZ * CgeoZ * Y*axi2line;
            Fvariantie = (FZ * CgeoZ * np.diagonal(cov_FZ))**2 *  Y**2*axi2line**2;

            # Vrms_vloer z1:
            Hmu     = np.array(HgebouwScenario["Hzz1"]);
            Hcovar  = np.array(HgebouwScenario["cov_Hzz1"]);   
            DictOut = VloerLognormaal(Vmu,Vvariantie,Hmu,Hcovar);
            Vrms_vloerMu[0]   = DictOut['mu'];
            Vrms_vloerVar[0]  = DictOut['var'];
            DominanteBand[0]  = DictOut['dominanteBand'];
            Vrms_overdrVar[0] = DictOut['varV'];  # bron+overdracht
            Vrms_gebouwVar[0] = DictOut['varH'];  # gebouw
            DictOut = VloerLognormaal(Fmu,Fvariantie,Hmu,Hcovar);
            Vrms_bronVar[0]   = DictOut['varV'];  # bron
            
            # Vrms_vloer z2:
            Hmu     = np.array(HgebouwScenario["Hzz2"]);
            Hcovar  = np.array(HgebouwScenario["cov_Hzz2"]);
            DictOut = VloerLognormaal(Vmu,Vvariantie,Hmu,Hcovar);
            Vrms_vloerMu[1]  = DictOut['mu'];
            Vrms_vloerVar[1] = DictOut['var'];
            DominanteBand[1] = DictOut['dominanteBand'];
            Vrms_overdrVar[1] = DictOut['varV'];  # bron+overdracht
            Vrms_gebouwVar[1] = DictOut['varH'];  # gebouw
            DictOut = VloerLognormaal(Fmu,Fvariantie,Hmu,Hcovar);
            Vrms_bronVar[1]   = DictOut['varV'];  # bron

            # Vrms_vloer x1:
            Hmu     = np.array(HgebouwScenario["Hzx"]);
            Hcovar  = np.array(HgebouwScenario["cov_Hzx"]);
            DictOut = VloerLognormaal(Vmu,Vvariantie,Hmu,Hcovar);
            Vrms_vloerMu[2]  = DictOut['mu'];
            Vrms_vloerVar[2] = DictOut['var'];
            DominanteBand[2] = DictOut['dominanteBand'];
            Vrms_overdrVar[2] = DictOut['varV'];  # bron+overdracht
            Vrms_gebouwVar[2] = DictOut['varH'];  # gebouw
            DictOut = VloerLognormaal(Fmu,Fvariantie,Hmu,Hcovar);
            Vrms_bronVar[2]   = DictOut['varV'];  # bron
            
            # Horizontale maaiveldtrillingen naar de vloer (1 pad)
            Vmu    =  Vrms_maaiveldX * dWd;
            Vvariantie  =  (var_Vrms_maaiveldX * Vmu)**2;
            # ten behoeve van bijdrage van bron aan onzekerheid
            Fmu        =  FX * CgeoX * Y*axi2line * Y_ratio;
            Fvariantie = (FX * CgeoX * np.diagonal(cov_FX))**2 * Y**2*axi2line**2 * Y_ratio**2;
            
            # Vrms_vloer x2:
            Hmu     = np.array(HgebouwScenario["Hxx"]);
            Hcovar  = np.array(HgebouwScenario["cov_Hxx"]);
            DictOut = VloerLognormaal(Vmu,Vvariantie,Hmu,Hcovar);
            Vrms_vloerMu[3]  = DictOut['mu'];
            Vrms_vloerVar[3] = DictOut['var'];
            DominanteBand[3] = DictOut['dominanteBand'];
            Vrms_overdrVar[3] = DictOut['varV'];  # bron+overdracht
            Vrms_gebouwVar[3] = DictOut['varH'];  # gebouw
            DictOut = VloerLognormaal(Fmu,Fvariantie,Hmu,Hcovar);
            Vrms_bronVar[3]   = DictOut['varV'];  # bron
            
            # Maximum bepalen van de vier trilvormen
            VrmsvloerMax = np.max(Vrms_vloerMu);
            Imax         = np.argmax(Vrms_vloerMu);
            
            VeffmaxMu             = 1.95 * VrmsvloerMax * 1e3;  # in mm/s
            if totaalaantaltreinen[treintypenr]>=1:
               VmaxMuss[scenario] = VeffmaxMu * np.exp(.3*stats.t.ppf(1-1/totaalaantaltreinen[treintypenr],np.round(totaalaantaltreinen[treintypenr])));
            else:
               VmaxMuss[scenario] = 0
            # spreiding is die van dominante trilvorm
            VmaxVarss[scenario]   = Vrms_vloerVar[Imax];        # dit moet echt 1x sigma zijn !
            VarcoefbijdrageBron   = Vrms_bronVar[Imax];
            VarcoefbijdrageOverdr = Vrms_overdrVar[Imax];
            VarcoefbijdrageGebouw = Vrms_gebouwVar[Imax];
            
            # bijdrage gebouw aan totale onzekerheid
            Varcoefss[6,scenario] = VarcoefbijdrageBron;  # totale bron, vanuit vloer gezien
            Varcoef2verschil      = VarcoefbijdrageOverdr**2 - VarcoefbijdrageBron**2;
            Varcoefss[7,scenario] = np.sqrt(abs(Varcoef2verschil)) * np.sign(Varcoef2verschil);
            Varcoefss[8,scenario] = VarcoefbijdrageGebouw;
            
#            Varcoefverschil = VmaxVarss[scenario]**2 - np.sign(Varcoefss[3,scenario])*Varcoefss[3,scenario]**2 - Varcoefss[2,scenario]**2;
#            Varcoefss[6,scenario] = np.sign(Varcoefverschil) * np.sqrt(np.abs(Varcoefverschil));
            
            richtingen  = ['zz','zz','zx','xx'];
            frequenties = ['2 Hz','4 Hz','8 Hz','16 Hz','32 Hz','63 Hz'];
            VmaxDirss.append(richtingen[Imax]); # 1..4, zz zz zx xx
            VmaxFdomss.append(frequenties[DominanteBand[Imax]]);
            
            # Hieruit Vper
            x = np.linspace(.1,10,991);  # in mm/s,  stapgrootte .01, dat meenemen in de integraal => .1
            PDF = np.exp(-(np.log(x)-np.log(VeffmaxMu))**2/(.18))/(x*.752);
            aantalperiodes = [1440,480,960];  # dag,avond,nacht
            VperMu = np.zeros(3);
            for dagdeel in range(3):
                dagdeelratio = aantaltreinen[treintypenr,dagdeel]/7/aantalperiodes[dagdeel];
                VperMu[dagdeel]  = .1*np.sqrt(dagdeelratio*np.sum(PDF*x**2)); 
            VperVarss[:,scenario] = VmaxVarss[scenario];
            VperMuss[:,scenario]  = VperMu;
            
            
            # Nu de fundering: Vtop (schade) en Vmaxfundering
            Vrms_funderingMu  = np.zeros(2);
            Vrms_funderingVar = np.zeros(2);
            DominanteBandFund = [0,0];
            # horizontaal
            Vmu     = Vrms_maaiveldX;
            Vvariantie  =  (var_Vrms_maaiveldX * Vmu)**2;
            Hmu     = np.array(HgebouwScenario["Hfxx"]);
            Hcovar  = np.array(HgebouwScenario["cov_Hfxx"]);
            DictOut = VloerLognormaal(Vmu,Vvariantie,Hmu,Hcovar);
            Vrms_funderingMu[0]  = DictOut['mu'];
            Vrms_funderingVar[0] = DictOut['var'];
            DominanteBandFund[0] = DictOut['dominanteBand'];
            Vrms_gebouwVar[0]    = DictOut['varH'];  # fundering apart
            Vrms_bodemVar[0]     = DictOut['varV'];  # vanuit oogpunt fundeirng
            Fmu        =  FX * CgeoX * Y*axi2line * Y_ratio;
            Fvariantie = (FX * CgeoX * np.diagonal(cov_FX))**2 * Y**2*axi2line**2 * Y_ratio**2;
            DictOut = VloerLognormaal(Fmu,Fvariantie,Hmu,Hcovar);
            Vrms_bronVar[0]      = DictOut['varV'];  # bron
            
            # vertikaal
            Vmu     = Vrms_maaiveldZ;
            Vvariantie  =  (var_Vrms_maaiveldZ * Vmu)**2;
            Hmu     = np.array(HgebouwScenario["Hfzz"]);
            Hcovar  = np.array(HgebouwScenario["cov_Hfzz"]);
            DictOut = VloerLognormaal(Vmu,Vvariantie,Hmu,Hcovar);
            Vrms_funderingMu[1]  = DictOut['mu'];
            Vrms_funderingVar[1] = DictOut['var'];
            DominanteBandFund[1] = DictOut['dominanteBand'];   
            Vrms_gebouwVar[1]    = DictOut['varH'];  # fundering apart
            Vrms_bodemVar[1]     = DictOut['varV'];  # vanuit oogpunt fundeirng
            Fmu        =  FZ * CgeoZ * Y*axi2line;
            Fvariantie = (FZ * CgeoZ * np.diagonal(cov_FZ))**2 * Y**2*axi2line**2;
            DictOut = VloerLognormaal(Fmu,Fvariantie,Hmu,Hcovar);
            Vrms_bronVar[1]      = DictOut['varV'];  # bron
            
            # Maximum bepalen van de twee trilrichtingen
            VrmsfunderingMax = np.max(Vrms_funderingMu);
            Imax             = np.argmax(Vrms_funderingMu);   
            # Daarmee Vmax en Vtop op de fundering uitrekenen
            if totaalaantaltreinen[treintypenr]>=1:
               Vmax_funderingMuss[scenario]  = 1.95 * VrmsfunderingMax * np.exp(.3*stats.t.ppf(1-1/totaalaantaltreinen[treintypenr],totaalaantaltreinen[treintypenr])) * 1e3;  # in [-]
            else:
               Vmax_funderingMuss[scenario]  = 0;
            VtopMuss[scenario]            = 2.4  * Vmax_funderingMuss[scenario];
            # spreiding is die van dominante trilrichting
            VtopVarss[scenario]           = Vrms_funderingVar[Imax];        # dit moet echt 1x sigma zijn !
            Vmax_funderingVarss[scenario] = Vrms_funderingVar[Imax];        # dit moet echt 1x sigma zijn !
            
            # bijdrage bodem-gebouw interactie aan totale onzekerheid
#            Varcoefverschil = Vmax_funderingVarss[scenario]**2 - np.sign(Varcoefss[3,scenario])*Varcoefss[3,scenario]**2 - Varcoefss[2,scenario]**2;
#            Varcoefss[4,scenario] = np.sign(Varcoefverschil) * np.sqrt(np.abs(Varcoefverschil));
            Varcoefss[3,scenario] = Vrms_bronVar[Imax];
            Varcoefss[4,scenario] = Vrms_bodemVar[Imax];  # bodem vanuit fundering
            Varcoefss[5,scenario] = Vrms_gebouwVar[Imax]; # 
            
            richtingen  = ['xx','zz'];
            frequenties = ['2 Hz','4 Hz','8 Hz','16 Hz','32 Hz','63 Hz'];
            VtopDirss.append(richtingen[Imax]); # 1..4, zz zz zx xx
            VtopFdomss.append(frequenties[DominanteBandFund[Imax]]);
            Vmax_funderingDirss.append(richtingen[Imax]); # 1..4, zz zz zx xx
            Vmax_funderingFdomss.append(frequenties[DominanteBandFund[Imax]]);
            
        
        # wrap up van de scenario's
        IndexDominanteScenario = np.argmax(scenarioKansen);    
        
        VmaxMus[treintypenr]            = np.sum(VmaxMuss  *scenarioKansen);
        VmaxVars[treintypenr]           = np.sum(VmaxVarss *scenarioKansen);
        VmaxDirs.append                  (VmaxDirss [IndexDominanteScenario]);
        VmaxFdoms.append                 (VmaxFdomss[IndexDominanteScenario]); 
        VperMus [treintypenr]           = np.sum(VperMuss  *scenarioKansen, axis=1);
        VperVars[treintypenr]           = np.sum(VperVarss *scenarioKansen, axis=1);
        VtopMus [treintypenr]           = np.sum(VtopMuss  *scenarioKansen);
        VtopVars[treintypenr]           = np.sum(VtopVarss *scenarioKansen);
        VtopDirs.append                  (VtopDirss [IndexDominanteScenario]);
        VtopFdoms.append                 (VtopFdomss[IndexDominanteScenario]);
        Vmax_funderingMus [treintypenr] = np.sum(Vmax_funderingMuss  *scenarioKansen);
        Vmax_funderingVars[treintypenr] = np.sum(Vmax_funderingVarss *scenarioKansen);
        Vmax_funderingDirs.append        (Vmax_funderingDirss [IndexDominanteScenario]);
        Vmax_funderingFdoms.append       (Vmax_funderingFdomss[IndexDominanteScenario]);       
        Vrms_maaiveldMus  [treintypenr] = np.sum(Vrms_maaiveldMuss   *scenarioKansen);
        Vrms_maaiveldVars [treintypenr] = np.sum(Vrms_maaiveldVarss  *scenarioKansen);
        
        Varcoefs[treintypenr] = np.sum(Varcoefss *scenarioKansen, axis=1);

    # resultaten van alle treintypes samenbrengen, per treinklasse
    IndexReizigers = [i for i,e in enumerate(treinklasse) if e==1];
    IndexGoederen  = [i for i,e in enumerate(treinklasse) if e==2];
    IndexAlles     = range(aantaltreintypes);

    ResultatenReizigers   = OutputSamenstellen(IndexReizigers);
    ResultatenGoederen    = OutputSamenstellen(IndexGoederen);              
    ResultatenAlleTreinen = OutputSamenstellen(IndexAlles);                  
      
    Resultaten = { 'AlleTreinen': ResultatenAlleTreinen,      
                   'Reizigers':   ResultatenReizigers,
                   'Goederen':    ResultatenGoederen};
                                    
    return Resultaten


def montecarloMetCovariantieNormaal(X,varX,MCgrootte):
    covX    = np.ones([6,6]) * np.transpose(varX[np.newaxis]) * varX; # maximale relaties tussen banden
    #covX    = np.diag(np.ones(6)) * np.transpose(varX[np.newaxis]) * varX; # geen relaties tussen banden
    covarX  = X *np.transpose([X]) * covX;
    XMC     = np.random.multivariate_normal(X,covarX,MCgrootte);
    #MCX     = np.swapaxes(XMC,0,1);
    return XMC

def montecarloMetCovariantieLognormaal(X,varX,MCgrootte):
    sigmalog = np.sqrt(np.log(1+varX**2));
    meanlog  = np.log(X) - (sigmalog**2)/2;
    variatiecoefflog = sigmalog/meanlog;
    covX    = np.ones([6,6]) * np.transpose(variatiecoefflog[np.newaxis]) * variatiecoefflog; # maximale relaties tussen banden
    #covX    = np.diag(np.ones(6)) * np.transpose(varX[np.newaxis]) * varX; # geen relaties tussen banden
    covarX  = meanlog *np.transpose([meanlog]) * covX;
    XMC     = np.exp(np.random.multivariate_normal(meanlog,covarX,MCgrootte));
    #MCX     = np.swapaxes(XMC,0,1);
    return XMC


def read_json(file_name):
    import json
    try:
        with open(file_name, "r") as fid:
             data = json.load(fid);  
    except OSError:
        exit(101)
    return data

    
def write_json(file_name, VmaxEtc):
    try:
       with open(file_name, "w+") as fid:
           json.dump(VmaxEtc, fid, separators=(',', ': '), sort_keys=True, indent=4)
    except OSError:
       exit(102)
    return

    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--json', help='input JSON file', required=True)
    parser.add_argument('-o', '--output', help='location of the output folder', required=True)
    args = parser.parse_args();
    Invoer  = read_json(args.json);                                        # reads input json file
    Uitvoer = deformule(Invoer["Bron"],Invoer["FEM"],Invoer["Hgebouw"],Invoer["Overig"]);   # do the work
    uitfile = os.path.join(args.output,"deformuleUit.json");                    
    # NB: error -1 nog afvangen     
    write_json(uitfile,Uitvoer);                                           # write output to json file 