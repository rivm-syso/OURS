{ @abstract(This unit contains some general classes.)
  All classes contain only class methods, no need to create an instance of the class.
  }

unit OursUtils;

interface

uses
  OursTypes;

// -------------------------------------------------------------------------------------------------

type
  { @abstract(This class contains converter functions for text to value.)
  }
  TOursConv = class (TObject)
  public
    { @abstract(Constructor will raise exception as creation of an instance of this class is not allowed.)
      Class only contains class functions.
    }
    constructor Create;

    { @abstract(This class function converts a text to a double.)
      The function accepts any text and converts all dots and commas to the local decimal separator
      before converting it to a double. If conversion fails, 'default' is returned.
    }
    class function AsFloat(const value: string; default: Double = 0.0): Double;
    { @abstract(This class function converts a text to a integer.)
      If conversion fails, 'default' is returned.
    }
    class function AsInteger(const value: string; default: Integer = 0): Integer;

    { @abstract(This class function formats a JSON string for better reading.)
    }
    class function FormatJSON(const JsonStr: string): string;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(This class contains some math routines.)
  }
  TOursMath = class(TObject)
  public const
    { @abstract('_eps' gives the precision with which doubles are compared.)}
    _eps = 1E-5;
  public
    { @abstract(Constructor will raise exception as creation of an instance of this class is not allowed.)
      Class only contains class functions.
    }
    constructor Create;

    { @abstract('dist' calculates the distance between two points)
      These points are given as 4 seperate double values (px1, py1) and (px2, py2)
    }
    class function dist(const px1, py1, px2, py2: Double): Double; overload;
    { @abstract('dist' calculates the distance between two points)
      These points are given as 2 co-ordinate pairs in 2 TRPoint structures.
    }
    class function dist(const p1, p2: TRPoint): Double; overload;

    { @abstract('DistanceToLine' calculates the shortest distance from a point to a line)
      The point is given by 'P' and the line is given by P1 and P2. @br
      Px and Py contains the co-ordinate of this nearest point.
    }
    class function DistanceToLine(const P: TRPoint; const p1, p2: TRPoint;
      out Px, Py: Double): Double; overload;

    { @abstract('DistanceToLine' calculates the shortest distance from a point to a polyline)
      The point is given by 'P' and the polyline is given by polyline (list of TRPoints). @br
      Px and Py contains the co-ordinate of this nearest point and 'len' contains the distance over
      the line from the beginning to (Px, Py).
    }
    class function DistanceToLine(const P: TRPoint; polyline: TRPoints;
      out Px, Py, len: Double): Double; overload;

    { @abstract('LengthLine' calculates the length of a polyline)
      The line is given by polyline (list of TRPoints).
    }
    class function LengthLine(const polyline: TRPoints): Double;

    { @abstract(Tests if a is greater than b) }
    class function gt(a, b: Double): Boolean; overload;
    { @abstract(Tests if a is greater than b) }
    class function gt(a, b: Extended): Boolean; overload;
    { @abstract(Tests if a is greater than b) }
    class function gt(a, b: Integer): Boolean; overload;

    { @abstract(Tests if a is greater than or equal to b) }
    class function ge(a, b: Double): Boolean; overload;
    { @abstract(Tests if a is greater than or equal to b) }
    class function ge(a, b: Extended): Boolean; overload;
    { @abstract(Tests if a is greater than or equal to b) }
    class function ge(a, b: Integer): Boolean; overload;

    { @abstract(Tests if a is smaller than b) }
    class function lt(a, b: Double): Boolean; overload;
    { @abstract(Tests if a is smaller than b) }
    class function lt(a, b: Extended): Boolean; overload;
    { @abstract(Tests if a is smaller than b) }
    class function lt(a, b: Integer): Boolean; overload;

    { @abstract(Tests if a is smaller than or equal to b) }
    class function le(a, b: Double): Boolean; overload;
    { @abstract(Tests if a is smaller than or equal to b) }
    class function le(a, b: Extended): Boolean; overload;
    { @abstract(Tests if a is smaller than or equal to b) }
    class function le(a, b: Integer): Boolean; overload;

    { @abstract(Tests if a equals b) }
    class function eq(a, b: Double): Boolean; overload;
    { @abstract(Tests if a equals b) }
    class function eq(a, b: Extended): Boolean; overload;
    { @abstract(Tests if a equals b) }
    class function eq(a, b: Integer): Boolean; overload;
  end;

