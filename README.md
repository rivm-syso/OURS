# OURS

This is the repository containing the source code, release and documentation of the Single calculation method foor railway vibrations.

The project was carried out by the Dutch National Institute for Public Health and the Environment by order of the ministry of Infrastucture and Water management.

The code is published under the European Union Public Licence v 1.2.
Generic scripts and code may be published under their respective licences. The code of these scripts are not modified.

Modification to the OURS code is possible. However when using modified code results of calculations can not be presented as if it was performed with OURS. An exception is if the modified code produces the exact same results. 

## Installation
To perform a quick installation of OURS, follow the steps below:
1. Download the installer **`setupOURS.exe`** from the GitHub **Releases** page.
2. Place `setupOURS.exe` on the desired drive and run it. The installation will be extracted using the Inno Setup Wizard.
3. Download the BRO data from:  
   https://service.pdok.nl/tno/bro-geotechnischsondeeronderzoek/atom/index.xml
4. Place the downloaded BRO data in the `BRO_DATA` folder created during installation.
5. Edit the `OURS.cfg` file:
   - point to the `BRO_DATA` folder  
   - point to the relevant BRO data file  
   - specify a temporary folder (temp directory)
6. Start `OURS.exe` and click **Calculate** to verify that the installation works correctly.

## Tutorial
To get started a tutorial is available in the repository:
- [Tutorial: simple OURS calculation for a railway vibration case near Beilen](tutorial/tutorial_01.md)

## Python depencies
The python scripts have a number of dependencies:
cftime, dateutil, lxml, matplotlib, mkl, more_itertools, mpl_toolkits, netCFD4, numpy, pandas, pyparadiso, pyproj, pytz, rtree, scipy, shapely, tqdm