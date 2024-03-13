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
    FVariatiecoeffs: TArray<Extended>;
    FVrms_spectraalX: TArray<Extended>;
    FVrms_spectraalZ: TArray<Extended>;
    FVrms_sigma_spectraalX: TArray<Extended>;
    FVrms_sigma_spectraalZ: TArray<Extended>;
  public
    property Vrms: Extended read FVrms write FVrms;
    property Vrms_sigma: Extended read FVrms_sigma write FVrms_sigma;
    property variatiecoeffs: TArray<Extended> read FVariatiecoeffs write FVariatiecoeffs;
    property Vrms_spectraalX: TArray<Extended> read FVrms_spectraalX write FVrms_spectraalX;
    property Vrms_spectraalZ: TArray<Extended> read FVrms_spectraalZ write FVrms_spectraalZ;
    property Vrms_sigma_spectraalX: TArray<Extended> read FVrms_sigma_spectraalX write FVrms_sigma_spectraalX;
    property Vrms_sigma_spectraalZ: TArray<Extended> read FVrms_sigma_spectraalZ write FVrms_sigma_spectraalZ;

    procedure Assign(Value: TMaaiveldClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TMaaiveldClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TGebouwClass = class(TTrainClassPart)
  private
    FVmax: Extended;
    FVmax_Dir: String;
    FVmax_Fdom: String;
    FVmax_sigma: Extended;
    FVper: TArray<Extended>;
    FVper_sigma: TArray<Extended>;
    FVariatiecoeffs: TArray<Extended>;
    FVmax_gemiddeld: Extended;
    FVmax_gem_sigma: Extended;
  public
    property Vmax: Extended read FVmax write FVmax;
    property Vmax_Dir: String read FVmax_Dir write FVmax_Dir;
    property Vmax_Fdom: String read FVmax_Fdom write FVmax_Fdom;
    property Vmax_sigma: Extended read FVmax_sigma write FVmax_sigma;
    property Vper: TArray<Extended> read FVper write FVper;
    property Vper_sigma: TArray<Extended> read FVper_sigma write FVper_sigma;
    property variatiecoeffs: TArray<Extended> read FVariatiecoeffs write FVariatiecoeffs;
    property Vmax_gemiddeld: Extended read FVmax_gemiddeld write FVmax_gemiddeld;
    property Vmax_gem_sigma: Extended read FVmax_gem_sigma write FVmax_gem_sigma;

    procedure Assign(Value: TGebouwClass);

    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TGebouwClass;
  end;

//--------------------------------------------------------------------------------------------------

type
  TFunderingClass = class(TTrainClassPart)
  private
    FVmax: Extended;
    FVmax_Dir: String;
    FVmax_Fdom: String;
    FVmax_sigma: Extended;
    FVtop: Extended;
    FVtop_Dir: String;
    FVtop_Fdom: String;
    FVtop_Vd: Extended;
    FVtop_sigma: Extended;
    FVariatiecoeffs: TArray<Extended>;
    FVmax_gemiddeld: Extended;
    FVmax_gem_sigma: Extended;
  public
    property Vmax: Extended read FVmax write FVmax;
    property Vmax_Dir: String read FVmax_Dir write FVmax_Dir;
    property Vmax_Fdom: String read FVmax_Fdom write FVmax_Fdom;
    property Vmax_sigma: Extended read FVmax_sigma write FVmax_sigma;
    property Vtop: Extended read FVtop write FVtop;
    property Vtop_Dir: String read FVtop_Dir write FVtop_Dir;
    property Vtop_Fdom: String read FVtop_Fdom write FVtop_Fdom;
    property Vtop_Vd: Extended read FVtop_Vd write FVtop_Vd;
    property Vtop_sigma: Extended read FVtop_sigma write FVtop_sigma;
    property variatiecoeffs: TArray<Extended> read FVariatiecoeffs write FVariatiecoeffs;
    property Vmax_gemiddeld: Extended read FVmax_gemiddeld write FVmax_gemiddeld;
    property Vmax_gem_sigma: Extended read FVmax_gem_sigma write FVmax_gem_sigma;

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
  { @abstract(Class to read the JSON result file of the main formula.)
    Remark: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
  TOursMainOutput = class
  private
    FAlleTreinen: TTrainClass;
    FGoederen: TTrainClass;
    FReizigers: TTrainClass;
  public
    property AlleTreinen: TTrainClass read FAlleTreinen write FAlleTreinen;
    property Goederen: TTrainClass read FGoederen write FGoederen;
    property Reizigers: TTrainClass read FReizigers write FReizigers;

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
  Result := '            "Overzicht":'                   + CRLF +
            '            {'                              + CRLF +
            '                "Aantaltreinen_pw":' + Format('%.f', [Aantaltreinen_pw])+ ',' + CRLF +
            '                "Aantaltreinen_dag":' + Format('%.f', [Aantaltreinen_dag])+ ',' + CRLF +
            '                "Aantaltreinen_avond":' + Format('%.f', [Aantaltreinen_avond])+ ',' + CRLF +
            '                "Aantaltreinen_nacht":' + Format('%.f', [Aantaltreinen_nacht]) + CRLF +
            '            }'                              + CRLF;
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
  Result := '            "Maaiveld":'                                            + CRLF +
            '            {'                                                      + CRLF +
            '                "Vrms":' + Format('%.f', [Vrms]) + ','              + CRLF +
            '                "Vrms_sigma":' + Format('%.f', [Vrms_sigma])  + ',' + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(Variatiecoeffs)    + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(Variatiecoeffs) + ','   + CRLF +
            '                "Vrms_spectraal_X":' + ArrayToJSON(Vrms_spectraalX) + ','   + CRLF +
            '                "Vrms_spectraal_X":' + ArrayToJSON(Vrms_spectraalZ) + ','   + CRLF +
            '                "Vrms_sigma_spectraalX":' + ArrayToJSON(Vrms_sigma_spectraalX) + ','   + CRLF +
            '                "Vrms_sigma_spectraalZ":' + ArrayToJSON(Vrms_sigma_spectraalZ)    + CRLF +
            '            }'                                                      + CRLF;
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

  SetLength(FVariatiecoeffs, Length(Value.variatiecoeffs));
  for var i := 0 to Length(Value.Variatiecoeffs)-1 do
    FVariatiecoeffs[i] := Value.Variatiecoeffs[i];

  SetLength(FVrms_spectraalX, Length(Value.Vrms_spectraalX));
  for var i := 0 to Length(Value.Vrms_spectraalX)-1 do
    FVrms_spectraalX[i] := Value.Vrms_spectraalX[i];

  SetLength(FVrms_spectraalZ, Length(Value.Vrms_spectraalZ));
  for var i := 0 to Length(Value.Vrms_spectraalZ)-1 do
    FVrms_spectraalZ[i] := Value.Vrms_spectraalZ[i];

  SetLength(FVrms_sigma_spectraalX, Length(Value.Vrms_sigma_spectraalX));
  for var i := 0 to Length(Value.Vrms_sigma_spectraalX)-1 do
    FVrms_sigma_spectraalX[i] := Value.Vrms_sigma_spectraalX[i];

  SetLength(FVrms_sigma_spectraalZ, Length(Value.Vrms_sigma_spectraalZ));
  for var i := 0 to Length(Value.Vrms_sigma_spectraalZ)-1 do
    FVrms_sigma_spectraalZ[i] := Value.Vrms_sigma_spectraalZ[i];
end;

//==================================================================================================
// TGebouwClass
//==================================================================================================

function TGebouwClass.ToJsonString: string;
begin
  Result := '            "Gebouw":'                                             + CRLF +
            '            {'                                                     + CRLF +
            '                "Vmax_alle_treinen":' + Format('%.f', [Vmax_gemiddeld]) + ','             + CRLF +
            '                "Vmax_Sigma_alle_treinen":' + Format('%.f', [Vmax_gem_sigma]) + ','             + CRLF +
            '                "Vmax":' + Format('%.f', [Vmax]) + ','             + CRLF +
            '                "Vmax_Dir":"' + Vmax_Dir + '",'                    + CRLF +
            '                "Vmax_Fdom":"' + Vmax_Fdom + '",'                  + CRLF +
            '                "Vmax_sigma":' + Format('%.f', [Vmax_sigma]) + ',' + CRLF +
            '                "Vper":' + ArrayToJSON(Vper) + ','                 + CRLF +
            '                "Vper_sigma":' + ArrayToJSON(Vper_sigma) + ','     + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(variatiecoeffs)   + CRLF +
            '            }'                                                     + CRLF;
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
  FVmax_gemiddeld := Value.Vmax_gemiddeld;
  FVmax_gem_sigma := Value.Vmax_gem_sigma;
  FVmax := Value.Vmax;
  FVmax_Dir := Value.Vmax_Dir;
  FVmax_Fdom := Value.Vmax_Fdom;
  FVmax_sigma := Value.Vmax_sigma;

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
  Result := '            "Fundering":'                                          + CRLF +
            '            {'                                                     + CRLF +
            '                "Vmax_alle_treinen":' + Format('%.f', [Vmax_gemiddeld]) + ','             + CRLF +
            '                "Vmax_Sigma_alle_treinen":' + Format('%.f', [Vmax_gem_sigma]) + ','             + CRLF +
            '                "Vmax":' + Format('%.f', [Vmax]) + ','             + CRLF +
            '                "Vmax_Dir":"' + Vmax_Dir + '",'                    + CRLF +
            '                "Vmax_Fdom":"' + Vmax_Fdom + '",'                  + CRLF +
            '                "Vmax_sigma":' + Format('%.f', [Vmax_sigma]) + ',' + CRLF +
            '                "Vtop":' + Format('%.f', [Vtop]) + ','             + CRLF +
            '                "Vtop_Dir":"' + Vtop_Dir + '",'                    + CRLF +
            '                "Vtop_Fdom":"' + Vtop_Fdom + '",'                  + CRLF +
            '                "Vtop_Vd":' + Format('%.f', [Vtop_Vd]) + ','       + CRLF +
            '                "Vtop_sigma":' + Format('%.f', [Vtop_sigma]) + ',' + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(variatiecoeffs)   + CRLF +
            '            }'                                                     + CRLF;
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

  FVmax_gemiddeld := Value.Vmax_gemiddeld;
  FVmax_gem_sigma := Value.Vmax_gem_sigma;
  FVmax := Value.Vmax;
  FVmax_Dir := Value.Vmax_Dir;
  FVmax_Fdom := Value.Vmax_Fdom;
  FVmax_sigma := Value.Vmax_sigma;
  FVtop := Value.Vtop;
  FVtop_Dir := Value.Vtop_Dir;
  FVtop_Fdom := Value.Vtop_Fdom;
  FVtop_Vd := Value.Vtop_Vd;
  FVtop_sigma := Value.Vtop_sigma;

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
  Result := FOverzicht.ToJsonString +
            FFundering.ToJsonString +
            FGebouw.ToJsonString +
            FMaaiveld.ToJsonString;
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
  FAlleTreinen := TTrainClass.Create();
  FGoederen := TTrainClass.Create();
  FReizigers := TTrainClass.Create();
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
  Result := '    {'                     + CRLF +
            '        "AlleTreinen":'    + CRLF +
            '        {'                 + CRLF +
            FAlleTreinen.ToJsonString +
            '        },'                + CRLF +
            '        "Goederen":'       + CRLF +
            '        {'                 + CRLF +
            FGoederen.ToJsonString +
            '        },'                + CRLF +
            '        "Reizigers":'      + CRLF +
            '        {'                 + CRLF +
            FReizigers.ToJsonString +
            '        }'                 + CRLF +
            '    }'                     + CRLF;
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