// -------------------------------------------------------------------------------------------------

  { @abstract(This class methods to retrieve the location of standard folders.)
  }
  TOursFileUtils = class(TObject)
  public
    { @abstract(Constructor will raise exception as creation of an instance of this class is not allowed.)
      Class only contains class functions.
    }
    constructor Create;

    { @abstract(Returns the documents folder (e.g. C:\Users\<user>\Documents\OURS).)
    }
    class function DocumentsDir: string;

    { @abstract(Returns the documents folder for all users (e.g. C:\Users\Public\Public Documents\OURS).)
    }
    class function CommonDocumentsDir: string;

    { @abstract(Returns the folder for temporary files.)
      This folder is a subfolder of the temp-folder. The subfolder is 'OURS_' followed by the
      process-id.
    }
    class function TempDir: string;

    { @abstract(Returns the folder where Python is located.)
      This folder is the subfolder 'Python' in the program folder.
    }
    class function PythonDir: string;

    { @abstract(Deletes the temp-folder and all containing files and subfolders.)
    }
    class procedure DeleteTempDir;

    { @abstract(Deletes a  folder and all containing files and subfolders.)
    }
    class procedure DeleteDir(aDir: string);

    { @abstract(Returns the folder where the software OURS is located.)
    }
    class function ProgDir: string;

    { @abstract(Tests if a folder is writable.)
    }
    class function IsFolderWriteable(const AFolder: string): Boolean;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  Types,
  Classes,
  Controls,
  Forms,
  IOUtils,
  ShlObj,
  ShellAPI,
  SysUtils,
  strUtils,
  Windows,
  Math,
  OursStrings;

// =================================================================================================
// TOursConv
// =================================================================================================

constructor TOursConv.Create;
begin
  raise Exception.Create('TOursConv.Create not allowed');
end;

// -------------------------------------------------------------------------------------------------

class function TOursConv.AsInteger(const value: string; default: Integer = 0): Integer;
begin
  Result := StrToIntDef(value, default)
end;

// -------------------------------------------------------------------------------------------------

class function TOursConv.AsFloat(const value: string; default: Double): Double;
var
  str: string;
begin
  str := value;
  str := ReplaceText(str, ',', FormatSettings.DecimalSeparator);
  str := ReplaceText(str, '.', FormatSettings.DecimalSeparator);

  Result := StrToFloatDef(str, default)
end;

// =================================================================================================
// TOursFileUtils
// =================================================================================================

constructor TOursFileUtils.Create;
begin
  raise Exception.Create('TOursFileUtils.Create not allowed');
end;

// -------------------------------------------------------------------------------------------------

class function TOursFileUtils.ProgDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))
end;

// -------------------------------------------------------------------------------------------------

class function TOursFileUtils.DocumentsDir: string;
begin
  Result := IncludeTrailingPathDelimiter(TPath.GetDocumentsPath) + 'OURS' + PathDelim;

  if not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

// -------------------------------------------------------------------------------------------------

class function TOursFileUtils.CommonDocumentsDir: string;
begin
  Result := IncludeTrailingPathDelimiter(TPath.GetSharedDocumentsPath) + 'OURS' + PathDelim;

  if not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

// -------------------------------------------------------------------------------------------------

class function TOursFileUtils.PythonDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ProgDir + 'Python');
end;

// -------------------------------------------------------------------------------------------------

class function TOursFileUtils.TempDir: string;
var
  pid: DWORD;
