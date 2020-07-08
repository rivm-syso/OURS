# -*- coding: utf-8 -*-
"""
Created on Tue Jul  2 17:41:57 2019

@author: Arnold Koopman
"""

import argparse
import math
import json
import os
import numpy as np
from scipy import signal

octaafbanden = np.array([2,4,8,16,31.5,63]);
bovengrenzen = octaafbanden*math.sqrt(2);
ondergrenzen = octaafbanden/math.sqrt(2);
        
def naverwerking(Res,Afstanden,Lengtes):
        
    RDisp_real = np.array(Res["RDisp_real"]);
    RDisp_imag = np.array(Res["RDisp_imag"]);
    ZDisp_real = np.array(Res["ZDisp_real"]);
    ZDisp_imag = np.array(Res["ZDisp_imag"]);
    Rcoord     = np.array(Res["Rcoord"]);
    Frequency  = np.array(Res["Frequency"]);
    
    if isinstance(Afstanden, list):
        aantalCases = len(Afstanden);
        listinput   = True;
    else:   # scalar opgeven, die ik in een triviale array stop
        Afstanden   = [Afstanden];
        Lengtes     = [Lengtes];
        aantalCases = 1;
        listinput   = False;
        
    if "MaxFreqLimited" in Res:
        MaxFreqLimited = Res["maxFreqLimited"]; # met lengte aantaltreintypes
        if MaxFreqLimited <= 0:
           MaxFreqLimited = Frequency[-1];
    else:
        MaxFreqLimited = Frequency[-1];
        
    # Indien de FEM som een maximale frequentie heeft die lager is dan de gevraagde frequentierange
    # zijn de waardes boven die maximale waarde niet te vertrouwen en gebruiken we de waarde van
    # de hoogst betrouwbare frequentie.  
    # Dit kan eleganter:
    # eerst checken of de waardes boven Fmax echt zo gek zijn
    # indien so, dan waardes bepalen op een Barkan achtige extrapolatie
    # fase info moet ook netter, want c bepaling heeft hier last van    
        
    Resultaten = [];  # deze gaan we vullen
    for case in range(aantalCases):
        GevraagdeAfstand = Afstanden[case];
        Lengte           = Lengtes[case];
        
        # ============ de knopen (afstandIndex) van deze case vinden ============
        # daartoe eerst uit de bak data de relevante afstanden halen, nl. de
        # afstanden tussen GevraagdeAfstand en GevraagdeAfstand + 10 (10 meter
        # verder)

        if Rcoord[-1] < GevraagdeAfstand + Lengte:
            # print('FEM bodem niet lang genoeg voor deze gevraagde afstand')
            exit(201)
        # index bepalen van de punten in de gewenste afstandrange
        # afstandIndex = find(Rcoord >= GevraagdeAfstand & Rcoord <= GevraagdeAfstand+Lengte);
        afstandIndex1 = np.where(Rcoord >= GevraagdeAfstand);
        afstandIndex2 = np.where(Rcoord <= GevraagdeAfstand+Lengte);
        afstandIndex  = np.intersect1d(afstandIndex1,afstandIndex2);
        
        
        # ============ golfsnelheid c ============
        
        # nu gaan we werken met de fase informatie (in plaats van de amplitudes)
        # Daarvoor gebruiken we Matlabfunctie "angle".  Input is een complex getal,
        # output een hoek in radialen (tussen -2pi en +2pi).
        Rfase = np.angle(RDisp_real + 1j*RDisp_imag);
        Zfase = np.angle(ZDisp_real + 1j*ZDisp_imag);
        
        # dan gaan we unwrappen waarbij we gebruik maken van voorkennis over het
        # verloop van de fase over de afstand
        # we beginnen met het bepalen van de afgeleide de fase over de afstand
        dRfase = np.diff(Rfase,axis=0);  # diff doet zijn werk, zoals alle matlabfuncties, over de kolommen
        dZfase = np.diff(Zfase,axis=0);  # dus restant is een rij
        # overigens geen echte afgeleide want niet gedeeld door dx
        # dan de slimmigheid: een unwrap door de fasesprongen te detecteren
        dRfase=np.where(dRfase>0,0,dRfase);
        dZfase=np.where(dZfase>0,0,dZfase);
        
        # nu kijken wat de totale faseachterstand op de gewenste afstand i
        # we pakken de laatste afstandIndex (die we al eerder gemaakt hadden) en
        # gaan er van uit dat de afstanden altijd oplopend worden geleverd door FEM
        #aI = afstandIndex(end-1);              # diff is 1 korter, dus niet all the way
        aI=afstandIndex[-2];
        RfaseUnwrapped = sum(dRfase[1:aI,:]);  # som van alle elementjes tot en met elementje aI, per frequentie
        ZfaseUnwrapped = sum(dZfase[1:aI,:]);  # ja dat kan je hierboven ook in de geneste for-next opnemen
        # soms komt er bij een frequentie 0 uit, nl. vlak bij bron en als er 0 uit komt gaat ie verderop delen door 0
        # nu gaan we vlak bij bron nooit een cR gebruiken, dus we vullen voor de voortgang maar een kleine waarde in
        RfaseUnwrapped=np.where(RfaseUnwrapped>=0,0.1,RfaseUnwrapped); 
        ZfaseUnwrapped=np.where(ZfaseUnwrapped>=0,0.1,ZfaseUnwrapped);  
        
        # dan uit de totale fasedraaiing en de afstand de voortplantingsnelheid halen
        afstand = Rcoord[aI];
        cRsmal  = -Frequency*afstand/(RfaseUnwrapped/6.28);
        cZsmal  = -Frequency*afstand/(ZfaseUnwrapped/6.28);
        
        # check op gekke c, als MaxFreqLimited lager is dan gewenste frequentierange
        # in dat geval displacements en c aanpassen
        if Frequency[-2] > MaxFreqLimited:         # ok, reden tot zorg
           Betrouwbaar = np.where(Frequency <= MaxFreqLimited);
           Repareren   = np.where(Frequency >  MaxFreqLimited);
           Repareren   = Repareren[0];
           Betrouwbaar = Betrouwbaar[0];
           cZdetrend   = signal.detrend(cZsmal);
           afwijking   = np.std(cZdetrend[Betrouwbaar]);         # maat voor acceptabele afwijking
           Iexplosie   = np.where(abs(cZdetrend[Repareren])>afwijking*2);
           Iexplosie   = Iexplosie[0];
           if np.size(Iexplosie)>0:
               begin = Betrouwbaar[-1];
               einde = Repareren[Iexplosie[0]];
               for i1 in range(Repareren[Iexplosie[0]], Repareren[-1]+1):
                   RDisp_real[afstandIndex,i1] = np.mean(RDisp_real[afstandIndex,begin:einde],axis=1);
                   RDisp_imag[afstandIndex,i1] = np.mean(RDisp_imag[afstandIndex,begin:einde],axis=1);
                   ZDisp_real[afstandIndex,i1] = np.mean(ZDisp_real[afstandIndex,begin:einde],axis=1);
                   ZDisp_imag[afstandIndex,i1] = np.mean(ZDisp_imag[afstandIndex,begin:einde],axis=1);    
                   cRsmal[i1]                  = np.mean(cRsmal[begin:einde]); 
                   cZsmal[i1]                  = np.mean(cZsmal[begin:einde]); 
        
        # dan dat middelen naar octaven
        cZ      = np.zeros(6);
        cX      = np.zeros(6);
        c_ratio = np.zeros(6);
        for octaafnr in range(len(octaafbanden)):
            frequentieIndex1 = np.where(Frequency>=ondergrenzen[octaafnr]);
            frequentieIndex2 = np.where(Frequency<=bovengrenzen[octaafnr]);
            frequentieIndex  = np.intersect1d(frequentieIndex1,frequentieIndex2);
            if len(frequentieIndex) > 0: 
                cX[octaafnr]      = np.mean(cRsmal[frequentieIndex]);
                cZ[octaafnr]      = np.mean(cZsmal[frequentieIndex]);
                c_ratio[octaafnr] = cX[octaafnr]/cZ[octaafnr];
        
        c       = np.round(cZ,decimals=0);
        c_ratio = np.round(c_ratio,decimals=2);
        
        
        # ============ admittantie Y en Y_ratio bepalen ============ 
        
        # RDisp en ZDisp van deze afstanden selecteren uit de complete set
        # Daarbij meteen naar een amplitude rekenend, met Pythagoras
        RDisp = abs(RDisp_real[afstandIndex,:] + 1j*RDisp_imag[afstandIndex,:]);
        ZDisp = abs(ZDisp_real[afstandIndex,:] + 1j*ZDisp_imag[afstandIndex,:]);
        
        # We middelen over de afstanden
        RDispMean = np.mean(RDisp,axis=0);  # Matlab doet dat automatisch in de eerste richting
        ZDispMean = np.mean(ZDisp,axis=0);
    
        # Dan gaan we sommeren over de frequenties, per band
        YZ = np.zeros(6)
        YX = np.zeros(6)
        
        for octaafnr in range(len(octaafbanden)):
            # afvangen als frequentiebereik te laag is
            #frequentieIndex = find(Frequency>=ondergrenzen[octaafnr] & Frequency<=bovengrenzen[octaafnr]);
            frequentieIndex1 = np.where(Frequency>=ondergrenzen[octaafnr]);
            frequentieIndex2 = np.where(Frequency<=bovengrenzen[octaafnr]);
            frequentieIndex  = np.intersect1d(frequentieIndex1,frequentieIndex2);
            if len(frequentieIndex) == 0: #isempty(frequentieIndex):  # of, in basictaal: " if length(frequentieIndex)==0 "
                # dit kan voorkomen, als bijv. niet hoger dan 32 Hz is gerekend;
                # dan blijft YZ voor die band de waarde 0 houden, dat is ok
                print('geen frequenties gevonden voor een octaafband')
            else:
                YZ[octaafnr] = np.mean(6.28*Frequency[frequentieIndex]*ZDispMean[frequentieIndex]);
                YX[octaafnr] = np.mean(6.28*Frequency[frequentieIndex]*RDispMean[frequentieIndex]);
        
        legebanden = np.where(YZ==0); 
        
        Y       = np.round(YZ,decimals=14);
        Y_ratio = np.round(YX/YZ,decimals=2);
        Y_ratio[legebanden] = 0; 
        
        
        
        # ============ fase van Y op gevraagde afstand ============
        fase = np.zeros(6);
        ZDispMeanAfstand_real = np.mean(ZDisp_real[afstandIndex,:],axis=0);
        ZDispMeanAfstand_imag = np.mean(ZDisp_imag[afstandIndex,:],axis=0);
        for octaafnr in range(len(octaafbanden)):
            frequentieIndex1 = np.where(Frequency>=ondergrenzen[octaafnr]);
            frequentieIndex2 = np.where(Frequency<=bovengrenzen[octaafnr]);
            frequentieIndex  = np.intersect1d(frequentieIndex1,frequentieIndex2);
            if len(frequentieIndex) > 0: 
                ZDispMean_real = np.mean(ZDispMeanAfstand_real[frequentieIndex],axis=0);
                ZDispMean_imag = np.mean(ZDispMeanAfstand_imag[frequentieIndex],axis=0);
                fase[octaafnr] = np.angle(ZDispMean_real + 1j*ZDispMean_imag);
        fase = np.round_(fase,decimals=2);
        
        
        # ============ en de boel bijeenbrengen in een dictionary ============
        Resultaten.append({'GevraagdeAfstand': GevraagdeAfstand,
                           'Lengte':           Lengte,
                           'c':                c[:].tolist(),
                           'c_ratio':          c_ratio[:].tolist(),
                           'Y':                Y[:].tolist(),
                           'Y_ratio':          Y_ratio[:].tolist(),
                           'fase':             fase[:].tolist()});
        if not listinput:
            Resultaten = Resultaten[0];
            
    return Resultaten
 
    
def read_json(file_name):
    import json
    try:
        with open(file_name, "r") as fid:
             data = json.load(fid);  
    except OSError:
        exit(101)
    return data

    
def write_json(file_name, result):
    try:
       with open(file_name, "w+") as fid:
           json.dump(result, fid, separators=(',', ':'), sort_keys=True, indent=4)
    except OSError:
       exit(102)
    return

    
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--json', help='input JSON file', required=True)
    parser.add_argument('-o', '--output', help='location of the output folder', required=True)
    args = parser.parse_args();
    # reads input json file
    Invoer  = read_json(args.json);
    # do the work
    Uitvoer = naverwerking(Invoer,Invoer["GevraagdeAfstand"],Invoer["Lengte"]);
    # write output to json file    
    # error -1 nog afvangen      
    uitfile = os.path.join(args.output,"FEMverwerkt.json");
    write_json(uitfile,Uitvoer);
        
     
     
     
