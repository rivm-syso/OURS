{ @abstract(This unit classes for output and storage of the ground module (CPT-tool).)
}
unit OursResultGround;

interface

uses
  Generics.Collections,
  Rest.Json;

// -------------------------------------------------------------------------------------------------

type
  { @abstract(Class for reading and storing the data for a ground scenario.)
    Remark: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
  TOursGroundOutputData = class
  private
    FLithology: TArray<String>;
    FDepth: TArray<Extended>;
    FE: TArray<Extended>;
    FV: TArray<Extended>;
    FRho: TArray<Extended>;
    FDamping: TArray<Extended>;

    FVar_depth: TArray<Extended>;
    FVar_E: TArray<Extended>;
    FVar_v: TArray<Extended>;
    FVar_rho: TArray<Extended>;
    FVar_damping: TArray<Extended>;

    { @abstract(Converts an array of floats to a text string.)
      The result starts with <prefix>. The values are separated by a semicolon. @br
      The number of decimals is given by <decCnt> and the point is used as decimal separator.
    }
    function ArrayAsText(prefix: string; anArray: TArray<Extended>; DecCnt: Integer): string; overload;

    { @abstract(Converts an array of floats to a text string.)
      The result starts with <prefix>. The values are separated by a semicolon. @br
      The point is used as decimal separator.
    }
    function ArrayAsText(prefix: string; anArray: TArray<String>): string; overload;

    { @abstract(Converts an array of strings to a JSON string.)
      The result starts with 8 spaces followed by the prefix. The values are separated by a comma. @br
      The values from the array are enclosed in brackets and all texts are within double quotes. @br
      If includeLastComma is True an comma will be added to the result.
    }
    function ArrayToJson(prefix: string; anArray: TArray<string>; includeLastComma: Boolean): string; overload;

    { @abstract(Converts an array of floats to a JSON string.)
      The result starts with 8 spaces followed by the prefix. The values are separated by a comma. @br
      The point is used as decimal separator. The values from the array are enclosed in brackets and
      at least 1 value will contain a decimal seperator (to prevent issues with the FEM script). @br
      If includeLastComma is True an comma will be added to the result.
    }
    function ArrayToJson(prefix: string; anArray: TArray<Extended>; ensureFloat, includeLastComma: Boolean): string; overload;
  public
    property lithology: TArray<String> read FLithology write FLithology;
    property depth: TArray<Extended> read FDepth write FDepth;
    property E: TArray<Extended> read FE write FE;
    property v: TArray<Extended> read FV write FV;
    property rho: TArray<Extended> read FRho write FRho;
    property damping: TArray<Extended> read FDamping write FDamping;

    property var_depth: TArray<Extended> read FVar_depth write FVar_depth;
    property var_E: TArray<Extended> read FVar_E write FVar_E;
    property var_v: TArray<Extended> read FVar_v write FVar_v;
    property var_rho: TArray<Extended> read FVar_rho write FVar_rho;
    property var_damping: TArray<Extended> read FVar_damping write FVar_damping;

    { @abstract(Converts the data to a JSON string suitable for the FEM-calculation.)
      The FEM script does not accept an array of numbers without at least one value with a decimal
      separator. This routine will ensure at least one value has a decimal separator.
    }
    function ToJsonForFem: string;

    { @abstract(Converts the data to a JSON string.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Converts the data to a text string.)
    }
    function AsText: string;

    { @abstract(Creates an instance of the class and fills it with data read from the given JSON string.)
    }
    class function FromJsonString(AJsonString: string): TOursGroundOutputData;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class for reading and storing the ground properties for a scenario.)
    Remark: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
  TOursGroundOutputScenario = class
  private
    FName: String;
    FProbability: Double;
    FData: TOursGroundOutputData;
    FCoordinates: TArray<Extended>;
  public
    property Name: String read FName write FName;
    property data: TOursGroundOutputData read FData write FData;
    property probability: Double read FProbability write FProbability;
    property coordinates: TArray<Extended> read FCoordinates write FCoordinates;

    { @abstract(Constructor)
    }
    constructor Create;
    { @abstract(Destructor)
    }
    destructor Destroy; override;

    { @abstract(Converts the data to a JSON string.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Converts the data to a readable text string.)
    }
    function AsText: string;

    { @abstract(Creates an instance of the class and fills it with data read from the given JSON string.)
    }
    class function FromJsonString(AJsonString: string): TOursGroundOutputScenario;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class for reading and storing the ground properties.)
    Remark: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
  TOursGroundOutput = class
  private
    FScenarios: TArray<TOursGroundOutputScenario>;
  public
    { @abstract(List of the scenarios with ground properties.)
    }
    property scenarios: TArray<TOursGroundOutputScenario> read FScenarios write FScenarios;

    { @abstract(Destructor.)
    }
    destructor Destroy; override;

    { @abstract(Converts the data to a JSON string.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Converts the data to a readbale text string.)
    }
    function AsText: string;

    { @abstract(Creates an instance of the class and fills it with data read from the given JSON string.)
    }
    class function FromJsonString(AJsonString: string): TOursGroundOutput;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  SysUtils,
  Math,
  OursUtils,
  OursStrings,
  OursData;

// =================================================================================================
// TOursGroundOutputData
// =================================================================================================

function TOursGroundOutputData.ArrayToJson(prefix: string; anArray: TArray<string>;
  includeLastComma: Boolean): string;
