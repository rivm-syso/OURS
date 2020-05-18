{ @abstract(This unit classes for output and storage of the FEM module and post-processing of the FEM results.)
}
unit OursResultFem;

interface

uses
  Generics.Collections,
  Rest.Json,
  OursResultGround,
  OursTypes;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class to read and store results from the FEM module.)
    Note: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
type
  TOursNaverwerkingJSON = class
  private
    FY: TArray<Extended>;
    FY_ratio: TArray<Extended>;
    Fc: TArray<Extended>;
    Fc_ratio: TArray<Extended>;
    Ffase: TArray<Extended>;
    FJSON: string;
  public
    property Y: TArray<Extended> read FY write FY;
    property Y_ratio: TArray<Extended> read FY_ratio write FY_ratio;
    property c: TArray<Extended> read Fc write Fc;
    property c_ratio: TArray<Extended> read Fc_ratio write Fc_ratio;
    property fase: TArray<Extended> read Ffase write Ffase;

    { @abstract(Converts the data to a JSON string.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Converts the data to a readable text string.)
    }
    function AsText: string;

    { @abstract(Returns the raw JSON string.)
    }
    function GetJSON: string;

    { @abstract(Creates an instance of the class and fills it with data read from the given JSON string.)
    }
    class function FromJsonString(AJsonString: string): TOursNaverwerkingJSON;
  end;


// -------------------------------------------------------------------------------------------------

  { @abstract(Class to read and store results from the FEM module.)
    Note: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
type
  TOursUncertaintyJSON = class
  private
    Fvar_Y: TArray<Extended>;
    Fvar_Y_ratio: TArray<Extended>;
    Fvar_c: TArray<Extended>;
    Fvar_c_ratio: TArray<Extended>;
    Fvar_fase: TArray<Extended>;
  public
    property var_Y: TArray<Extended>        read Fvar_Y       write Fvar_Y;
    property var_Y_ratio: TArray<Extended>  read Fvar_Y_ratio write Fvar_Y_ratio;
    property var_c: TArray<Extended>        read Fvar_c       write Fvar_c;
    property var_c_ratio: TArray<Extended>  read Fvar_c_ratio write Fvar_c_ratio;
    property var_fase: TArray<Extended>     read Fvar_fase    write Fvar_fase;

    { @abstract(Converts the data to a JSON string.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Converts the data to a readable text string.)
    }
    function AsText: string;

    { @abstract(Creates an instance of the class and fills it with data read from the given JSON string.)
    }
    class function FromJsonString(AJsonString: string): TOursUncertaintyJSON;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class to read and store results from the post-processing module.)
    Note: data fields need to start with 'F'. Otherwise TJson.JsonToObject won't work.
  }
  TOursFemOutput = class
  private
    // Field names need to start with 'F'. Otherwise TJson.JsonToObject won't work.
    FMaxFreqLimited: Extended;
    FFrequency: TArray<Extended>;
    FRcoord: TArray<Extended>;
    FRDisp_imag: TArray<TArray<Extended>>;
    FRDisp_real: TArray<TArray<Extended>>;
    FZDisp_imag: TArray<TArray<Extended>>;
    FZDisp_real: TArray<TArray<Extended>>;
  public
    constructor Create;
    property MaxFreqLimited: Extended read FMaxFreqLimited write FMaxFreqLimited;
    property Frequency: TArray<Extended> read FFrequency write FFrequency;
    property Rcoord: TArray<Extended> read FRcoord write FRcoord;
    property RDisp_imag: TArray<TArray<Extended>> read FRDisp_imag write FRDisp_imag;
    property RDisp_real: TArray<TArray<Extended>> read FRDisp_real write FRDisp_imag;
    property ZDisp_imag: TArray<TArray<Extended>> read FZDisp_imag write FRDisp_imag;
    property ZDisp_real: TArray<TArray<Extended>> read FZDisp_real write FRDisp_imag;

    { @abstract(Converts the data to a JSON string.)
      The point will be used as decimal separator.
    }
    function ToJsonString: string;

    { @abstract(Converts the data to a JSON string used to calculate derived results.)
      The point will be used as decimal separator.
    }
    function ToJsonForDerived(const dist, len: Double): string;

    { @abstract(Converts the data to a readable text string.)
    }
    function AsText: string;

    { @abstract(Creates an instance of the class and fills it with data read from the given JSON string.)
    }
    class function FromJsonString(AJsonString: string): TOursFemOutput;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  Classes,
  StrUtils,
  SysUtils,
  Math,
  OursStrings,
  OursUtils,
  OursData;

// =================================================================================================
// TOursFemOutput
// =================================================================================================

