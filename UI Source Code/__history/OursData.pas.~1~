unit OursData;

interface

uses
  Generics.Collections,
  OursTypes,
  OursResultGround,
  OursResultBuilding,
  OursResultFem,
  OursResultMain;

// -------------------------------------------------------------------------------------------------

type
  TOursMeasurement = class(TObject)
  strict private
    _name: string;
    _description: string;
    _category: Integer;
    _sourcetype: Integer;
    _z0: TSpectrum;
    _d_z0: TSpectrum;
    _yratio: TSpectrum;
    _d_yratio: TSpectrum;
    _vref: Integer;
    _n0: Double;
    _d_n0: Double;
    _n1: Double;
    _d_n1: Double;
    _fz0: TSpectrum;
    _d_fz0: TSpectrum;
    _fz1: TSpectrum;
    _d_fz1: TSpectrum;
    _fx0: TSpectrum;
    _d_fx0: TSpectrum;
    _fx1: TSpectrum;
    _d_fx1: TSpectrum;

    _z0_id: Integer;
    _d_z0_id: Integer;
    _yratio_id: Integer;
    _d_yratio_id: Integer;
    _fz0_id: Integer;
    _d_fz0_id: Integer;
    _fz1_id: Integer;
    _d_fz1_id: Integer;
    _fx0_id: Integer;
    _d_fx0_id: Integer;
    _fx1_id: Integer;
    _d_fx1_id: Integer;

    procedure Setd_fx0_id(const Value: Integer);
    procedure Setd_fx1_id(const Value: Integer);
    procedure Setd_fz0_id(const Value: Integer);
    procedure Setd_fz1_id(const Value: Integer);
    procedure Setd_yratio_id(const Value: Integer);
    procedure Setd_z0_id(const Value: Integer);
    procedure Setfx0_id(const Value: Integer);
    procedure Setfx1_id(const Value: Integer);
    procedure Setfz0_id(const Value: Integer);
    procedure Setfz1_id(const Value: Integer);
    procedure Setyratio_id(const Value: Integer);
    procedure Setz0_id(const Value: Integer);

    procedure LoadSpectrum(aSpectrum: TSpectrum; aId: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function AsText: string;

    property name: string read _name write _name;
    property description: string read _description write _description;
    property category: Integer read _category write _category;
    property sourcetype: Integer read _sourcetype write _sourcetype;
    property z0: TSpectrum read _z0;
    property d_z0: TSpectrum read _d_z0;
    property yratio: TSpectrum read _yratio;
    property d_yratio: TSpectrum read _d_yratio;
    property vref: Integer read _vref write _vref;
    property n0: Double read _n0 write _n0;
    property d_n0: Double read _d_n0 write _d_n0;
    property n1: Double read _n1 write _n1;
    property d_n1: Double read _d_n1 write _d_n1;
    property fz0: TSpectrum read _fz0;
    property d_fz0: TSpectrum read _d_fz0;
    property fz1: TSpectrum read _fz1;
    property d_fz1: TSpectrum read _d_fz1;
    property fx0: TSpectrum read _fx0;
    property d_fx0: TSpectrum read _d_fx0;
    property fx1: TSpectrum read _fx1;
    property d_fx1: TSpectrum read _d_fx1;

    property z0_id: Integer read _z0_id write Setz0_id;
    property d_z0_id: Integer read _d_z0_id write Setd_z0_id;
    property yratio_id: Integer read _yratio_id write Setyratio_id;
    property d_yratio_id: Integer read _d_yratio_id write Setd_yratio_id;
    property fz0_id: Integer read _fz0_id write Setfz0_id;
    property d_fz0_id: Integer read _d_fz0_id write Setd_fz0_id;
    property fz1_id: Integer read _fz1_id write Setfz1_id;
    property d_fz1_id: Integer read _d_fz1_id write Setd_fz1_id;
    property fx0_id: Integer read _fx0_id write Setfx0_id;
    property d_fx0_id: Integer read _d_fx0_id write Setd_fx0_id;
    property fx1_id: Integer read _fx1_id write Setfx1_id;
    property d_fx1_id: Integer read _d_fx1_id write Setd_fx1_id;
  end;

  TOursMeasurements = class(TList<TOursMeasurement>)
  public
    function AsText: string;
    function AsJSON: string;
  end;

// -------------------------------------------------------------------------------------------------

type
  TOursTrain = class(TObject)
  strict private
    _material_id: Integer;
    _qd: Double;
    _vd: Double;
    _qe: Double;
    _ve: Double;
    _qn: Double;
    _vn: Double;

    function GetCat: Integer;
  public
    function AsText: string;
    function getQ(per: Integer): Double;
    function getV(per: Integer): Double;
    function getQweek(per: Integer): Double;
    function getAverageV: Double;
    property material_id: Integer read _material_id write _material_id;
    property qd: Double read _qd write _qd;
    property vd: Double read _vd write _vd;
    property qe: Double read _qe write _qe;
    property ve: Double read _ve write _ve;
    property qn: Double read _qn write _qn;
    property vn: Double read _vn write _vn;
    property cat: Integer read GetCat;
  end;

  TOursTrains = class(TList<TOursTrain>)
  public
    function AsText: string;
  end;

  TOursTrainMeasurements = class(TDictionary<TOursTrain, TOursMeasurements>)
  public
    procedure Clear;
    function AsText: string;
  end;

// -------------------------------------------------------------------------------------------------

type
  TOursTrackPart = class(TObject)
  strict private
    _name: string;
    _description: string;
    _kmstart: Integer;
    _kmend: Integer;
    _CgeoX: TSpectrum;
    _CgeoZ: TSpectrum;
    _trains: TOursTrains;
  public
    constructor Create;
    destructor Destroy; override;
    function AsText: string;
    property name: string read _name write _name;
    property description: string read _description write _description;
    property kmstart: Integer read _kmstart write _kmstart;
    property kmend: Integer read _kmend write _kmend;
    property CgeoX: TSpectrum read _CgeoX;
    property CgeoZ: TSpectrum read _CgeoZ;
    property Trains: TOursTrains read _trains;
  end;

  TOursTrackParts = class(TList<TOursTrackPart>)
  public
    function AsText: string;
  end;

// -------------------------------------------------------------------------------------------------

type
  TOursTrack = class(TObject)
  strict private
    _name: string;
    _description: string;
    _branch: string;
    _kmstart: Integer;
    _kmend: Integer;
    _sourcetype_id: Integer;
    _location: TRPoints;
    _trackparts: TOursTrackParts;
  public
    constructor Create;
    destructor Destroy; override;
    function AsText: string;

    property name: string read _name write _name;
    property description: string read _description write _description;
    property branch: string read _branch write _branch;
    property kmstart: Integer read _kmstart write _kmstart;
    property kmend: Integer read _kmend write _kmend;
    property sourcetype_id: Integer read _sourcetype_id write _sourcetype_id;

    property Location: TRPoints read _location;
    property TrackParts: TOursTrackParts read _trackparts;
  end;

  TOursTracks = class(TList<TOursTrack>)
  public
    function AsText: string;
  end;

// -------------------------------------------------------------------------------------------------

type
  TOursGroundScenario = class(TObject)
  strict private
    _name: string;
    _distance: Double;
    _Lithology: TStringsList;

    _Depth: TDoubleList;
    _E: TDoubleList;
    _V: TDoubleList;
    _Rho: TDoubleList;
    _Damping: TDoubleList;

    _Var_depth: TDoubleList;
    _Var_E: TDoubleList;
    _Var_v: TDoubleList;
    _Var_rho: TDoubleList;
    _Var_damping: TDoubleList;

    _FemResults: TOursFemOutput;

    procedure SetDistance(value: Double);
    procedure SetFemResults(value: TOursFemOutput);
  public
    constructor Create;
    destructor Destroy; override;

    function AsText: string;
    function GroundAsText: string;
    function FemAsText: string;
    function GroundAsJsonForFem: string;
    function GroundAsJsonForUncertainty: string;
    function IsEqual(AScenario: TOursGroundScenario): Boolean;

    property name: string               read _name        write _name;
    property distance: Double           read _distance    write SetDistance;
    property lithology: TStringsList    read _Lithology   write _Lithology;

    property depth: TDoubleList         read _Depth       write _Depth;
    property E: TDoubleList             read _E           write _E;
    property v: TDoubleList             read _V           write _V;
    property rho: TDoubleList           read _Rho         write _Rho;
    property damping: TDoubleList       read _Damping     write _Damping;

    property var_depth: TDoubleList     read _Var_depth   write _Var_depth;
    property var_E: TDoubleList         read _Var_E       write _Var_E;
    property var_v: TDoubleList         read _Var_v       write _Var_v;
    property var_rho: TDoubleList       read _Var_rho     write _Var_rho;
    property var_damping: TDoubleList   read _Var_damping write _Var_damping;

    property FemResults: TOursFemOutput read _FemResults  write SetFemResults;
  end;

  TOursGroundScenarios = class(TList<TOursGroundScenario>)
  public
    function IndexOf(AScenario: TOursGroundScenario): Integer;

    function GroundAsText: string;
    function FemAsText: string;
    function AsText: string;
    function AsJSON: string;
  end;

// -------------------------------------------------------------------------------------------------

type
  TOursFemDerived = class (TObject)
  strict private
    _Y_0: TSpectrum;        // value Y for 0m
    _fase_0: TSpectrum;     // value fase for 0m
    _Y_25: TSpectrum;       // value Y for 25m
    _Y_ratio_25: TSpectrum; // value Y_ratio for 25m
    _c_X: TSpectrum;        // value c for distance source-receptor
    _c_ratio_X: TSpectrum;  // value c_ratio for distance source-receptor
    _Y_X: TSpectrum;        // value Y for distance source-receptor
    _Y_ratio_X: TSpectrum;  // value Y_ratio for distance source-receptor
    _JSON_0: string;        // JSON output string from "naverwerking.py" for 0m
    _JSON_25: string;       // JSON output string from "naverwerking.py" for 25m
    _JSON_X: string;        // JSON output string from "naverwerking.py" for distance source-receptor
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    function AsText: string;

    property Y_0: TSpectrum        read _Y_0;
    property fase_0: TSpectrum     read _fase_0;
    property Y_25: TSpectrum       read _Y_25;
    property Y_ratio_25: TSpectrum read _Y_ratio_25;
    property c_X: TSpectrum        read _c_X;
    property c_ratio_X: TSpectrum  read _c_ratio_X;
    property Y_X: TSpectrum        read _Y_X;
    property Y_ratio_X: TSpectrum  read _Y_ratio_X;

    property JSON_0: string        read _JSON_0  write _JSON_0;
    property JSON_25: string       read _JSON_25 write _JSON_25;
    property JSON_X: string        read _JSON_X  write _JSON_X;
  end;

type
  TOursFemUncertainty = class (TObject)
  strict private
    _var_Y_0: TSpectrum;         // value var_Y for 0m
    _var_fase_0: TSpectrum;      // value var_fase for 0m
    _var_Y_25: TSpectrum;        // value var_Y for 25m
    _var_Y_ratio_25: TSpectrum;  // value var_Y_ratio for 25m
    _var_c_X: TSpectrum;         // value var_c for distance source-receptor
    _var_c_ratio_X: TSpectrum;   // value var_c_ratio for distance source-receptor
    _var_Y_X: TSpectrum;         // value var_Y for distance source-receptor
    _var_Y_ratio_X: TSpectrum;   // value var_Y_ratio for distance source-receptor
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    function AsText: string;

    property var_Y_0: TSpectrum        read _var_Y_0;
    property var_fase_0: TSpectrum     read _var_fase_0;
    property var_Y_25: TSpectrum       read _var_Y_25;
    property var_Y_ratio_25: TSpectrum read _var_Y_ratio_25;
    property var_c_X: TSpectrum        read _var_c_X;
    property var_c_ratio_X: TSpectrum  read _var_c_ratio_X;
    property var_Y_X: TSpectrum        read _var_Y_X;
    property var_Y_ratio_X: TSpectrum  read _var_Y_ratio_X;
  end;

type
  TOursHBuilding = class (TOursBuildingResult)
    // implementation in unit OursResultBuilding
  end;

type
  TOursSourceResults = class(TOursMainOutput)
    // implementation in unit OursResultMain
  end;

// -------------------------------------------------------------------------------------------------
// forwards...
type
  TOursReceptor = class;
  TOursSource = class;
// -------------------------------------------------------------------------------------------------

  TOursResultScenario = class(TObject)
  strict private
    _receptor: TOursReceptor;     // reference to receptor
    _source: TOursSource;         // reference to source
    _ground: TOursGroundScenario; // reference to ground scenario

    _probability: Double;         // probability of this scenario: fraction (0.00 .. 1.00)
    _distance: Double;            // distance between source and receptor

    _FemDerived: TOursFemDerived;
    _FemUncertainty: TOursFemUncertainty;
    _HBuilding: TOursHBuilding;
  public
    constructor Create(const rec: TOursReceptor; const src: TOursSource; const grnd: TOursGroundScenario); virtual;
    destructor Destroy; override;

    function GroundAsText: string;
    function FemForMainFormulaAsJSON: string;

    property receptor: TOursReceptor     read _receptor;
    property source: TOursSource         read _source;
    property ground: TOursGroundScenario read _ground;

    property probability: Double read _probability write _probability;
    property distance: Double    read _distance    write _distance;

    property FemDerived: TOursFemDerived           read _FemDerived;
    property FemUncertainty: TOursFemUncertainty   read _FemUncertainty;
    property HBuilding: TOursHBuilding             read _HBuilding;
  end;

  TOursResultScenarios = class(TList<TOursResultScenario>)
  public
    function GroundAsText: string;
    function FemDerivedAsText: string;
    function FemUncertaintyAsText: string;
    function HBuildingAsText: string;
  end;

// -------------------------------------------------------------------------------------------------

  TOursResults = class(TObject)
  strict private
    _receptor: TOursReceptor;     // reference to receptor
    _source: TOursSource;         // reference to source
    _scenarios: TOursResultScenarios;

    _MainResults: TOursSourceResults;
  public
    constructor Create(const rec: TOursReceptor; const src: TOursSource); virtual;
    destructor Destroy; override;

    function AddScenario(const grnd: TOursGroundScenario): TOursResultScenario;
    function MainResultsAsText: string;

    property Receptor: TOursReceptor         read _receptor;
    property Source: TOursSource             read _source;
    property Scenarios: TOursResultScenarios read _scenarios;
    property MainResults: TOursSourceResults read _MainResults;
  end;

// -------------------------------------------------------------------------------------------------

  TOursSource = class(TObject)
  strict private
    _track: TOursTrack;
    _receptor: TOursReceptor;
    _measurements: TOursTrainMeasurements;
    _results: TOursResults;

    _x: Double;
    _y: Double;
    _km: Integer;

    function sourcetype: string;
    function GetPos: TRpoint;
    procedure SetPos(const Value: TRpoint);
    function GetTrackPart: TOursTrackPart;
    procedure FillMeasurements;
  public
    constructor Create(aReceptor: TOursReceptor; aTrack: TOursTrack);
    destructor Destroy; override;
    function AsText: string;
    function GroundAsText: string;
    function FemDerivedAsText: string;
    function FemUncertaintyAsText: string;
    function HBuildingAsText: string;
    function MainResultsAsText: string;

    property km: Integer read _km write _km;
    property x: Double read _x write _x;
    property y: Double read _y write _y;
    property Pos: TRpoint read GetPos write SetPos;

    property Track: TOursTrack read _track;
    property TrackPart: TOursTrackPart read GetTrackPart;
    property TrainMeasurements: TOursTrainMeasurements read _measurements;
    property Results: TOursResults read _results;
  end;

  TOursSources = class(TList<TOursSource>)
  public
    function AsText: string;
    function GroundAsText: string;
    function FemDerivedAsText: string;
    function FemUncertaintyAsText: string;
    function HBuildingAsText: string;
    function MainResultsAsText: string;
  end;

// -------------------------------------------------------------------------------------------------

  TOursReceptorBuilding = class(TObject)
  strict private
    _bagId: string;                      // building id or empty                                         --> --
    _yearOfConstruction: TIntegerList;   // integer list or empty                                        --> bouwjaar
    _apartment: TIntegerList;            // integer list or empty, valid values: 0=false, 1=true         --> appartement
    _buildingHeight: TDoubleList;        // float list or empty                                          --> gebouwHoogte
    _numberOfFloors: TIntegerList;       // integer list or empty                                        --> aantalBouwlagen
    _heightOfFloor: TDoubleList;         // float list or empty                                          --> vloerHoogte
    _floorNumber: TIntegerList;          // integer list or empty                                        --> verdiepingNr
    _wallLength: TDoubleList;            // float list or empty                                          --> wandlengte
    _facadeLength: TDoubleList;          // float list or empty                                          --> gevellengte
    _varYearOfConstruction: TDoubleList; // empty or same number of float values as "yearOfConstruction" --> var_bouwjaar
    _varApartment: TDoubleList;          // empty or same number of float values as "apartment"          --> var_appartement
    _varBuildingHeight: TDoubleList;     // empty or same number of float values as "buildingHeight"     --> var_gebouwHoogte
    _varNumberOfFloors: TDoubleList;     // empty or same number of float values as "numberOfFloors"     --> var_aantalBouwlagen
    _varHeightOfFloor: TDoubleList;      // empty or same number of float values as "heightOfFloor"      --> var_vloerHoogte
    _varFloorNumber: TDoubleList;        // empty or same number of float values as "floorNumber"        --> var_verdiepingNr
    _varWallLength: TDoubleList;         // empty or same number of float values as "wallLength"         --> var_wandlengte
    _varFacadeLength: TDoubleList;       // empty or same number of float values as "facadeLength"       --> var_gevellengte
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AsText: string;

    property bagId: string                      read _bagId write _bagId;
    property yearOfConstruction: TIntegerList   read _yearOfConstruction;
    property apartment: TIntegerList            read _apartment;
    property buildingHeight: TDoubleList        read _buildingHeight;
    property numberOfFloors: TIntegerList       read _numberOfFloors;
    property heightOfFloor: TDoubleList         read _heightOfFloor;
    property floorNumber: TIntegerList          read _floorNumber;
    property wallLength: TDoubleList            read _wallLength;
    property facadeLength: TDoubleList          read _facadeLength;
    property varYearOfConstruction: TDoubleList read _varYearOfConstruction;
    property varApartment: TDoubleList          read _varApartment;
    property varBuildingHeight: TDoubleList     read _varBuildingHeight;
    property varNumberOfFloors: TDoubleList     read _varNumberOfFloors;
    property varHeightOfFloor: TDoubleList      read _varHeightOfFloor;
    property varFloorNumber: TDoubleList        read _varFloorNumber;
    property varWallLength: TDoubleList         read _varWallLength;
    property varFacadeLength: TDoubleList       read _varFacadeLength;

  end;
  TOursReceptorFloor = class(TObject)
  strict private
    _frequenciesQuarterSpan: TDoubleList;    // float list or empty                                              --> frequentiesQuarterspan
    _frequenciesMidSpan: TDoubleList;        // float list or empty                                              --> frequentiesMidspan
    _floorSpan: TDoubleList;                 // float list or empty                                              --> vloerOverspanning
    _woodenFloor: TIntegerList;              // integer list or empty, valid values: 0=false, 1=true             --> hout
    _varFrequenciesQuarterSpan: TDoubleList; // empty or same number of float values as "frequenciesQuarterSpan" --> var_frequentiesQuarterspan
    _varFrequenciesMidSpan: TDoubleList;     // empty or same number of float values as "frequenciesMidSpan"     --> var_frequentiesMidspan
    _varFloorSpan: TDoubleList;              // empty or same number of float values as "floorSpan"              --> vloerOverspanning
    _varWoodenFloor: TDoubleList;            // empty or same number of float values as "woodenFloor"            --> var_hout
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AsText: string;

    property frequenciesQuarterSpan: TDoubleList    read _frequenciesQuarterSpan;
    property frequenciesMidSpan: TDoubleList        read _frequenciesMidSpan;
    property floorSpan: TDoubleList                 read _floorSpan;
    property woodenFloor: TIntegerList              read _woodenFloor;
    property varFrequenciesQuarterSpan: TDoubleList read _varFrequenciesQuarterSpan;
    property varFrequenciesMidSpan: TDoubleList     read _varFrequenciesMidSpan;
    property varFloorSpan: TDoubleList              read _varFloorSpan;
    property varWoodenFloor: TDoubleList            read _varWoodenFloor;
  end;

  TOursReceptor = class(TObject)
  strict private
    _name: string;
    _description: string;
    _x: Double;
    _y: Double;
    _building: TOursReceptorBuilding;
    _floor: TOursReceptorFloor;
    _sources: TOursSources;

    function GetPos: TRpoint;
    procedure SetPos(const Value: TRpoint);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AsText: string;
    function SourcesAsText: string;
    function GroundAsText: string;
    function FemDerivedAsText: string;
    function FemUncertaintyAsText: string;
    function HBuildingAsText: string;
    function MainResultsAsText: string;

    function CalcLength: Double;

    property name: string read _name write _name;
    property description: string read _description write _description;
    property x: Double read _x write _x;
    property y: Double read _y write _y;
    property Building: TOursReceptorBuilding read _building;
    property Floor: TOursReceptorFloor read _floor;
    property Pos: TRpoint read GetPos write SetPos;
    property Sources: TOursSources read _sources;
  end;

  TOursReceptors = class(TList<TOursReceptor>)
    function AsText: string;
    function SourcesAsText: string;
    function GroundAsText: string;
    function FemDerivedAsText: string;
    function FemUncertaintyAsText: string;
    function HBuildingAsText: string;
    function MainResultsAsText: string;
  end;

// -------------------------------------------------------------------------------------------------

type
  TOursSettings = class(TObject)
  strict private
    function GetMaxCalcDepth: Double;
    function GetMaxCalcDistance: Double;
    function GetMinLayerThickness: Double;
    function GetMinElementSize: Double;
    function GetSpectrumType: Integer;
    function GetLowFreq: Double;
    function GetHighFreq: Double;
    function GetCalcType: Integer;
  public
    function AsText: string;
    property maxCalcDepth: Double read GetMaxCalcDepth;
    property minLayerThickness: Double read GetMinLayerThickness;
    property minElementSize: Double read GetMinElementSize;
    property maxCalcDistance: Double read GetMaxCalcDistance;
    property spectrumType: Integer read GetSpectrumType;
    property lowFreq: Double read GetLowFreq;
    property highFreq: Double read GetHighFreq;
    property calcType: Integer read GetCalcType;
  end;

// -------------------------------------------------------------------------------------------------

type
  TOursProject = class(TObject)
  strict private
    _infile: string;
    _outfile: string;
    _testmode: Boolean;
    _silentmode: Boolean;

    _name: string;
    _description: string;
    _vd: Integer; // 0=false, 1=true, -1=use default (=false) and don't display.

    _settings: TOursSettings;
    _receptors: TOursReceptors;
    _tracks: TOursTracks;
    _groundList: TOursGroundScenarios;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    function AsText: string;
    function GroundAsText: string;
    function FemAsText: string;
    function FemDerivedAsText: string;
    function FemUncertaintyAsText: string;
    function HBuildingAsText: string;
    function MainResultsAsText: string;
    procedure CreateSources;

    property inFile: string read _infile write _infile;
    property outFile: string read _outfile write _outfile;
    property testMode: Boolean read _testmode write _testmode;
    property silentMode: Boolean read _silentmode write _silentmode;
    property name: string read _name write _name;
    property description: string read _description write _description;
    property vd: Integer read _vd write _vd;

    property Settings: TOursSettings read _settings;
    property Receptors: TOursReceptors read _receptors;
    property Tracks: TOursTracks read _tracks;
    property GroundList: TOursGroundScenarios read _groundList;
 end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  SysUtils,
  Math,
  SQLiteTable3,
  OursStrings,
  OursUtils,
  OursDatabase;

// =================================================================================================
// TOursProject
// =================================================================================================

function TOursProject.AsText: string;
begin
  var vdStr := '';
  case _vd of
    0: vdStr := Format('%-22s = false', [rsVd]) + CRLF + CRLF;
    1: vdStr := Format('%-22s = true', [rsVd]) + CRLF + CRLF;
  else vdStr := CRLF;
  end;

  Result := Format('%-22s = ', [rsName]) + name + CRLF +
            Format('%-22s = ', [rsDescription]) + description + CRLF +
            vdStr +
            Format('%-22s = ', [rsInputfile]) + _infile + CRLF +
            Format('%-22s = ', [rsOutputfile]) + _outfile + CRLF +
            Format('%-22s = ', [rsTestmode]) + cYES_NO[_testmode] + CRLF +
            Format('%-22s = ', [rsSilentmode]) + cYES_NO[_silentmode] + CRLF + CRLF +
            _settings.AsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursProject.GroundAsText: string;
begin
  Result := _receptors.GroundAsText + _groundList.GroundAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursProject.FemAsText: string;
begin
  Result := _groundList.FemAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursProject.FemDerivedAsText: string;
begin
  Result := _receptors.FemDerivedAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursProject.FemUncertaintyAsText: string;
begin
  Result := _receptors.FemUncertaintyAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursProject.HBuildingAsText: string;
begin
  Result := _receptors.HBuildingAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursProject.MainResultsAsText: string;
begin
  Result := _receptors.MainResultsAsText;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursProject.Clear;
begin
  _name := '';
  _description := '';
  _receptors.Clear;
  _tracks.Clear;
  _groundList.Clear;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursProject.Create;
begin
  _settings := TOursSettings.Create;

  _receptors := TOursReceptors.Create;
  _tracks := TOursTracks.Create;
  _groundList := TOursGroundScenarios.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursProject.Destroy;
begin
  _settings.Free;

  _receptors.Free;
  _tracks.Free;
  _groundList.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursProject.CreateSources;
begin
  for var rec in Receptors do begin
    for var src in Tracks do begin
      var newSrc := TOursSource.Create(rec, src);

      var dist := TOursMath.dist(rec.Pos, newSrc.Pos);
      if dist <= TOursDatabase.GetMaxCalcDistance then begin
        rec.Sources.Add(newSrc);
      end else begin
        newSrc.Free;
      end;
    end;
  end;
end;

// =================================================================================================
// TOursReceptor(s)
// =================================================================================================

function TOursReceptor.CalcLength: Double;
begin
  Result := 10.0;

  if Assigned(_building.wallLength) and (_building.wallLength.Count > 0) and (_building.wallLength[0] > 10.0) then
    Result := _building.wallLength[0];
end;

// -------------------------------------------------------------------------------------------------

procedure TOursReceptor.Clear;
begin
  _name := '';
  _description := '';
  _x := 0.0;
  _y := 0.0;
  _building.Clear;
  _floor.Clear;
  _sources.Clear;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursReceptor.Create;
begin
  _building := TOursReceptorBuilding.Create;
  _floor := TOursReceptorFloor.Create;
  _sources := TOursSources.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursReceptor.Destroy;
begin
  _building.Free;
  _floor.Free;
  _sources.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.GetPos: TRpoint;
begin
  Result.x := x;
  Result.y := y;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursReceptor.SetPos(const Value: TRpoint);
begin
  x := Value.x;
  y := Value.y;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.AsText: string;
begin
  Result := Format('%-19s = ', [rsName]) + name + CRLF +
            Format('%-19s = ', [rsDescription]) + description + CRLF +
            Format('%-19s = ', [rsLocation]) + Pos.AsText + CRLF +
            _building.AsText + _floor.AsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.GroundAsText: string;
begin
  Result := Format('%s: %s - %s %s', [rsReceptor, name, description, Pos.AsText]) + CRLF;
  Result := Result + Sources.GroundAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.FemDerivedAsText: string;
begin
  Result := Format('%s: %s - %s %s', [rsReceptor, name, description, Pos.AsText]) + CRLF;
  Result := Result + Sources.FemDerivedAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.FemUncertaintyAsText: string;
begin
  Result := Format('%s: %s - %s %s', [rsReceptor, name, description, Pos.AsText]) + CRLF;
  Result := Result + Sources.FemUncertaintyAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.HBuildingAsText: string;
begin
  Result := Format('%s: %s - %s %s', [rsReceptor, name, description, Pos.AsText]) + CRLF;
  Result := Result + Sources.HBuildingAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.MainResultsAsText: string;
begin
  Result := Format('%s: %s - %s %s', [rsReceptor, name, description, Pos.AsText]) + CRLF;
  Result := Result + Sources.MainResultsAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptor.SourcesAsText: string;
begin
  Result := Format('%s: %s - %s %s', [rsReceptor, name, description, Pos.AsText]) + CRLF;
  Result := Result + Sources.AsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptors.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.AsText;
    Result := Result + '--------------------------------------------------------------------------------' + CRLF;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptors.GroundAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.GroundAsText;
  end;
  Result := Result + '--------------------------------------------------------------------------------' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptors.FemDerivedAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.FemDerivedAsText;
    Result := Result + '--------------------------------------------------------------------------------' + CRLF;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptors.FemUncertaintyAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.FemUncertaintyAsText;
    Result := Result + '--------------------------------------------------------------------------------' + CRLF;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptors.HBuildingAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.HBuildingAsText;
    Result := Result + '--------------------------------------------------------------------------------' + CRLF;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptors.MainResultsAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.MainResultsAsText;
    Result := Result + '--------------------------------------------------------------------------------' + CRLF;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursReceptors.SourcesAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.SourcesAsText;
    Result := Result + '--------------------------------------------------------------------------------' + CRLF;
  end;
end;

// =================================================================================================
// TOursTrack/TOursTracks
// =================================================================================================

constructor TOursTrack.Create;
begin
  _location := TRPoints.Create;
  _trackparts := TOursTrackParts.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursTrack.Destroy;
begin
  _location.Free;
  _trackparts.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrack.AsText: string;
var
  s: string;
begin
  s := ' [' + TOursDatabase.GetDescriptionFromId('sourcetype', sourcetype_id) + ']';

  Result := Format('%-19s = ', [rsName]) + name + CRLF +
            Format('%-19s = ', [rsDescription]) + description + CRLF +
            Format('%-19s = ', [rsRailBranch]) + Format('%s', [branch]) + CRLF +
            Format('%-19s = ', [rsKmStartMm]) + Format('%d', [kmstart]) + CRLF +
            Format('%-19s = ', [rsKmEndMm]) + Format('%d', [kmend]) + CRLF +
            Format('%-19s = ', [rsSourcetype]) + Format('%d', [sourcetype_id]) + s + CRLF;

  Result := Result + _location.AsText;
  Result := Result + _trackparts.AsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursTracks.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.AsText;
    Result := Result + '--------------------------------------------------------------------------------' + CRLF;
  end;
end;

// =================================================================================================
// TOursTrain(s)
// =================================================================================================

function TOursTrain.AsText: string;
var
  s1, s2: string;
begin
  s1 := ' [' + TOursDatabase.GetDescriptionFromId('traintype', material_id) + ']';
  s2 := ' [' + TOursDatabase.GetDescriptionFromId('category', cat) + ']';

  Result := Format('  %-17s = ', [rsMaterial]) + Format('%d', [material_id]) + s1 + CRLF +
            Format('    %-15s = ', [rsQdayH]) + Format('%.3f', [qd]) + CRLF +
            Format('    %-15s = ', [rsVdayKmh]) + Format('%.0f', [vd]) + CRLF +
            Format('    %-15s = ', [rsQeveningH]) + Format('%.3f', [qe]) + CRLF +
            Format('    %-15s = ', [rsVeveningKmh]) + Format('%.0f', [ve]) + CRLF +
            Format('    %-15s = ', [rsQnightH]) + Format('%.3f', [qn]) + CRLF +
            Format('    %-15s = ', [rsVnightKmh]) + Format('%.0f', [vn]) + CRLF +
            Format('    %-15s = ', [rsCategory]) + Format('%d', [cat]) + s2 + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrain.getQweek(per: Integer): Double;
begin
  case per of
    1: Result := qd * 12 * 7;
    2: Result := qe *  4 * 7;
    3: Result := qn *  8 * 7;
  else raise Exception.Create('TOursTrain.getQ called with invalid period (1..3)');
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrain.getQ(per: Integer): Double;
begin
  case per of
    1: Result := qd;
    2: Result := qe;
    3: Result := qn;
  else raise Exception.Create('TOursTrain.getQ called with invalid period (1..3)');
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrain.getAverageV: Double;
begin
  Result := Round((vd + ve + vn)/3);
end;

// -------------------------------------------------------------------------------------------------
function TOursTrain.getV(per: Integer): Double;
begin
  case per of
    1: Result := vd;
    2: Result := ve;
    3: Result := vn;
  else raise Exception.Create('TOursTrain.getV called with invalid period (1..3)');
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrain.GetCat: Integer;
begin
  Result := TOursDatabase.GetValueAsInteger('traintype', 'category_id', material_id);
end;

// -------------------------------------------------------------------------------------------------

function TOursTrains.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.AsText;
  end;
end;

// =================================================================================================
// TOursTrackPart(ken)
// =================================================================================================

constructor TOursTrackPart.Create;
begin
  _trains := TOursTrains.Create;
  _CgeoX := TSpectrum.Create;
  _CgeoZ := TSpectrum.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursTrackPart.Destroy;
begin
  _trains.Free;
  _CgeoX.Free;
  _CgeoZ.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrackPart.AsText: string;
begin
  Result := Format('%-19s = ', [rsName]) + name + CRLF +
            Format('  %-17s = ', [rsDescription]) + description + CRLF +
            Format('  %-17s = ', [rsKmStartMm]) + Format('%d', [kmstart]) + CRLF +
            Format('  %-17s = ', [rsKmEndMm]) + Format('%d', [kmend]) + CRLF +
            Format('  %-17s = ', [rsCgeoX]) + Format('%s', [CgeoX.AsText]) + CRLF +
            Format('  %-17s = ', [rsCgeoZ]) + Format('%s', [CgeoZ.AsText]) + CRLF +
            _trains.AsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrackParts.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.AsText;
  end;
end;

// =================================================================================================
// TOursSources
// =================================================================================================

function TOursSource.GroundAsText: string;
begin
  Result := '  ' + rsSource + ' = ' + Track.name + ' - ' + Track.description + ' ' + Pos.AsText + CRLF;
  Result := Result + _results.scenarios.GroundAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.FemDerivedAsText: string;
begin
  Result := '  ' + rsSource + ' = ' + Track.name + ' - ' + Track.description + ' ' + Pos.AsText + CRLF;
  Result := Result + _results.scenarios.FemDerivedAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.FemUncertaintyAsText: string;
begin
  Result := '  ' + rsSource + ' = ' + Track.name + ' - ' + Track.description + ' ' + Pos.AsText + CRLF;
  Result := Result + _results.scenarios.FemUncertaintyAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.HBuildingAsText: string;
begin
  Result := '  ' + rsSource + ' = ' + Track.name + ' - ' + Track.description + ' ' + Pos.AsText + CRLF;
  Result := Result + _results.scenarios.HBuildingAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.MainResultsAsText: string;
begin
  Result := '  ' + rsSource + ' = ' + Track.name + ' - ' + Track.description + ' ' + Pos.AsText + CRLF;
  Result := Result + _results.MainResultsAsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.AsText: string;
begin
  Result := rsSource                                                                  + CRLF +
            Format('- %-8s = ', [rsTrack]) + _track.name + ' - ' + _track.description + CRLF +
            Format('- %-8s = ', [rsType]) + sourcetype                                + CRLF +
            Format('- %-8s = ', [rsKm]) + Format('%8d', [km])                         + CRLF +
            Format('- %-8s = ', [rsLocation]) + Pos.AsText                            + CRLF +
            _measurements.AsText                                                      + CRLF;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursSource.Create(aReceptor: TOursReceptor; aTrack: TOursTrack);
var
  dist, len: Double;
begin
  _measurements := TOursTrainMeasurements.Create;
  _results := TOursResults.Create(aReceptor, Self);

  _receptor := aReceptor;
  _track := aTrack;

  // dist is de afstand over de track van het begin van de Track tot de bronpunt (_x, _y)
  TOursMath.DistanceToLine(_receptor.Pos, _track.Location, _x, _y, dist);

  // len is de totale lengte van het Track
  len := TOursMath.LengthLine(aTrack.Location);

  if len <= 0 then begin
    km := _track.kmstart;
  end else if dist >= len then begin
    km := _track.kmend;
  end else begin
    km := Round(_track.kmstart + (dist / len) * (_track.kmend - _track.kmstart));
  end;

  FillMeasurements;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursSource.Destroy;
begin
  if Assigned(_measurements) then begin
    _measurements.Clear;
    _measurements.Free;
  end;

  if Assigned(_results) then begin
    // _results.Clear;
    _results.Free;
  end;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursSource.FillMeasurements;
var
  part: TOursTrackPart;
  srctype_id, cat_id: Integer;
  measurementTable: TSQLiteTable;
begin
  part := TrackPart;
  if part = nil then
    Exit;

  // delete old measurements
  _measurements.Clear;

  if _track = nil then
    Exit;

  srctype_id := _track.sourcetype_id;
  for var train in part.Trains do begin
    cat_id := train.cat;

    // Retrieve all measurements from database based on cat_id and srctype_id.
    var sql := Format('SELECT * FROM measurement WHERE category_id=%d AND sourcetype_id=%d', [cat_id, srctype_id]);
    measurementTable := TOursDatabase.GetTableFromSQL(sql);
    try
      while not measurementTable.EOF do begin
        var item := TOursMeasurement.Create;

        item.name := measurementTable.FieldByName['name'];
        item.description := measurementTable.FieldByName['description'];
        item.category := TOursConv.AsInteger(measurementTable.FieldByName['category_id']);
        item.sourcetype := TOursConv.AsInteger(measurementTable.FieldByName['sourcetype_id']);
        item.z0_id := TOursConv.AsInteger(measurementTable.FieldByName['z0_id']);
        item.d_z0_id := TOursConv.AsInteger(measurementTable.FieldByName['d_z0_id']);
        item.yratio_id := TOursConv.AsInteger(measurementTable.FieldByName['yratio_id']);
        item.d_yratio_id := TOursConv.AsInteger(measurementTable.FieldByName['d_yratio_id']);
        item.vref := TOursConv.AsInteger(measurementTable.FieldByName['vref']);
        item.n0 := TOursConv.AsFloat(measurementTable.FieldByName['n0']);
        item.d_n0 := TOursConv.AsFloat(measurementTable.FieldByName['d_n0']);
        item.n1 := TOursConv.AsFloat(measurementTable.FieldByName['n1']);
        item.d_n1 := TOursConv.AsFloat(measurementTable.FieldByName['d_n1']);
        item.fz0_id := TOursConv.AsInteger(measurementTable.FieldByName['fz0_id']);
        item.d_fz0_id := TOursConv.AsInteger(measurementTable.FieldByName['d_fz0_id']);
        item.fz1_id := TOursConv.AsInteger(measurementTable.FieldByName['fz1_id']);
        item.d_fz1_id := TOursConv.AsInteger(measurementTable.FieldByName['d_fz1_id']);
        item.fx0_id := TOursConv.AsInteger(measurementTable.FieldByName['fx0_id']);
        item.d_fx0_id := TOursConv.AsInteger(measurementTable.FieldByName['d_fx0_id']);
        item.fx1_id := TOursConv.AsInteger(measurementTable.FieldByName['fx1_id']);
        item.d_fx1_id := TOursConv.AsInteger(measurementTable.FieldByName['d_fx1_id']);

        var value: TOursMeasurements := nil;
        if not _measurements.TryGetValue(train, value) then begin
          value := TOursMeasurements.Create;
          _measurements.Add(train, value);
        end;
        value.Add(item);
        measurementTable.Next;
      end;
    finally
      measurementTable.Free;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.GetTrackPart: TOursTrackPart;
begin
  // Op basis van km kan de bijbehorende TrackPart worden bepaald.
  Result := nil;
  if (not Assigned(_track)) or (_km < _track.kmstart) or (_km > _track.kmend) then
    Exit;

  for var i := 0 to _track.TrackParts.Count - 1 do begin
    var item := _track.TrackParts[i];

    if InRange(_km, item.kmstart, item.kmend) then begin
      Result := item;

      if _km = item.kmstart then begin
        // Punt ligt precies op het begin van een part. Check "kmend" andere parts, deze overruled.
        for var j := 0 to _track.TrackParts.Count - 1 do
          if (i <> j) and (_km = _track.TrackParts[j].kmend) then
            Result := _track.TrackParts[j];
      end;

      Break;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.GetPos: TRpoint;
begin
  Result.x := x;
  Result.y := y;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursSource.SetPos(const Value: TRpoint);
begin
  x := Value.x;
  y := Value.y;
end;

// -------------------------------------------------------------------------------------------------

function TOursSource.sourcetype: string;
begin
  Result := '--';
  if Assigned(_track) then begin
    Result := TOursDatabase.GetDescriptionFromId('sourcetype', _track.sourcetype_id);
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSources.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.AsText;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSources.GroundAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.GroundAsText;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSources.FemDerivedAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.FemDerivedAsText;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSources.FemUncertaintyAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.FemUncertaintyAsText;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSources.HBuildingAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.HBuildingAsText;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursSources.MainResultsAsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.MainResultsAsText;
  end;
end;

// =================================================================================================
// TOursSettings
// =================================================================================================

function TOursSettings.AsText: string;
begin
  Result := Format('%-22s = ', [rsMaxCalcDistanceM]) + Format('%.2f', [maxCalcDistance]) + CRLF +
            Format('%-22s = ', [rsMaxCalcDepthM]) + Format('%.2f', [maxCalcDepth]) + CRLF +
            Format('%-22s = ', [rsMinLayerThicknessM]) + Format('%.2f', [minLayerThickness]) + CRLF +
            Format('%-22s = ', [rsMinElementSizeM]) + Format('%.2f', [minElementSize]) + CRLF +
            Format('%-22s = ', [rsSpectrumType]) + sSPEC_TYPE[spectrumType] + CRLF +
            Format('%-22s = ', [rsLowFrequencyHz]) + Format('%.f', [lowFreq]) + CRLF +
            Format('%-22s = ', [rsHighFrequenceHz]) + Format('%.f', [highFreq]) + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetCalcType: Integer;
begin
  Result := TOursDatabase.GetCalcType;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetHighFreq: Double;
begin
  Result := TOursDatabase.GetHighFreq;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetLowFreq: Double;
begin
  Result := TOursDatabase.GetLowFreq;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetMaxCalcDepth: Double;
begin
  Result := TOursDatabase.GetMaxCalcDepth;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetMaxCalcDistance: Double;
begin
  Result := TOursDatabase.GetMaxCalcDistance;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetMinLayerThickness: Double;
begin
  Result := TOursDatabase.GetMinLayerThickness;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetMinElementSize: Double;
begin
  Result := TOursDatabase.GetMinElementSize;
end;

// -------------------------------------------------------------------------------------------------

function TOursSettings.GetSpectrumType: Integer;
begin
  Result := TOursDatabase.GetSpectrumType;
end;

// =================================================================================================
// TOursTrainMeasurements
// =================================================================================================

procedure TOursTrainMeasurements.Clear;
begin
  for var item in Self do begin
    item.Value.Clear;
    item.Value.Free;
  end;

  inherited Clear;
end;

// -------------------------------------------------------------------------------------------------

function TOursTrainMeasurements.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.Key.AsText +
                       item.Value.AsText;
  end;
end;

// =================================================================================================
// TOursMeasurement(s)
// =================================================================================================

function TOursMeasurements.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + item.AsText;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursMeasurements.AsJSON: string;
begin
  Result := '';
  for var item in Self do begin
    Result := Result + '            {' + CRLF +
                Format('                "Vref":%d,', [item.vref]) + CRLF +
                Format('                "Zo":%s,', [item.z0.AsJsonText]) + CRLF +
                Format('                "Y_ratio":%s,', [item.yratio.AsJsonText]) + CRLF +
                Format('                "FZ0":%s,', [item.fz0.AsJsonText]) + CRLF +
                Format('                "FZ1":%s,', [item.fz1.AsJsonText]) + CRLF +
                Format('                "FX0":%s,', [item.fx0.AsJsonText]) + CRLF +
                Format('                "FX1":%s,', [item.fx1.AsJsonText]) + CRLF +
                Format('                "n0":%.f,', [item.n0]) + CRLF +
                Format('                "n1":%.f,', [item.n1]) + CRLF +
                Format('                "dZo":%s,', [item.d_z0.AsJsonText]) + CRLF +
                Format('                "dY_ratio":%s,', [item.d_yratio.AsJsonText]) + CRLF +
                Format('                "dFZ0":%s,', [item.d_fz0.AsJsonText]) + CRLF +
                Format('                "dFZ1":%s,', [item.d_fz1.AsJsonText]) + CRLF +
                Format('                "dFX0":%s,', [item.d_fx0.AsJsonText]) + CRLF +
                Format('                "dFX1":%s,', [item.d_fx1.AsJsonText]) + CRLF +
                Format('                "dn0":%.f,', [item.d_n0]) + CRLF +
                Format('                "dn1":%.f', [item.d_n1]) + CRLF +
                       '            }';

    if item <> Self.Items[Self.Count - 1] then begin
      Result := Result + ',';
    end;
    Result := Result + CRLF;
  end;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursMeasurement.Create;
begin
  _z0 := TSpectrum.Create;
  _d_z0 := TSpectrum.Create;
  _yratio := TSpectrum.Create;
  _d_yratio := TSpectrum.Create;
  _fz0 := TSpectrum.Create;
  _d_fz0 := TSpectrum.Create;
  _fz1 := TSpectrum.Create;
  _d_fz1 := TSpectrum.Create;
  _fx0 := TSpectrum.Create;
  _d_fx0 := TSpectrum.Create;
  _fx1 := TSpectrum.Create;
  _d_fx1 := TSpectrum.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursMeasurement.Destroy;
begin
  _z0.Free;
  _d_z0.Free;
  _yratio.Free;
  _d_yratio.Free;
  _fz0.Free;
  _d_fz0.Free;
  _fz1.Free;
  _d_fz1.Free;
  _fx0.Free;
  _d_fx0.Free;
  _fx1.Free;
  _d_fx1.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursMeasurement.AsText: string;
begin
  Result := Format('    %-16s     ', ['- Measurement']) + CRLF +
            Format('      %-14s = ', [rsName]) + name + CRLF +
            Format('      %-14s = ', [rsDescription]) + description + CRLF +
            Format('      %-14s = ', [rsCategory]) + category.ToString + CRLF +
            Format('      %-14s = ', [rsSourcetype]) + sourcetype.ToString + CRLF +
            Format('      %-14s = ', ['z0']) + z0.AsText + CRLF +
            Format('      %-14s = ', ['d_z0']) + d_z0.AsText + CRLF +
            Format('      %-14s = ', ['yratio']) + yratio.AsText + CRLF +
            Format('      %-14s = ', ['d_yratio']) + d_yratio.AsText + CRLF +
            Format('      %-14s = ', ['vref']) + vref.ToString + CRLF +
            Format('      %-14s = ', ['n0']) + n0.ToString + CRLF +
            Format('      %-14s = ', ['d_n0']) + d_n0.ToString + CRLF +
            Format('      %-14s = ', ['n1']) + n1.ToString + CRLF +
            Format('      %-14s = ', ['d_n1']) + d_n1.ToString + CRLF +
            Format('      %-14s = ', ['fz0']) + fz0.AsText + CRLF +
            Format('      %-14s = ', ['d_fz0']) + d_fz0.AsText + CRLF +
            Format('      %-14s = ', ['fz1']) + fz1.AsText + CRLF +
            Format('      %-14s = ', ['d_fz1']) + d_fz1.AsText + CRLF +
            Format('      %-14s = ', ['fx0']) + fx0.AsText + CRLF +
            Format('      %-14s = ', ['d_fx0']) + d_fx0.AsText + CRLF +
            Format('      %-14s = ', ['fx1']) + fx1.AsText + CRLF +
            Format('      %-14s = ', ['d_fx1']) + d_fx1.AsText + CRLF;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMeasurement.Setd_fx0_id(const Value: Integer);
begin
  _d_fx0_id := Value;
  LoadSpectrum(_d_fx0, _d_fx0_id);
end;

procedure TOursMeasurement.Setd_fx1_id(const Value: Integer);
begin
  _d_fx1_id := Value;
  LoadSpectrum(_d_fx1, _d_fx1_id);
end;

procedure TOursMeasurement.Setd_fz0_id(const Value: Integer);
begin
  _d_fz0_id := Value;
  LoadSpectrum(_d_fz0, _d_fz0_id);
end;

procedure TOursMeasurement.Setd_fz1_id(const Value: Integer);
begin
  _d_fz1_id := Value;
  LoadSpectrum(_d_fz1, _d_fz1_id);
end;

procedure TOursMeasurement.Setd_yratio_id(const Value: Integer);
begin
  _d_yratio_id := Value;
  LoadSpectrum(_d_yratio, _d_yratio_id);
end;

procedure TOursMeasurement.Setd_z0_id(const Value: Integer);
begin
  _d_z0_id := Value;
  LoadSpectrum(_d_z0, _d_z0_id);
end;

procedure TOursMeasurement.Setfx0_id(const Value: Integer);
begin
  _fx0_id := Value;
  LoadSpectrum(_fx0, _fx0_id);
end;

procedure TOursMeasurement.Setfx1_id(const Value: Integer);
begin
  _fx1_id := Value;
  LoadSpectrum(_fx1, _fx1_id);
end;

procedure TOursMeasurement.Setfz0_id(const Value: Integer);
begin
  _fz0_id := Value;
  LoadSpectrum(_fz0, _fz0_id);
end;

procedure TOursMeasurement.Setfz1_id(const Value: Integer);
begin
  _fz1_id := Value;
  LoadSpectrum(_fz1, _fz1_id);
end;

procedure TOursMeasurement.Setyratio_id(const Value: Integer);
begin
  _yratio_id := Value;
  LoadSpectrum(_yratio, _yratio_id);
end;

procedure TOursMeasurement.Setz0_id(const Value: Integer);
begin
  _z0_id := Value;
  LoadSpectrum(_z0, _z0_id);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMeasurement.LoadSpectrum(aSpectrum: TSpectrum; aId: Integer);
var
  spectrumTable: TSQLiteTable;
begin
  var sql := Format('SELECT * FROM spectrum WHERE id=%d', [aId]);
  spectrumTable := TOursDatabase.GetTableFromSQL(sql);
  try
    if not spectrumTable.EOF then begin
      for var i := 0 to aSpectrum.size - 1 do begin
        var field := TFrequency.f_fieldname[i];

        aSpectrum.Value[i] := TOursConv.AsFloat(spectrumTable.FieldByName[field]);
      end;
    end;
  finally
    spectrumTable.Free;
  end;
end;

// =================================================================================================
// TOursGroundScenario
// =================================================================================================

function TOursGroundScenario.AsText: string;
begin
  Result := Format(' - %-11s = ', [rsName])       + _name                  + CRLF +
            Format(' - %-11s = ', [rsDistance])   + _distance.ToString     + CRLF +
            Format(' - %-11s = ', [rsLithology])  + _Lithology.AsText      + CRLF +
            Format(' - %-11s = ', [rsDepth])      + _Depth.AsText(3)       + CRLF +
            Format(' - %-11s = ', [rsE])          + _E.AsText(2)           + CRLF +
            Format(' - %-11s = ', [rsV])          + _V.AsText(3)           + CRLF +
            Format(' - %-11s = ', [rsRho])        + _Rho.AsText(3)         + CRLF +
            Format(' - %-11s = ', [rsDamping])    + _Damping.AsText(5)     + CRLF +
            Format(' - %-11s = ', [rsVarDepth])   + _Var_depth.AsText(3)   + CRLF +
            Format(' - %-11s = ', [rsVarE])       + _Var_E.AsText(2)       + CRLF +
            Format(' - %-11s = ', [rsVarV])       + _Var_v.AsText(3)       + CRLF +
            Format(' - %-11s = ', [rsVarRho])     + _Var_rho.AsText(3)     + CRLF +
            Format(' - %-11s = ', [rsVarDamping]) + _Var_damping.AsText(5) + CRLF;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursGroundScenario.Create;
begin
  _Lithology := TStringsList.Create;

  _Depth := TDoubleList.Create;
  _E := TDoubleList.Create;
  _V := TDoubleList.Create;
  _Rho := TDoubleList.Create;
  _Damping := TDoubleList.Create;

  _Var_depth := TDoubleList.Create;
  _Var_E := TDoubleList.Create;
  _Var_v := TDoubleList.Create;
  _Var_rho := TDoubleList.Create;
  _Var_damping := TDoubleList.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursGroundScenario.Destroy;
begin
  _Lithology.Free;

  _Depth.Free;
  _E.Free;
  _V.Free;
  _Rho.Free;
  _Damping.Free;

  _Var_depth.Free;
  _Var_E.Free;
  _Var_v.Free;
  _Var_rho.Free;
  _Var_damping.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenario.IsEqual(AScenario: TOursGroundScenario): Boolean;
begin
  // name and lithology not relevant. These fields are information and not data
  Result := _Depth.IsEqual(AScenario._Depth, 1E-5) and
            _E.IsEqual(AScenario._E, 1E-5) and
            _V.IsEqual(AScenario._V, 1E-5) and
            _Rho.IsEqual(AScenario._Rho, 1E-5) and
            _Damping.IsEqual(AScenario._Damping, 1E-5) and
            _Var_depth.IsEqual(AScenario._Var_depth, 1E-5) and
            _Var_E.IsEqual(AScenario._Var_E, 1E-5) and
            _Var_v.IsEqual(AScenario._Var_v, 1E-5) and
            _Var_rho.IsEqual(AScenario._Var_rho, 1E-5) and
            _Var_damping.IsEqual(AScenario._Var_damping, 1E-5);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursGroundScenario.SetDistance(value: Double);
begin
  if value > _distance then
    _distance := value;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursGroundScenario.SetFemResults(value: TOursFemOutput);
begin
  if Assigned(_FemResults) then
    _FemResults.Free;

  _FemResults := value;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenario.GroundAsJsonForFem: string;
begin
  // The FEM script does not accept an array of numbers without at least one value with a decimal
  // separator. As the JSON string is created by Delphi, I have no way of enforcing this.
  // Work around: create the JSON by hand...
  Result := '    "Ground":{' + CRLF +
                  _Depth.AsJson(8, 'Depth', True, True) +
                  _E.AsJson(8, 'E', True, True) +
                  _Lithology.AsJson(8, 'Lithology', True) +
                  _Damping.AsJson(8, 'damping', True, True) +
                  _rho.AsJson(8, 'rho', True, True) +
                  _v.AsJson(8, 'v', True, False) +
            '    }' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenario.GroundAsJsonForUncertainty: string;
begin
  // The FEM script does not accept an array of numbers without at least one value with a decimal
  // separator. As the JSON string is created by Delphi, I have no way of enforcing this.
  // Work around: create the JSON by hand...
  Result := '    "CPTtoolOutput":{' + CRLF +
                  _Lithology.AsJson(8, 'Lithology', True) +

                  _Depth.AsJson(8, 'Depth', True, True) +
                  _E.AsJson(8, 'E', True, True) +
                  _v.AsJson(8, 'v', True, True) +
                  _rho.AsJson(8, 'rho', True, True) +
                  _Damping.AsJson(8, 'damping', True, True) +

                  _Var_depth.AsJson(8, 'var_depth', True, True) +
                  _Var_E.AsJson(8, 'var_E', True, True) +
                  _Var_v.AsJson(8, 'var_v', True, True) +
                  _Var_rho.AsJson(8, 'var_rho', True, True) +
                  _Var_Damping.AsJson(8, 'var_damping', True, False) +
            '    }';
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenario.FemAsText: string;
begin
  Result := Self.name + CRLF +
            FemResults.AsText +
            '--------------------------------------------------------------------------------' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenario.GroundAsText: string;
begin
  Result := AsText + '--------------------------------------------------------------------------------' + CRLF;
end;

// =================================================================================================
// TOursGroundScenarios
// =================================================================================================

function TOursGroundScenarios.GroundAsText: string;
begin
  if Count = 0 then begin
    Result := 'No ground data available.' + CRLF +
              '--------------------------------------------------------------------------------' + CRLF;
  end else begin
    for var item in Self do begin
      Result := Result + item.GroundAsText;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenarios.FemAsText: string;
begin
  if Count = 0 then begin
    Result := 'No FEM results available.' + CRLF +
              '--------------------------------------------------------------------------------' + CRLF;
  end else begin
    for var item in Self do begin
      Result := Result + item.FemAsText;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenarios.AsJSON: string;
begin
  Result :='TODO:' + CRLF + '    function TOursGroundScenarios.AsJSON: string;' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenarios.AsText: string;
begin
  Result :='TODO:' + CRLF + '    function TOursGroundScenarios.AsText: string;' + CRLF;

end;

// -------------------------------------------------------------------------------------------------

function TOursGroundScenarios.IndexOf(AScenario: TOursGroundScenario): Integer;
begin
  Result := -1;
  if (AScenario = nil) or (Count = 0) then
    Exit;

  for var idx := 0 to Count-1 do begin
    if items[idx].IsEqual(AScenario) then begin
      Result := idx;
      Exit;
    end;
  end;
end;

// =================================================================================================
// TOursResults
// =================================================================================================

constructor TOursResults.Create(const rec: TOursReceptor; const src: TOursSource);
begin
  _Receptor := rec;
  _Source := src;

  _Scenarios := TOursResultScenarios.Create;
  _MainResults := TOursSourceResults.Create;

end;

// -------------------------------------------------------------------------------------------------

destructor TOursResults.Destroy;
begin
  _Scenarios.Free;
  _MainResults.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursResults.MainResultsAsText: string;
begin
  Result := MainResults.AsText;
end;

// -------------------------------------------------------------------------------------------------

function TOursResults.AddScenario(const grnd: TOursGroundScenario): TOursResultScenario;
begin
  Result := TOursResultScenario.Create(_receptor, _source, grnd);
  _scenarios.Add(Result);
end;

// =================================================================================================
// TOursResultScenario
// =================================================================================================

constructor TOursResultScenario.Create(const rec: TOursReceptor; const src: TOursSource; const grnd: TOursGroundScenario);
begin
  _receptor := rec;
  _source := src;
  _ground := grnd;

  _FemDerived := TOursFemDerived.Create;
  _FemUncertainty := TOursFemUncertainty.Create;
  _HBuilding := TOursHBuilding.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursResultScenario.Destroy;
begin
  _FemDerived.Free;
  _FemUncertainty.Free;
  _HBuilding.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursResultScenario.GroundAsText: string;
begin
  Result := '  - ' + _ground.name + ' (' + (100 * _probability).ToString + '%)' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursResultScenario.FemForMainFormulaAsJSON: string;
begin
  Result := '        {' + CRLF +
            '            "Yo": '           + _FemDerived.Y_25.AsJsonText               + ',' + CRLF +
            '            "Yo_ratio": '     + _FemDerived.Y_ratio_25.AsJsonText         + ',' + CRLF +
            '            "Y": '            + _FemDerived.Y_X.AsJsonText                + ',' + CRLF +
            '            "Y_ratio": '      + _FemDerived.Y_ratio_X.AsJsonText          + ',' + CRLF +

            '            "var_Yo": '       + _FemUncertainty.var_Y_25.AsJsonText       + ',' + CRLF +
            '            "var_Yo_ratio": ' + _FemUncertainty.var_Y_ratio_25.AsJsonText + ',' + CRLF +
            '            "var_Y": '        + _FemUncertainty.var_Y_X.AsJsonText        + ',' + CRLF +
            '            "var_Y_ratio": '  + _FemUncertainty.var_Y_ratio_X.AsJsonText        + CRLF +
            '        }';
end;

// =================================================================================================
// TOursResultScenarios
// =================================================================================================

function TOursResultScenarios.GroundAsText: string;
begin
  if Count = 0 then begin
    Result := '    No ground data available.' + CRLF;
  end else begin
    Result := '';
    for var item in Self do begin
      Result := Result + item.GroundAsText;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursResultScenarios.FemDerivedAsText: string;
begin
  if Count = 0 then begin
    Result := '    No results available.' + CRLF;
  end else begin
    Result := '';
    for var item in Self do begin
      Result := Result + Format('    %-18s = ', ['Scenario']) + item.ground.name + CRLF +
                         item.FemDerived.AsText;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursResultScenarios.FemUncertaintyAsText: string;
begin
  if Count = 0 then begin
    Result := '    No results available.' + CRLF;
  end else begin
    Result := '';
    for var item in Self do begin
      Result := Result + Format('    %-18s = ', ['Scenario']) + item.ground.name + CRLF +
                         item.FemUncertainty.AsText;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursResultScenarios.HBuildingAsText: string;
begin
  if Count = 0 then begin
    Result := '    No results available.' + CRLF;
  end else begin
    Result := '';
    for var item in Self do begin
      Result := Result + Format('    %-18s = ', ['Scenario']) + item.ground.name + CRLF +
                         item.HBuilding.AsText;
    end;
  end;
end;

// =================================================================================================
// TOursFemDerived
// =================================================================================================

function TOursFemDerived.AsText: string;
begin
  Result := Format('    %-18s = ', ['- Y (0m)'])        + _Y_0.AsText        + CRLF +
            Format('    %-18s = ', ['- fase (0m)'])     + _fase_0.AsText     + CRLF +
            Format('    %-18s = ', ['- Y (25m)'])       + _Y_25.AsText       + CRLF +
            Format('    %-18s = ', ['- Y_ratio (25m)']) + _Y_ratio_25.AsText + CRLF +
            Format('    %-18s = ', ['- c (Xm)'])        + _c_X.AsText        + CRLF +
            Format('    %-18s = ', ['- c_ratio (Xm)'])  + _c_ratio_X.AsText  + CRLF +
            Format('    %-18s = ', ['- Y (Xm)'])        + _Y_X.AsText        + CRLF +
            Format('    %-18s = ', ['- Y_ratio (Xm)'])  + _Y_ratio_X.AsText  + CRLF;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursFemDerived.Clear;
begin
  _Y_0.FillValue(0.0);
  _fase_0.FillValue(0.0);

  _Y_25.FillValue(0.0);
  _Y_ratio_25.FillValue(0.0);

  _c_X.FillValue(0.0);
  _c_ratio_X.FillValue(0.0);
  _Y_X.FillValue(0.0);
  _Y_ratio_X.FillValue(0.0);

  _JSON_0  := '';
  _JSON_25 := '';
  _JSON_X  := '';
end;

// -------------------------------------------------------------------------------------------------

constructor TOursFemDerived.Create;
begin
  _Y_0 := TSpectrum.Create;
  _fase_0 := TSpectrum.Create;

  _Y_25 := TSpectrum.Create;
  _Y_ratio_25 := TSpectrum.Create;

  _c_X := TSpectrum.Create;
  _c_ratio_X := TSpectrum.Create;
  _Y_X := TSpectrum.Create;
  _Y_ratio_X := TSpectrum.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursFemDerived.Destroy;
begin
  _Y_0.Free;
  _fase_0.Free;

  _Y_25.Free;
  _Y_ratio_25.Free;

  _c_X.Free;
  _c_ratio_X.Free;
  _Y_X.Free;
  _Y_ratio_X.Free;

  inherited;
end;

// =================================================================================================
// TOursFemUncertainty
// =================================================================================================

function TOursFemUncertainty.AsText: string;
begin
  Result := Format('    %-18s = ', ['- var_Y (0m)'])        + _var_Y_0.AsText        + CRLF +
            Format('    %-18s = ', ['- var_fase (0m)'])     + _var_fase_0.AsText     + CRLF +
            Format('    %-18s = ', ['- var_Y (25m)'])       + _var_Y_25.AsText       + CRLF +
            Format('    %-18s = ', ['- var_Y_ratio (25m)']) + _var_Y_ratio_25.AsText + CRLF +
            Format('    %-18s = ', ['- var_c (Xm)'])        + _var_c_X.AsText        + CRLF +
            Format('    %-18s = ', ['- var_c_ratio (Xm)'])  + _var_c_ratio_X.AsText  + CRLF +
            Format('    %-18s = ', ['- var_Y (Xm)'])        + _var_Y_X.AsText        + CRLF +
            Format('    %-18s = ', ['- var_Y_ratio (Xm)'])  + _var_Y_ratio_X.AsText  + CRLF;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursFemUncertainty.Clear;
begin
  _var_Y_0.FillValue(0.0);
  _var_fase_0.FillValue(0.0);

  _var_Y_25.FillValue(0.0);
  _var_Y_ratio_25.FillValue(0.0);

  _var_c_X.FillValue(0.0);
  _var_c_ratio_X.FillValue(0.0);
  _var_Y_X.FillValue(0.0);
  _var_Y_ratio_X.FillValue(0.0);
end;

// -------------------------------------------------------------------------------------------------

constructor TOursFemUncertainty.Create;
begin
  _var_Y_0 := TSpectrum.Create;
  _var_fase_0 := TSpectrum.Create;

  _var_Y_25 := TSpectrum.Create;
  _var_Y_ratio_25 := TSpectrum.Create;

  _var_c_X := TSpectrum.Create;
  _var_c_ratio_X := TSpectrum.Create;
  _var_Y_X := TSpectrum.Create;
  _var_Y_ratio_X := TSpectrum.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursFemUncertainty.Destroy;
begin
  _var_Y_0.Free;
  _var_fase_0.Free;

  _var_Y_25.Free;
  _var_Y_ratio_25.Free;

  _var_c_X.Free;
  _var_c_ratio_X.Free;
  _var_Y_X.Free;
  _var_Y_ratio_X.Free;

  inherited;
end;

// =================================================================================================
// TOursReceptorBuilding
// =================================================================================================

function TOursReceptorBuilding.AsText: string;
begin
  // Data is niet verplicht. Alleen afbeelden als deze is gevuld.
  Result := '';
  if _bagId <> '' then
    Result := Result + Format('- %-24s = ', [rsBagId]) + _bagId + CRLF;

  Result := Result + TIntegerList.AsTextLine(_yearOfConstruction,   Format('- %-24s = ', [rsConstructionYear]));
  Result := Result + TIntegerList.AsTextLine(_apartment,            Format('- %-24s = ', [rsApartment]));
  Result := Result + TDoubleList.AsTextLine(_buildingHeight,        Format('- %-24s = ', [rsBuildingHeight]), 2);
  Result := Result + TDoubleList.AsTextLine(_heightOfFloor,         Format('- %-24s = ', [rsHeightOfFloor]), 2);
  Result := Result + TIntegerList.AsTextLine(_floorNumber,          Format('- %-24s = ', [rsFloorNumber]));
  Result := Result + TDoubleList.AsTextLine(_wallLength,            Format('- %-24s = ', [rsWallLength]), 2);
  Result := Result + TDoubleList.AsTextLine(_facadeLength,          Format('- %-24s = ', [rsFacadeLength]), 2);
  Result := Result + TDoubleList.AsTextLine(_varYearOfConstruction, Format('- %-24s = ', [rsVarConstructionYear]), 2);
  Result := Result + TDoubleList.AsTextLine(_varApartment,          Format('- %-24s = ', [rsVarApartment]), 2);
  Result := Result + TDoubleList.AsTextLine(_varBuildingHeight,     Format('- %-24s = ', [rsVarBuildingHeight]), 2);
  Result := Result + TDoubleList.AsTextLine(_varNumberOfFloors,     Format('- %-24s = ', [rsVarNumberoffloors]), 2);
  Result := Result + TDoubleList.AsTextLine(_varHeightOfFloor,      Format('- %-24s = ', [rsVarHeightOfFloor]), 2);
  Result := Result + TDoubleList.AsTextLine(_varFloorNumber,        Format('- %-24s = ', [rsVarFloorNumber]), 2);
  Result := Result + TDoubleList.AsTextLine(_varWallLength,         Format('- %-24s = ', [rsVarWallLength]), 2);
  Result := Result + TDoubleList.AsTextLine(_varFacadeLength,       Format('- %-24s = ', [rsVarFacadelength]), 2);

  if Result <> '' then
    Result := rsBuilding + CRLF + Result;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursReceptorBuilding.Clear;
begin
  _bagId := '';
  _yearOfConstruction.Clear;
  _apartment.Clear;
  _buildingHeight.Clear;
  _numberOfFloors.Clear;
  _heightOfFloor.Clear;
  _floorNumber.Clear;
  _wallLength.Clear;
  _facadeLength.Clear;
  _varYearOfConstruction.Clear;
  _varApartment.Clear;
  _varBuildingHeight.Clear;
  _varNumberOfFloors.Clear;
  _varHeightOfFloor.Clear;
  _varFloorNumber.Clear;
  _varWallLength.Clear;
  _varFacadeLength.Clear;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursReceptorBuilding.Create;
begin
  _bagId := '';
  _yearOfConstruction := TIntegerList.Create;
  _apartment := TIntegerList.Create;
  _buildingHeight := TDoubleList.Create;
  _numberOfFloors := TIntegerList.Create;
  _heightOfFloor := TDoubleList.Create;
  _floorNumber := TIntegerList.Create;
  _wallLength := TDoubleList.Create;
  _facadeLength := TDoubleList.Create;
  _varYearOfConstruction := TDoubleList.Create;
  _varApartment := TDoubleList.Create;
  _varBuildingHeight := TDoubleList.Create;
  _varNumberOfFloors := TDoubleList.Create;
  _varHeightOfFloor := TDoubleList.Create;
  _varFloorNumber := TDoubleList.Create;
  _varWallLength := TDoubleList.Create;
  _varFacadeLength := TDoubleList.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursReceptorBuilding.Destroy;
begin
  _yearOfConstruction.Free;
  _apartment.Free;
  _buildingHeight.Free;
  _numberOfFloors.Free;
  _heightOfFloor.Free;
  _floorNumber.Free;
  _wallLength.Free;
  _facadeLength.Free;
  _varYearOfConstruction.Free;
  _varApartment.Free;
  _varBuildingHeight.Free;
  _varNumberOfFloors.Free;
  _varHeightOfFloor.Free;
  _varFloorNumber.Free;
  _varWallLength.Free;
  _varFacadeLength.Free;

  inherited;
end;

// =================================================================================================
// TOursReceptorFloor
// =================================================================================================

function TOursReceptorFloor.AsText: string;
begin
  Result := '';

  Result := Result + TDoubleList.AsTextLine(_frequenciesQuarterSpan,    Format('- %-24s = ', [rsFrequenciesQuarterSpan]), 2);
  Result := Result + TDoubleList.AsTextLine(_frequenciesMidSpan,        Format('- %-24s = ', [rsFrequenciesMidSpan]), 2);
  Result := Result + TDoubleList.AsTextLine(_floorSpan,                 Format('- %-24s = ', [rsFloorSpan]), 2);
  Result := Result + TIntegerList.AsTextLine(_woodenFloor,              Format('- %-24s = ', [rsWoodenFloor]));
  Result := Result + TDoubleList.AsTextLine(_varFrequenciesQuarterSpan, Format('- %-24s = ', [rsVarFrequenciesQuarterSpan]), 2);
  Result := Result + TDoubleList.AsTextLine(_varFrequenciesMidSpan,     Format('- %-24s = ', [rsVarFrequenciesMidSpan]), 2);
  Result := Result + TDoubleList.AsTextLine(_varFloorSpan,              Format('- %-24s = ', [rsVarFloorSpan]), 2);
  Result := Result + TDoubleList.AsTextLine(_varWoodenFloor,            Format('- %-24s = ', [rsVarWoodenFloor]), 2);

  if Result <> '' then
    Result := rsFloor + CRLF + Result;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursReceptorFloor.Clear;
begin
  _frequenciesQuarterSpan.Clear;
  _frequenciesMidSpan.Clear;
  _floorSpan.Clear;
  _woodenFloor.Clear;
  _varFrequenciesQuarterSpan.Clear;
  _varFrequenciesMidSpan.Clear;
  _varFloorSpan.Clear;
  _varWoodenFloor.Clear;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursReceptorFloor.Create;
begin
  _frequenciesQuarterSpan := TDoubleList.Create;
  _frequenciesMidSpan := TDoubleList.Create;
  _floorSpan := TDoubleList.Create;
  _woodenFloor := TIntegerList.Create;
  _varFrequenciesQuarterSpan := TDoubleList.Create;
  _varFrequenciesMidSpan := TDoubleList.Create;
  _varFloorSpan := TDoubleList.Create;
  _varWoodenFloor := TDoubleList.Create;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursReceptorFloor.Destroy;
begin
  _frequenciesQuarterSpan.Free;
  _frequenciesMidSpan.Free;
  _floorSpan.Free;
  _woodenFloor.Free;
  _varFrequenciesQuarterSpan.Free;
  _varFrequenciesMidSpan.Free;
  _varFloorSpan.Free;
  _varWoodenFloor.Free;

  inherited;
end;

// =================================================================================================

end.