begin
  Result := IncludeTrailingPathDelimiter(TPath.GetTempPath);

  pid := GetCurrentProcessId;
  Result := IncludeTrailingPathDelimiter(Result) + 'OURS_' + pid.ToString;
  Result := IncludeTrailingPathDelimiter(Result);

  if not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

// -------------------------------------------------------------------------------------------------

class function TOursFileUtils.IsFolderWriteable(const AFolder: string): Boolean;
begin
  var FileName := IncludeTrailingPathDelimiter(AFolder) + 'chk.tmp';

  var H := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    CREATE_NEW, FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE, 0);

  Result := (H <> INVALID_HANDLE_VALUE);

  if Result then
    CloseHandle(H);
end;

// -------------------------------------------------------------------------------------------------

class procedure TOursFileUtils.DeleteDir(aDir: string);
begin
  TDirectory.Delete(aDir, True);
end;

// -------------------------------------------------------------------------------------------------

class procedure TOursFileUtils.DeleteTempDir;
begin
  DeleteDir(TOursFileUtils.TempDir);
end;

// -------------------------------------------------------------------------------------------------

class function TOursConv.FormatJSON(const JsonStr: string): string;
var
  str: string;
  sl: TStringlist;
begin
  str := JsonStr;

  // Format JSON string to make it better readable.
  str := StringReplace(str, '{', '{' + CRLF, [rfReplaceAll]);
  str := StringReplace(str, '}', '}' + CRLF, [rfReplaceAll]);
  str := StringReplace(str, ',', ',' + CRLF, [rfReplaceAll]);
  str := StringReplace(str, ':', ':' + CRLF, [rfReplaceAll]);
  str := StringReplace(str, '[', '[' + CRLF, [rfReplaceAll]);
  str := StringReplace(str, ']', CRLF + ']' + CRLF, [rfReplaceAll]);
  str := StringReplace(str, CRLF + ']' + CRLF + ',', CRLF + '],', [rfReplaceAll]);

  sl := TStringlist.Create;
  sl.Text := str;
  var indent: Integer := 0;
  for var i := 0 to sl.Count - 1 do begin
    str := sl[i];
    if str = '' then
      Continue;

    var first: char := str[1];
    if CharInSet(first, ['}', ']']) then
      dec(indent, 3);
    for var j := 0 to indent do
      str := ' ' + str;
    if CharInSet(first, ['{', '[']) then
      inc(indent, 3);

    sl[i] := str;
  end;

  Result := sl.Text;
  sl.Free;
end;

// =================================================================================================
// TOursMath
// =================================================================================================

constructor TOursMath.Create;
begin
  raise Exception.Create('TOursMath.Create not allowed');
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.dist(const px1, py1, px2, py2: Double): Double;
begin
  Result := sqrt(sqr(px1 - px2) + sqr(py1 - py2));
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.dist(const p1, p2: TRPoint): Double;
begin
  Result := dist(p1.x, p1.y, p2.x, p2.y);
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.DistanceToLine(const P: TRPoint; polyline: TRPoints;
  out Px, Py, len: Double): Double;
var
  tmpDist, tmpX, tmpY: Double;
begin
  Result := 99999999.9;
  Px := 0.0;
  Py := 0.0;
  len := 0.0;

  if polyline.Count=1 then begin
    Result := dist(P, polyline[0]);
    Px := polyline[0].x;
    Py := polyline[0].y;
    Exit;
  end;

  for var i := 0 to polyline.Count - 2 do begin
    tmpDist := DistanceToLine(P, polyline[i], polyline[i + 1], tmpX, tmpY);
    if (i = 0) or (tmpDist < Result) then begin
      Result := tmpDist;
      Px := tmpX;
      Py := tmpY;

      len := dist(polyline[i].x, polyline[i].y, Px, Py);
      for var j := 0 to i - 1 do begin
        len := len + dist(polyline[j].x, polyline[j].y, polyline[j + 1].x,
          polyline[j + 1].y);
      end;
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.eq(a, b: Double): Boolean;
begin
  Result := CompareValue(a, b, _eps) = EqualsValue
end;

