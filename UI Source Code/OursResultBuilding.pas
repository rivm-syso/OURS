{ @abstract(This unit classes for input, output and storage of the Building module.)
}
unit OursResultBuilding;

interface

uses
  Generics.Collections,
  Rest.Json,
  OursResultFem,
  OursResultGround,
  OursTypes;

// -------------------------------------------------------------------------------------------------

type
  { @abstract(Class for storing the section "Bodem" for the the Building module.)
    These values are stored in TOursReceptor.Sources[*].FemResults[*]
  }
  TOursBuildingInput_Ground = class
  private
    _y: TSpectrum;
    _fase: TSpectrum;
    _c: TSpectrum;
    _c_ratio: TSpectrum;
    _var_Y: TSpectrum;
    _var_fase: TSpectrum;
    _var_c: TSpectrum;
    _var_c_ratio: TSpectrum;
  public
    { @abstract(Constructor.)
    }
    constructor Create; virtual;

    { @abstract(Destructor.)
    }
    destructor Destroy; override;

    { @abstract(Converts the data to JSON suitable for the Building module.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    property y: TSpectrum read _y;
    property fase: TSpectrum read _fase;
    property c: TSpectrum read _c;
    property c_ratio: TSpectrum read _c_ratio;
    property var_y: TSpectrum read _var_Y;
    property var_fase: TSpectrum read _var_fase;
    property var_c: TSpectrum read _var_c;
    property var_c_ratio: TSpectrum read _var_c_ratio;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class for storing the section "Vloer" for the the Building module.)
    These values are stored in TOursReceptor (freqQuarterspan, freqMidspan, woodenfloor).
    Values of var_* are currently set to zero.
  }
  TOursBuildingInput_Floor = class
  private
    _quarterSpan: TDoubleList;
    _midSpan: TDoubleList;
    _floorSpan: TDoubleList;
    _wood: TIntegerList;
    _varQuarterSpan: TDoubleList;
    _varMidSpan: TDoubleList;
    _varFloorSpan: TDoubleList;
    _varWood: TDoubleList;
  public
    { @abstract( Constructor.)
    }
    constructor Create; virtual;

    { @abstract( Destructor.)
    }
    destructor Destroy; override;

    { @abstract( Converts the data to JSON suitable for the Building module.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Frequency list with 0 or more values).
    }
    property quarterSpan: TDoubleList read _quarterSpan;

    { @abstract(Frequency list with 0 or more values).
    }
    property midSpan: TDoubleList read _midSpan;

    { @abstract(List with 0 or more values).
    }
    property floorSpan: TDoubleList read _floorSpan;

    { @abstract(List with 0 or 1 values. Empty=unknown, 0=False, 1=True.)
    }
    property wood: TIntegerList read _wood;

    { @abstract(Frequency list which is empty or contains the same number of values as quarterspan.)
    }
    property varQuarterSpan: TDoubleList read _varQuarterSpan;

    { @abstract(Frequency list which is empty or contains the same number of values as midspan.)
    }
    property varMidSpan: TDoubleList read _varMidSpan;

    { @abstract(List which is empty or contains the same number of values as floorspan.)
    }
    property varFloorSpan: TDoubleList read _varFloorSpan;

    { @abstract(List which is empty or contains the same number of values as wood.)
    }
    property varWood: TDoubleList read _varWood;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class for storing the section "Gebouw" for the the Building module.)
    These values are stored in TOursReceptor (constructionyear, apartment, numberoffloors,
    walllength, facadelength).
    Values of var_* are currently set to zero.
    }
  TOursBuildingInput_Building = class
  private
    _yearOfConstruction: TIntegerList;   // bouwjaar
    _apartment: TIntegerList;            // appartement
    _buildingHeight: TDoubleList;        // gebouwHoogte
    _numberOfFloors: TIntegerList;       // aantalBouwlagen
    _heightOfFloor: TDoubleList;         // vloerHoogte
    _floorNumber: TIntegerList;          // verdiepingNr
    _wallLength: TDoubleList;            // wandlengte
    _facadeLength: TDoubleList;          // gevellengte
    _varYearOfConstruction: TDoubleList; // var_bouwjaar
    _varApartment: TDoubleList;          // var_appartement
    _varBuildingHeight: TDoubleList;     // var_gebouwHoogte
    _varNumberOfFloors: TDoubleList;     // var_aantalBouwlagen
    _varHeightOfFloor: TDoubleList;      // var_vloerHoogte
    _varFloorNumber: TDoubleList;        // var_verdiepingNr
    _varWallLength: TDoubleList;         // var_wandlengte
    _varFacadeLength: TDoubleList;       // var_gevellengte
  public
    { @abstract( Constructor.)
    }
    constructor Create; virtual;

    { @abstract( Destructor.)
    }
    destructor Destroy; override;

    { @abstract( Converts the data to JSON suitable for the Building module.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

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

// -------------------------------------------------------------------------------------------------

  { @abstract(Class for storing the data needed for the Building module.)
  }
  TOursBuildingInput = class
  private
    _ground: TOursBuildingInput_Ground;
    _floor: TOursBuildingInput_Floor;
    _building: TOursBuildingInput_Building;
  public
    { @abstract( Constructor.)
    }
    constructor Create; virtual;

    { @abstract( Destructor.)
    }
    destructor Destroy; override;

    { @abstract( Gives the data needed for the building module in JSON format.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract( Pointer to the ground data for the Building module.)
    }
    property ground: TOursBuildingInput_Ground read _ground;

    { @abstract( Pointer to the floor data for the Building module.)
    }
    property floor: TOursBuildingInput_Floor read _floor;

    { @abstract( Pointer to the building data for the Building module.)
    }
    property building: TOursBuildingInput_Building read _building;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class for reading the results from the Building module.)
    Note: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
  TOursBuildingOutput = class
  private
    FHfxx: TArray<Extended>;
    FHfzz: TArray<Extended>;
    FHgebouw: TArray<Extended>;
    FHxx: TArray<Extended>;
    FHxz: TArray<Extended>;
    FHzx: TArray<Extended>;
    FHzz1: TArray<Extended>;
    FHzz2: TArray<Extended>;
    Fcov_Hxx: TArray<TArray<Extended>>;
    Fcov_Hxz: TArray<TArray<Extended>>;
    Fcov_Hzx: TArray<TArray<Extended>>;
    Fcov_Hzz1: TArray<TArray<Extended>>;
    Fcov_Hzz2: TArray<TArray<Extended>>;
    Fcov_Hfxx: TArray<TArray<Extended>>;
    Fcov_Hfzz: TArray<TArray<Extended>>;
  public
    property Hfxx: TArray<Extended>             read FHfxx     write FHfxx;
    property Hfzz: TArray<Extended>             read FHfzz     write FHfzz;
    property Hgebouw: TArray<Extended>          read FHgebouw  write FHgebouw;
    property Hxx: TArray<Extended>              read FHxx      write FHxx;
    property Hxz: TArray<Extended>              read FHxz      write FHxz;
    property Hzx: TArray<Extended>              read FHzx      write FHzx;
    property Hzz1: TArray<Extended>             read FHzz1     write FHzz1;
    property Hzz2: TArray<Extended>             read FHzz2     write FHzz2;
    property cov_Hxx: TArray<TArray<Extended>>  read Fcov_Hxx  write Fcov_Hxx;
    property cov_Hxz: TArray<TArray<Extended>>  read Fcov_Hxz  write Fcov_Hxz;
    property cov_Hzx: TArray<TArray<Extended>>  read Fcov_Hzx  write Fcov_Hzx;
    property cov_Hzz1: TArray<TArray<Extended>> read Fcov_Hzz1 write Fcov_Hzz1;
    property cov_Hzz2: TArray<TArray<Extended>> read Fcov_Hzz2 write Fcov_Hzz2;
    property cov_Hfxx: TArray<TArray<Extended>> read Fcov_Hfxx write Fcov_Hfxx;
    property cov_Hfzz: TArray<TArray<Extended>> read Fcov_Hfzz write Fcov_Hfzz;

    { @abstract(Converts the data to JSON suitable for the Building module.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Gives the data in readable text format.)
    }
    function AsText: string;

    { @abstract(Creates an instance of the class and fills it with data read from the given JSON string.)
    }
    class function FromJsonString(AJsonString: string): TOursBuildingOutput;
  end;

  // Output structure building section for Hgebouw.py
  { @abstract(Class for storing the building results.)
  }
  TOursBuildingResult = class
  private
    _Hfxx: TSpectrum;
    _Hfzz: TSpectrum;
    _Hgebouw: TSpectrum;
    _Hxx: TSpectrum;
    _Hxz: TSpectrum;
    _Hzx: TSpectrum;
    _Hzz1: TSpectrum;
    _Hzz2: TSpectrum;
    _cov_Hxx: TSpectrumArray;
    _cov_Hxz: TSpectrumArray;
    _cov_Hzx: TSpectrumArray;
    _cov_Hzz1: TSpectrumArray;
    _cov_Hzz2: TSpectrumArray;
    _cov_Hfxx: TSpectrumArray;
    _cov_Hfzz: TSpectrumArray;
  public
    { @abstract( Constructor.)
    }
    constructor Create; virtual;

    { @abstract( Destructor.)
    }
    destructor Destroy; override;

    { @abstract(Converts the data to JSON suitable for the Building module.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Gives the data in readable text format.)
    }
    function AsText: string;

    { @abstract(Copies the relevant data from output into the data fields.)
    }
    procedure SetFromOutput(output: TOursBuildingOutput);

    property Hfxx: TSpectrum          read _Hfxx     write _Hfxx;
    property Hfzz: TSpectrum          read _Hfzz     write _Hfzz;
    property Hgebouw: TSpectrum       read _Hgebouw  write _Hgebouw;
    property Hxx: TSpectrum           read _Hxx      write _Hxx;
    property Hxz: TSpectrum           read _Hxz      write _Hxz;
    property Hzx: TSpectrum           read _Hzx      write _Hzx;
    property Hzz1: TSpectrum          read _Hzz1     write _Hzz1;
    property Hzz2: TSpectrum          read _Hzz2     write _Hzz2;
    property cov_Hxx: TSpectrumArray  read _cov_Hxx  write _cov_Hxx;
    property cov_Hxz: TSpectrumArray  read _cov_Hxz  write _cov_Hxz;
    property cov_Hzx: TSpectrumArray  read _cov_Hzx  write _cov_Hzx;
    property cov_Hzz1: TSpectrumArray read _cov_Hzz1 write _cov_Hzz1;
    property cov_Hzz2: TSpectrumArray read _cov_Hzz2 write _cov_Hzz2;
    property cov_Hfxx: TSpectrumArray read _cov_Hfxx write _cov_Hfxx;
    property cov_Hfzz: TSpectrumArray read _cov_Hfzz write _cov_Hfzz;
  end;

//--------------------------------------------------------------------------------------------------

implementation

uses
  SysUtils,
  OursUtils,
  OursStrings;

//==================================================================================================
// TOursBuildingInput
//==================================================================================================

constructor TOursBuildingInput.Create;
begin
  _ground := TOursBuildingInput_Ground.Create;
  _floor := TOursBuildingInput_Floor.Create;
  _building := TOursBuildingInput_Building.Create;
end;

//--------------------------------------------------------------------------------------------------

destructor TOursBuildingInput.Destroy;
begin
  _ground.Free;
  _floor.Free;
  _building.Free;

  inherited;
end;

//--------------------------------------------------------------------------------------------------

function TOursBuildingInput.ToJsonString: string;
begin
  Result := '{'                           + CRLF +
                ground.ToJsonString + ',' + CRLF +
                floor.ToJsonString + ','  + CRLF +
                building.ToJsonString     + CRLF +
            '}';
end;

//==================================================================================================
// TOursBuildingInput_Ground
//==================================================================================================

constructor TOursBuildingInput_Ground.Create;
begin
  _y := TSpectrum.Create;
  _fase := TSpectrum.Create;
  _c := TSpectrum.Create;
  _c_ratio := TSpectrum.Create;
  _var_Y := TSpectrum.Create;
  _var_fase := TSpectrum.Create;
  _var_c := TSpectrum.Create;
  _var_c_ratio := TSpectrum.Create;
end;

//--------------------------------------------------------------------------------------------------

destructor TOursBuildingInput_Ground.Destroy;
begin
  _y.Free;
  _fase.Free;
  _c.Free;
  _c_ratio.Free;
  _var_Y.Free;
  _var_fase.Free;
  _var_c.Free;
  _var_c_ratio.Free;

  inherited;
end;

//--------------------------------------------------------------------------------------------------

function TOursBuildingInput_Ground.ToJsonString: string;
begin
  Result := '    "Bodem":' + CRLF +
            '    {'                                           + CRLF +
            '        "Y":' + y.AsJsonText               + ',' + CRLF +
            '        "fase":' + fase.AsJsonText         + ',' + CRLF +
            '        "c":' + c.AsJsonText               + ',' + CRLF +
            '        "c_ratio":' + c_ratio.AsJsonText   + ',' + CRLF +
            '        "var_Y":' + var_y.AsJsonText       + ',' + CRLF +
            '        "var_fase":' + var_fase.AsJsonText + ',' + CRLF +
            '        "var_c":' + var_c.AsJsonText       + ',' + CRLF +
            '        "var_c_ratio":' + var_c_ratio.AsJsonText + CRLF +
            '    }';
end;

//==================================================================================================
// TOursBuildingInput_Floor
//==================================================================================================

constructor TOursBuildingInput_Floor.Create;
begin
  _quarterSpan := TDoubleList.Create;
  _midSpan := TDoubleList.Create;
  _floorSpan := TDoubleList.Create;
  _wood := TIntegerList.Create;
  _varQuarterSpan := TDoubleList.Create;
  _varMidSpan := TDoubleList.Create;
  _varFloorSpan := TDoubleList.Create;
  _varWood := TDoubleList.Create;
end;

//--------------------------------------------------------------------------------------------------

destructor TOursBuildingInput_Floor.Destroy;
begin
  _quarterSpan.Free;
  _midSpan.Free;
  _floorSpan.Free;
  _wood.Free;
  _varQuarterSpan.Free;
  _varMidSpan.Free;
  _varFloorSpan.Free;
  _varWood.Free;

  inherited;
end;

//--------------------------------------------------------------------------------------------------

function TOursBuildingInput_Floor.ToJsonString: string;
begin
  Result := '    "Vloer":' + CRLF +
            '    {' + CRLF +
                 quarterSpan.AsJsonText   ('        "frequentiesQuarterspan": ',     True ) +
                 midSpan.AsJsonText       ('        "frequentiesMidspan": ',         True ) +
                 floorSpan.AsJsonText     ('        "vloerOverspanning": ',          False) +
                 wood.AsJsonText          ('        "hout": ',                       True ) +
                 varQuarterSpan.AsJsonText('        "var_frequentiesQuarterspan": ', True ) +
                 varMidSpan.AsJsonText    ('        "var_frequentiesMidspan": ',     True ) +
                 varFloorSpan.AsJsonText  ('        "var_vloerOverspanning": ',      False) +
                 varWood.AsJsonText       ('        "var_hout": ',                   True );

  if Result[Length(Result)-2] = ',' then
    Result[Length(Result)-2] := ' ';
  Result := Result + '    }';
end;

//==================================================================================================
// TOursBuildingInput_Building
//==================================================================================================

constructor TOursBuildingInput_Building.Create;
begin
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

//--------------------------------------------------------------------------------------------------

destructor TOursBuildingInput_Building.Destroy;
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

//--------------------------------------------------------------------------------------------------

function TOursBuildingInput_Building.ToJsonString: string;
begin
  Result := '    "Gebouw":' + CRLF +
            '    {' + CRLF +
            yearOfConstruction.AsJsonText   ('        "bouwjaar": '           , True ) +
            apartment.AsJsonText            ('        "appartement": '        , True ) +
            buildingHeight.AsJsonText       ('        "gebouwHoogte": '       , False) +
            numberOfFloors.AsJsonText       ('        "aantalBouwlagen": '    , False) +
            heightOfFloor.AsJsonText        ('        "vloerHoogte": '        , False) +
            floorNumber.AsJsonText          ('        "verdiepingNr": '       , False) +
            wallLength.AsJsonText           ('        "wandlengte": '         , True ) +
            facadeLength.AsJsonText         ('        "gevellengte": '        , True ) +
            varYearOfConstruction.AsJsonText('        "var_bouwjaar": '       , True ) +
            varApartment.AsJsonText         ('        "var_appartement": '    , True ) +
            varBuildingHeight.AsJsonText    ('        "var_gebouwHoogte": '   , True ) +
            varNumberOfFloors.AsJsonText    ('        "var_aantalBouwlagen": ', False) +
            varHeightOfFloor.AsJsonText     ('        "var_vloerHoogte": '    , False) +
            varFloorNumber.AsJsonText       ('        "var_verdiepingNr": '   , False) +
            varWallLength.AsJsonText        ('        "var_wandlengte": '     , True ) +
            varFacadeLength.AsJsonText      ('        "var_gevellengte": '    , True );

  if Result[Length(Result)-2] = ',' then
    Result[Length(Result)-2] := ' ';

  Result := Result + '    }';
end;

// ==================================================================================================
// TOursBuildingOutput
// ==================================================================================================

function TOursBuildingOutput.AsText: string;
begin
  Result := ToJsonString;
end;

//--------------------------------------------------------------------------------------------------

class function TOursBuildingOutput.FromJsonString(AJsonString: string): TOursBuildingOutput;
begin
  Result := TJson.JsonToObject<TOursBuildingOutput>(AJsonString)
end;

//--------------------------------------------------------------------------------------------------

function TOursBuildingOutput.ToJsonString: string;
begin
  Result := TOursConv.FormatJSON(TJson.ObjectToJsonString(Self));
end;

//==================================================================================================
// TOursBuildingResult
//==================================================================================================

constructor TOursBuildingResult.Create;
begin
  _Hfxx := TSpectrum.Create;
  _Hfzz := TSpectrum.Create;
  _Hgebouw := TSpectrum.Create;
  _Hxx := TSpectrum.Create;
  _Hxz := TSpectrum.Create;
  _Hzx := TSpectrum.Create;
  _Hzz1 := TSpectrum.Create;
  _Hzz2 := TSpectrum.Create;

  SetLength(_cov_Hxx, TFrequency.size);
  SetLength(_cov_Hxz, TFrequency.size);
  SetLength(_cov_Hzx, TFrequency.size);
  SetLength(_cov_Hzz1, TFrequency.size);
  SetLength(_cov_Hzz2, TFrequency.size);
  SetLength(_cov_Hfxx, TFrequency.size);
  SetLength(_cov_Hfzz, TFrequency.size);
  for var i := 0 to TFrequency.size - 1 do begin
    _cov_Hxx[i] := TSpectrum.Create;
    _cov_Hxz[i] := TSpectrum.Create;
    _cov_Hzx[i] := TSpectrum.Create;
    _cov_Hzz1[i] := TSpectrum.Create;
    _cov_Hzz2[i] := TSpectrum.Create;
    _cov_Hfxx[i] := TSpectrum.Create;
    _cov_Hfzz[i] := TSpectrum.Create;
  end;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursBuildingResult.Destroy;
begin
  _Hfxx.Free;
  _Hfzz.Free;
  _Hgebouw.Free;
  _Hxx.Free;
  _Hxz.Free;
  _Hzx.Free;
  _Hzz1.Free;
  _Hzz2.Free;

  for var i := 0 to TFrequency.size - 1 do begin
    _cov_Hxx[i].Free;
    _cov_Hxz[i].Free;
    _cov_Hzx[i].Free;
    _cov_Hzz1[i].Free;
    _cov_Hzz2[i].Free;
    _cov_Hfxx[i].Free;
    _cov_Hfzz[i].Free;
  end;
  SetLength(_cov_Hxx, 0);
  SetLength(_cov_Hxz, 0);
  SetLength(_cov_Hzx, 0);
  SetLength(_cov_Hzz1, 0);
  SetLength(_cov_Hzz2, 0);
  SetLength(_cov_Hfxx, 0);
  SetLength(_cov_Hfzz, 0);

  inherited;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursBuildingResult.SetFromOutput(output: TOursBuildingOutput);
begin
  Hfxx.AssignFromArray(output.Hfxx);
  Hfzz.AssignFromArray(output.Hfzz);
  Hgebouw.AssignFromArray(output.Hgebouw);
  Hxx.AssignFromArray(output.Hxx);
  Hxz.AssignFromArray(output.Hxz);
  Hzx.AssignFromArray(output.Hzx);
  Hzz1.AssignFromArray(output.Hzz1);
  Hzz2.AssignFromArray(output.Hzz2);

  SetLength(_cov_Hxx, Length(output.cov_Hxx));
  for var i := 0 to Length(output.cov_Hxx) - 1 do
    cov_Hxx[i].AssignFromArray(output.cov_Hxx[i]);

  SetLength(_cov_Hxz, Length(output.cov_Hxz));
  for var i := 0 to Length(output.cov_Hxz) - 1 do
    cov_Hxz[i].AssignFromArray(output.cov_Hxz[i]);

  SetLength(_cov_Hzx, Length(output.cov_Hzx));
  for var i := 0 to Length(output.cov_Hzx) - 1 do
    cov_Hzx[i].AssignFromArray(output.cov_Hzx[i]);

  SetLength(_cov_Hzz1, Length(output.cov_Hzz1));
  for var i := 0 to Length(output.cov_Hzz1) - 1 do
    cov_Hzz1[i].AssignFromArray(output.cov_Hzz1[i]);

  SetLength(_cov_Hzz2, Length(output.cov_Hzz2));
  for var i := 0 to Length(output.cov_Hzz2) - 1 do
    cov_Hzz2[i].AssignFromArray(output.cov_Hzz2[i]);

  SetLength(_cov_Hfxx, Length(output.cov_Hfxx));
  for var i := 0 to Length(output.cov_Hfxx) - 1 do
    cov_Hfxx[i].AssignFromArray(output.cov_Hfxx[i]);

  SetLength(_cov_Hfzz, Length(output.cov_Hfzz));
  for var i := 0 to Length(output.cov_Hfzz) - 1 do
    cov_Hfzz[i].AssignFromArray(output.cov_Hfzz[i]);
end;

// -------------------------------------------------------------------------------------------------

function TOursBuildingResult.AsText: string;
begin
  Result := Format('    - %-16s = ', ['Hfxx'])            + _Hfxx.AsText     + CRLF +
            Format('    - %-16s = ', ['Hfzz'])            + _Hfzz.AsText     + CRLF +
            Format('    - %-16s = ', ['Hgebouw'])         + _Hgebouw.AsText  + CRLF +
            Format('    - %-16s = ', ['Hxx'])             + _Hxx.AsText      + CRLF +
            Format('    - %-16s = ', ['Hxz'])             + _Hxz.AsText      + CRLF +
            Format('    - %-16s = ', ['Hzx'])             + _Hzx.AsText      + CRLF +
            Format('    - %-16s = ', ['Hzz1'])            + _Hzz1.AsText     + CRLF +
            Format('    - %-16s = ', ['Hzz2'])            + _Hzz2.AsText     + CRLF +
            Format('    - %-16s = [%s]', ['cov_Hxx ', _cov_Hxx[1].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxx[2].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxx[3].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxx[4].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxx[5].AsText])   + CRLF +
            Format('    - %-16s = [%s]', ['cov_Hxz ', _cov_Hxz[1].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxz[2].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxz[3].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxz[4].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hxz[5].AsText])   + CRLF +
            Format('    - %-16s = [%s]', ['cov_Hzx ', _cov_Hzx[1].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzx[2].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzx[3].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzx[4].AsText])   + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzx[5].AsText])   + CRLF +
            Format('    - %-16s = [%s]', ['cov_Hzz1', _cov_Hzz1[1].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz1[2].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz1[3].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz1[4].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz1[5].AsText])  + CRLF +
            Format('    - %-16s = [%s]', ['cov_Hzz2', _cov_Hzz2[1].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz2[2].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz2[3].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz2[4].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hzz2[5].AsText])  + CRLF +
            Format('    - %-16s = [%s]', ['cov_Hfxx', _cov_Hfxx[1].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfxx[2].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfxx[3].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfxx[4].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfxx[5].AsText])  + CRLF +
            Format('    - %-16s = [%s]', ['cov_Hfzz', _cov_Hfzz[1].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfzz[2].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfzz[3].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfzz[4].AsText])  + CRLF +
            Format('      %-16s   [%s]', ['        ', _cov_Hfzz[5].AsText])  + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursBuildingResult.ToJsonString: string;
