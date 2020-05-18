{ @abstract(This unit contains some general types.)
  It contains classes for list of doubles/integers, spectrums and points.
}
unit OursTypes;

interface

uses
  Generics.Collections;

// -------------------------------------------------------------------------------------------------

type
  { @abstract(Wrapper around a List of Strings.)
    Enables translation to JSON and Text.
  }
  TStringsList = class(TList<String>)
    { @abstract(Converts a list of string values to a JSON string.)
      The values are seperated by a comma and a space. Each string is enclodes in "
      The values are enclosed between brackets.
    }
    function AsJsonText(prefix: string; compulsary: Boolean): string;

    { @abstract(Converts a list of string values to a text string.)
      The values are seperated by a semicolon.
    }
    function AsText: string;

    { @abstract(Checks if two lists contain same data.)
    }
    function IsEqual(AList: TStringsList): Boolean;

    { @abstract(Copies values from an array of values.)
    }
    procedure AssignFromArray(AnArray: TArray<String>);

    { @abstract(Converts a list of string values to a JSON string, with more options.)
      The result starts "indent" spaces follword by with the prefix. The values are separated by a comma.@br
      The values from the array are enclosed in brackets. If includeLastComma is True an comma will be added to the result.
    }
    function AsJson(indent: Integer; prefix: string; includeLastComma: Boolean): string;
  end;

  { @abstract(Wrapper around a List of Doubles.)
    Enables translation to JSON and Text.
  }
  TDoubleList = class(TList<Double>)
    { @abstract(Converts a list of double values to a JSON string.)
      As decimal separator '.' is used and the values are seperated by a comma and a space.
      The values are enclosed between brackets.
    }
    function AsJsonText(prefix: string; compulsary: Boolean): string;

    { @abstract(Converts a list of double values to a text string.)
      As decimal separator the user defined setting is used and the values are seperated by a
      semicolon.
    }
    function AsText(precision: Integer): string;

    { @abstract(Converts a list of integer values to a text string.)
      The values are seperated by a semicolon.
    }
    class function AsTextLine(aList: TDoubleList; prefix: string; precision: Integer): string;

    { @abstract(Checks if two lists contain same data.)
    }
    function IsEqual(AList: TDoubleList; epsilon: Double): Boolean;

    { @abstract(Copies values from an array of values.)
    }
    procedure AssignFromArray(AnArray: TArray<Extended>);

    { @abstract(Reads data from a string.)
    }
    procedure FromString(str: string);

    { @abstract(Converts a list of double values to a JSON string, with more options.)
      The result starts "indent" spaces follword by with the prefix. The values are separated by a comma.@br
      The point is used as decimal separator. The values from the array are enclosed in brackets and
      at least 1 value will contain a decimal seperator (to prevent issues with the FEM script). @br
      If includeLastComma is True an comma will be added to the result.
    }
    function AsJson(indent: Integer; prefix: string; ensureFloat, includeLastComma: Boolean): string;
  end;

  { @abstract(Wrapper around a List of Integers.)
    Enables translation to JSON and Text.
    }
  TIntegerList = class(TList<Integer>)
    { @abstract(Converts a list of integer values to a JSON string.)
      The values are seperated by a comma and a space and are enclosed between brackets.
    }
    function AsJsonText(prefix: string; compulsary: Boolean): string;

    { @abstract(Converts a list of integer values to a text string.)
      The values are seperated by a semicolon.
    }
    function AsText: string;

    { @abstract(Converts a list of integer values to a text string.)
      The values are seperated by a semicolon.
    }
    class function AsTextLine(aList: TIntegerList; prefix: string): string;

    { @abstract(Checks if two lists contain same data.)
    }
    function IsEqual(AList: TIntegerList): Boolean;

    { @abstract(Copies values from an array of values.)
    }
    procedure AssignFromArray(AnArray: TArray<Integer>);
    { @abstract(Reads data from a string.)
    }
    procedure FromString(str: string);

    { @abstract(Converts a list of integer values to a JSON string, with more options.)
      The result starts "indent" spaces follword by with the prefix. The values are separated by a comma.@br
      The values from the array are enclosed in brackets. If includeLastComma is True an comma will be added to the result.
    }
    function AsJson(indent: Integer; prefix: string; includeLastComma: Boolean): string;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class which describes a Spectrum.)
    It gives the size and the relevant bans values (lower, middle and upper). 
  }
  TFrequency = class(TObject)
  strict private
    { @abstract(Private function which returns the number of supported frequency bands) 
      Used by property size.
    }
    class function GetSize: Integer; static;
	
    { @abstract(Private function which returns the exact frequency for a given frequency band)
      Used by property f_exact.
    }
    class function GetExact(Index: Integer): Double; static;
	
    { @abstract(Private function which returns the nominal frequency for a given frequency band)
      Used by property f_nominal.
    }
    class function GetNominal(Index: Integer): Double; static;
	
    { @abstract(Private function which returns the fieldname for a given frequency band)
      Used by property f_fieldname.
    }
    class function GetFieldname(Index: Integer): string; static;
	
    { @abstract(Private function which returns the lower frequency for a given frequency band)
      Used by property f_lower.
    }
    class function GetLower(Index: Integer): Double; static;
	
    { @abstract(Private function which returns the upper frequency for a given frequency band)
      Used by property f_upper.
    }
    class function GetUpper(Index: Integer): Double; static;
  public
    { @abstract(Constructor will raise exception as creation of an instance of this class is not allowed.)
      Class only contains class functions.
    }
    constructor Create;

    { @abstract(Returns the number of supported frequency bands.)
      Result is 6 for 1/1-octave and 18 for 1/3-octaves. The spectrum type is stored in the database 
      and retrieved with TOursDatabase.GetSpectrumType: @br
	  - 1 = 1/1-octave @br
	  - 2 = 1/3-octave.
    }
    class property size: Integer read GetSize;

    { @abstract(Returns the nominal frequency for a given frequency band)
      - For 1/1-ocatves the results are: @italic(2.0, 4.0, 8.0, 16.0, 31.5, 63.0)  @br 
      - For 1/3-ocatves the results are: @italic(1.6, 2.0, 2.5, 3.2, 4.0, 5.0, 6.3, 8.0, 10.0, 12.5, 
        16.0, 20.0, 25.0, 31.5, 40.0, 50.0, 63.0, 80.0)
    }
    class property f_nominal[Index: Integer]: Double read GetNominal;

    { @abstract(Returns the upper frequency for a given frequency band)
      For 1/1-octaves: @italic(<exact frequency> * 2^(1/2)) @br
      For 1/3-octaves: @italic(<exact frequency> * 2^(1/6))
    }
    class property f_upper[Index: Integer]: Double read GetUpper;

    { @abstract(Returns the lower frequency for a given frequency band)
      For 1/1-octaves: @italic(<exact frequency> / 2^(1/2)) @br
      For 1/3-octaves: @italic(<exact frequency> / 2^(1/6))
    }
    class property f_lower[Index: Integer]: Double read GetLower;

    { @abstract(Returns the exact frequency for a given frequency band)
      The values are calculated based on 1000 Hz. @br
      - For 1/1-ocatves the results are: @italic(2.0, 4.0, 7.9, 15.8, 31.6, 63.1)  @br 
      - For 1/3-ocatves the results are: @italic(1.6, 2.0, 2.5, 3.2, 4.0, 5.0, 6.3, 7.9, 10.0, 12.6, 
	    15.8, 20.0, 25.1, 31.6, 39.8, 50.1, 63.1, 79.4)
    }
    class property f_exact[Index: Integer]: Double read GetExact;

    { @abstract(Returns the fieldname for a given frequency band)
      This field name is the index number of the frequency band starting with '1'. @br 
      - For 1/1-ocatves the results are: @italic('1', '2', '3', '4', '5', '6')  @br 
      - For 1/3-ocatves the results are: @italic('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 
        '11', '12', '13', '14', '15', '16', '17', '18')
    }
    class property f_fieldname[Index: Integer]: string read GetFieldname;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(Class that stores spectrum values.)
  }
  TSpectrum = class(TObject)
  strict private
    { @abstract(Private field which contains the number of supportd frequency bands) 
    }
    _size: Integer;
	
    { @abstract(Private field which contains the values for each frequency band) 
    }
    _octaves: array of Double;

    { @abstract(Private function which returns the number of supported frequency bands) 
      Used by property size.
    }
    function GetSize: Integer;
	
    { @abstract(Private function which returns the value for a given frequency band) 
      Used by property value.
    }
    function GetValue(Index: Integer): Double;
	
    { @abstract(Private procedure to set the value for a given frequency band) 
      Used by property value.
    }
    procedure SetValue(Index: Integer; const Value: Double);
  public
    { @abstract(Constructor: depending on the configuration it will create a spectrum for
      1/1/-octave or 1/3-octave.)
    }
    constructor Create;

    { @abstract(Destructor.)
    }
    destructor Destroy; override;

    { @abstract(Returns the contents as text.)
      As decimal separator the user defined setting is used and the values are seperated by a 
      semicolon.
    }
    function AsText: string;

    { @abstract(Returns the contents as JSON text.)
      As decimal separator '.' is used and the values are seperated by a comma and a space.
      The values are enclosed between brackets.
    }
    function AsJsonText: string;

    { @abstract(Fills each frequency band with the given value.)
    }
    procedure FillValue(const Value: Double);

    { @abstract(Copies the values for each frequency band from the given spectrum.)
    }
    procedure FillValues(const Value: TSpectrum);

    { @abstract(Creates an instance of TSpectrum and fills it with the values from AnArray.)
      If AnArray has more or less values than TSpectrum, the results in nil.
    }
    procedure FillFromArray(AnArray: TArray<Extended>);

    { @abstract(Copies the values from AnArray.)
      If AnArray has less values the resulting values will be set to zero.
    }
    procedure AssignFromArray(AnArray: TArray<Extended>);

    { @abstract(Gives the number of frequency bands.)
    }
    property size: Integer read GetSize;

    { @abstract(Gives the value for a given frequency band.)
    }
    property Value[Index: Integer]: Double read GetValue write SetValue; default;
  end;

  { @abstract(Type for an array of spectrums.)
  }
  TSpectrumArray = array of TSpectrum;

