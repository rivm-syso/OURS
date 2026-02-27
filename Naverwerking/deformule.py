# -*- coding: utf-8 -*-
"""
Created on Thu Sep 12 12:16:59 2019

@author: Arnold Koopman

Todo:
    - meer sporen
    
Version 1.0.1.01

Aangepast op 21-1-2024 door Lennart Bouma
- Eerst een gewogen gemiddelde en dan de vmax,bts toepassen
- Spectrale data wordt nu uitgevoerd
"""
import argparse
import json
import os
import numpy as np
from scipy import stats

MCgrootte = 33*333    # streven: 333
np.random.seed(1235)  # fixeren laatste decimaal in de output

def Bronkracht(Bron: dict, Idx, stijfheidsratioZ,stijfheidsratioX, covar_sZ,covar_sX, V):    
    FzMcArray = np.ones([MCgrootte, 6])
    FxMcArray = np.ones([MCgrootte, 6])
    sZmcArray = np.zeros([MCgrootte, 6])
    sXmcArray = np.zeros([MCgrootte, 6])
    sZmcArray = np.random.multivariate_normal(stijfheidsratioZ, covar_sZ, MCgrootte)
    sXmcArray = np.random.multivariate_normal(stijfheidsratioX, covar_sX, MCgrootte)

    sZmcArray.clip(min=0, max=1, out=sZmcArray)
    sXmcArray.clip(min=0, max=1, out=sXmcArray)

    for bron in range(2):
        refbron = Bron[Idx[bron]]
        Vref = float(refbron["Vref"]) # 1
        FZ0  = np.array(refbron["FZ0"])  # 1x6
        FZ1  = np.array(refbron["FZ1"])  # 1x6
        FX0  = np.array(refbron["FX0"])  # 1x6
        FX1  = np.array(refbron["FX1"])  # 1x6
        n0   = float(refbron["n0"])   # 1
        n1   = float(refbron["n1"])   # 1
        dFZ0 = np.array(refbron["dFZ0"])  # 1x6  varcoef
        dFZ1 = np.array(refbron["dFZ1"])  # 1x6  varcoef
        dFX0 = np.array(refbron["dFX0"])  # 1x6  varcoef
        dFX1 = np.array(refbron["dFX1"])  # 1x6  varcoef
        dn0  = float(refbron["dn0"])   # 1    std of minmax
        dn1  = float(refbron["dn1"])   # 1    std of minmax      
        FZ0[np.where(FZ0 == 0)] = 1
        FZ1[np.where(FZ1 == 0)] = 1
        FX0[np.where(FX0 == 0)] = 1
        FX1[np.where(FX1 == 0)] = 1
        # eigenlijk hier covars maken van dF
        n0mcArray = np.random.normal(n0, dn0, MCgrootte)
        n0mcArray = np.transpose(np.array([n0mcArray for _ in range(6)]))
        n1mcArray = np.random.normal(n1, dn1, MCgrootte)
        n1mcArray = np.transpose(np.array([n1mcArray for _ in range(6)]))
        FZ0mcArray = montecarloMetCovariantieLognormaal(FZ0, dFZ0, MCgrootte)
        FX0mcArray = montecarloMetCovariantieLognormaal(FX0, dFX0, MCgrootte)
        FZ1mcArray = montecarloMetCovariantieLognormaal(FZ1, dFZ1, MCgrootte)
        FX1mcArray = montecarloMetCovariantieLognormaal(FX1, dFX1, MCgrootte)

        vNorm = V/Vref
        shift = np.log2(vNorm)
        heleshift = int(np.floor(shift))
        fracshift = np.mod(shift, 1)

        sz = bron + ((-1)**bron)*sZmcArray  # s resp (1-s)
        sx = bron + ((-1)**bron)*sXmcArray  # s resp (1-s)
        TFZ1 = shiftspectrum(FZ1mcArray, heleshift, fracshift)
        TFX1 = shiftspectrum(FX1mcArray, heleshift, fracshift)

        arr0 = vNorm**n0mcArray
        arr1 = vNorm**n1mcArray
        FzMcArray = FzMcArray + sz * (FZ0mcArray*arr0 + TFZ1*arr1)
        FxMcArray = FxMcArray + sx * (FX0mcArray*arr0 + TFX1*arr1)

    Fz = np.mean(FzMcArray, axis=0)  # 1x6
    Fx = np.mean(FxMcArray, axis=0)  # 1x6
    muZ = 1e3*Fz  # in Bronbestand staan kN, om mooie getallen rond 1 te krijgen
    muX = 1e3*Fx
    varZ = np.std(FzMcArray, axis=0)/Fz
    varX = np.std(FxMcArray, axis=0)/Fx

    # covar maken met maximaal verband tussen banden
    covZ = np.sqrt(np.ones([6, 6]) * np.transpose(varZ[np.newaxis]) * varZ)  # @ np.diag(var_c)
    covX = np.sqrt(np.ones([6, 6]) * np.transpose(varX[np.newaxis]) * varX)  # @ np.diag(var_c)

    Verdeling = {'muZ': muZ, 'covZ': covZ,  'muX': muX, 'covX': covX}

    return Verdeling


def Stijfheidsratio(FEM,Bron,Idx):
    hoog = Idx[0]
    laag = Idx[1]  # np.array(Bodem["Y"])
    BronHoog = Bron[hoog]
    BronLaag = Bron[laag]
    ZoHoog = np.array(BronHoog["Zo"])
    ZoLaag = np.array(BronLaag["Zo"])
    Yo = np.array(FEM["Yo"])
    Yo_ratio = np.array(FEM["Yo_ratio"])
    YHoog_ratio = np.array(BronHoog["Y_ratio"])
    YLaag_ratio = np.array(BronLaag["Y_ratio"])

    varZoHoog = np.array(BronHoog["dZo"])
    varZoLaag = np.array(BronLaag["dZo"])
    varYo = np.array(FEM["var_Yo"])
    varYo_ratio = np.array(FEM["var_Yo_ratio"])
    varYHoog_ratio = np.array(BronHoog["dY_ratio"])
    varYLaag_ratio = np.array(BronLaag["dY_ratio"])

    # controle op lege banden in Yo
    legebanden = np.where(Yo == 0)
    Yo[legebanden] = 1e-11
    Yo_ratio[legebanden] = 1

    # covars van vars maken
    YoMC = montecarloMetCovariantieLognormaal(Yo,       varYo,       MCgrootte)
    Yo_ratioMC = montecarloMetCovariantieNormaal(Yo_ratio, varYo_ratio, MCgrootte)

    ZoHoogMC = montecarloMetCovariantieLognormaal(ZoHoog,      varZoHoog,      MCgrootte)
    ZoLaagMC = montecarloMetCovariantieLognormaal(ZoLaag,      varZoLaag,      MCgrootte)
    YHoog_ratioMC = montecarloMetCovariantieLognormaal(YHoog_ratio, varYHoog_ratio, MCgrootte)
    YLaag_ratioMC = montecarloMetCovariantieLognormaal(YLaag_ratio, varYLaag_ratio, MCgrootte)

    # fix 8 maart 2020, vanwege overgang van lognormal naar multivariate.normal
    YoMC[np.where(YoMC <= 0)] = 1e-11
    Yo_ratioMC[np.where(Yo_ratioMC <= 0)] = .1
    ZoHoogMC[np.where(ZoHoogMC <= 0)] = 1e7
    ZoLaagMC[np.where(ZoLaagMC <= 0)] = 1e6
    YHoog_ratioMC[np.where(YHoog_ratioMC <= 0)] = .1
    YLaag_ratioMC[np.where(YLaag_ratioMC <= 0)] = .1

    stijfheidsratioZ = -np.log(YoMC * ZoLaagMC) / np.log(ZoHoogMC / ZoLaagMC)
    stijfheidsratioX = -np.log(YoMC * ZoLaagMC * Yo_ratioMC / YLaag_ratioMC) / np.log(ZoHoogMC / ZoLaagMC * YLaag_ratioMC / YHoog_ratioMC)

    stijfheidsratioX.clip(min=0, max=1, out=stijfheidsratioX)
    stijfheidsratioZ.clip(min=0, max=1, out=stijfheidsratioZ)

    muZ = np.mean(stijfheidsratioZ, axis=0)
    muX = np.mean(stijfheidsratioX, axis=0)

    covarZ = np.cov(stijfheidsratioZ, rowvar=False)
    covarX = np.cov(stijfheidsratioX, rowvar=False)
    Verdeling = {'muZ': muZ, 'covarZ': covarZ,  'muX': muX, 'covarX': covarX}
    return Verdeling


