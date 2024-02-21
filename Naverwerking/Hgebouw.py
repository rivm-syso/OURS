# -*- coding: utf-8 -*-
"""
Created on Thu Sep 12 12:16:59 2019
@author: Arnold Koopman
version tracker
1.01 24 juni 2022 Arnold Koopman
- Hfundering improved, for large buildings
    - Impedance jump limited, based on consideration of low building stiffness
    - Tau effect reduced, based on limitation of foundation stiffness
"""

import argparse
import math
import json
import os
import numpy as np
from scipy import stats


octaafbanden = np.array([2,4,8,16,31.5,63]);
aantalbanden = len(octaafbanden);
bovengrenzen = octaafbanden*math.sqrt(2);
ondergrenzen = octaafbanden/math.sqrt(2);
omega        = 2*np.pi*octaafbanden;

MCgrootte    = 3*333;   # streven: 333
np.random.seed(1234);   # om te zorgen voor steeds dezelfde output, laatste cijfer kan nl. wat zwabberen

# rekenwaardes
gebouwdichtheid          = 300;  # kg/m3
zetaOnbekend             = .06;  # wordt overschreven indien hout bekend is
zetaHout                 = .07;
zetaBeton                = .05;
var_gebouwdichtheid      = .1 ;
var_zetaOnbekend         = .2 ;
var_zetaHout             = .1 ;
var_zetaBeton            = .1 ;

# defaultwaardes, voor als gebruiker niets invoert
StandaardWandlengte          =  10;  # meter, diepte van de woning
StandaardGevellengte         =   6;  # meter
StandaardAantalBouwlagen     =   2;  # 2, dus BG en eerste verdieping (zonder dak)
StandaardGebouwHoogte        =   5.6;# meter
StandaardGebouwC1Hz          = 180;  # m/s, buiggolfsnelheid, over de hoogte van het gebouw, bij 1Hz
StandaardVloerHoogte         =   2.8;  # eerste verdieping
StandaardVar_wandlengte      =   1;  # in meters,  2*std
StandaardVar_gevellengte     =   1;  # in meters, 2*std
StandaardVar_aantalBouwlagen =   1;  # in aantalverdiepingen,  2*std
StandaardVar_frequenties     =   .1;  # voor zowel Mid- als Quarterspan
StandaardVar_gebouwHoogte    =  2.8;# in meters,  2*std
StandaardVar_gebouwC1Hz      =   50; # in meters, 2*std
StandaardVar_vloerHoogte     =  2.8; # in meters,  2*std
StandaardVloeroverspanningHout  = 4;
StandaardVloeroverspanningBeton = 6;
# onzekerheden over vloerfrequenties, indien die freqs nog berekend moeten worden
var_MS = .3;        
var_QS = .3;        