// -------------------------------------------------------------------------------------------------

  { @abstract(Structure which contains the X and Y co-ordinate of a point.)
  }
  TRPoint = record
    x, y: Double;
    { @abstract(Gives the co-ordinate as text within brackets and seperated by a semicolon.)
    }
    function AsText: string;
  end;

  { @abstract(Structure which contains a list of points.)
  }
  TRPoints = class(TList<TRPoint>)
  public
    { @abstract(Gives the list of co-ordinate as text seperated by semicolons.)
    }
    function AsText: string;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  Types,
  SysUtils,
  StrUtils,
  Math,
  OursUtils,
  OursStrings,
  OursDatabase;

// =================================================================================================
// TRPoint(s)
// =================================================================================================

function TRPoint.AsText: string;
begin
  Result := Format('(%.2f; %.2f)', [x, y]);
end;

// -------------------------------------------------------------------------------------------------

function TRPoints.AsText: string;
begin
  Result := '';
  for var item in Self do begin
    if Result <> '' then begin
      Result := Result + '; ';
    end;
    Result := Result + item.AsText;
  end;
  Result := Format('%-19s = ', [rsLocation]) + Result + CRLF;
end;

// =================================================================================================
// TSpectrum
// =================================================================================================

constructor TSpectrum.Create;
var
  spectrumtype: Integer;