def VloerLognormaal(Vmul,Vvarl,Hmu,Hcovar):   # de statistiek!
    # Vvarl is een variantie van een lognormaal verdeelde V
    # Hcovar is een covariantiecoefficient (raar ding) van een normaal verdeelde H
    Vmul[np.where(Vmul==0)]=1e-20  # conditionering van de input, blijkt dat soms een band leeg is.
    
    # V naar normale verdeling brengen, met schaling naar mu = 0
    Vvar = np.log(1+Vvarl/Vmul**2)
    V2mu  = Vmul**2 * np.exp(Vvar)    
    V2var = 4*Vvarl*Vmul**2 + 2*Vvarl**2 
    
    Hcovar =  (Hmu*np.transpose([Hmu])) * np.sign(Hcovar) * Hcovar**2
    covHiViHjVj = np.zeros([6,6])
    for i1 in range(6):
        for i2 in range(6):
            if i1==i2:
                covHiViHjVj[i1,i1] = 4 * Hmu[i1]**2      * Hcovar[i1,i1] * V2mu[i1]**2     +   V2var[i1] * (Hcovar[i1,i1]+Hmu[i1]**2)**2 # + 4*Hmu[i1]**2*Hcovar[i1,i1]*Vmu[i1]**2*Vvar[i1]
            else:
                covHiViHjVj[i1,i2] = 4 * Hmu[i1]*Hmu[i2] * Hcovar[i1,i2] * V2mu[i1]*V2mu[i2]
    sigmaSum = np.sqrt(sum(sum(covHiViHjVj)))  # was: 4*cov
    muBand = np.zeros(6)
    for i1 in range(6):
        muBand[i1] = V2mu[i1] * (Hmu[i1]**2 + Hcovar[i1,i1]) 
    muSum          = sum(muBand)

    sigma          = np.sqrt(sigmaSum**2/(4*muSum) + sigmaSum**4/(32*muSum**3) )
    dominanteBand  = np.argmax(muBand)
    dominanteBandA = np.argmax(muBand/[1,1,1,1.2,1.8,2.7])  # weging naar criterium SBR A
    
    # bovenstaande gaat mis bij var>1, daarom anders:
    mu  = np.sqrt(np.sum(Vmul**2*Hmu**2))  # directe bepaling van mediaan,   # directe bepaling van mediaan, deze formule nog afleiden!
    gem = mu*np.sqrt((1+np.sqrt(1+4*sigma**2/mu**2))/2)  # lelijke formule, kan dit niet beter?
    var = sigma/gem         

    # ten behoeve van bepaling bijdrage H, de sigma van covH = 0:
    sigmaSum = np.sqrt(sum(V2var*Hmu**4))
    muSum    = sum(V2mu*Hmu**2)
    varV   = np.sqrt(sigmaSum**2/(4*muSum) + sigmaSum**4/(32*muSum**3) ) / gem
    varH   = np.sqrt(abs(var**2 - varV**2)) * np.sign(var**2 - varV**2)
    
    Verdeling = {'mu':mu, 'sigma':sigma, 'dominanteBand': dominanteBand, 'var': var, 'varV': varV, 'varH': varH, 'dominanteBandA': dominanteBandA}
    return Verdeling

def RSSmetCovarLognormaal(Ymu,Ycovar):   # de statistiek!
    # invoer: gemiddelde Ymu en covariatiecoefficient van een lognormaal verdeelde Y
    # uitvoer: mediaan, standaard deviatie (wortel variantie) en variatiecoefficient van RMS
    # bepalen van mu en covar van  normaal verdeelde variabel X (Y=exp(X))
    Ymu[np.where(Ymu==0)]=1e-20  # conditionering van de input, blijkt dat soms een band leeg is.
    Xcovariantie = np.log(1+Ycovar**2)  # covariantiematrix
    Xva          = np.diagonal(Xcovariantie)  
    Xmu          = np.log(Ymu) - Xva/2  ## Dit is met de formules van lognormaal, waarbij dus mu van schaal parameter wordt gevonden

    # stap naar Y**2

    Y2mu          = np.exp(2*Xmu+2*Xva)
    Y2covariantie = (4*Ycovar**2 + 2*Ycovar**4 ) * (Ymu*np.transpose([Ymu]))**2                  

    sigmaSum       = np.sqrt(sum(sum(Y2covariantie)))
    muSum          = np.sum(Y2mu)
    # we gaan er van uit dat dit resultaat ook weer lognormaal verdeeld is
    sigma          = np.sqrt(sigmaSum**2/(4*muSum) + sigmaSum**4/(32*muSum**3) )
    dominanteBand  = np.argmax(Y2mu)   

    # bovenstaande gaat mis bij var>1, daarom anders:
    mu  = np.sqrt(np.sum(Ymu**2))  # directe bepaling van mediaan, 
    gem = mu*np.sqrt((1+np.sqrt(1+4*sigma**2/mu**2))/2)  # lelijke formule, kan dit niet beter?
    var = sigma/gem
    Verdeling = {'mu':mu, 'sigma':sigma, 'dominanteBand': dominanteBand, 'var': var}
    return Verdeling


# aangepast van originele OURS om duplicate code te verhelpen - MT
def shiftspectrum(RMSin, heleshift, fracshift):
    # verschuif een RMS spectrum (zoals Feq) vanwege snelheidsverschuiving
    lengte = np.shape(RMSin)[1]
    RMS = np.zeros_like(RMSin)
    # Full shift
    if heleshift >= 0:
        RMS[:, heleshift:lengte] = RMSin[:, 0:lengte-heleshift]
        RMSlaagste = 0
    else:
        RMS[:, 0:lengte+heleshift] = RMSin[:, 0-heleshift:lengte]
        RMSlaagste = RMSin[:, 0-heleshift-1]
    MSe = RMS**2
    MSe2 = MSe*(1-fracshift)
    MSe2[:, 1:lengte] = MSe2[:, 1:lengte] + MSe[:, 0:lengte-1]*fracshift
    MSe2[:, 0] = MSe2[:, 0] + fracshift*RMSlaagste**2
    RMSuit = np.sqrt(MSe2)
    return RMSuit


