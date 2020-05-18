{ @abstract(This unit contains most of the used strings in the application.)
  The resourcestrings enable translation of the software.
  }
unit OursStrings;

interface

const
  CRLF = #13#10;

resourcestring
  // General
  rsYes = 'Yes';
  rsNo = 'No';
  rsError = 'Error';
  rsWarning = 'Warning';
  rsInfo = 'Info';
  rsProgress = 'Progress';
  rsName = 'name';
  rsDescription = 'description';
  rsVd = 'Vd';
  rsReceptor = 'receptor';
  rsSource = 'source';
  rsDistance = 'distance';
  rsCalcDistance = 'calculation distance';
  rsCalcLength = 'calculation length';
  rsGroundType = 'ground type';

  // F_Main
  rsStarted = 'started';
  rsClosed = 'closed';
  rsCancel = 'Cancel';
  rsInputfileNotFound = 'Input file "%s" not found';
  rsOutputfileInvalid = 'Output file "%s" invalid';
  rsOutputfolderNotFound = 'Output folder "%s" not found';
  rsInputEqualsOutputfile = 'Output file "%s" is same as input file';

  // OursData
  rsBuilding = 'building';
  rsBagId = 'BAG-id';
  rsConstructionYear = 'year of construction';
  rsApartment = 'apartment';
  rsBuildingHeight = 'building height';
  rsNumberoffloors = 'number of floors';
  rsHeightOfFloor = 'height of floor [m]';
  rsFloorNumber = 'floor number';
  rsWallLength = 'wall length [m]';
  rsFacadelength = 'facade length [m]';
  rsVarConstructionYear = 'var year of construction';
  rsVarApartment = 'var apartment';
  rsVarBuildingHeight = 'var building height';
  rsVarNumberoffloors = 'var number of floors';
  rsVarHeightOfFloor = 'var height of floor [m]';
  rsVarFloorNumber = 'var floor number';
  rsVarWallLength = 'var wall length [m]';
  rsVarFacadelength = 'var facade length [m]';
  rsFloor = 'floor';
  rsFrequenciesQuarterSpan = 'quarter span [Hz]';
  rsFrequenciesMidSpan = 'mid span [Hz]';
  rsFloorSpan = 'floor span [m]';
  rsWoodenFloor = 'wooden floor';
  rsVarFrequenciesQuarterSpan = 'var quarter span [Hz]';
  rsVarFrequenciesMidSpan = 'var mid span [Hz]';
  rsVarFloorSpan = 'var floor span [m]';
  rsVarWoodenFloor = 'var wooden floor';

  rsInputfile = 'input file';
  rsOutputfile = 'output file';
  rsTestmode = 'test mode';
  rsSilentmode = 'silent mode';
  rsLocation = 'location';
  rsRailBranch = 'rail branch';
  rsKmStartMm = 'km start [mm]';
  rsKmEndMm = 'km end [mm]';
  rsCgeoX = 'CgeoX';
  rsCgeoZ = 'CgeoZ';
  rsSourcetype = 'source type';
  rsSwitch = 'switch';
  rsEsWeld = 'es-weld';
  rsCrossing = 'crossing';
  rsMaterial = 'rolling stock';
  rsQdayH = 'Qday [/h]';
  rsVdayKmh = 'Vday [km/h]';
  rsQeveningH = 'Qevening [/h]';
  rsVeveningKmh = 'Vevening [km/h]';
  rsQnightH = 'Qnight [/h]';
  rsVnightKmh = 'Vnight [km/h]';
  rsCategory = 'Category';
  rsKm = 'km';
  rsTrack = 'track';
  rsType = 'type';
  rsErrorBrackets = '<error>';
  rsMaxCalcDistanceM = 'max.calc.distance [m]';
  rsMaxCalcDepthM = 'max.calc.depth [m]';
  rsMinLayerThicknessM = 'min.layer thickness[m]';
  rsMinElementSizeM = 'min.element size[m]';
  rsSpectrumType = 'spectrum type';
  rsLowFrequencyHz = 'low frequency [Hz]';
  rsHighFrequenceHz = 'high frequency [Hz]';
  rsOctave = '1/1-octave';
  rsTerts = '1/3-octave';

  // F_Stamtabel
  rsTableNotFound = 'Table "%s" not found';
  rsTableIsEmpty = 'Table "%s" is empty';
  rsTableLoaded = 'Table "%s" loaded';

  // OursData_XML
  rsXmlCoordsReceptor = 'Loading XML: invalid co-ordinates for receptor point';
  rsXmlNoReceptors = 'Loading XML: file does not contain receptors';
  rsXmlFileNotFound = 'File "%s" not found';
  rsXmlMultipleProjectNodes = 'Loading XML: file contains multiple project-nodes';
  rsXmlNoProjectNodes = 'Loading XML: file does not contain any project-nodes';
  rsXmlTrackCoordsCount = 'Loading XML: file contains less than 2 nodes for a track';
  rsXmlTrackCoordsXY = 'Loading XML: file contains more x than y co-ordinates for a track';
  rsXmlTrackCoordsInvalid = 'Loading XML: file contains invalid co-ordinates for a track';
  rsXmlTrainNoTrainNode = 'Loading XML: at least 1 track does not contain train information';
  rsXmlTrackKmError = 'Loading XML: value for kmstart is smaller than or equal to value for kmend for at least 1 track';
  rsXmlTrackCount = 'Loading XML: invalid number of tracks';
  rsXmlTrackKmMatchError1 = 'Loading XML: Track %s: kilometre information does not match track. Parts start or end outside track km';
  rsXmlTrackKmMatchError2 = 'Loading XML: Track %s: kilometre information does not match track. Length track smaller than sum part lengths';
  rsXmlTrackKmMatchWarning1 = 'Loading XML: Track %s: kilometre information does not match track. Length track larger than sum part lengths';
  rsXmlTrackKmOverlapping = 'Loading XML: Track %s: invalid kilometre information for tracks, partly overlapping';
  rsXmlTracksMissing = 'Loading XML: file does not contain tracks';
  rsXmlMultipleTrackNodes = 'Loading XML: file contains multiple tracks-nodes';

  // OursGroundResult
  rsProbability = 'probability';
  rsCoordinates = 'coordinates';
  rsLithology = 'lithology';
  rsDepth = 'depth';
  rsE = 'E';
  rsV = 'v';
  rsRho = 'rho';
  rsDamping = 'damping';
  rsVarDepth = 'var_depth';
  rsVarE = 'var_E';
  rsVarV = 'var_v';
  rsVarRho = 'var_rho';
  rsVarDamping = 'var_damping';

  // OursCalcWrapper
  rsDocFolderNotFound = 'Folder for documents "%s" not found';
  rsDocFolderNotWritable = 'Folder for documents "%s" is readonly';
  rsDocFolderBroNotFound = 'File with BRO-data "%s" not found. Download from PDOK.nl/datasets';
  rsTempFolderNotFound = 'Folder for temporary files "%s" not found';
  rsTempFolderNotWritable = 'Folder for temporary files "%s" is readonly';
  rsOutFolderWriteError = 'Output folder "%s" not available';
  rsExternalModuleNotFound = 'Module "%s" not found';
  rsExternalModuleError = 'Error in module "%s". Exit code: %d';
  rsExternalModuleNoResult = 'Error in module "%s". Output file "%s" not found';
  rsExternalModuleNoGroundResults = 'No ground data found for receiver "%s" and source  "%s". Cannot calculate receiver';
  rsExternalModuleNoGround = 'No ground data available for source "%s". Cannot calculate';
  rsInFileWriteError = 'Could not write file "%s" for input external module';
  rsCalculationTerminated = 'Calculation terminated by user';
  rsSourceDistanceTooLarge = 'Distance receiver to source (%.2f) larger than maximum calculation distance (%.2f). Source is skipped.';
  rsModuleNameNotSupported = 'Error: module not supported. Class is just a wrapper';

  // OursMessage
  rsUsage = 'Error using OURS_UI.EXE' + #13 + #13 + 'Message:' + #13 + '%s' +
            #13 + #13 + 'Number of commandline parameters:' + #13 + #13 +
            '0: OURS_input.xml is used as inputfile.' + #13 + #13 +
            '1: <parameter1> is used as inputfile.' + #13 + #13 +
            '2: <parameter1> is used as inputfile, calculation is being executed and the results are written in file <parameter2>.'
            + #13 + 'Progress dialogue with messages will be visible. Software will close when calculation is completed..'
            + #13 + #13 +
            '3 or more: Same as 2 parameters, but with additional options: ' + #13 + #13
            + '/TEST' + #13 +
            'only first receptor will be calculated and all intermediate results will be written to a TXT-file.'
            + #13 + #13 + '/SILENT' + #13 +
            'silent execution. No user-inteface will be visible.';

const
  cYES_NO: array [False .. True] of string = (rsNo, rsYes);
  sSPEC_TYPE: array [1 .. 2] of string = (rsOctave, rsTerts);

implementation

end.
