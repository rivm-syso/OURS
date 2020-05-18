{ @abstract(This unit splits a given Prorail datafile into smaller files for each traject code.)
  This option is only available for test purposes.
  }
unit OursSplitProrailData;

interface

uses
  OursTypes,
  OursUtils;

type
  { @abstract(Class method lets the user select a CSV file and will then split the file.)
    Warning: This will take up te 8 hours!
  }
  TOursSplitProrailData = class(TObject)
  public
    { @abstract(Constructor will raise exception as creation of an instance of this class is not allowed.)
      Class only contains class functions.
    }
    constructor Create;

    { @abstract(This class method lets the user select a raildata file and starts the conversion.)
      The method will create a folder with the same name as the selected file. In this folder the 
      files for each traject code are placed.
    }
    class procedure SplitProrailData;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  Types,
  StrUtils,
  SysUtils,
  Dialogs;

type
  TSplitProrailData = class(TObject)
  private
    mainFile: textfile;
    dataFolder: string;

    procedure Split;
    function GetSpoortakID(line: string): string;
    procedure Process(line: string);
  public
    procedure Execute;
  end;

// =================================================================================================
// TOursSplitProrailData
// =================================================================================================

constructor TOursSplitProrailData.Create;
begin
  raise Exception.Create('TOursSplitProrailData.Create not allowed');
end;

// -------------------------------------------------------------------------------------------------

class procedure TOursSplitProrailData.SplitProrailData;
begin
  with TSplitProrailData.Create do begin
    Execute;
    Free
  end;
end;

// =================================================================================================
// TSplitProrailData
// =================================================================================================

procedure TSplitProrailData.Execute;
var
  openDialog: TOpenDialog;
begin
  openDialog := TOpenDialog.Create(nil);
  openDialog.Filter := 'Prorail Data File|*.csv';
  openDialog.Options := [ofFileMustExist];
  openDialog.InitialDir := TOursFileUtils.ProgDir;
  if openDialog.Execute then begin
    var dataFile := openDialog.FileName;

    dataFolder := ChangeFileExt(dataFile, '');
    if not DirectoryExists(dataFolder) then
      ForceDirectories(dataFolder);
    dataFolder := IncludeTrailingPathDelimiter(dataFolder);

    AssignFile(mainFile, dataFile);
    Reset(mainFile);
    Split;
    CloseFile(mainFile);
  end;
  openDialog.Free;
end;

// -------------------------------------------------------------------------------------------------

function TSplitProrailData.GetSpoortakID(line: string): string;
var
  p: Integer;
  fields: TStringDynArray;
begin
  fields := SplitString(line, ';');
  Result := fields[0];

  p := Pos('_', Result);
  if p > 0 then
    Delete(Result, 1, p);

  p := Pos('_', Result);
  if p > 0 then
    Delete(Result, p - 1, 255);

  SetLength(fields, 0);
end;

// -------------------------------------------------------------------------------------------------

procedure TSplitProrailData.Process(line: string);
var
  tmpStr: string;
  tmpFile: textfile;
begin
  tmpStr := GetSpoortakID(line);
  var
  subFileName := dataFolder + tmpStr + '.csv';

  if FileExists(subFileName) then begin
    AssignFile(tmpFile, subFileName);
    Append(tmpFile);
  end else begin
    AssignFile(tmpFile, subFileName);
    Rewrite(tmpFile);
    Writeln(tmpFile, 'Spoortak_identificatie;Spoortak_locatie;KM;Contractgebied;GPS_Lat;GPS_Long;Hoogte_D1_L;Hoogte_D1_R;Hoogte_D1D2_L;Hoogte_D1D2_R;Schift_D1_L;Schift_D1_R;Schift_D1D21_L;Schift_D1D21_R;Spoorwijdte;Verkanting');
  end;
  Writeln(tmpFile, line);
  CloseFile(tmpFile);
end;

// -------------------------------------------------------------------------------------------------

procedure TSplitProrailData.Split;
var
  line: string;
begin
  ReadLn(mainFile, line); // Skip first line
  while not Eof(mainFile) do begin
    ReadLn(mainFile, line);
    Process(line);
  end;
end;

// =================================================================================================

end.