def shiftCgeoSpectrum(Cin, Vin, Vuit):
    # verschuif een H spectrum (zoals Cgeo) vanwege snelheidsverschuiving
    shift = np.log2(Vuit/Vin)
    lengte = len(Cin)
    C = np.ones(lengte)
    heleshift = int(np.floor(shift))
    if heleshift >= 0:
        C[heleshift:lengte] = Cin[0:lengte-heleshift]
        Claagste = 1
    else:
        C[0:lengte+heleshift] = Cin[-heleshift:lengte]
        Claagste = Cin[0-heleshift-1]
    fracshift = np.mod(shift, 1)
    C2 = C*(1-fracshift)
    C2[1:lengte] = C2[1:lengte] + C[0:lengte-1]*fracshift
    C2[0] = C2[0] + fracshift*Claagste
    Cuit = C2
    return Cuit


def CovariantProduct(X, cov_X, Y, cov_Y):  # X,Y,factor zijn vectoren
    # cov_X is covariantiecoefficient (dus wortel van cov/mu^2, met teken)
    Xmatrix = X * np.transpose(X[np.newaxis])
    Ymatrix = Y * np.transpose(Y[np.newaxis])

    covariantieX = np.sign(cov_X) * cov_X**2
    covariantieY = np.sign(cov_Y) * cov_Y**2
    tekenX = np.sign(Xmatrix)
    tekenY = np.sign(Ymatrix)
    covariantieT = covariantieX + covariantieY + covariantieX * covariantieY
    cov = np.sign(covariantieT) * tekenX * tekenY * np.sqrt(np.abs(covariantieT))
    return cov


def OutputSamenstellen(
    treinklasse,
    Index,
    Vrms_fundering_treintype,
    Vrms_maaiveldspectraal,
    totaalaantaltreinen,
    Vrms_vloer_treintype,
    VperVars, VperMus,
    VmaxMus, VmaxVars, VmaxFdoms, Varcoefs,
    VtopMus, VtopVars, VtopFdoms,
    Vmax_funderingMus, Vmax_funderingVars, Vmax_funderingFdoms,
    Vrms_maaiveldMus, Vrms_maaiveldVars,
    Sigma_maaiveld_spectraal,
    aantaltreinen_dagd,
    richting # <-- Toegevoegd
):
    if len(Index) > 0:
        # Selecteer de juiste richting
        Vrms_fundering_treintype = Vrms_fundering_treintype[richting]
        Vrms_maaiveldspectraal = Vrms_maaiveldspectraal[richting]
        Vrms_vloer_treintype = Vrms_vloer_treintype[richting]
        VperVars = VperVars[richting]
        VperMus = VperMus[richting]
        VmaxMus = VmaxMus[richting]
        VmaxVars = VmaxVars[richting]
        VmaxFdoms = VmaxFdoms[richting]
        Varcoefs = Varcoefs[richting]
        VtopMus = VtopMus[richting]
        VtopVars = VtopVars[richting]
        VtopFdoms = VtopFdoms[richting]
        Vmax_funderingMus = Vmax_funderingMus[richting]
        Vmax_funderingVars = Vmax_funderingVars[richting]
        Vmax_funderingFdoms = Vmax_funderingFdoms[richting]
        Vrms_maaiveldMus = Vrms_maaiveldMus[richting]
        Vrms_maaiveldVars = Vrms_maaiveldVars[richting]
        Sigma_maaiveld_spectraal = Sigma_maaiveld_spectraal[richting]
        
        Aantaltreinen = np.sum(totaalaantaltreinen[Index])
        Aantaltreinen_dagdeel = np.sum(aantaltreinen_dagd[Index, :], axis=0)
        
        VmaxBTS_gem = naverwerking_BTS(Vrms_vloer_treintype[Index], totaalaantaltreinen[Index])
        VmaxBTS_gem_fundering = naverwerking_BTS(Vrms_fundering_treintype[Index], totaalaantaltreinen[Index])
        
        sigma_gem = gecombineerde_onzekerheid2(totaalaantaltreinen[Index], VmaxVars[Index], VmaxBTS_gem)
        sigma_gem_fundering = gecombineerde_onzekerheid2(totaalaantaltreinen[Index], Vmax_funderingVars[Index], VmaxBTS_gem_fundering)
        
        VperSigs = VperVars[Index] * VperMus[Index]
        VperSig = np.sqrt(np.sum(VperSigs**2 * VperMus[Index]**2, axis=0) / np.sum(1e-18 + VperMus[Index]**2, axis=0))
        VperMu = np.sqrt(np.sum(VperMus[Index]**2, axis=0) + np.sum(VperSigs**2, axis=0) - VperSig**2)
        
        Imax = Index[np.argmax(VmaxMus[Index])]
        Maatgevende_klasse_vloer = str(treinklasse[Imax])
        VmaxFdom = VmaxFdoms[Imax]
        Varcoef = Varcoefs[Imax, [6,7,8]]
        Varcoef_maaiveld = Varcoefs[Imax, [0,1,2]]
        Varcoef_fundering = Varcoefs[Imax, [3,4,5]]
        
        VtopMu = np.max(VtopMus[Index])
        Imax_top = Index[np.argmax(VtopMus[Index])]
        VtopSig = VtopMu * VtopVars[Imax_top]
        VtopVd = 1.6 * (VtopMu + 1.66*VtopSig)
        VtopFdom = VtopFdoms[Imax_top]
        
        Maatgevende_klasse_fundering = str(treinklasse[Imax])
        Vmax_funderingFdom = Vmax_funderingFdoms[Imax]
        
        Vrms_maaiveldMu = np.max(Vrms_maaiveldMus[Index])
        Imax_maaiveld = Index[np.argmax(Vrms_maaiveldMus[Index])]
        Maatgevende_klasse_maaiveld = str(treinklasse[Imax_maaiveld])
        Vrms_maaiveldSig = Vrms_maaiveldVars[Imax_maaiveld] * Vrms_maaiveldMu
        Imax_spec = np.argmax(Vrms_maaiveldspectraal[:,Index], axis=1)
        Vrmsmax_maaiveldspectraal = np.max(Vrms_maaiveldspectraal[:,Index], axis=1)
        Sigmamax_maaiveld_spectraal = Sigma_maaiveld_spectraal[np.arange(Sigma_maaiveld_spectraal.shape[0]), Imax_spec]
        
        # Afronden
        Vrms_maaiveldMu = np.round(Vrms_maaiveldMu, 2)
        Vrmsmax_maaiveldspectraal = np.round(Vrmsmax_maaiveldspectraal, 3)
        Sigmamax_maaiveld_spectraal = np.round(Sigmamax_maaiveld_spectraal, 3)
        Vrms_maaiveldSig = np.round(Vrms_maaiveldSig, 3)
        VtopMu = np.round(VtopMu, 2)
        VtopSig = np.round(VtopSig, 3)
        VtopVd = np.round(VtopVd, 2)
        VperMu = np.round(VperMu, 3)
        VperSig = np.round(VperSig, 4)
        Varcoef = np.round(Varcoef, 2)
        Varcoef_maaiveld = np.round(Varcoef_maaiveld, 2)
        Varcoef_fundering = np.round(Varcoef_fundering, 2)
        Aantaltreinen = np.round(Aantaltreinen, 1)
        Aantaltreinen_dagdeel = np.round(Aantaltreinen_dagdeel, 1)
        sigma_gem = np.round(sigma_gem, 3)
        sigma_gem_fundering = np.round(sigma_gem_fundering, 3)
        VmaxBTS_gem = np.round(VmaxBTS_gem, 2)
        VmaxBTS_gem_fundering = np.round(VmaxBTS_gem_fundering, 2)
    else:
        # Lege output
        VmaxBTS_gem_fundering = np.zeros(1)
        VmaxBTS_gem = np.zeros(1)
        Vrmsmax_maaiveldspectraal = np.zeros(6)
        Sigmamax_maaiveld_spectraal = np.zeros(6)
        Vrms_maaiveldMu = np.zeros(1)
        Vrms_maaiveldSig = np.zeros(1)
        VtopMu = np.zeros(1)
        VtopSig = np.zeros(1)
        VtopVd = np.zeros(1)
        VperMu = np.zeros(3)
        VperSig = np.zeros(3)
        Varcoef = np.zeros(3)
        Varcoef_maaiveld = np.zeros(3)
        Varcoef_fundering = np.zeros(3)
        VmaxFdom = ''
        VtopFdom = ''
        Vmax_funderingFdom = ''
        Maatgevende_klasse_fundering = ''
        Maatgevende_klasse_maaiveld = ''
        Maatgevende_klasse_vloer = ''
        Aantaltreinen = np.zeros(1)
        Aantaltreinen_dagdeel = np.zeros(3)
        sigma_gem_fundering = np.zeros(1)
        sigma_gem = np.zeros(1)

    Aantaltreinen_dic = {
        'Aantaltreinen_pw': Aantaltreinen.item(0),
        'Aantaltreinen_dag': Aantaltreinen_dagdeel.item(0),
        'Aantaltreinen_avond': Aantaltreinen_dagdeel.item(1),
        'Aantaltreinen_nacht': Aantaltreinen_dagdeel.item(2)
    }
    Maaiveld = {
        'Vrms': Vrms_maaiveldMu.item(0),
        'Vrms_sigma': Vrms_maaiveldSig.item(0),
        'Maatgevende_cat': Maatgevende_klasse_maaiveld,
        'variatiecoeffs': Varcoef_maaiveld.tolist(),
        'Vrms_spectraal': Vrmsmax_maaiveldspectraal.tolist(),
        'Vrms_sigma_spectraal': Sigmamax_maaiveld_spectraal.tolist()
    }
    Fundering = {
        'Vmax': VmaxBTS_gem_fundering.item(0),
        'Vmax_sigma': sigma_gem_fundering.item(0),
        'Maatgevende_cat': Maatgevende_klasse_fundering,
        'Vtop': VtopMu.item(0),
        'Vtop_sigma': VtopSig.item(0),
        'Vtop_Vd': VtopVd.item(0),
        'Vtop_Fdom': VtopFdom,
        'Vmax_Fdom': Vmax_funderingFdom,
        'variatiecoeffs': Varcoef_fundering.tolist()
    }
    Gebouw = {
        'Vmax': VmaxBTS_gem.item(0),
        'Vmax_sigma': sigma_gem.item(0),
        'Maatgevende_cat': Maatgevende_klasse_vloer,
        'Vper': VperMu.tolist(),
        'Vper_sigma': VperSig.tolist(),
        'Vmax_Fdom': VmaxFdom,
        'variatiecoeffs': Varcoef.tolist()
    }
    
    Resultaten = {
        'Overzicht': Aantaltreinen_dic,
        'Maaiveld': Maaiveld,
        'Fundering': Fundering,
        'Gebouw': Gebouw
    }
    return Resultaten