constructor TOursFemOutput.Create;
begin
  FMaxFreqLimited := -999.0
end;

// -------------------------------------------------------------------------------------------------

function TOursFemOutput.AsText: string;
begin
  Result := ToJsonString;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemOutput.ToJsonString: string;
begin
  Result := TOursConv.FormatJSON(TJson.ObjectToJsonString(self));
end;

// -------------------------------------------------------------------------------------------------

function TOursFemOutput.ToJsonForDerived(const dist, len: Double): string;
var
  str: string;
  strList: TStringList;
begin
  Result := '';

  // De teksten in de JSON zijn case sensitive!
  str := ToJsonString;
  str := StringReplace(str, '"frequency"',  '"Frequency"',  [rfReplaceAll]);
  str := StringReplace(str, '"rcoord"',     '"Rcoord"',     [rfReplaceAll]);
  str := StringReplace(str, '"rDisp_imag"', '"RDisp_imag"', [rfReplaceAll]);
  str := StringReplace(str, '"rDisp_real"', '"RDisp_real"', [rfReplaceAll]);
  str := StringReplace(str, '"zDisp_imag"', '"ZDisp_imag"', [rfReplaceAll]);
  str := StringReplace(str, '"zDisp_real"', '"ZDisp_real"', [rfReplaceAll]);

  strList := TStringList.Create;
  try
    if TOursMath.lt(FMaxFreqLimited, 0.0) then begin
      // Don't use MaxFreqLimited if value is not returned by FEM calculation
      for var i := 0 to strList.Count-1 do begin
        if ContainsText(strList.Strings[i], 'MaxFreqLimited') then begin
          strList.Delete(i);  //    "Lengte":
          strList.Delete(i);  //      -999.0,
          Break;
        end;
      end;
    end;

    strList.Text := str;
    strList.Insert(1, Format('    "Lengte":%f,', [len]));
    strList.Insert(1, Format('    "GevraagdeAfstand":%f,', [dist]));

    Result := strList.Text;
  finally
    strList.Free;
  end;
end;

// -------------------------------------------------------------------------------------------------

class function TOursFemOutput.FromJsonString(AJsonString: string): TOursFemOutput;
begin
  Result := TJson.JsonToObject<TOursFemOutput>(AJsonString)
end;

// =================================================================================================
// TOursNaverwerkingJSON
// =================================================================================================

function TOursNaverwerkingJSON.AsText: string;
begin
  Result := ToJsonString;
end;

// -------------------------------------------------------------------------------------------------

class function TOursNaverwerkingJSON.FromJsonString(AJsonString: string): TOursNaverwerkingJSON;
var
  str: string;
begin
  // Work-around: post-processing script could return 'NaN' and 'Infinity'.
  str := StringReplace(AJsonString, 'NaN', '9.9e-20', [rfReplaceAll]);
  str := StringReplace(str, 'Infinity', '9.9e+20', [rfReplaceAll]);

  Result := TJson.JsonToObject<TOursNaverwerkingJSON>(str);

  Result.FJSON := str; // Store raw JSON for future use.
end;

// -------------------------------------------------------------------------------------------------

function TOursNaverwerkingJSON.GetJSON: string;
begin
  Result := FJSON;
end;

// -------------------------------------------------------------------------------------------------

function TOursNaverwerkingJSON.ToJsonString: string;
begin
  Result := TOursConv.FormatJSON(TJson.ObjectToJsonString(self));
end;

// =================================================================================================
// TOursUncertaintyJSON
// =================================================================================================

function TOursUncertaintyJSON.AsText: string;
begin
  Result := ToJsonString;
end;

// -------------------------------------------------------------------------------------------------

class function TOursUncertaintyJSON.FromJsonString(AJsonString: string): TOursUncertaintyJSON;
var
  str: string;
begin
  // Work-around: post-processing script returns also 'NaN' and 'Infinity'.
  str := StringReplace(AJsonString, 'NaN', '9.9e-20', [rfReplaceAll]);
  str := StringReplace(str, 'Infinity', '9.9e+20', [rfReplaceAll]);

  if (str[1]='[') and (str[Length(str)-2]=']') and (str[Length(str)-1]=#13) and (str[Length(str)]=#10) then begin
    str[1] := ' ';
    str[Length(str)-2] := ' ';
  end;

  Result := TJson.JsonToObject<TOursUncertaintyJSON>(str);
end;

// -------------------------------------------------------------------------------------------------

function TOursUncertaintyJSON.ToJsonString: string;
begin
  Result := TOursConv.FormatJSON(TJson.ObjectToJsonString(self));
end;

// =================================================================================================

end.
