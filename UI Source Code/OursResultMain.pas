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
  TMaaiveldClass = class(TTrainClassPart)
  private
    FVrms: Extended;
    FVrms_sigma: Extended;
    FVariatiecoeffs: TArray<Extended>;
  public
    property Vrms: Extended read FVrms write FVrms;
    property Vrms_sigma: Extended read FVrms_sigma write FVrms_sigma;
    property variatiecoeffs: TArray<Extended> read FVariatiecoeffs write FVariatiecoeffs;

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
  public
    property Vmax: Extended read FVmax write FVmax;
    property Vmax_Dir: String read FVmax_Dir write FVmax_Dir;
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
    FVmax_Dir: String;
    FVmax_Fdom: String;
    FVmax_sigma: Extended;
    FVtop: Extended;
    FVtop_Dir: String;
    FVtop_Fdom: String;
    FVtop_Vd: Extended;
    FVtop_sigma: Extended;
    FVariatiecoeffs: TArray<Extended>;
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
// TMaaiveldClass
//==================================================================================================

function TMaaiveldClass.ToJsonString: string;
begin
  Result := '            "Maaiveld":'                                            + CRLF +
            '            {'                                                      + CRLF +
            '                "Vrms":' + Format('%.f', [Vrms]) + ','              + CRLF +
            '                "Vrms_sigma":' + Format('%.f', [Vrms_sigma])  + ',' + CRLF +
            '                "variatiecoeffs":' + ArrayToJSON(Variatiecoeffs)    + CRLF +
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
end;

//==================================================================================================
// TGebouwClass
//==================================================================================================

function TGebouwClass.ToJsonString: string;
begin
  Result := '            "Gebouw":'                                             + CRLF +
            '            {'                                                     + CRLF +
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
  FFundering := TFunderingClass.Create();
  FGebouw := TGebouwClass.Create();
  FMaaiveld := TMaaiveldClass.Create();
end;

//--------------------------------------------------------------------------------------------------

destructor TTrainClass.Destroy;
begin
  FFundering.Free;
  FGebouw.Free;
  FMaaiveld.Free;
  inherited;
end;

//--------------------------------------------------------------------------------------------------

function TTrainClass.ToJsonString: string;
begin
  Result := FFundering.ToJsonString +
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
