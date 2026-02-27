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
    FVrms: Extended;
    FVrms_sigma: Extended;
    FMaatgevende_cat: String;
    FVariatiecoeffs: TArray<Extended>;
    FVrms_spectraal: TArray<Extended>;
    FVrms_sigma_spectraal: TArray<Extended>;
  public
    property Vrms: Extended read FVrms write FVrms;
    property Vrms_sigma: Extended read FVrms_sigma write FVrms_sigma;
    property Maatgevende_cat: String read FMaatgevende_cat write FMaatgevende_cat;
    property variatiecoeffs: TArray<Extended> read FVariatiecoeffs write FVariatiecoeffs;
    property Vrms_spectraal: TArray<Extended> read FVrms_spectraal write FVrms_spectraal;
    property Vrms_sigma_spectraal: TArray<Extended> read FVrms_sigma_spectraal write FVrms_sigma_spectraal;

    procedure Assign(Value: TMaaiveldClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TMaaiveldClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TGebouwClass = class(TTrainClassPart)
  private
    FVmax: Extended;
    FVmax_Fdom: String;
    FVmax_sigma: Extended;
    FMaatgevende_cat: String;
    FVper: TArray<Extended>;
    FVper_sigma: TArray<Extended>;
    FVariatiecoeffs: TArray<Extended>;
  public
    property Vmax: Extended read FVmax write FVmax;
    property Maatgevende_cat: STring read FMaatgevende_cat write FMaatgevende_cat;
    property Vmax_Fdom: String read FVmax_Fdom write FVmax_Fdom;
    property Vmax_sigma: Extended read FVmax_sigma write FVmax_sigma;
    property Vper: TArray<Extended> read FVper write FVper;
    property Vper_sigma: TArray<Extended> read FVper_sigma write FVper_sigma;
    property variatiecoeffs: TArray<Extended> read FVariatiecoeffs write FVariatiecoeffs;

    procedure Assign(Value: TGebouwClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TGebouwClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TFunderingClass = class(TTrainClassPart)
  private
    FVmax: Extended;
    FVmax_Fdom: String;
    FVmax_sigma: Extended;
    FMaatgevende_cat: String;
    FVtop: Extended;
    FVtop_Fdom: String;
    FVtop_Vd: Extended;
    FVtop_sigma: Extended;
    FVariatiecoeffs: TArray<Extended>;
  public
    property Vmax: Extended read FVmax write FVmax;
    property Vmax_Fdom: String read FVmax_Fdom write FVmax_Fdom;
    property Vmax_sigma: Extended read FVmax_sigma write FVmax_sigma;
    property Maatgevende_cat: String read FMaatgevende_cat write FMaatgevende_cat;
    property Vtop: Extended read FVtop write FVtop;
    property Vtop_Fdom: String read FVtop_Fdom write FVtop_Fdom;
    property Vtop_Vd: Extended read FVtop_Vd write FVtop_Vd;
    property Vtop_sigma: Extended read FVtop_sigma write FVtop_sigma;
    property variatiecoeffs: TArray<Extended> read FVariatiecoeffs write FVariatiecoeffs;

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
    FOverzicht: TOverzichtClass;
  public
    property Fundering: TFunderingClass read FFundering write FFundering;
    property Gebouw: TGebouwClass read FGebouw write FGebouw;
    property Maaiveld: TMaaiveldClass read FMaaiveld write FMaaiveld;
    property Overzicht: TOverzichtClass read FOverzicht write FOverzicht;

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

    Result := Result + Format('%.f', [AnArray[i]]);
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
    '    "Aantaltreinen_pw":' + Format('%f', [Aantaltreinen_pw]) + ',' + CRLF +
    '    "Aantaltreinen_dag":' + Format('%f', [Aantaltreinen_dag]) + ',' + CRLF +
    '    "Aantaltreinen_avond":' + Format('%f', [Aantaltreinen_avond]) + ',' + CRLF +
    '    "Aantaltreinen_nacht":' + Format('%f', [Aantaltreinen_nacht]) + CRLF +
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
  Result := '            "Maaiveld":'                                                             + CRLF +
            '            {'                                                                       + CRLF +
            '                "Vrms":' + Format('%.f', [Vrms]) + ','                               + CRLF +
            '                "Vrms_sigma":' + Format('%.f', [Vrms_sigma])  + ','                  + CRLF +
            '                "maatgevende_cat":' + Maatgevende_cat  + ','                         + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(Variatiecoeffs)                     + CRLF +
            '                "Vrms_spectraal":' + ArrayToJSON(Vrms_spectraal) + ','               + CRLF +
            '                "Vrms_sigma_spectraal":' + ArrayToJSON(Vrms_sigma_spectraal)         + CRLF +
            '            }'                                                                       + CRLF;
end;


//--------------------------------------------------------------------------------------------------

class function TMaaiveldClass.FromJsonString(AJsonString: string): TMaaiveldClass;
begin
  Result := TJson.JsonToObject<TMaaiveldClass>(AJsonString)
end;

//--------------------------------------------------------------------------------------------------

procedure TMaaiveldClass.Assign(Value: TMaaiveldClass);
begin
  if not Assigned(Value) then
    Exit;

  FVrms := Value.Vrms;
  FVrms_sigma := Value.Vrms_sigma;
  FMaatgevende_cat := Value.Maatgevende_cat;

  SetLength(FVariatiecoeffs, Length(Value.variatiecoeffs));
  for var i := 0 to Length(Value.Variatiecoeffs)-1 do
    FVariatiecoeffs[i] := Value.Variatiecoeffs[i];

  SetLength(FVrms_spectraal, Length(Value.Vrms_spectraal));
  for var i := 0 to Length(Value.Vrms_spectraal)-1 do
    FVrms_spectraal[i] := Value.Vrms_spectraal[i];

  SetLength(FVrms_sigma_spectraal, Length(Value.Vrms_sigma_spectraal));
  for var i := 0 to Length(Value.Vrms_sigma_spectraal)-1 do
    FVrms_sigma_spectraal[i] := Value.Vrms_sigma_spectraal[i];

end;

//==================================================================================================
// TGebouwClass
//==================================================================================================

function TGebouwClass.ToJsonString: string;
begin
  Result := '            "Gebouw":'                                                              + CRLF +
            '            {'                                                                      + CRLF +
            '                "Vmax":' + Format('%.f', [Vmax]) + ','                              + CRLF +
            '                "Vmax_sigma":' + Format('%.f', [Vmax_sigma]) + ','                  + CRLF +
            '                "Vmax_Fdom":"' + Vmax_Fdom + '",'                                   + CRLF +
            '                "maatgevende_cat":' + Maatgevende_cat  + ','                        + CRLF +
            '                "Vper":' + ArrayToJSON(Vper) + ','                                  + CRLF +
            '                "Vper_sigma":' + ArrayToJSON(Vper_sigma) + ','                      + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(variatiecoeffs)                    + CRLF +
            '            }'                                                                      + CRLF;
end;

//--------------------------------------------------------------------------------------------------

class function TGebouwClass.FromJsonString(AJsonString: string): TGebouwClass;
begin
  Result := TJson.JsonToObject<TGebouwClass>(AJsonString)
end;

//--------------------------------------------------------------------------------------------------

procedure TGebouwClass.Assign(Value: TGebouwClass);
begin
  if not Assigned(Value) then
    Exit;
  FVmax := Value.Vmax;
  FVmax_Fdom := Value.Vmax_Fdom;
  FVmax_sigma := Value.Vmax_sigma;
  FMaatgevende_cat := Value.Maatgevende_cat;

  SetLength(FVper, Length(Value.Vper));
  for var i := 0 to Length(Value.Vper)-1 do
    FVper[i] := Value.Vper[i];

  SetLength(FVper_sigma, Length(Value.Vper_sigma));
  for var i := 0 to Length(Value.Vper_sigma)-1 do
    FVper_sigma[i] := Value.Vper_sigma[i];

  SetLength(FVariatiecoeffs, Length(Value.Variatiecoeffs));
  for var i := 0 to Length(Value.Variatiecoeffs)-1 do
    FVariatiecoeffs[i] := Value.Variatiecoeffs[i];
end;

//==================================================================================================
// TFunderingClass
//==================================================================================================

function TFunderingClass.ToJsonString: string;
begin
  Result := '            "Fundering":'                                                            + CRLF +
            '            {'                                                                       + CRLF +
            '                "Vmax":' + Format('%.f', [Vmax]) + ','                               + CRLF +
            '                "Vmax_sigma":' + Format('%.f', [Vmax_sigma]) + ','                   + CRLF +
            '                "Vmax_Fdom":"' + Vmax_Fdom + '",'                                    + CRLF +
            '                "maatgevende_cat":' + Maatgevende_cat  + ','                         + CRLF +
            '                "Vtop":' + Format('%.f', [Vtop]) + ','                               + CRLF +
            '                "Vtop_sigma":' + Format('%.f', [Vtop_sigma]) + ','                   + CRLF +
            '                "Vtop_Fdom":"' + Vtop_Fdom + '",'                                    + CRLF +
            '                "Vtop_Vd":' + Format('%.f', [Vtop_Vd]) + ','                         + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(variatiecoeffs)                     + CRLF +
            '            }'                                                                       + CRLF;
end;


//--------------------------------------------------------------------------------------------------

class function TFunderingClass.FromJsonString(AJsonString: string): TFunderingClass;
begin
  Result := TJson.JsonToObject<TFunderingClass>(AJsonString)
end;

//--------------------------------------------------------------------------------------------------

procedure TFunderingClass.Assign(Value: TFunderingClass);
begin
  if not Assigned(Value) then
    Exit;

  FVmax := Value.Vmax;
  FVmax_Fdom := Value.Vmax_Fdom;
  FVmax_sigma := Value.Vmax_sigma;
  FVtop := Value.Vtop;
  FVtop_Fdom := Value.Vtop_Fdom;
  FVtop_Vd := Value.Vtop_Vd;
  FVtop_sigma := Value.Vtop_sigma;
  FMaatgevende_cat := Value.Maatgevende_cat;

  SetLength(FVariatiecoeffs, Length(Value.variatiecoeffs));
  for var i := 0 to Length(Value.Variatiecoeffs)-1 do
    FVariatiecoeffs[i] := Value.Variatiecoeffs[i];
end;

//==================================================================================================
// TTrainClass
//==================================================================================================

constructor TTrainClass.Create;
begin
  inherited;
  FOverzicht := TOverzichtClass.Create();
  FFundering := TFunderingClass.Create();
  FGebouw := TGebouwClass.Create();
  FMaaiveld := TMaaiveldClass.Create();
end;

//--------------------------------------------------------------------------------------------------

destructor TTrainClass.Destroy;
begin

  FOverzicht.Free;
  FFundering.Free;
  FGebouw.Free;
  FMaaiveld.Free;
  inherited;
end;

//--------------------------------------------------------------------------------------------------

function TTrainClass.ToJsonString: string;
begin
  Result :=
    FMaaiveld.ToJsonString +
    FFundering.ToJsonString +
    FGebouw.ToJsonString;
end;

//--------------------------------------------------------------------------------------------------

class function TTrainClass.FromJsonString(AJsonString: string): TTrainClass;
begin
  result := TJson.JsonToObject<TTrainClass>(AJsonString)
end;

//--------------------------------------------------------------------------------------------------

procedure TTrainClass.Assign(Value: TTrainClass);
begin
  if not Assigned(Value) then
    Exit;

  FOverzicht.Assign(Value.Overzicht);
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
    '    "X-richting": {' + CRLF +
    FX.ToJsonString + CRLF +
    '    },' + CRLF +
    '    "Z-richting": {' + CRLF +
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