def deformule(Bron,FEM,Hgebouw,Overig):
    ## dit is de hoofd functie
    # wat invoer uitpakken (rest gaat direct naar subfuncties)
    snelheid = np.array(Overig["snelheid"])   # met lengte aantaltreintypes
    Vd       = bool(Overig["Vd"])         # boolean, switch
    R        = np.array(Overig["R"])          # afstand, scalar
    CgeoZ    = np.array(Overig["CgeoZ"])      # 1x6
    CgeoX    = np.array(Overig["CgeoX"])      # 1x6
    scenarioKansen  = np.array(Overig["scenarioKansen"])      # 1xiets
    aantaltreinenPW = np.array(Overig["aantaltreinenPerWeek"]) # per dagdeel, dus aantaltreintypes x 3

    if "treinklasse" in Overig:
        treinklasse = Overig["treinklasse"] # met lengte aantaltreintypes
    else:
        treinklasse = []
        print('Warning: treinklasses niet opgegeven, dus reizigers en goederen dan maar op 1 hoop')

    if "brontype" in Overig:
        brontype = Overig["brontype"] # met lengte aantal afstanden, dus voorlopig 1
    else:
        brontype = 1
        print('Warning: brontype niet opgegeven, dus we gaan uit van doorgaand spoor')

    # scenarioKansen wegen
    scenarioKansen = scenarioKansen/sum(scenarioKansen)

    # perceptieweging kiezen
    if Vd:   # tov Wn, waarmee bron al gewogen is
        dWk = np.array([0.56, 1.2 , 1.8,  2.3,  2.3,  2.1])   # z richting
        dWd = np.array([0.95, 0.63, 0.44, 0.38, 0.37, 0.33])  # x richting
    else:
        dWk = np.ones(6)
        dWd = np.ones(6)

    # aantaltreintypes bepalen
    aantaltreintypes = len(snelheid)

    # lege invoer aanvullen met default waardes en berekeningen
    if not(isinstance(treinklasse,list)):
        treinklasse=[treinklasse]

    if len(treinklasse)==0:         
        treinklasse = [0]   # 0 = onbekend / alles, 1 = reizigers 2= goederen

    elif len(treinklasse)>1 and (0 in treinklasse):   # gekke situatie, mag niet
        exit(204) 

    if len(treinklasse)>1 and not(len(treinklasse)==aantaltreintypes):
        exit(205)

    # eerst Bron structure controleren, komt die overeen met snelheid array?
    if not(isinstance(Bron[0],list)):
        Bron=[Bron]

    if not(len(Bron)==aantaltreintypes):   # reparatiepogingen doen
        if len(Bron)==1: # dan blijkbaar zelfde trein bij verschillende snelheden
            for treinnr in range(aantaltreintypes-1):
                Bron.append(Bron[0])

        elif  aantaltreintypes==1: # blijkbaar meerdere treintypes met zelfde snelheid
            aantaltreintypes = len(Bron)
            snelheid = np.ones(aantaltreintypes)*snelheid

        else:
            exit(201)

    totaalaantaltreinen = np.zeros(aantaltreintypes)      # per type
    aantaltreinen       = np.zeros([aantaltreintypes,3])  # per type, per dagdeel

    if aantaltreintypes>1: 
        if np.ndim(aantaltreinenPW)==2:
            if np.size(aantaltreinenPW,axis=0)==aantaltreintypes and np.size(aantaltreinenPW,axis=1)==3:
                aantaltreinen       = aantaltreinenPW
                totaalaantaltreinen = np.sum(aantaltreinen,axis=1) 
            elif np.size(aantaltreinenPW,axis=0)==1 or np.size(aantaltreinenPW,axis=1)==1: # vector of zelfs scalar
                aantaltreinenPW = aantaltreinenPW[0]  # bij de volgende if verder bestuderen.
            else: # something rotten in the state of Denmark
                exit(202)
        
        if np.ndim(aantaltreinenPW)<2: # probleem: geen 2D array maar een 1D of een scalar
            if len(aantaltreinenPW)==1: # scalar zelfs
                for treinnr in range(aantaltreintypes):
                    totaalaantaltreinen[treinnr] = aantaltreinenPW/aantaltreintypes # ik interpreteer dat we aantal treinen maar moeten gaan verdelen
                    aantaltreinen[treinnr] = np.array([12,4,2])*totaalaantaltreinen[treinnr]/18
            else: # array maar met wat er in?
                if len(aantaltreinenPW)==3 and not(aantaltreintypes==3): # array van dagdelen
                    for treinnr in range(aantaltreintypes):
                        aantaltreinen[treinnr] = aantaltreinenPW/aantaltreintypes
                    totaalaantaltreinen = np.sum(aantaltreinen,axis=1)   
                elif len(aantaltreinenPW)==aantaltreintypes and not(aantaltreintypes==3): # array van treintupen
                    totaalaantaltreinen = aantaltreinenPW
                    for treinnr in range(aantaltreintypes):
                        aantaltreinen[treinnr] = np.array([12,4,2])*totaalaantaltreinen[treinnr]/18
                else:
                    exit(202)  # 3 getallen bij 3 treintypes, onduidelijk hoe te interpreteren    
    else:
        if np.ndim(aantaltreinenPW)<2: # repareren
            aantaltreinenPW = np.expand_dims(aantaltreinenPW,axis=0)
        if np.size(aantaltreinenPW,axis=1)==1:   # scalar, ik verdeel ze over de dagdelen, met reizigersritme
            totaalaantaltreinen[0] = aantaltreinenPW[0,0]
            aantaltreinen[0] = np.array([12,4,2])*aantaltreinenPW[0,0]/18
        elif np.size(aantaltreinenPW,axis=1)==3:    # array van dagdelen
            totaalaantaltreinen[0] = np.sum(aantaltreinenPW[0])
            aantaltreinen = aantaltreinenPW
        else:
            exit(203) # verkeerde lengte van een input
     
    if isinstance(R, list):         # indien scalar, dan list van maken
        aantalafstanden = len(R)   # doen we nu nog nix mee, zal UI nu moeten doen
    else:
        R = [R]
        aantalafstanden = 1
    if aantalafstanden>1:
        exit(206)
        
    aantalScenarios  = len(scenarioKansen) 
    axi2lineExponent = (1-np.sqrt(2))/np.sqrt(8) ## Dit is niet heel makkelijk af te leiden maar is een formule voor lijnbron van spoor
    if R[0]<25 or not brontype==1:
        axi2line = 1
    else:
        axi2line = (25/R[0])**(axi2lineExponent) 

    VmaxMus        = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    VmaxVars       = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    VmaxFdoms      = {'Z': [], 'X': []}
    VperMus        = {'Z': np.zeros([aantaltreintypes, 3]), 'X': np.zeros([aantaltreintypes, 3])}
    VperVars       = {'Z': np.zeros([aantaltreintypes, 3]), 'X': np.zeros([aantaltreintypes, 3])}
    VtopMus        = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    VtopVars       = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    VtopFdoms      = {'Z': [], 'X': []}
    Vrms_maaiveldMus  = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    Vrms_maaiveldVars = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    Vmax_funderingMus     = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    Vmax_funderingVars    = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    Vmax_funderingFdoms   = {'Z': [], 'X': []}
    Vrms_maaiveldspectraal = {'Z': np.zeros([6, aantaltreintypes]), 'X': np.zeros([6, aantaltreintypes])}
    Sigma_maaiveld_spectraal = {'Z': np.zeros([6, aantaltreintypes]), 'X': np.zeros([6, aantaltreintypes])}
    # resp. Bronkracht, Bron-bodem interactie, Totale Bron, Bodem, Bodem-Gebouw, Totale gebouw:
    Varcoefs = {'Z': np.zeros([aantaltreintypes, 9]), 'X': np.zeros([aantaltreintypes, 9])}
    Vrms_vloer_treintype     = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    Vrms_fundering_treintype = {'Z': np.zeros(aantaltreintypes), 'X': np.zeros(aantaltreintypes)}
    for treintypenr in range(aantaltreintypes): 
        BronInfo = Bron[treintypenr] 
        # constanten:
        aantalBronnen            = len(BronInfo)    # aantal gevonden bronmetingen, grootte van Bron
        VmaxMuss      = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        VmaxVarss     = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        VmaxFdomss    = {'Z': [], 'X': []}
        VperMuss      = {'Z': np.zeros([3, aantalScenarios]), 'X': np.zeros([3, aantalScenarios])}
        VperVarss     = {'Z': np.zeros([3, aantalScenarios]), 'X': np.zeros([3, aantalScenarios])}
        VtopMuss      = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        VtopVarss     = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        VtopFdomss    = {'Z': [], 'X': []}
        Vrms_maaiveldMuss  = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        Vrms_maaiveldVarss = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        Vmax_funderingMuss    = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        Vmax_funderingVarss   = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        Vmax_funderingFdomss  = {'Z': [], 'X': []}
        Varcoefss = {'Z': np.zeros([9, aantalScenarios]), 'X': np.zeros([9, aantalScenarios])}
        Vrms_maaiveldspectraal_s = {'Z': np.zeros([6, aantalScenarios]), 'X': np.zeros([6, aantalScenarios])}
        Sigma_maaiveld_spectraal_s = {'Z': np.zeros([6, aantalScenarios]), 'X': np.zeros([6, aantalScenarios])}
        Vrms_vloer_scenario           = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        Vrms_fundering_scenario   = {'Z': np.zeros(aantalScenarios), 'X': np.zeros(aantalScenarios)}
        # vertaalspoorligging (bij 130km/uur) naar snelheid van deze trein 
        CgeoZtrein               = shiftCgeoSpectrum(CgeoZ,130,snelheid[treintypenr]) 
        CgeoXtrein               =  shiftCgeoSpectrum(CgeoX,130,snelheid[treintypenr])
        
        for scenario in range(aantalScenarios): ## hier loopen we over het aantal scenarios, dus loop in een loop
            FEMscenario     = FEM[scenario]
            HgebouwScenario = Hgebouw[scenario]
            Y           = np.array(FEMscenario["Y"])             # 1x6 uit FEM, naar ontvangpunt
            Y_ratio     = np.array(FEMscenario["Y_ratio"])       # 1x6
            varY        = np.array(FEMscenario["var_Y"])         # 6x6 covariantiecoefficient
            #varY_ratio  = np.array(FEMscenario["var_Y_ratio"])   # nog neit in gebruik
            
            # van covariantiecoefficienten echte covariantiematrices maken
            cov_Y       = np.ones([6,6]) * np.transpose(varY[np.newaxis]) * varY # maximale relaties tussen banden
           # cov_Y_ratio = np.ones([6,6]) * np.transpose(varY_ratio[np.newaxis]) * varY_ratio # maximale relaties tussen banden

            # Eerst maar eens de brongegevens bepalen, door ze te kiezen uit de gemeten bronnen kiezen
            if aantalBronnen==1:    # dan kiezen we nu die meting, in feite zonder de bronkracht te modificeren
                BronIdxHoogLaag  = [0,0]
                sZ     = np.ones(6)
                sX     = np.ones(6)
                covar_sZ = np.zeros([6,6])
                covar_sX = np.zeros([6,6])
            elif aantalBronnen==2:
                BronIdxHoogLaag = [0,1]
                DictOut   = Stijfheidsratio(FEMscenario,BronInfo,BronIdxHoogLaag)  # structure: stijfheidsratio.x (1x6) stijfheidsratio.z (1x6)
                sZ        = DictOut['muZ']
                sX        = DictOut['muX']
                covar_sZ  = DictOut['covarZ']
                covar_sX  = DictOut['covarX']
            else:                    # >2 cases, we gaan per band de dichtstbij omliggende kiezen, wel tricky eigenlijk
                Yo   = np.array(FEMscenario["Yo"])
                afstand = np.zeros(aantalBronnen)
                for i1 in range(aantalBronnen):
                   BronIn = BronInfo[i1]
                   Zo   = np.array(BronIn["Zo"]) 
                   afstand[i1] = np.mean(np.log(Yo[1:5]*Zo[1:5]))
                afstand = np.argsort(abs(afstand))
                BronIdxHoogLaag = afstand[range(2)]

                DictOut   = Stijfheidsratio(FEMscenario,BronInfo,BronIdxHoogLaag)  # structure: stijfheidsratio.x (1x6) stijfheidsratio.z (1x6)
                sZ        = DictOut['muZ']
                sX        = DictOut['muX']
                covar_sZ  = DictOut['covarZ']
                covar_sX  = DictOut['covarX']
            
            # dan de bronkracht corrigeren cq vaststellen
            DictOut = Bronkracht(BronInfo,BronIdxHoogLaag,sZ,sX,covar_sZ,covar_sX,snelheid[treintypenr])          # structure F:   F.x,F.z
            FZ      = DictOut['muZ']
            FX      = DictOut['muX']
            cov_FZ  = DictOut['covZ']     # covariantiecoefficient
            cov_FX  = DictOut['covX']
            #### verwerking per richting
            for richting in ['Z', 'X']:
                if richting == 'Z':
                    Vrms_maaiveld = FZ * CgeoZtrein * Y * axi2line # kernformule
                    cov_Vrms_maaiveld = CovariantProduct(FZ * CgeoZtrein, cov_FZ, Y * axi2line, cov_Y)
                    DictOut= RSSmetCovarLognormaal(FZ, cov_FZ)
                    dW = dWk
                    # Specifiek voor vloerberekeningen
                    vloer_indices = [0, 1, 2]
                    vloer_keys = ['Hzz1', 'Hzz2', 'Hzx']
                    vloer_cov_keys = ['cov_Hzz1', 'cov_Hzz2', 'cov_Hzx']
                    fundering_key = 'Hfzz'
                    fundering_cov_key = 'cov_Hfzz'
                   # richtingen_vloer = ['zz1', 'zz2', 'zx'] # dit voeren we niet meer uit
                   # richting_fundering = 'zz'
                else:
                    Vrms_maaiveld = FX * CgeoXtrein * Y * Y_ratio * axi2line # kernformule
                    cov_Vrms_maaiveld = CovariantProduct(FX * CgeoXtrein, cov_FX, Y * axi2line * Y_ratio, cov_Y)
                    DictOut = RSSmetCovarLognormaal(FX, cov_FX)
                    dW = dWd
                    # Specifiek voor vloerberekeningen
                    vloer_indices = [3]      # Alleen xx
                    vloer_keys = ['Hxx']
                    vloer_cov_keys = ['cov_Hxx']
                    fundering_key = 'Hfxx'
                    fundering_cov_key = 'cov_Hfxx'
                    #richtingen_vloer = ['xx']
                    #richting_fundering = 'xx'

                # Onzekerheid in bron (per richting)
                Varcoefss[richting][1, scenario] = DictOut['var'] # bron onzekerheid pr richting

                # Uitvoer maaiveld
                Vrms_maaiveldspectraal_s[richting][:, scenario] = Vrms_maaiveld * 1e3
                Sigma_maaiveld_spectraal_s[richting][:, scenario] = np.diagonal(cov_Vrms_maaiveld) * Vrms_maaiveld * 1e3 # diagonaal is relatieve sigma, dit is relatief dus maal Vrms_maaiveld

                DictOut_mu = RSSmetCovarLognormaal(Vrms_maaiveld, cov_Vrms_maaiveld)
                Vrms_maaiveldMuss[richting][scenario]  = DictOut_mu['mu'] * 1.05 * 1e3 # 5 procent therstel voor verlies octaafbanddecompositie
                Vrms_maaiveldVarss[richting][scenario] = DictOut_mu['var']

                Varcoefverschil = Vrms_maaiveldVarss[richting][scenario]**2 - Varcoefss[richting][1, scenario]**2
                Varcoefss[richting][2, scenario] = np.sign(Varcoefverschil) * np.sqrt(np.abs(Varcoefverschil))

                # === combineren met Hgebouw tot Vrms_vloer ===
                n_vloer = len(vloer_indices)
                Vrms_vloerMu   = np.zeros(n_vloer)
                Vrms_vloerVar  = np.zeros(n_vloer)
                Vrms_overdrVar = np.zeros(n_vloer)
                Vrms_gebouwVar = np.zeros(n_vloer)
                Vrms_bronVar   = np.zeros(n_vloer)
                DominanteBand  = [0]*n_vloer
                var_Vrms_maaiveld = np.diagonal(cov_Vrms_maaiveld) # quick fix, liever straks de hele covar Vloer
                
                # Bron is di tneit gwn Vrms? Daardoor beetje vearnderd. Want verschlvan Vmu en Fmu is dan allene de weiging
                if richting == 'Z':
                    Fmu = FZ * CgeoZtrein * Y * axi2line # is dit niet gewoon vrms?
                    Fvariantie = (FZ * CgeoZtrein * np.diagonal(cov_FZ))**2 * Y**2 * axi2line**2
                else:
                    Fmu = FX * CgeoXtrein * Y * axi2line * Y_ratio
                    Fvariantie = (FX * CgeoXtrein * np.diagonal(cov_FX))**2 * Y**2 * axi2line**2 * Y_ratio**2

                for i, (key, covkey) in enumerate(zip(vloer_keys, vloer_cov_keys)):
                    if richting == 'Z' and i == 2:  # zx
                        Vmu = Vrms_maaiveld * dWd
                    else:
                        Vmu = Vrms_maaiveld * dW # dWk voor Z en dWd voor X
                    Vvariantie = (var_Vrms_maaiveld * Vmu)**2
                    Hmu = np.array(HgebouwScenario[key])
                    Hcovar = np.array(HgebouwScenario[covkey])
                    DictOut = VloerLognormaal(Vmu, Vvariantie, Hmu, Hcovar)
                    Vrms_vloerMu[i]   = DictOut['mu']
                    Vrms_vloerVar[i]  = DictOut['var']
                    DominanteBand[i]  = DictOut['dominanteBand']
                    Vrms_overdrVar[i] = DictOut['varV'] # bron+overdracht
                    Vrms_gebouwVar[i] = DictOut['varH'] # gebouw
                 
                    DictOut = VloerLognormaal(Fmu, Fvariantie, Hmu, Hcovar)
                    Vrms_bronVar[i] = DictOut['varV'] # bron
                    
                # We nemen het maximum van de3 trilvormen voor Z en 1 voor X
                VrmsvloerMax = np.max(Vrms_vloerMu)
                Imax = np.argmax(Vrms_vloerMu)
                
                Vrms_vloer_scenario[richting][scenario] = VrmsvloerMax * 1e3
                VmaxMuss[richting][scenario] = naverwerking_BTS(VrmsvloerMax, totaalaantaltreinen[treintypenr]) * 1e3
      
                # spreiding is die van de dominante trillingsvorm  
                VmaxVarss[richting][scenario] = Vrms_vloerVar[Imax]
                VarcoefbijdrageBron   = Vrms_bronVar[Imax]
                VarcoefbijdrageOverdr = Vrms_overdrVar[Imax]
                VarcoefbijdrageGebouw = Vrms_gebouwVar[Imax]
                
                #Bijdrage totale onzekerheid
                Varcoefss[richting][6, scenario] = VarcoefbijdrageBron
                Varcoef2verschil = VarcoefbijdrageOverdr**2 - VarcoefbijdrageBron**2
                Varcoefss[richting][7, scenario] = np.sqrt(abs(Varcoef2verschil)) * np.sign(Varcoef2verschil)
                Varcoefss[richting][8, scenario] = VarcoefbijdrageGebouw

                frequenties = ['2 Hz', '4 Hz', '8 Hz', '16 Hz', '32 Hz', '63 Hz']
                VmaxFdomss[richting].append(frequenties[DominanteBand[Imax]])

                # Vper
                VeffmaxMu = 1.95 * VrmsvloerMax * 1e3
                x = np.linspace(.1, 10, 991)
                PDF = np.exp(-(np.log(x) - np.log(VeffmaxMu))**2 / (.18)) / (x * .752)
                aantalperiodes = [1440, 480, 960]
                VperMu = np.zeros(3)
                for dagdeel in range(3):
                    dagdeelratio = aantaltreinen[treintypenr, dagdeel] / 7 / aantalperiodes[dagdeel]
                    VperMu[dagdeel] = .1 * np.sqrt(dagdeelratio * np.sum(PDF * x**2))
                VperVarss[richting][:, scenario] = VmaxVarss[richting][scenario]
                VperMuss[richting][:, scenario] = VperMu

                # === Fundering: Vtop (schade) en Vmaxfundering ===
                Vrms_funderingMu   = np.zeros(1)
                Vrms_funderingVar  = np.zeros(1)
                DominanteBandFund  = [0]
                DominanteBandFundA = [0]
                Vrms_gebouwVar_f   = np.zeros(1)
                Vrms_bodemVar_f    = np.zeros(1)
                Vrms_bronVar_f     = np.zeros(1)

                Vmu = Vrms_maaiveld
                Vvariantie = (var_Vrms_maaiveld * Vmu)**2 # diag(Covar) == sigma relatief dus d tis sigma^2/Vmu^2 * Vmu^2 geeft absolute sigma^2 = Variantie
                Hmu = np.array(HgebouwScenario[fundering_key])
                Hcovar = np.array(HgebouwScenario[fundering_cov_key])
                DictOut = VloerLognormaal(Vmu, Vvariantie, Hmu, Hcovar)
                Vrms_funderingMu[0]   = DictOut['mu']
                Vrms_funderingVar[0]  = DictOut['var']
                DominanteBandFund[0]  = DictOut['dominanteBand']
                DominanteBandFundA[0] = DictOut['dominanteBandA']
                Vrms_gebouwVar_f[0]   = DictOut['varH'] # fundering apart
                Vrms_bodemVar_f[0]    = DictOut['varV'] # vanuit oogpunt fundeirng

                if richting == 'Z':
                    Fmu = FZ * CgeoZtrein * Y * axi2line
                    Fvariantie = (FZ * CgeoZtrein * np.diagonal(cov_FZ))**2 * Y**2 * axi2line**2
                else:
                    Fmu = FX * CgeoXtrein * Y * axi2line * Y_ratio
                    Fvariantie = (FX * CgeoXtrein * np.diagonal(cov_FX))**2 * Y**2 * axi2line**2 * Y_ratio**2
                DictOut = VloerLognormaal(Fmu, Fvariantie, Hmu, Hcovar)
                Vrms_bronVar_f[0] = DictOut['varV']

                # Altijd maar 1 optie want 1 waarde per ricthing
                VrmsfunderingMax = Vrms_funderingMu[0]
                Imax_f = 0

                Vrms_fundering_scenario[richting][scenario] = VrmsfunderingMax * 1e3
                Vmax_funderingMuss[richting][scenario] = naverwerking_BTS(VrmsfunderingMax, totaalaantaltreinen[treintypenr]) * 1e3
              
                VtopMuss[richting][scenario] = 2.4 * Vmax_funderingMuss[richting][scenario]
                VtopVarss[richting][scenario] = Vrms_funderingVar[0]
                Vmax_funderingVarss[richting][scenario] = Vrms_funderingVar[0]

                Varcoefss[richting][3, scenario] = Vrms_bronVar_f[0]
                Varcoefss[richting][4, scenario] = Vrms_bodemVar_f[0]
                Varcoefss[richting][5, scenario] = Vrms_gebouwVar_f[0]

                VtopFdomss[richting].append(frequenties[DominanteBandFundA[Imax_f]])
                Vmax_funderingFdomss[richting].append(frequenties[DominanteBandFund[Imax_f]])
            
        
        # wrap up van de scenario's
        for richting in ['Z', 'X']:
            IndexDominanteScenario = np.argmax(scenarioKansen)
            Vrms_fundering_treintype[richting][treintypenr] = np.sum(Vrms_fundering_scenario[richting] * scenarioKansen)
            Vrms_vloer_treintype[richting][treintypenr]     = np.sum(Vrms_vloer_scenario[richting] * scenarioKansen)
            VmaxMus[richting][treintypenr]                     = np.sum(VmaxMuss[richting] * scenarioKansen)
            VmaxVars[richting][treintypenr]                    = np.sum(VmaxVarss[richting] * scenarioKansen)
            VmaxFdoms[richting].append                         (VmaxFdomss[richting][IndexDominanteScenario])
            VperMus[richting][treintypenr]                     = np.sum(VperMuss[richting] * scenarioKansen, axis=1)
            VperVars[richting][treintypenr]                    = np.sum(VperVarss[richting] * scenarioKansen, axis=1)
            VtopMus[richting][treintypenr]                     = np.sum(VtopMuss[richting] * scenarioKansen)
            VtopVars[richting][treintypenr]                    = np.sum(VtopVarss[richting] * scenarioKansen)
            VtopFdoms[richting].append                         (VtopFdomss[richting][IndexDominanteScenario])
            Vmax_funderingMus[richting][treintypenr]           = np.sum(Vmax_funderingMuss[richting] * scenarioKansen)
            Vmax_funderingVars[richting][treintypenr]          = np.sum(Vmax_funderingVarss[richting] * scenarioKansen)
            Vmax_funderingFdoms[richting].append               (Vmax_funderingFdomss[richting][IndexDominanteScenario])
            Vrms_maaiveldMus[richting][treintypenr]            = np.sum(Vrms_maaiveldMuss[richting] * scenarioKansen)
            Vrms_maaiveldVars[richting][treintypenr]           = np.sum(Vrms_maaiveldVarss[richting] * scenarioKansen)
            Vrms_maaiveldspectraal[richting][:, treintypenr]   = np.sum(Vrms_maaiveldspectraal_s[richting] * scenarioKansen, axis=1)
            Sigma_maaiveld_spectraal[richting][:, treintypenr] = np.sum(Sigma_maaiveld_spectraal_s[richting] * scenarioKansen, axis=1)
            Varcoefs[richting][treintypenr]                    = np.sum(Varcoefss[richting] * scenarioKansen, axis=1)
    # resultaten van alle treintypes samenbrengen, per treinklasse
    IndexReizigers = [i for i,e in enumerate(treinklasse) if e<=10]
    IndexGoederen  = [i for i,e in enumerate(treinklasse) if e>10]
    IndexAlles     = range(aantaltreintypes)


    ## Hier wordt alle output samengesteld en wordt ook Vmax,bts berekend ipv veffmax gemiddeld over de treintypes.
    Resultaten = {
    'AlleTreinen': {},
    'Reizigers': {},
    'Goederen': {}
    }   
    for richting in ['Z', 'X']:
        ResultatenReizigers   = OutputSamenstellen(
            treinklasse, IndexReizigers,
            Vrms_fundering_treintype, Vrms_maaiveldspectraal,
            totaalaantaltreinen, Vrms_vloer_treintype,
            VperVars, VperMus, VmaxMus, VmaxVars, VmaxFdoms, Varcoefs,
            VtopMus, VtopVars, VtopFdoms,
            Vmax_funderingMus, Vmax_funderingVars, Vmax_funderingFdoms,
            Vrms_maaiveldMus, Vrms_maaiveldVars,
            Sigma_maaiveld_spectraal,
            aantaltreinen,
            richting
        )
        ResultatenGoederen    = OutputSamenstellen(
            treinklasse, IndexGoederen,
            Vrms_fundering_treintype, Vrms_maaiveldspectraal,
            totaalaantaltreinen, Vrms_vloer_treintype,
            VperVars, VperMus, VmaxMus, VmaxVars, VmaxFdoms, Varcoefs,
            VtopMus, VtopVars, VtopFdoms,
            Vmax_funderingMus, Vmax_funderingVars, Vmax_funderingFdoms,
            Vrms_maaiveldMus, Vrms_maaiveldVars,
            Sigma_maaiveld_spectraal,
            aantaltreinen,
            richting
        )
        ResultatenAlleTreinen = OutputSamenstellen(
            treinklasse, IndexAlles,
            Vrms_fundering_treintype, Vrms_maaiveldspectraal,
            totaalaantaltreinen, Vrms_vloer_treintype,
            VperVars, VperMus, VmaxMus, VmaxVars, VmaxFdoms, Varcoefs,
            VtopMus, VtopVars, VtopFdoms,
            Vmax_funderingMus, Vmax_funderingVars, Vmax_funderingFdoms,
            Vrms_maaiveldMus, Vrms_maaiveldVars,
            Sigma_maaiveld_spectraal,
            aantaltreinen,
            richting
        )
        
    
        Resultaten['AlleTreinen'][richting] = {k: v for k, v in ResultatenAlleTreinen.items() if k != 'Overzicht'}
        Resultaten['Reizigers'][richting]   = {k: v for k, v in ResultatenReizigers.items()   if k != 'Overzicht'}
        Resultaten['Goederen'][richting]    = {k: v for k, v in ResultatenGoederen.items()    if k != 'Overzicht'}

    # Overzicht toevoegen (richting-onafhankelijk)
    Resultaten['AlleTreinen']['Overzicht'] = ResultatenAlleTreinen['Overzicht']
    Resultaten['Reizigers']['Overzicht']   = ResultatenReizigers['Overzicht']
    Resultaten['Goederen']['Overzicht']    = ResultatenGoederen['Overzicht']
            
        
        
                                        
    return Resultaten