begin
  spectrumtype := TOursDatabase.GetSpectrumType;
  case spectrumtype of
    1: _size := 6; // 1/1-octaves
    2: _size := 18; // 1/3-octaves
  else raise Exception.Create('TSpectrum.Create: spectrumtype not defined (1/1-octave or 1/3-octave).');
  end;

  SetLength(_octaves, _size);
end;

// -------------------------------------------------------------------------------------------------

destructor TSpectrum.Destroy;
begin
  SetLength(_octaves, 0);

  inherited;
end;

// -------------------------------------------------------------------------------------------------

function TSpectrum.AsText: string;
begin
  Result := '';
  for var i := 0 to _size - 1 do begin
    Result := Result + _octaves[i].ToString;
    while (Length(Result) > 1) and (Result[Length(Result)] = '0') and (Result[Length(Result) - 1] = '0') do
      Delete(Result, Length(Result), 1);

    if i < _size - 1 then
      Result := Result + '; ';
  end;
end;

// -------------------------------------------------------------------------------------------------

function TSpectrum.AsJsonText: string;
begin
  Result := '[';
  for var i := 0 to _size - 1 do begin
    Result := Result + _octaves[i].ToString;
    if i < _size - 1 then
      Result := Result + ', ';
  end;
  Result := Result + ']';
