# -*- coding: utf-8 -*-
"""
Created on Sat Jan 15 16:50:53 2020

@author: bwakoop
"""

import argparse
import math
import json
import os
import numpy as np
from scipy import signal


octaafbanden = np.array([2,4,8,16,31.5,63]);
aantalbanden = len(octaafbanden);
bovengrenzen = octaafbanden*math.sqrt(2);
ondergrenzen = octaafbanden/math.sqrt(2);
omega        = 2*np.pi*octaafbanden;

ReferentieAfstand = 25;  # tbv van Barkan waarop variatie is gebaseerd


def bodemonzekerheid(CPTtoolOutput,NaverwerkingOutput):
    
#    if isinstance(Afstanden, list):
#        aantalAfstanden = len(Afstanden);
#        listinput      = True;
#    else:   # scalar opgeven, die ik in een triviale array stop
#        Afstanden       = [Afstanden];
#        aantalAfstanden = 1;
#        listinput      = False;
 
    if isinstance(NaverwerkingOutput, list):
        aantalAfstanden = len(NaverwerkingOutput);
        listinput       = True;
    else:
        NaverwerkingOutput = [NaverwerkingOutput];
        aantalAfstanden    = 1;
        listinput          = False;
        

    # let's start!    
    Resultaten = [];
    for afstandnr in range(aantalAfstanden):
         NavOutput = NaverwerkingOutput[afstandnr];
         #Y       = np.array(NaverwerkingOutput["Y"]);        # 1x6
         Yratio  = np.array(NavOutput["Y_ratio"]);  # 1x6
         c       = np.array(NavOutput["c"]);         # 1x6
         cratio  = np.array(NavOutput["c_ratio"]);  # 1x6
         fase    = np.array(NavOutput["fase"]);     # 1x6
         
         depth   = np.array(CPTtoolOutput["Depth"]);
         E       = np.array(CPTtoolOutput["E"]);
         rho     = np.array(CPTtoolOutput["rho"]);
         nu      = np.array(CPTtoolOutput["v"]);
         damping = np.array(CPTtoolOutput["damping"]);
         
         #var_depth   = np.array(CPTtoolOutput["var_depth"]);   #  variationcoefficient
         var_E       = np.array(CPTtoolOutput["var_E"]);       #  variationcoefficient
         var_rho     = np.array(CPTtoolOutput["var_rho"]);     #  variationcoefficient
         var_nu      = np.array(CPTtoolOutput["var_v"]);       #  variationcoefficient
         var_damping = np.array(CPTtoolOutput["var_damping"]); #  variationcoefficient              
        
         #GevraagdeAfstand = Afstanden[afstandnr];
         GevraagdeAfstand = NavOutput["GevraagdeAfstand"]; # np.array(NavOutput["GevraagdeAfstand"]);
         
         MaatgevendeDiepte = c/octaafbanden;   # 1x6   1 golflengte
         aantallagen = np.zeros(6);
         var_Y       = np.zeros(6);
         var_c       = np.zeros(6);
         for band in range(6):
              aantallagen    = range(len(np.where(depth<MaatgevendeDiepte[band])[0]));
              # working points for demping & Poissons
              DampingMu   = np.mean(damping[aantallagen]);  # 1x1
              nuMu        = np.mean(nu[aantallagen]);       # 1x1
              var2E       = np.mean(var_E[aantallagen])**2       + (np.std(E[aantallagen])       /np.mean(E[aantallagen]))**2;       
              var2rho     = np.mean(var_rho[aantallagen])**2     + (np.std(rho[aantallagen])     /np.mean(rho[aantallagen]))**2;
              var2nu      = np.mean(var_nu[aantallagen])**2      + (np.std(nu[aantallagen])      /np.mean(nu[aantallagen]))**2;
              var2damping = np.mean(var_damping[aantallagen])**2 + (np.std(damping[aantallagen]) /np.mean(damping[aantallagen]))**2;
              
              alfa2 = (omega[band]*DampingMu/c[band])**2;                # 1x6   
              var2c = var2E/4 + var2rho/4 + var2nu*(nuMu/(1+nuMu))**2;
              var2Y = var2E/4 + var2rho/4 + var2nu*(nuMu**2/(1-nuMu**2))**2 + \
                      var2c + alfa2*(GevraagdeAfstand-ReferentieAfstand)**2 * (var2damping+var2c);
              var_Y[band] = np.sqrt(var2Y)
              var_c[band] = np.sqrt(var2c);
              
         # dan een lelijke manier om iets te zeggen over de ratio's:
         # we postuleren dat Y, c en fase spectra een lineaire trend volgen
         # de afwijking van de trend is een maat voor de onderzekerheid
         # misshcien x2 ?
         var_Y_ratio = abs(signal.detrend(Yratio))/Yratio; # np.ones(6)*.1;
         var_c_ratio = abs(signal.detrend(cratio))/cratio; # np.ones(6)*.1; 
         # dan de fase, geen variatiecoeff maar een std!!!!  Want anders delen door 0
         var_fase    = abs(signal.detrend(fase)); # slaat alleen ergens op bij R=0, dus rond fase=0;
         # spectrum gladstrijken want afwijking per band is gebaseerd op hele spectrum
         var_Y_ratio = np.polyval(np.polyfit(range(6),var_Y_ratio,1),range(6));
         var_c_ratio = np.polyval(np.polyfit(range(6),var_c_ratio,1),range(6));
         var_fase    = np.polyval(np.polyfit(range(6),var_fase,1),range(6));
         # reparatie waar de var onder de 0 duikt
         var_Y_ratio[np.where(var_Y_ratio<=0.01)] = 0.01;
         var_c_ratio[np.where(var_c_ratio<=0.01)] = 0.01;
         var_fase[np.where(var_fase<=0.01)]       = 0.01;
         
         var_Y       = np.round(var_Y,       decimals=3);
         var_c       = np.round(var_c,       decimals=3);
         var_Y_ratio = np.round(var_Y_ratio, decimals=3);
         var_c_ratio = np.round(var_c_ratio, decimals=3);
         var_fase    = np.round(var_fase,    decimals=3);
        
         Resultaten.append({'GevraagdeAfstand': GevraagdeAfstand,
                            'var_Y':            var_Y[:].tolist(),
                            'var_c':            var_c[:].tolist(),
                            'var_Y_ratio':      var_Y_ratio[:].tolist(),
                            'var_c_ratio':      var_c_ratio[:].tolist(),
                            'var_fase':         var_fase[:].tolist()} );
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
    Uitvoer = bodemonzekerheid(Invoer["CPTtoolOutput"],Invoer["NaverwerkingOutput"]);   # do the work
    uitfile = os.path.join(args.output,"bodemonzekerheidUit.json");                    
    # NB: error -1 nog afvangen     
    write_json(uitfile,Uitvoer);                                           # write output to json file 