def naverwerking_BTS(vrms, aantaltreinen):
    # dit combineert lgo normaal verdelingen door een linearie combinatie te nemen in het log domein. Vervolgens wordt vanuit de gecombineerde veffmax de Bts bepaald.
    # mu zou goed bepaald moeten worden zo en in lijn met metingen ln(X) = N(mui, 0.3^2 ) > is de set. dit zou ehtzelfde moeten zijn als sum wiui van ours
    totaal_treinen = np.sum(aantaltreinen)
    if  totaal_treinen  > 1:
        # vrms is hier een vector van het aantal treinen en de bijbehorende medianen
        veffmax = 1.95 * vrms
        mu_totaal = np.sum(np.log(veffmax) * aantaltreinen/totaal_treinen )   # gewogen gemiddelde van de mu's
        VmaxBTS = np.exp(mu_totaal + .3*stats.t.ppf(1-1/totaal_treinen, totaal_treinen))
    else:
        VmaxBTS = 0
    return VmaxBTS

def gecombineerde_onzekerheid(vrms, VmaxVars, aantaltreinen, VmaxBts):
    totaal_treinen = np.sum(aantaltreinen)
    if totaal_treinen > 1:
        Veffmax = 1.95 * vrms
        Veffmax_worstcase = Veffmax + Veffmax*VmaxVars
        Veffmax_gemiddeld_worstcase = np.sum(np.log(Veffmax_worstcase)*aantaltreinen/totaal_treinen)     
        Vmax_BTS_worstcase = np.exp(Veffmax_gemiddeld_worstcase + .3*stats.t.ppf(1-1/totaal_treinen,np.round(totaal_treinen)))
        sigma_worstcase = Vmax_BTS_worstcase-VmaxBts
        # standardeviation average van vloer 
    else:
        sigma_worstcase = 0  # anders krijg je NaN waarde door de stat.t.ppf
    return sigma_worstcase