end;

// -------------------------------------------------------------------------------------------------

function TSpectrum.GetSize: Integer;
begin
  Result := _size;
end;

// -------------------------------------------------------------------------------------------------

function TSpectrum.GetValue(Index: Integer): Double;
begin
  Result := _octaves[Index];
end;

// -------------------------------------------------------------------------------------------------

procedure TSpectrum.SetValue(Index: Integer; const Value: Double);
begin
  _octaves[Index] := Value;
end;

// -------------------------------------------------------------------------------------------------

procedure TSpectrum.FillValues(const Value: TSpectrum);
begin
  for var i := 0 to _size - 1 do begin
    _octaves[i] := Value[i];
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TSpectrum.AssignFromArray(AnArray: TArray<Extended>);
begin
  FillValue(0.0);
  for var i := 0 to Min(size, Length(AnArray)) - 1 do begin
    Self[i] := AnArray[i];
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TSpectrum.FillFromArray(AnArray: TArray<Extended>);
begin
  if Length(AnArray) = size then begin
    for var i := 0 to size - 1 do
      Self[i] := AnArray[i];
  end else begin
    FillValue(0.0);
  end;

end;

// -------------------------------------------------------------------------------------------------

procedure TSpectrum.FillValue(const Value: Double);
begin
  for var i := 0 to _size - 1 do begin
    _octaves[i] := Value;
  end;
end;

// =================================================================================================
// TFrequency
// =================================================================================================

constructor TFrequency.Create;
begin
  raise Exception.Create('TFrequency.Create not allowed');
end;

// -------------------------------------------------------------------------------------------------

class function TFrequency.GetExact(Index: Integer): Double;
const
  f_octave: array [0 .. 5] of Double = (2.0, 4.0, 7.9, 15.8, 31.6, 63.1);
  f_terts: array [0 .. 17] of Double = (1.6, 2.0, 2.5, 3.2, 4.0, 5.0, 6.3, 7.9, 10.0, 12.6, 15.8, 
                                        20.0, 25.1, 31.6, 39.8, 50.1, 63.1, 79.4);
var
  tmpSize: Integer;
begin
  tmpSize := GetSize;
  if (tmpSize <> 6) and (tmpSize <> 18) then
    raise Exception.Create('TFrequency.f_exact: invalid spectrumtype');

  if (Index < 0) or (Index >= tmpSize) then
    raise Exception.Create('TFrequency.f_exact: invalid index');

  if tmpSize = 6 then
    Result := f_octave[Index]
  else
    Result := f_terts[Index];
end;

// -------------------------------------------------------------------------------------------------

class function TFrequency.GetFieldname(Index: Integer): string;
var
  tmpSize: Integer;
begin
  tmpSize := GetSize;
  if (tmpSize <> 6) and (tmpSize <> 18) then
    raise Exception.Create('TFrequency.f_fieldname: invalid spectrumtype');

  if (Index < 0) or (Index >= tmpSize) then
    raise Exception.Create('TFrequency.f_fieldname: invalid index');

  Result := Format('f%d', [Index + 1]);
end;

// -------------------------------------------------------------------------------------------------

class function TFrequency.GetNominal(Index: Integer): Double;
const
  f_octave: array [0 .. 5] of Double = (2.0, 4.0, 8.0, 16.0, 31.5, 63.0);
  f_terts: array [0 .. 17] of Double = (1.6, 2.0, 2.5, 3.2, 4.0, 5.0, 6.3, 8.0,
    10.0, 12.5, 16.0, 20.0, 25.0, 31.5, 40.0, 50.0, 63.0, 80.0);
var
  tmpSize: Integer;
begin
  tmpSize := GetSize;
  if (tmpSize <> 6) and (tmpSize <> 18) then
    raise Exception.Create('TFrequency.f_nominal: invalid spectrumtype');

  if (Index < 0) or (Index >= tmpSize) then
    raise Exception.Create('TFrequency.f_nominal: invalid index');

  if tmpSize = 6 then
    Result := f_octave[Index]
  else
    Result := f_terts[Index];
end;

// -------------------------------------------------------------------------------------------------

class function TFrequency.GetLower(Index: Integer): Double;
var
  f: Double;
  tmpSize: Integer;