def Hgebouw(Bodem,Gebouw,Vloer):
    
    Y           = np.array(Bodem["Y"]);        # absolute waarde van de puntimpedantie, dus op afstand = 0
    fase        = np.array(Bodem["fase"]);     # fase van de puntimpedantie
    c           = np.array(Bodem["c"]);        # golfsnelheid, zoals waargenomen op woningafstand
    c_ratio     = np.array(Bodem["c_ratio"]);  # verhouding cX/cZ  (bijv. compressie/Rayleigh)
    var_Y       = np.array(Bodem["var_Y"]);
    var_fase    = np.array(Bodem["var_fase"]);  # is een std!!
    var_c       = np.array(Bodem["var_c"]);
    var_c_ratio = np.array(Bodem["var_c_ratio"]);
 
    # onzekerheden over de bodem
    if sum(var_c)==0 :
        var_c       = var_c + .1;
        var_c_ratio = var_c_ratio + .1;
    if sum(var_Y)==0 :
        var_Y    = var_Y + .1;
        var_fase = var_fase + .1;
        
    bouwjaar            = np.array(Gebouw["bouwjaar"]);
    appartement         = np.array(Gebouw["appartement"]);
    #aantalBouwlagen     = np.array(Gebouw["aantalBouwlagen"]);
    wandlengte          = np.array(Gebouw["wandlengte"]);        # optioneel
    gevellengte         = np.array(Gebouw["gevellengte"]);       # optioneel
    var_bouwjaar        = np.array(Gebouw["var_bouwjaar"]);      # in jaren, 2*std
    var_appartement     = np.array(Gebouw["var_appartement"]);   # als kans, tussen 0 en 1; x% kans dat het iets anders is
    #var_aantalBouwlagen = np.array(Gebouw["var_aantalBouwlagen"]); # in aantallen bouwlagen. 2*std
    var_wandlengte      = np.array(Gebouw["var_wandlengte"]);    # in m,  2*std
    var_gevellengte     = np.array(Gebouw["var_gevellengte"]);   # in m,  2*std
    
    hout                       = np.array(Vloer["hout"]);                          # optioneel
    frequentiesMidspan         = np.array(Vloer["frequentiesMidspan"]);            # optioneel
    frequentiesQuarterspan     = np.array(Vloer["frequentiesQuarterspan"]);        # optioneel
    var_hout                   = np.array(Vloer["var_hout"]);                      # als kans, tussen 0 en 1 x% kans dat het iets anders is
    var_frequentiesMidspan     = np.array(Vloer["var_frequentiesMidspan"]);        # varcoef eerste mode
    var_frequentiesQuarterspan = np.array(Vloer["var_frequentiesQuarterspan"]);    # varcoef eerste mode
    
    # gebouwhoogte bepalen
    # gebouwhoogte kan expliciet worden gegeven of via aantalBouwlagen
    # evenzo voor onzekerheid daarvan
    if "gebouwHoogte" in Gebouw:
        gebouwHoogte     = np.array(Gebouw["gebouwHoogte"]); 
    else:
        gebouwHoogte = [];
    if len(gebouwHoogte)==0: 
        if"aantalBouwlagen" in Gebouw:
            aantalBouwlagen     = np.array(Gebouw["aantalBouwlagen"]); 
            if not len(aantalBouwlagen)==0:
               gebouwHoogte = aantalBouwlagen*2.8;     
    if len(gebouwHoogte)==0: 
        gebouwHoogte = StandaardGebouwHoogte;    
       
    if "var_gebouwHoogte" in Gebouw:
        var_gebouwHoogte = np.array(Gebouw["var_gebouwHoogte"]); 
    else:
        var_gebouwHoogte = [];
    if len(var_gebouwHoogte)==0:     
        if "var_aantalBouwlagen" in Gebouw:
            var_aantalBouwlagen = np.array(Gebouw["var_aantalBouwlagen"]);   
            if not len(var_aantalBouwlagen)==0:
               var_gebouwHoogte = var_aantalBouwlagen*2.8;
    if len(var_gebouwHoogte)==0:  # maw: leeg
        var_gebouwHoogte = StandaardVar_gebouwHoogte;
    if var_gebouwHoogte==0:
       var_gebouwHoogte=.01;    
    
    if "gebouwBuigfrequentie" in Gebouw:        # in Hz
        gebouwBuigfrequentie = np.array(Gebouw["gebouwBuigfrequentie"]); 
    else:
        gebouwBuigfrequentie = [];    
    if len(gebouwBuigfrequentie)==0: 
        gebouwC1Hz     = StandaardGebouwC1Hz;
        var_gebouwC1Hz = StandaardVar_gebouwC1Hz; 
    else:
        gebouwC1Hz = 4*gebouwHoogte*np.sqrt(gebouwBuigfrequentie);
        if "var_gebouwBuigfrequentie" in Gebouw:      # in Hz, 2*std
            var_gebouwBuigfrequentie = np.array(Gebouw["var_gebouwBuigfrequentie"]); 
        else:
            var_gebouwBuigfrequentie = [];
        if len(var_gebouwBuigfrequentie)==0:  # maw: leeg
            var_gebouwC1Hz = StandaardVar_gebouwC1Hz;
        else:
            var_gebouwC1Hz = np.sqrt((var_gebouwBuigfrequentie * gebouwC1Hz/(2*gebouwBuigfrequentie))**2 + 
                             (4*var_gebouwHoogte*np.sqrt(gebouwBuigfrequentie))**2);
        if var_gebouwC1Hz==0:
            var_gebouwC1Hz = StandaardVar_gebouwC1Hz; 
          
        
    # vloerhoogte bepalen
    # vloerhoogte kan expliciet worden gegeven of via VerdiepingNr
    # evenzo voor de onzekerheid ervan
    if "vloerHoogte" in Gebouw:
        vloerHoogte     = np.array(Gebouw["vloerHoogte"]); 
    else:
        vloerHoogte = [];
    if len(vloerHoogte)==0: 
        if"verdiepingNr" in Gebouw:
            verdiepingNr     = np.array(Gebouw["verdiepingNr"]); 
            if not len(verdiepingNr)==0:
               vloerHoogte = verdiepingNr*2.8;     
    if len(vloerHoogte)==0: 
        vloerHoogte = np.max([0,gebouwHoogte-2.8]);    
       
    if "var_vloerHoogte" in Gebouw:
        var_vloerHoogte = np.array(Gebouw["var_vloerHoogte"]); 
    else:
        var_vloerHoogte = [];
    if len(var_vloerHoogte)==0:     
        if "var_verdiepingNr" in Gebouw:
            var_verdiepingNr = np.array(Gebouw["var_verdiepingNr"]);   
            if not len(var_verdiepingNr)==0:
               var_vloerHoogte = var_verdiepingNr*2.8;
    if len(var_vloerHoogte)==0:  # maw: leeg
        var_vloerHoogte = StandaardVar_vloerHoogte;
    if var_vloerHoogte==0:
       var_vloerHoogte=.01;
       
    # vloeroverspanning bepalen
    if "vloerOverspanning" in Gebouw:
        vloerOverspanning     = np.array(Vloer["vloerOverspanning"]); 
        var_vloerOverspanning = np.array(Vloer["var_vloerOverspanning"]); 
    else:
        vloerOverspanning = [];

    # lege invoer aanvullen met default waardes en berekeningen
    if len(wandlengte)==0:          wandlengte          = StandaardWandlengte;
    if len(gevellengte)==0:         gevellengte         = StandaardGevellengte;
    #if len(aantalBouwlagen)==0:     aantalBouwlagen     = StandaardAantalBouwlagen;
    if len(var_wandlengte)==0:      var_wandlengte      = StandaardVar_wandlengte;
    if len(var_gevellengte)==0:     var_gevellengte     = StandaardVar_gevellengte;
    #if len(var_aantalBouwlagen)==0: var_aantalBouwlagen = StandaardVar_aantalBouwlagen;
  
    if len(appartement)==0: appartement = 0;
    if len(bouwjaar)==0:    bouwjaar    = 0;
    if len(hout)==0:   # vloermateriaal onbekend, gaan we dus zelf verzinnen
        hout     = 0;  # zal wel nieuwbouw betreffen   NB: zeta en var_zeta blijven de defaultwaarden voor onbekend
        var_hout = .4;  # 40% kans dat het toch geen beton is
        zeta     = zetaOnbekend;
        var_zeta = var_zetaOnbekend;     
        if bouwjaar < 1945: 
            hout     = 1;
            var_hout = .1;
            zeta     = zetaHout;
            var_zeta = var_zetaHout;
        else:
            if bouwjaar<1965 & appartement == 0: 
                hout     = 1;
                var_hout = .2;  
                zeta     = zetaHout;
                var_zeta = var_zetaHout;           
    else:
        hout     = hout[0];
        if len(var_hout)==0:
            var_hout = 0;   # blijkbaar weet ie het zeker
        else:
            var_hout = var_hout[0];
        if hout:
            zeta     = zetaHout;
            var_zeta = var_zetaHout;
        else:
            zeta     = zetaBeton;
            var_zeta = var_zetaBeton;
            
    if len(frequentiesMidspan)==0:
        Vloerfreqsberekenen = True;
    else:
        Vloerfreqsberekenen = False;  
        if len(frequentiesQuarterspan)==0:
            if hout:
               frequentiesQuarterspan = np.array([4  *frequentiesMidspan[0]]);
            else:
               frequentiesQuarterspan = np.array([2.8*frequentiesMidspan[0]]);
        if len(var_frequentiesMidspan)==0:
            var_frequentiesMidspan = np.ones(len(frequentiesMidspan))*StandaardVar_frequenties;
        if len(var_frequentiesQuarterspan)==0:
            var_frequentiesQuarterspan = np.ones(len(frequentiesQuarterspan))*StandaardVar_frequenties;
            
    # rho = Gebouw.rho;
    # GevelL = Gebouw.Gevelbreedte;  %
    # orientatie = Gebouw.Orientatie;   % hoek tov spoor, in graden, 0 tot 90, 0=gevel naar spoor
    # hoogte = Gebouw.Hoogte;       % [m]
    
    # check op lege Y's. 1 band mag leeg zijn, als eerste 2 of laatste leeg zijn hebben we een probleem
    for octaafnr in range(aantalbanden):        
        if Y[octaafnr]<1e-10:    # als van een band geen Y is bepaald (dus =0)
            buren = range(octaafnr-1,octaafnr+2,2); # info bij de buurbanden halen
            octnr = range(aantalbanden);            # bestaande buurbanden
            buren = list(set(buren)&set(octnr));    # doorsnede
            Y[octaafnr]=np.mean(Y[buren]); 

    Hzz1mcArray = np.zeros([MCgrootte,aantalbanden]);
    Hzz2mcArray = np.zeros([MCgrootte,aantalbanden]);
    Hv1mcArray  = np.zeros([MCgrootte,aantalbanden]);
    Hv2mcArray  = np.zeros([MCgrootte,aantalbanden]);
    HzxmcArray  = np.zeros([MCgrootte,aantalbanden]);
    HxxmcArray  = np.zeros([MCgrootte,aantalbanden]);
    HfxxmcArray = np.zeros([MCgrootte,aantalbanden]);
    HfzzmcArray = np.zeros([MCgrootte,aantalbanden]);   
    ZbMC        = np.zeros([aantalbanden,MCgrootte], dtype=complex); 
    ZgXMC       = np.zeros([aantalbanden,MCgrootte], dtype=complex); 
    ZgZMC       = np.zeros([aantalbanden,MCgrootte], dtype=complex); 
    cZMC        = np.zeros([aantalbanden,MCgrootte]); 
    cXMC        = np.zeros([aantalbanden,MCgrootte]);     
    
    # pseudorandom verdelen: ik bemonster netjes de CDF, scheelt factor 10 in benodigde MC grootte
    kansenreeks = np.linspace(1/MCgrootte,1-1/MCgrootte,MCgrootte);
    
    gebouwdichtheidMC = stats.lognorm.ppf(kansenreeks,var_gebouwdichtheid)             * gebouwdichtheid;
    gebouwhoogteMC    = stats.lognorm.ppf(kansenreeks,var_gebouwHoogte/gebouwHoogte/2) * gebouwHoogte;
    vloerhoogteMC     = stats.norm.ppf(kansenreeks,vloerHoogte,var_vloerHoogte/2);
    vloerhoogteMC     = np.where(vloerhoogteMC<0,0,vloerhoogteMC); 
    gebouwC1HzMC      = stats.lognorm.ppf(kansenreeks,var_gebouwC1Hz/gebouwC1Hz/2)     * gebouwC1Hz;
    wandlengteMC      = stats.lognorm.ppf(kansenreeks,var_wandlengte/wandlengte/2)     * wandlengte;
    gevellengteMC     = stats.lognorm.ppf(kansenreeks,var_gevellengte/gevellengte/2)   * gevellengte;
    zetaMC            = stats.lognorm.ppf(kansenreeks,var_zeta)                        * zeta;
    np.random.shuffle(gebouwdichtheidMC);
    np.random.shuffle(gebouwhoogteMC);
    np.random.shuffle(vloerhoogteMC);
    np.random.shuffle(wandlengteMC);
    np.random.shuffle(gevellengteMC);
    np.random.shuffle(zetaMC);
    np.random.shuffle(gebouwC1HzMC);
    # fase, Y en c zijn spectra, dus covariantie tussen banden meenemen
    # dat kan met np.random.multivariate, maar helaas alleen voor normale verdelingen
    # En dus helaas geen pseudorandom.
    # Opmkerlijk is dat variatie in uitkomst (cov_H's) groter wordt door meenemen covariatie
    # Maar de cov_H's zien er wel "rustiger" uit 
    covX    = np.ones([6,6]) * np.transpose(var_fase[np.newaxis]) * var_fase; # maximale relaties tussen banden
    XMC     = np.random.multivariate_normal(fase,covX,MCgrootte);
    faseMC  = np.swapaxes(XMC,0,1);
    
    YMC       = montecarloMetCovariantie(Y,      var_Y,      MCgrootte);
    cZMC      = montecarloMetCovariantie(c,      var_c,      MCgrootte);
    c_ratioMC = montecarloMetCovariantie(c_ratio,var_c_ratio,MCgrootte);
    
    for band in range(aantalbanden):
        #faseMC    = stats.lognorm.ppf(kansenreeks,var_fase[band]) * fase[band];
        #YMC       = stats.lognorm.ppf(kansenreeks,var_Y[band])    * Y[band];
        #c_ratioMC = stats.lognorm.ppf(kansenreeks,var_c_ratio[band]) * c_ratio[band];
        #np.random.shuffle(faseMC);
        #np.random.shuffle(YMC);
        #np.random.shuffle(c_ratioMC);
        ZbMC[band]    = np.exp(-1j*faseMC[band]) / YMC[band];   # complexe impedantie van de bodem
        #cZMC[band]    = stats.lognorm.ppf(kansenreeks,var_c[band])       * c[band];
        #np.random.shuffle(cZMC[band]);
        cXMC[band]    = c_ratioMC[band] * cZMC[band]; 
        lamdbaX       = cXMC[band] / octaafbanden[band]; 
        lamdbaZ       = cZMC[band] / octaafbanden[band]; 
        # ZgMC[band]    = 1j * gebouwdichtheidMC * gebouwhoogteMC * wandlengteMC * gevellengteMC * omega[band];  # complexe impedantie van het gebouw
        VolumeTotaal  = gebouwhoogteMC * wandlengteMC * gevellengteMC;
        VolumeActiefX = np.pi * lamdbaX**3 / 100;
        VolumeActiefX = np.minimum(VolumeTotaal,VolumeActiefX);
        VolumeActiefZ = np.pi * lamdbaZ**3 / 100;
        VolumeActiefZ = np.minimum(VolumeTotaal,VolumeActiefZ);       
        ZgXMC[band]    = 1j * gebouwdichtheidMC * VolumeActiefX * omega[band];  # complexe impedantie van het gebouw
        ZgZMC[band]    = 1j * gebouwdichtheidMC * VolumeActiefZ * omega[band];  # complexe impedantie van het gebouw
    Zb  = np.swapaxes(ZbMC ,0,1);
    ZgX = np.swapaxes(ZgXMC,0,1);   
    ZgZ = np.swapaxes(ZgZMC,0,1); 
    cZ  = np.swapaxes(cZMC ,0,1);
    cX  = np.swapaxes(cXMC ,0,1);

    for i1 in range(MCgrootte):   # Monte Carlo over variaties, om covariantiematrix te kunnen maken
        # Hfundering