def gecombineerde_onzekerheid2(aantaltreinen, VmaxVars, VmaxBts):
    # dit combineert lgo normaal verdelingen door een linearie combinatie te nemen in het log domein. Vars is ier de VC rond de mediaan. Dus modelonzekerheid, klopt dit?
    totaal_treinen = np.sum(aantaltreinen)
    if totaal_treinen > 1:
        sigma2_log = np.log(VmaxVars**2 + 1)  # sigma in log domein
        sigma2_totaal = np.sum((aantaltreinen / totaal_treinen)**2 * sigma2_log) # Var(mu) = sum (w2 *2s2) met  w = aantaltreinen/totaal
        VC = np.sqrt(np.exp(sigma2_totaal) - 1) # terug naar VC
        sigma = VmaxBts * VC
    else:
        sigma = 0
    return sigma

def montecarloMetCovariantieNormaal(X, varX, MCgrootte):
    covX = np.ones([6, 6]) * np.transpose(varX[np.newaxis]) * varX  # maximale relaties tussen banden
    covarX = X * np.transpose([X]) * covX
    XMC = np.random.multivariate_normal(X, covarX, MCgrootte)
    return XMC


def montecarloMetCovariantieLognormaal(X, varX, MCgrootte):
    sigmalog = np.sqrt(np.log(1+varX**2))
    meanlog = np.log(X) - (sigmalog**2)/2
    variatiecoefflog = sigmalog/meanlog
    covX = np.ones([6, 6]) * np.transpose(variatiecoefflog[np.newaxis]) * variatiecoefflog  # maximale relaties tussen banden
    covarX = meanlog * np.transpose([meanlog]) * covX
    XMC = np.exp(np.random.multivariate_normal(meanlog, covarX, MCgrootte))
    return XMC


def read_json(file_name):
    import json
    try:
        with open(file_name, "r") as fid:
             data = json.load(fid)  
    except OSError:
        exit(101)
    return data

    
def write_json(file_name, VmaxEtc):
    try:
       with open(file_name, "w+") as fid:
           json.dump(VmaxEtc, fid, separators=(',', ': '), sort_keys=False, indent=4)  ## Deze stond eerst op True, op False lijkt me logischer..
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
 