begin
  tmpSize := GetSize;
  if (tmpSize <> 6) and (tmpSize <> 18) then
    raise Exception.Create('TFrequency.f_lower: invalid spectrumtype');

  if (Index < 0) or (Index >= tmpSize) then
    raise Exception.Create('TFrequency.f_lower: invalid index');

  f := f_nominal[Index];
  if tmpSize = 6 then
    Result := f / Power(2.0, 1.0 / 2.0)
  else
    Result := f / Power(2.0, 1.0 / 6.0);
end;

// -------------------------------------------------------------------------------------------------

class function TFrequency.GetUpper(Index: Integer): Double;
var
  f: Double;
  tmpSize: Integer;
begin
  tmpSize := GetSize;
  if (tmpSize <> 6) and (tmpSize <> 18) then
    raise Exception.Create('TFrequency.f_upper: invalid spectrumtype');

  if (Index < 0) or (Index >= tmpSize) then
    raise Exception.Create('TFrequency.f_upper: invalid index');

  f := f_nominal[Index];
  if tmpSize = 6 then
    Result := f * Power(2.0, 1.0 / 2.0)
  else
    Result := f * Power(2.0, 1.0 / 6.0);
end;

// -------------------------------------------------------------------------------------------------

class function TFrequency.GetSize: Integer;
var
  spectrumtype: Integer;
begin
  spectrumtype := TOursDatabase.GetSpectrumType;
  case spectrumtype of
    1: Result := 6; // Octaves
    2: Result := 18; // Terts
  else raise Exception.Create('TFrequency.Create: spectrumtype not defined (1/1-octave or 1/3-octave)');
  end;
end;

// =================================================================================================
// TDoubleList
// =================================================================================================

procedure TDoubleList.AssignFromArray(AnArray: TArray<Extended>);
begin
  for var i := 0 to Length(AnArray)-1 do begin
    Add(AnArray[i]);
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TDoubleList.FromString(str: string);
begin
  Clear;

  var tmpValues := SplitString(str, ' ');
  for var i := 0 to Length(tmpValues) - 1 do
    Add(TOursConv.AsFloat(tmpValues[i]));
  SetLength(tmpValues, 0);
end;

// -------------------------------------------------------------------------------------------------

function TDoubleList.AsText(precision: Integer): string;
begin
  var _format := '%.' + precision.ToString + 'f';

  Result := '';
  for var i := 0 to Count - 1 do begin
    Result := Result + Format(_format, [items[i]]);
    if i < Count - 1 then
      Result := Result + '; ';
  end;
end;

// -------------------------------------------------------------------------------------------------

class function TDoubleList.AsTextLine(aList: TDoubleList; prefix: string; precision: Integer): string;
begin
  Result := '';

  if Assigned(aList) and (aList.Count > 0) then
    Result := Result + prefix + aList.AsText(precision) + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TDoubleList.IsEqual(AList: TDoubleList; epsilon: Double): Boolean;
begin
  Result := False;
  if (not Assigned(AList)) or (Count <> AList.Count) then
    Exit;

  for var i := 0 to Count-1 do begin
    if not SameValue(Items[i], AList.Items[i], epsilon) then
      Exit;
  end;

  Result := True;
end;

// -------------------------------------------------------------------------------------------------

function TDoubleList.AsJson(indent: Integer; prefix: string; ensureFloat, includeLastComma: Boolean): string;
begin
  Result := '';
  for var i := 0 to indent-1 do
    Result := Result + ' ';

  Result := Result + '"' + prefix + '":[';

  for var i := 0 to Count-1 do begin
    Result := Result + Self[i].ToString;
    if i < Count-1 then
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

function TDoubleList.AsJsonText(prefix: string; compulsary: Boolean): string;
begin
  if (Count=0) and (not compulsary) then begin
    Result := '';
    Exit;
  end;

  Result := prefix + '[';
  for var i := 0 to Count - 1 do begin
    Result := Result + Items[i].ToString;
    if i < Count - 1 then
      Result := Result + ', ';
  end;
  Result := Result + '],' + CRLF;
end;

// =================================================================================================
// TIntegerList
// =================================================================================================

procedure TIntegerList.AssignFromArray(AnArray: TArray<Integer>);
begin
  for var i := 0 to Length(AnArray)-1 do begin
    Add(AnArray[i]);
  end;
