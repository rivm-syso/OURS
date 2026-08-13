{ @abstract(This unit classes for output and storage of the main formula.)
  Code created with the help of: https://jsontodelphi.com/
}
unit OursResultMain;

interface

uses
  Generics.Collections,
  Rest.Json;

//--------------------------------------------------------------------------------------------------

type
  TTrainClassPart = class
  private
    function ArrayToJSON(AnArray: TArray<Extended>): string;
  end;

//--------------------------------------------------------------------------------------------------


type
  TOverzichtClass = class(TTrainClassPart)
  private
    FAantaltreinen_pw: Extended;
    FAantaltreinen_dag: Extended;
    FAantaltreinen_avond: Extended;
    FAantaltreinen_nacht: Extended;
  public
    property Aantaltreinen_pw: Extended read FAantaltreinen_pw write FAantaltreinen_pw;
    property Aantaltreinen_dag: Extended read FAantaltreinen_dag write FAantaltreinen_dag;
    property Aantaltreinen_avond: Extended read FAantaltreinen_avond write FAantaltreinen_avond;
    property Aantaltreinen_nacht: Extended read FAantaltreinen_nacht write FAantaltreinen_nacht;

    procedure Assign(Value: TOverzichtClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TOverzichtClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TMaaiveldClass = class(TTrainClassPart)
  private
    FVrms_50: Extended;
    FVrms_p: Extended;
    FMaatgevende_cat: String;
    FVrms_spectraal_50: TArray<Extended>;
  public
    property Vrms_50: Extended read FVrms_50 write FVrms_50;
    property Vrms_p: Extended read FVrms_p write FVrms_p;
    property Maatgevende_cat: String read FMaatgevende_cat write FMaatgevende_cat;
    property Vrms_spectraal_50: TArray<Extended> read FVrms_spectraal_50 write FVrms_spectraal_50;

    procedure Assign(Value: TMaaiveldClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TMaaiveldClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TGebouwClass = class(TTrainClassPart)
  private
    FVmax_50: Extended;
    FVmax_p: Extended;
    FVmax_Fdom: String;
    FMaatgevende_cat: String;
    FVper_50: TArray<Extended>;
    FVper_p: TArray<Extended>;
  public
    property Vmax_50: Extended read FVmax_50 write FVmax_50;
    property Vmax_p: Extended read FVmax_p write FVmax_p;
    property Vmax_Fdom: String read FVmax_Fdom write FVmax_Fdom;
    property Maatgevende_cat: String read FMaatgevende_cat write FMaatgevende_cat;
    property Vper_50: TArray<Extended> read FVper_50 write FVper_50;
    property Vper_p: TArray<Extended> read FVper_p write FVper_p;

    procedure Assign(Value: TGebouwClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TGebouwClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TFunderingClass = class(TTrainClassPart)
  private
    FVmax_50: Extended;
    FVmax_p: Extended;
    FMaatgevende_cat: String;
    FVmax_Fdom: String;
    FVtop_50: Extended;
    FVtop_p: Extended;
    FVtop_Fdom: String;
    FVtop_Vd: Extended;
  public
    property Vmax_50: Extended read FVmax_50 write FVmax_50;
    property Vmax_p: Extended read FVmax_p write FVmax_p;
    property Maatgevende_cat: String read FMaatgevende_cat write FMaatgevende_cat;
    property Vmax_Fdom: String read FVmax_Fdom write FVmax_Fdom;
    property Vtop_50: Extended read FVtop_50 write FVtop_50;
    property Vtop_p: Extended read FVtop_p write FVtop_p;
    property Vtop_Fdom: String read FVtop_Fdom write FVtop_Fdom;
    property Vtop_Vd: Extended read FVtop_Vd write FVtop_Vd;

    procedure Assign(Value: TFunderingClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TFunderingClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TTrainClass = class
  private
    FFundering: TFunderingClass;
    FGebouw: TGebouwClass;
    FMaaiveld: TMaaiveldClass;
  public
    property Fundering: TFunderingClass read FFundering write FFundering;
    property Gebouw: TGebouwClass read FGebouw write FGebouw;
    property Maaiveld: TMaaiveldClass read FMaaiveld write FMaaiveld;

    constructor Create;
    destructor Destroy; override;

    procedure Assign(Value: TTrainClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TTrainClass;
  end;
//--------------------------------------------------------------------------------------------------
type
  TTrainDirections = class
  private
    FX: TTrainClass;
    FZ: TTrainClass;
    FOverzicht: TOverzichtClass;
  public
    property X: TTrainClass read FX write FX;
    property Z: TTrainClass read FZ write FZ;
    property Overzicht: TOverzichtClass read FOverzicht write FOverzicht;

    constructor Create;
    destructor Destroy; override;

    procedure Assign(Value: TTrainDirections);

    function ToJsonString: string;
  end;

type
  { @abstract(Class to read the JSON result file of the main formula.)
    Remark: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
  TOursMainOutput = class
  private
    FAlleTreinen: TTrainDirections;
    FGoederen: TTrainDirections;
    FReizigers: TTrainDirections;
  public
    property AlleTreinen: TTrainDirections  read FAlleTreinen write FAlleTreinen;
    property Goederen: TTrainDirections  read FGoederen write FGoederen;
    property Reizigers: TTrainDirections  read FReizigers write FReizigers;

    constructor Create;
    destructor Destroy; override;

    procedure CopyFromJsonString(AJsonString: string);
    procedure Assign(Value: TOursMainOutput);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TOursMainOutput;

    function AsText: string;
end;


//--------------------------------------------------------------------------------------------------

implementation

uses
  SysUtils,
  OursUtils,
  OursStrings;

//==================================================================================================
// TTrainClassPart
//==================================================================================================

function TTrainClassPart.ArrayToJSON(AnArray: TArray<Extended>): string;
begin
  Result := '';
  for var i := 0 to Length(AnArray)-1 do begin
    if Result<>'' then
      Result := Result + ', '
    else
      Result := '[';

    Result := Result + Format('%.6f', [AnArray[i]]);
  end;
  Result := Result + ']';
end;

//==================================================================================================
// TOverzichtClass
//==================================================================================================

function TOverzichtClass.ToJsonString: string;
begin
  Result :=
    '{' + CRLF +
    '    "AantalTreinen_pw":' + Format('%.6f', [Aantaltreinen_pw]) + ',' + CRLF +
    '    "AantalTreinen_dag":' + Format('%.6f', [Aantaltreinen_dag]) + ',' + CRLF +
    '    "AantalTreinen_avond":' + Format('%.6f', [Aantaltreinen_avond]) + ',' + CRLF +
    '    "AantalTreinen_nacht":' + Format('%.6f', [Aantaltreinen_nacht]) + CRLF +
    '}';
end;

//--------------------------------------------------------------------------------------------------
class function TOverzichtClass.FromJsonString(AJsonString: string): TOverzichtClass;
begin
  Result := TJson.JsonToObject<TOverzichtClass>(AJsonString)
end;

//--------------------------------------------------------------------------------------------------

procedure TOverzichtClass.Assign(Value: TOverzichtClass);
begin
  if not Assigned(Value) then
    Exit;

    FAantaltreinen_pw := Value.Aantaltreinen_pw;
    FAantaltreinen_dag := Value.Aantaltreinen_dag;
    FAantaltreinen_avond := Value.Aantaltreinen_avond;
    FAantaltreinen_nacht := Value.Aantaltreinen_nacht;
end;

//==================================================================================================
// TMaaiveldClass
//==================================================================================================

function TMaaiveldClass.ToJsonString: string;
begin
  Result :=
    '            "Maaiveld":' + CRLF +
    '            {' + CRLF +
    '                "Vrms_50": ' + Format('%.6f', [Vrms_50]) + ',' + CRLF +
    '                "Vrms_p": ' + Format('%.6f', [Vrms_p]) + ',' + CRLF +
    '                "Maatgevende_cat": "' + Maatgevende_cat + '",' + CRLF +
    '                "Vrms_spectraal_50": ' + ArrayToJSON(Vrms_spectraal_50) + CRLF +
    '            }' + CRLF;
end;

class function TMaaiveldClass.FromJsonString(AJsonString: string): TMaaiveldClass;
begin
  Result := TJson.JsonToObject<TMaaiveldClass>(AJsonString)
end;

procedure TMaaiveldClass.Assign(Value: TMaaiveldClass);
begin
  if not Assigned(Value) then
    Exit;

  FVrms_50         := Value.Vrms_50;
  FVrms_p          := Value.Vrms_p;
  FMaatgevende_cat := Value.Maatgevende_cat;

  SetLength(FVrms_spectraal_50, Length(Value.Vrms_spectraal_50));
  for var i := 0 to Length(Value.Vrms_spectraal_50) - 1 do
    FVrms_spectraal_50[i] := Value.Vrms_spectraal_50[i];
end;

//==================================================================================================
// TGebouwClass
//==================================================================================================

function TGebouwClass.ToJsonString: string;
begin
  Result :=
    '            "Gebouw":' + CRLF +
    '            {' + CRLF +
    '                "Vmax_50": ' + Format('%.6f', [Vmax_50]) + ',' + CRLF +
    '                "Vmax_p": ' + Format('%.6f', [Vmax_p]) + ',' + CRLF +
    '                "Vmax_Fdom": "' + Vmax_Fdom + '",' + CRLF +
    '                "Maatgevende_cat": "' + Maatgevende_cat + '",' + CRLF +
    '                "Vper_50": ' + ArrayToJSON(Vper_50) + ',' + CRLF +
    '                "Vper_p": ' + ArrayToJSON(Vper_p) + CRLF +
    '            }' + CRLF;
end;

class function TGebouwClass.FromJsonString(AJsonString: string): TGebouwClass;
begin
  Result := TJson.JsonToObject<TGebouwClass>(AJsonString)
end;

procedure TGebouwClass.Assign(Value: TGebouwClass);
begin
  if not Assigned(Value) then
    Exit;

  FVmax_50         := Value.Vmax_50;
  FVmax_p          := Value.Vmax_p;
  FVmax_Fdom       := Value.Vmax_Fdom;
  FMaatgevende_cat := Value.Maatgevende_cat;

  SetLength(FVper_50, Length(Value.Vper_50));
  for var i := 0 to Length(Value.Vper_50) - 1 do
    FVper_50[i] := Value.Vper_50[i];

  SetLength(FVper_p, Length(Value.Vper_p));
  for var i := 0 to Length(Value.Vper_p) - 1 do
    FVper_p[i] := Value.Vper_p[i];
end;

//==================================================================================================
// TFunderingClass
//==================================================================================================

function TFunderingClass.ToJsonString: string;
begin
  Result :=
    '            "Fundering":' + CRLF +
    '            {' + CRLF +
    '                "Vmax_50": ' + Format('%.6f', [Vmax_50]) + ',' + CRLF +
    '                "Vmax_p": ' + Format('%.6f', [Vmax_p]) + ',' + CRLF +
    '                "Vmax_Fdom": "' + Vmax_Fdom + '",' + CRLF +
    '                "Maatgevende_cat": "' + Maatgevende_cat + '",' + CRLF +
    '                "Vtop_50": ' + Format('%.6f', [Vtop_50]) + ',' + CRLF +
    '                "Vtop_p": ' + Format('%.6f', [Vtop_p]) + ',' + CRLF +
    '                "Vtop_Fdom": "' + Vtop_Fdom + '",' + CRLF +
    '                "Vtop_Vd": ' + Format('%.6f', [Vtop_Vd]) + CRLF +
    '            }' + CRLF;
end;

class function TFunderingClass.FromJsonString(AJsonString: string): TFunderingClass;
begin
  Result := TJson.JsonToObject<TFunderingClass>(AJsonString)
end;

procedure TFunderingClass.Assign(Value: TFunderingClass);
begin
  if not Assigned(Value) then
    Exit;

  FVmax_50         := Value.Vmax_50;
  FVmax_p          := Value.Vmax_p;
  FVmax_Fdom       := Value.Vmax_Fdom;
  FMaatgevende_cat := Value.Maatgevende_cat;
  FVtop_50         := Value.Vtop_50;
  FVtop_p          := Value.Vtop_p;
  FVtop_Fdom       := Value.Vtop_Fdom;
  FVtop_Vd         := Value.Vtop_Vd;
end;

//==================================================================================================
// TTrainClass
//==================================================================================================

constructor TTrainClass.Create;
begin
  inherited;
  FFundering := TFunderingClass.Create;
  FGebouw := TGebouwClass.Create;
  FMaaiveld := TMaaiveldClass.Create;
end;

destructor TTrainClass.Destroy;
begin
  FFundering.Free;
  FGebouw.Free;
  FMaaiveld.Free;
  inherited;
end;

function TTrainClass.ToJsonString: string;
begin
  Result :=
    FMaaiveld.ToJsonString +
    FFundering.ToJsonString +
    FGebouw.ToJsonString;
end;

class function TTrainClass.FromJsonString(AJsonString: string): TTrainClass;
begin
  Result := TJson.JsonToObject<TTrainClass>(AJsonString)
end;

procedure TTrainClass.Assign(Value: TTrainClass);
begin
  if not Assigned(Value) then
    Exit;

  FFundering.Assign(Value.Fundering);
  FGebouw.Assign(Value.Gebouw);
  FMaaiveld.Assign(Value.Maaiveld);
end;

//==================================================================================================
// TTrainDirections
//==================================================================================================

procedure TTrainDirections.Assign(Value: TTrainDirections);
begin
  if not Assigned(Value) then Exit;
  FX.Assign(Value.X);
  FZ.Assign(Value.Z);
  FOverzicht.Assign(Value.Overzicht);
end;

//--------------------------------------------------------------------------------------------------

constructor TTrainDirections.Create;
begin
  inherited;
  FX := TTrainClass.Create;
  FZ := TTrainClass.Create;
  FOverzicht := TOverzichtClass.Create;
end;

//--------------------------------------------------------------------------------------------------

destructor TTrainDirections.Destroy;
begin
  FX.Free;
  FZ.Free;
  FOverzicht.Free;
  inherited;
end;

//--------------------------------------------------------------------------------------------------

function TTrainDirections.ToJsonString: string;
begin
  Result :=
    '    "Overzicht": ' + FOverzicht.ToJsonString + ',' + CRLF +
    '    "X-Richting": {' + CRLF +
    FX.ToJsonString + CRLF +
    '    },' + CRLF +
    '    "Z-Richting": {' + CRLF +
    FZ.ToJsonString + CRLF +
    '    }';
end;

//==================================================================================================
// TOursMainOutput
//==================================================================================================

function TOursMainOutput.AsText: string;
begin
  Result := ToJsonString + CRLF;
end;

//--------------------------------------------------------------------------------------------------

constructor TOursMainOutput.Create;
begin
  inherited;
  FAlleTreinen := TTrainDirections.Create;
  FGoederen := TTrainDirections.Create;
  FReizigers := TTrainDirections.Create;
end;

//--------------------------------------------------------------------------------------------------

destructor TOursMainOutput.Destroy;
begin
  FAlleTreinen.Free;
  FGoederen.Free;
  FReizigers.Free;
  inherited;
end;

//--------------------------------------------------------------------------------------------------

function TOursMainOutput.ToJsonString: string;
begin
  Result :=
    '{' + CRLF +
    '  "AlleTreinen": {' + CRLF +
    FAlleTreinen.ToJsonString + CRLF +
    '  },' + CRLF +
    '  "Goederen": {' + CRLF +
    FGoederen.ToJsonString + CRLF +
    '  },' + CRLF +
    '  "Reizigers": {' + CRLF +
    FReizigers.ToJsonString + CRLF +
    '  }' + CRLF +
    '}';
end;
//--------------------------------------------------------------------------------------------------

procedure TOursMainOutput.CopyFromJsonString(AJsonString: string);
begin
  var tmp := TOursMainOutput.FromJsonString(AJsonString);
  Self.Assign(tmp);
  tmp.Free;
end;

//--------------------------------------------------------------------------------------------------

procedure TOursMainOutput.Assign(Value: TOursMainOutput);
begin
  FAlleTreinen.Assign(Value.AlleTreinen);
  FGoederen.Assign(Value.Goederen);
  FReizigers.Assign(Value.Reizigers);
end;

//--------------------------------------------------------------------------------------------------

class function TOursMainOutput.FromJsonString(AJsonString: string): TOursMainOutput;
begin
  result := TJson.JsonToObject<TOursMainOutput>(AJsonString)
end;

//==================================================================================================

end.