#        gebouwdichtheidMC = np.random.lognormal(0,var_gebouwdichtheid) * gebouwdichtheid;
#        gebouwhoogteMC    = np.random.lognormal(0,var_gebouwHoogte/gebouwHoogte/2) * gebouwHoogte;
#        vloerhoogteMC     = np.random.lognormal(0,var_vloerHoogte/vloerHoogte/2) * vloerHoogte;
#        wandlengteMC      = np.random.lognormal(0,var_wandlengte/wandlengte/2)  * wandlengte;
#        gevellengteMC     = np.random.lognormal(0,var_gevellengte/gevellengte/2) * gevellengte;
#        Zb      = np.exp(-1j*fase*np.random.lognormal(0,var_fase))/(Y*np.random.lognormal(0,var_Y));   # complexe impedantie van de bodem
#        cZ      = np.random.lognormal(0,var_c)      *c;
#        cX      = np.random.lognormal(0,var_c_ratio)*cZ*c_ratio;
#        Zg      = 1j * gebouwdichtheidMC * gebouwhoogteMC * wandlengteMC * gevellengteMC * omega;  # complexe impedantie van het gebouw
        DictOut = Hfundering(Zb[i1],cX[i1],ZgX[i1],wandlengteMC[i1]); # in x richting kloppen Z's eigenlijk niet
        Hfxx    = DictOut['Htranslatie'];
        DictOut = Hfundering(Zb[i1],cZ[i1],ZgZ[i1],wandlengteMC[i1]);
        Hfzz    = DictOut['Htranslatie'];
        Hfr     = DictOut['Hrocking'];
            
        # Hconstructie
        Hcxx = 1.0;   # doen we even niets mee, gaat over schuif en buig, beiden xx
        
        maxvloerhoogte = gebouwC1HzMC[i1]/np.sqrt(octaafbanden)/4;
        vloerhoogte    = np.minimum(vloerhoogteMC[i1],maxvloerhoogte);
        
        Hczx = vloerhoogte*omega/cZ[i1];  #  zwaaien, geometrische versterkin
        Hczz = 1.0;   # hoogteverzwakking

        # eerste resultaten: maaiveld naar x-richting bovenste verdieping
        HxxmcArray[i1,:]  = Hfxx * Hcxx;         # 1x6
        HzxmcArray[i1,:]  = Hfr  * Hczx;         # 1x6
        
        # wat doet de fundering (voor Vtop en voor eventuele latere beoordeling op fundering ipv vloer of maaiveld)
        HfxxmcArray[i1,:] = Hfxx;         # 1x6
        HfzzmcArray[i1,:] = Hfzz;         # 1x6
        
        
        # Hvloer
        if Vloerfreqsberekenen:
            if hout:
                E     = 5e9;    # checken bij Jemima
                rho   = 600;  # Sovist: 390, Bassit: 700, Jemima?
                h1    = .19;  # balk
                h2    = .03;  # planken + bedekking
                if len(vloerOverspanning)==0:
                   L  = StandaardVloeroverspanningHout;
                else:
                   L  = vloerOverspanning;
                b     = .07; # balkdikte
                a     = .45; # hoh balk
                Mvloer = rho*wandlengteMC[i1]*L*(h1*b/a+h2);
                I      = (wandlengteMC[i1]*b*h1**3)/(12*a);
            else:  # nog onderscheid naar broodjes, kanaalplaat, woningscheidend etc.
                E     = 2.5e10;
                rho   = 2400;  
                if bouwjaar > 2000 & appartement==1:
                    h = .3;
                else: 
                    h = .2; # ???
                if len(vloerOverspanning)==0:
                   L  = StandaardVloeroverspanningBeton;
                else:
                   L  = vloerOverspanning;
                Mvloer = rho*wandlengteMC[i1]*L*h;
                I      = (wandlengteMC[i1]*h**3)/12;     
            M = 75;  # gemiddeld persoon die trillingen voelt
            if hout:
                first  = (2/np.pi)*np.sqrt(3*E*I/(L**3*(M + .49*Mvloer)));
                second = 4 * first;
                oneven = np.append(first,second*np.array([3/2,5/2,7/2,9/2,11/2]));
                even   = second * np.array(range(1,7));  # 1 t/m 6
            else:
                first  = (4/np.pi)*np.sqrt(3*E*I/(L**3*(M + .37*Mvloer)));
                second = 2.8 * first;
                even   = second * np.array(range(1,7));  # 1 t/m 6
                oneven = np.append(first,second*np.array([3/2,5/2,7/2,9/2,11/2]));
            muMS  = -np.log (np.sqrt(1+var_MS**2));   # lognormale verdelig definieren
            sigMS =  np.sqrt(np.log (1+var_MS**2));   # dit was nodig in Matlab
            muQS  = -np.log (np.sqrt(1+var_QS**2));   # numpy kan lognormal getallen trekken
            sigQS =  np.sqrt(np.log (1+var_QS**2));
            deven   = np.append(even[0], np.diff(even));
            doneven = np.append(oneven[0], np.diff(oneven));
            for freq in range(len(even)):
                factor = np.exp(sigQS*np.random.normal(0)+muQS);
                #factor = np.random.lognormal(0,varcoefQS); # doet precies hetzelfde
                deven[freq] = factor*deven[freq];
            for freq in range(len(oneven)):
                factor = np.exp(sigMS*np.random.normal(0)+muMS);
                doneven[freq] = factor*doneven[freq];
            evenMC   = np.cumsum(even);
            onevenMC = np.cumsum(oneven);   
        else:
            evenMC   = frequentiesMidspan     * np.random.lognormal(0,var_frequentiesMidspan);
            if len(frequentiesQuarterspan)>0:
                onevenMC = frequentiesQuarterspan * np.random.lognormal(0,var_frequentiesQuarterspan);
            else:
                onevenMC = np.array([]);
        # zetaMC            = np.random.lognormal(0,var_zeta)*zeta;
        
        DictOut           = Hvloer(onevenMC,evenMC,zetaMC[i1]);
        Hv1mcArray[i1,:]  = DictOut['Hmidspan'];
        Hv2mcArray[i1,:]  = DictOut['Hquarterspan'];
        Hzz1mcArray[i1,:] = Hczz * Hv1mcArray[i1,:] * Hfzz;
        Hzz2mcArray[i1,:] = Hczz * Hv2mcArray[i1,:] * Hfzz;
    
    # gemiddelden uit de MC halen
    Hxx  = np.mean(HxxmcArray, axis=0); # 1x6
    Hxz  = np.zeros(6);        # x slaat vloer aan, doen we nog even niets mee, 
    Hzx  = np.mean(HzxmcArray, axis=0); # 1x6
    Hzz1 = np.mean(Hzz1mcArray,axis=0); # 1x6
    Hzz2 = np.mean(Hzz2mcArray,axis=0); # 1x6
    Hfxx = np.mean(HfxxmcArray,axis=0); # 1x6 
    Hfzz = np.mean(HfzzmcArray,axis=0); # 1x6
    
    # Hgebouw bepalen, legacy vanwege Bts
    Hfunvloer    = np.zeros([3,6]);  #  hier komen de drie overdrachten fundering naar vloer
    Hfunvloer[0] = np.mean(HzxmcArray,axis=0) / Hfzz;   #    Hczx;  # zwaaien van het gebouw
    Hfunvloer[1] = np.mean(Hv1mcArray,axis=0);   # opslingering midspan
    Hfunvloer[2] = np.mean(Hv2mcArray,axis=0);   # opslingering midspan
    Hgebouw      = np.max(Hfunvloer,axis=0);  # volgens Level memo
    
    # varianties uit de MC halen, eerst wat voorwerk
    legeCov  = np.zeros([6,6]);
    # delen door nul is flauwekul,
    Hxx[Hxx==0]   = .001;
    Hzx[Hzx==0]   = .001;
    Hzz1[Hzz1==0] = .001;
    Hzz2[Hzz2==0] = .001;
    Hfxx[Hfxx==0] = .001;
    Hfzz[Hfzz==0] = .001;
    # nu dus de covs maken
    cov_Hxx  = np.cov(HxxmcArray, rowvar=False) / (Hxx *np.transpose([Hxx ]));
    cov_Hxz  = legeCov;
    cov_Hzx  = np.cov(HzxmcArray, rowvar=False) / (Hzx *np.transpose([Hzx ]));
    cov_Hzz1 = np.cov(Hzz1mcArray,rowvar=False) / (Hzz1*np.transpose([Hzz1]));
    cov_Hzz2 = np.cov(Hzz2mcArray,rowvar=False) / (Hzz2*np.transpose([Hzz2]));
    cov_Hfxx = np.cov(HfxxmcArray,rowvar=False) / (Hfxx*np.transpose([Hfxx]));
    cov_Hfzz = np.cov(HfzzmcArray,rowvar=False) / (Hfzz*np.transpose([Hfzz]));
    cov_Hxx  = np.sqrt(np.abs(cov_Hxx )) * np.sign(cov_Hxx);   
    cov_Hzx  = np.sqrt(np.abs(cov_Hzx )) * np.sign(cov_Hzx); 
    cov_Hzz1 = np.sqrt(np.abs(cov_Hzz1)) * np.sign(cov_Hzz1);
    cov_Hzz2 = np.sqrt(np.abs(cov_Hzz2)) * np.sign(cov_Hzz2);
    cov_Hfxx = np.sqrt(np.abs(cov_Hfxx)) * np.sign(cov_Hfxx);  
    cov_Hfzz = np.sqrt(np.abs(cov_Hfzz)) * np.sign(cov_Hfzz);  
    
    # afronding, letterlijk en figuurlijk
    Hxx      = np.round(Hxx,      decimals=2);
    Hxz      = np.round(Hxz,      decimals=2);
    Hzx      = np.round(Hzx,      decimals=2);
    Hzz1     = np.round(Hzz1,     decimals=2);
    Hzz2     = np.round(Hzz2,     decimals=2);
    cov_Hfxx = np.round(cov_Hfxx, decimals=3);
    cov_Hfzz = np.round(cov_Hfzz, decimals=3);
    cov_Hxx  = np.round(cov_Hxx,  decimals=3);
    cov_Hxz  = np.round(cov_Hxz,  decimals=3);
    cov_Hzx  = np.round(cov_Hzx,  decimals=3);
    cov_Hzz1 = np.round(cov_Hzz1, decimals=3);
    cov_Hzz2 = np.round(cov_Hzz2, decimals=3);   
    Hgebouw  = np.round(Hgebouw,  decimals=1);
    Hfxx     = np.round(Hfxx,     decimals=2);
    Hfzz     = np.round(Hfzz,     decimals=2);
    
    # opbergen in een dictionary en weg ermee
    Resultaten = {'Hxx'  :    Hxx[:].tolist(),       # tolist maakt van np array een gewone array ?
                  'Hxz'  :    Hxz[:].tolist(),
                  'Hzx'  :    Hzx[:].tolist(),                  
                  'Hzz1' :    Hzz1[:].tolist(),      # NB: dit zijn means uit een MC, dus cov's behandelen   
                  'Hzz2' :    Hzz2[:].tolist(),      #     dus cov's behandelen als van een normale verdeling!
                  'cov_Hxx' : cov_Hxx[:].tolist(),                  
                  'cov_Hxz' : cov_Hxz[:].tolist(),
                  'cov_Hzx' : cov_Hzx[:].tolist(),                  
                  'cov_Hzz1': cov_Hzz1[:].tolist(),                  
                  'cov_Hzz2': cov_Hzz2[:].tolist(),
                  'Hgebouw' : Hgebouw[:].tolist(),
                  'Hfxx'    : Hfxx[:].tolist(),
                  'Hfzz'    : Hfzz[:].tolist(),
                  'cov_Hfxx': cov_Hfxx[:].tolist(),
                  'cov_Hfzz': cov_Hfzz[:].tolist()                  
                  };                     
    return Resultaten

    