end;

// -------------------------------------------------------------------------------------------------

function TIntegerList.AsText: string;
begin
  Result := '';
  for var i := 0 to Count - 1 do begin
    Result := Result + Items[i].ToString;
    if i < Count - 1 then
      Result := Result + '; ';
  end;
end;

// -------------------------------------------------------------------------------------------------

class function TIntegerList.AsTextLine(aList: TIntegerList; prefix: string): string;
begin
  Result := '';
  if Assigned(aList) and (aList.Count > 0) then
    Result := Result + prefix + aList.AsText + CRLF;
end;

// -------------------------------------------------------------------------------------------------

procedure TIntegerList.FromString(str: string);
begin
  Clear;

  var tmpValues := SplitString(str, ' ');
  for var i := 0 to Length(tmpValues) - 1 do
    Add(TOursConv.AsInteger(tmpValues[i]));
  SetLength(tmpValues, 0);
end;

// -------------------------------------------------------------------------------------------------

function TIntegerList.IsEqual(AList: TIntegerList): Boolean;
begin
  Result := False;
  if (not Assigned(AList)) or (Count <> AList.Count) then
    Exit;

  for var i := 0 to Count-1 do begin
    if (Items[i] <> AList.Items[i]) then
      Exit;
  end;

  Result := True;
end;

// -------------------------------------------------------------------------------------------------

function TIntegerList.AsJson(indent: Integer; prefix: string; includeLastComma: Boolean): string;
begin
  Result := '';
  for var i := 0 to indent-1 do
    Result := Result + ' ';

  Result := Result + '"' + prefix + '":[';

  for var i := 0 to Count-1 do begin
    Result := Result + Self[i].ToString;
    if i < Count-1 then
      Result := Result + ', ';
  end;

  if includeLastComma then
    Result := Result + '],' + CRLF
  else
    Result := Result + ']' + CRLF
end;

// -------------------------------------------------------------------------------------------------

function TIntegerList.AsJsonText(prefix: string; compulsary: Boolean): string;
begin
  if (Count=0) and (not compulsary) then begin
    Result := '';
    Exit;
  end;

  Result := prefix + '[';
  for var i := 0 to Count - 1 do begin
    Result := Result + Items[i].ToString;
    if i < Count - 1 then
      Result := Result + ', ';
  end;
  Result := Result + '],' + CRLF;
end;

// =================================================================================================
// TStringsList
// =================================================================================================

function TStringsList.AsJson(indent: Integer; prefix: string; includeLastComma: Boolean): string;
begin
  Result := '';
  for var i := 0 to indent-1 do
    Result := Result + ' ';

  Result := Result + '"' + prefix + '":[';

  for var i := 0 to Count-1 do begin
    Result := Result + '"' + Self[i] + '"';
    if i < Count-1 then
      Result := Result + ', ';
  end;

  if includeLastComma then
    Result := Result + '],' + CRLF
  else
    Result := Result + ']' + CRLF
end;

// -------------------------------------------------------------------------------------------------

function TStringsList.AsJsonText(prefix: string; compulsary: Boolean): string;
begin
  if (Count=0) and (not compulsary) then begin
    Result := '';
    Exit;
  end;

  Result := prefix + '[';
  for var i := 0 to Count - 1 do begin
    Result := Result + '"' + Items[i] + '"';
    if i < Count - 1 then
      Result := Result + ', ';
  end;
  Result := Result + '],' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

procedure TStringsList.AssignFromArray(AnArray: TArray<String>);
begin
  for var i := 0 to Length(AnArray)-1 do begin
    Add(AnArray[i]);
  end;
end;

// -------------------------------------------------------------------------------------------------

function TStringsList.AsText: string;
begin
  Result := '';
  for var i := 0 to Count - 1 do begin
    Result := Result + Items[i];
    if i < Count - 1 then
      Result := Result + '; ';
  end;
end;

// -------------------------------------------------------------------------------------------------

function TStringsList.IsEqual(AList: TStringsList): Boolean;
begin
  Result := False;
  if (not Assigned(AList)) or (Count <> AList.Count) then
    Exit;

  for var i := 0 to Count-1 do begin
    if (Items[i] <> AList.Items[i]) then
      Exit;
  end;

  Result := True;
end;

// =================================================================================================

end.