begin
  Result := '        "' + prefix + '":[';

  for var i := Low(anArray) to High(anArray) do begin
    Result := Result + '"' + anArray[i] + '"';
    if i < High(anArray) then
      Result := Result + ', ';
  end;

  if includeLastComma then
    Result := Result + '],' + CRLF
  else
    Result := Result + ']' + CRLF
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutputData.ArrayToJson(prefix: string; anArray: TArray<Extended>; ensureFloat,
  includeLastComma: Boolean): string;
begin
  Result := '        "' + prefix + '":[';

  for var i := Low(anArray) to High(anArray) do begin
    Result := Result + anArray[i].ToString;
    if i < High(anArray) then
      Result := Result + ', ';
  end;

  if ensureFloat and (Pos('.', Result) <= 0) then
    Result := Result + '.0'; // Ensure array contains at least one number with decimal seperator.

  if includeLastComma then
    Result := Result + '],' + CRLF
  else
    Result := Result + ']' + CRLF
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutputData.ToJsonForFem: string;
begin
  // The FEM script does not accept an array of numbers without at least one value with a decimal
  // separator. As the JSON string is created by Delphi, I have no way of enforcing this.
  // Work around: create the JSON by hand...
  Result := '    "Ground":{' + CRLF +
                  ArrayToJson('Depth', FDepth, True, True) +
                  ArrayToJson('E', FE, True, True) +
                  ArrayToJson('Lithology', FLithology, True) +
                  ArrayToJson('damping', FDamping, True, True) +
                  ArrayToJson('rho', FRho, True, True) +
                  ArrayToJson('v', FV, True, False) +
            '    }' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutputData.ToJsonString: string;
begin
  Result := TJson.ObjectToJsonString(self);
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutputData.ArrayAsText(prefix: string; anArray: TArray<String>): string;
var
  item: string;
begin
  Result := prefix;
  for item in anArray do begin
    Result := Result + item + '; ';
  end;
  Delete(Result, Length(Result) - 1, 2);
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutputData.ArrayAsText(prefix: string; anArray: TArray<Extended>; DecCnt: Integer): string;
begin
  Result := prefix;

  var formatStr := '%.' + DecCnt.ToString + 'f';

  for var item in anArray do begin
    Result := Result + Format(formatStr, [item]);
    while (Length(Result) > 1) and (Result[Length(Result)] = '0') and (Result[Length(Result) - 1] = '0') do
      Delete(Result, Length(Result), 1);
    Result := Result + '; ';
  end;

  Delete(Result, Length(Result) - 1, 2);
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutputData.AsText: string;
begin
  Result := ArrayAsText(Format(' - %-11s = ', [rsLithology]), lithology) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsDepth]), depth, 4) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsE]), E, 10) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsV]), v, 17) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsRho]), rho, 15) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsDamping]), damping, 6) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsVarDepth]), var_depth, 6) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsVarE]), var_E, 10) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsVarV]), var_v, 17) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsVarRho]), var_rho, 15) + CRLF +
            ArrayAsText(Format(' - %-11s = ', [rsVarDamping]), var_damping, 6) + CRLF;
end;

// -------------------------------------------------------------------------------------------------

class function TOursGroundOutputData.FromJsonString(AJsonString: string): TOursGroundOutputData;
begin
  Result := TJson.JsonToObject<TOursGroundOutputData>(AJsonString)
end;

// =================================================================================================
// TOursGroundOutputScenario
// =================================================================================================

function TOursGroundOutputScenario.AsText: string;
begin
  Result := ' - ' + Format('%-11s', [rsName]) + ' = ' + FName + CRLF +
            ' - ' + Format('%-11s', [rsProbability]) + ' = ' + (100 * FProbability).ToString + '%' + CRLF +
            ' - ' + Format('%-11s', [rsCoordinates]) + ' = ' + FCoordinates[0].ToString + '; ' + FCoordinates[1].ToString + CRLF +
            data.AsText + CRLF;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursGroundOutputScenario.Create;
begin
  inherited;

  FData := TOursGroundOutputData.Create();
end;

// -------------------------------------------------------------------------------------------------

destructor TOursGroundOutputScenario.Destroy;
begin
  FData.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutputScenario.ToJsonString: string;
begin
  Result := TJson.ObjectToJsonString(self);
end;

// -------------------------------------------------------------------------------------------------

class function TOursGroundOutputScenario.FromJsonString(AJsonString: string): TOursGroundOutputScenario;
begin
  Result := TJson.JsonToObject<TOursGroundOutputScenario>(AJsonString)
end;

// =================================================================================================
// TOursGroundOutput
// =================================================================================================

function TOursGroundOutput.AsText: string;
begin
  for var scenario in FScenarios do begin
    Result := Result + scenario.AsText;
  end;
end;

// -------------------------------------------------------------------------------------------------

destructor TOursGroundOutput.Destroy;
begin
  for var item in FScenarios do
    item.Free;

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundOutput.ToJsonString: string;
begin
  Result := TJson.ObjectToJsonString(self);
end;

// -------------------------------------------------------------------------------------------------

class function TOursGroundOutput.FromJsonString(AJsonString: string): TOursGroundOutput;
begin
  Result := TJson.JsonToObject<TOursGroundOutput>(AJsonString)
end;

// =================================================================================================

end.