def Hfundering(Zbodem, cbodem, Zgebouw, Lgebouw):
    
    tauRockingOct = np.ones(aantalbanden);
    tauTransOct   = np.ones(aantalbanden);
    aantallijnen  = 10;
    tauRockingff  = np.ones(aantallijnen);
    tauTransff    = np.ones(aantallijnen);
    # length of bending waves in foundation, assuming concrete or brick
    # assuming 1 meter height; walls (up to underside window) can take part
    # higher walls will "buckle" 
    # NB: double heigth shifts wave lengths one octave
    lambdafundering = np.array([52,37,26,19,13,9.5]);   # nb: vervangen door functie golflengte.py
    for octaafnr in range(aantalbanden):
        if cbodem[octaafnr]<1:    # als van een band geen c is bepaald (dus =0)
            buren = range(octaafnr-1,octaafnr+2,2); # info bij de buurbanden halen
            octnr = range(aantalbanden);            # bestaande buurbanden
            buren = list(set(buren)&set(octnr));    # doorsnede
            cbodem[octaafnr]=np.mean(cbodem[buren]); 
        ff           = 2**(np.log2(octaafnr+1)+np.linspace(-.45,.45,aantallijnen));
        LgebouwEff   = min(Lgebouw,lambdafundering[octaafnr]); 
        labda        = cbodem[octaafnr]/ff;
        coeff        = np.pi*LgebouwEff/labda;
        for lijnnr in range(aantallijnen):
            tauRockingff[lijnnr]       = math.sin(coeff[lijnnr])/coeff[lijnnr];
            tauTransff[lijnnr]         = math.sqrt((1+math.cos(coeff[lijnnr]))/2);
        tauRockingff[labda<Lgebouw]    = 0;
        tauTransff[labda<LgebouwEff/2] = 0;
        tauRockingOct[octaafnr]        = np.mean(tauRockingff,axis=0);
        tauTransOct[octaafnr]          = np.mean(tauTransff,axis=0);
    # dan impedantiesprong nog in rekening brengen:
    H = np.abs(Zbodem/(Zbodem+Zgebouw));
    # effecten bijelkaar:
    Hrocking    = H*tauRockingOct;
    Htranslatie = H*tauTransOct;
    Haas = {'Htranslatie':Htranslatie, 'Hrocking':Hrocking};
    return Haas