class function TOursMath.eq(a, b: Extended): Boolean;
begin
  Result := CompareValue(a, b, _eps) = EqualsValue
end;

class function TOursMath.eq(a, b: Integer): Boolean;
begin
  Result := CompareValue(a, b) = EqualsValue
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.gt(a, b: Double): Boolean;
begin
  Result := CompareValue(a, b, _eps) = GreaterThanValue
end;

class function TOursMath.gt(a, b: Extended): Boolean;
begin
  Result := CompareValue(a, b, _eps) = GreaterThanValue
end;

class function TOursMath.gt(a, b: Integer): Boolean;
begin
  Result := CompareValue(a, b) = GreaterThanValue
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.ge(a, b: Double): Boolean;
begin
  Result := CompareValue(a, b, _eps) <> LessThanValue
end;

class function TOursMath.ge(a, b: Extended): Boolean;
begin
  Result := CompareValue(a, b, _eps) <> LessThanValue
end;

class function TOursMath.ge(a, b: Integer): Boolean;
begin
  Result := CompareValue(a, b) <> LessThanValue
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.lt(a, b: Double): Boolean;
begin
  Result := CompareValue(a, b, _eps) = LessThanValue
end;

class function TOursMath.lt(a, b: Extended): Boolean;
begin
  Result := CompareValue(a, b, _eps) = LessThanValue
end;

class function TOursMath.lt(a, b: Integer): Boolean;
begin
  Result := CompareValue(a, b) = LessThanValue
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.le(a, b: Double): Boolean;
begin
  Result := CompareValue(a, b, _eps) <> GreaterThanValue
end;

class function TOursMath.le(a, b: Extended): Boolean;
begin
  Result := CompareValue(a, b, _eps) <> GreaterThanValue
end;

class function TOursMath.le(a, b: Integer): Boolean;
begin
  Result := CompareValue(a, b) <> GreaterThanValue
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.DistanceToLine(const P, p1, p2: TRPoint; out Px, Py: Double): Double;
var
  a, b, c: Double;
begin
  if SameValue(p1.x, p2.x, _eps) and SameValue(p1.y, p2.y, _eps) then begin
    Px := p1.x;
    Py := p1.y;
    Result := dist(P.x, P.y, Px, Py);
    Exit
  end; // if

  a := sqr(p2.x - p1.x) + sqr(p2.y - p1.y);
  b := sqr(P.x - p1.x) + sqr(P.y - p1.y);
  c := sqr(P.x - p2.x) + sqr(P.y - p2.y);
  if -c + a + b < 0.0 then begin
    // Phi1 is a blunt angle --> P1 closest
    Px := p1.x;
    Py := p1.y;
    Result := sqrt(b)
  end else if -b + c + a < 0.0 then begin
    // Phi2 is a blunt angle --> P2 closest
    Px := p2.x;
    Py := p2.y;
    Result := sqrt(c)
  end else begin
    // Both angles sharp --> perpendicular to line segment
    if SameValue(p1.x, p2.x, _eps) then begin
      Px := p1.x;
      Py := P.y;
    end else if SameValue(p1.y, p2.y, _eps) then begin
      Px := P.x;
      Py := p1.y;
    end else begin
      var
      Alfa := (p2.y - p1.y) / (p2.x - p1.x);
      Px := (P.y + (P.x / Alfa) - p1.y + Alfa * p1.x) / (Alfa + (1.0 / Alfa));
      Py := (-1.0 / Alfa) * Px + P.y + (P.x / Alfa);
    end;
    Result := dist(P.x, P.y, Px, Py);
  end
end;

// -------------------------------------------------------------------------------------------------

class function TOursMath.LengthLine(const polyline: TRPoints): Double;
begin
  Result := 0.0;
  for var i := 0 to polyline.Count - 2 do
    Result := Result + dist(polyline[i], polyline[i + 1]);
end;

// =================================================================================================

initialization
  TOursFileUtils.TempDir;

finalization
  TOursFileUtils.DeleteTempDir;

end.