begin
  Result := '        {'                                           + CRLF +
            '            "Hfxx":'     + Hfxx.AsJsonText     + ',' + CRLF +
            '            "Hfzz":'     + Hfzz.AsJsonText     + ',' + CRLF +
            '            "Hgebouw":'  + Hgebouw.AsJsonText  + ',' + CRLF +
            '            "Hxx":'      + Hxx.AsJsonText      + ',' + CRLF +
            '            "Hxz":'      + Hxz.AsJsonText      + ',' + CRLF +
            '            "Hzx":'      + Hzx.AsJsonText      + ',' + CRLF +
            '            "Hzz1":'     + Hzz1.AsJsonText     + ',' + CRLF +
            '            "Hzz2":'     + Hzz2.AsJsonText     + ',' + CRLF +
            '            "cov_Hfxx":['                            + CRLF +
            '                ' + cov_Hfxx[0].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfxx[1].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfxx[2].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfxx[3].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfxx[4].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfxx[5].AsJsonText           + CRLF +
            '            ],'                                      + CRLF +
            '            "cov_Hfzz":['                            + CRLF +
            '                ' + cov_Hfzz[0].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfzz[1].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfzz[2].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfzz[3].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfzz[4].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hfzz[5].AsJsonText           + CRLF +
            '            ],'                                      + CRLF +
            '            "cov_Hxx":['                             + CRLF +
            '                ' + cov_Hxx[0].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxx[1].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxx[2].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxx[3].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxx[4].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxx[5].AsJsonText            + CRLF +
            '            ],'                                      + CRLF +
            '            "cov_Hxz":['                             + CRLF +
            '                ' + cov_Hxz[0].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxz[1].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxz[2].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxz[3].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxz[4].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hxz[5].AsJsonText            + CRLF +
            '            ],'                                      + CRLF +
            '            "cov_Hzx":['                             + CRLF +
            '                ' + cov_Hzx[0].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hzx[1].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hzx[2].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hzx[3].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hzx[4].AsJsonText      + ',' + CRLF +
            '                ' + cov_Hzx[5].AsJsonText            + CRLF +
            '            ],'                                      + CRLF +
            '            "cov_Hzz1":['                            + CRLF +
            '                ' + cov_Hzz1[0].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz1[1].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz1[2].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz1[3].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz1[4].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz1[5].AsJsonText           + CRLF +
            '            ],'                                      + CRLF +
            '            "cov_Hzz2":['                            + CRLF +
            '                ' + cov_Hzz2[0].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz2[1].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz2[2].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz2[3].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz2[4].AsJsonText     + ',' + CRLF +
            '                ' + cov_Hzz2[5].AsJsonText           + CRLF +
            '            ]'                                       + CRLF +
            '        }'                                           + CRLF;
end;

// =================================================================================================

end.