def Hvloer(eigenfreqsMidspan, eigenfreqsQuarterspan, zeta): 
    
    def berekenH(eigenfreqs):
        aantaleigenfreqs = len(eigenfreqs);
        Hb = np.ones([aantaleigenfreqs+1,aantallijnen]);
        for k in range(aantaleigenfreqs):
            f0      = eigenfreqs[k];
            Hb[k,:] = (f0**2)*(1/np.sqrt((f0**2-np.exp(2*x))**2 + 4*(f0**2)*zeta**2*np.exp(2*x)));   # lineair
        return np.mean(np.max(Hb,axis=0));
        
    aantallijnen = int(2*np.ceil(np.log(2)/zeta)); # log(2) want octaafband
    Hms = np.ones(aantalbanden);
    Hqs = np.ones(aantalbanden);
    for octaafnr in range(aantalbanden): 
        x  = np.linspace(np.log(ondergrenzen[octaafnr]),np.log(bovengrenzen[octaafnr]),aantallijnen);
        Hms[octaafnr] = berekenH(eigenfreqsMidspan);
        Hqs[octaafnr] = berekenH(eigenfreqsQuarterspan);
    Haas = {'Hmidspan':Hms, 'Hquarterspan':Hqs};
    return Haas       


def montecarloMetCovariantie(X,varX,MCgrootte):
    covX    = np.ones([6,6]) * np.transpose(varX[np.newaxis]) * varX; # maximale relaties tussen banden
    #covX    = np.diag(np.ones(6)) * np.transpose(varX[np.newaxis]) * varX; # geen relaties tussen banden
    covarX  = np.sign(covX) * X *np.transpose([X]) * covX;
    XMC     = np.random.multivariate_normal(X,covarX,MCgrootte);
    MCX     = np.swapaxes(XMC,0,1);
    return MCX



def read_json(file_name):
    import json
    try:
        with open(file_name, "r") as fid:
             data = json.load(fid);  
    except OSError:
        exit(101)
    return data

    
def write_json(file_name, Hgebouw):
    try:
       with open(file_name, "w+") as fid:
           json.dump(Hgebouw, fid, separators=(',', ':'), sort_keys=True, indent=4)
    except OSError:
       exit(102)
    return

    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--json', help='input JSON file', required=True)
    parser.add_argument('-o', '--output', help='location of the output folder', required=True)
    args = parser.parse_args();
    Invoer  = read_json(args.json);                                        # reads input json file
    Uitvoer = Hgebouw(Invoer["Bodem"],Invoer["Gebouw"],Invoer["Vloer"]);   # do the work
    uitfile = os.path.join(args.output,"HgebouwUit.json");                    
    # NB: error -1 nog afvangen     
    write_json(uitfile,Uitvoer);                                           # write output to json file 