{ @abstract(This unit contains the calculator for the Fem calculations.)
  The calculator executes the Python script "fem_main.py" for each ground scenario.
}
unit OursCalcFem;

interface

uses
  OursData,
  OursCalcBase;

type
  { @abstract(Class responsible for executing the Phyton script, loading and storing all results.)
  }
  TOursFemCalculator = class(TOursBaseCalculator)
  strict private
  const
    { @abstract(Name of the corresponding Python script.)
      This script needs to be present in the Python folder, which is located in the program folder.
    }
    NAME_MODULE = 'fem_main.py';
  strict private
    { @abstract(Creates the JSON input file for the calculation.)
    }
    function CreateJsonString(const grnd: TOursGroundScenario): string;
  protected
    { @abstract(Returns the module name.)
    }
    function GetModuleName: string; override;

    { @abstract(Returns the parameters to execute the FEM script.)
      The current FEM script requires a 3rd parameter!
      Example of execution Python script: @br
      @italic(python.exe naverwerking.py -i input.json -o outputfolder -r output.txt)
    }
    function GetParams(const inStr, outStr: string): string; override;
  public
    { @abstract(Executes the Python script and loads and stores all results.)
    }
    function Execute: Boolean; override;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  SysUtils,
  Classes,
  OursResultFem,
  OursStrings;

// =================================================================================================
// TOursFemCalculator
// =================================================================================================

function TOursFemCalculator.Execute: Boolean;
var
  inJSON, inFile, outFolder, outFile: string;
  params, progStr: string;
  ExitCode: Cardinal;
begin
  Result := False;

  // Check if tempfolder, external module and out-folder are available
  if not (TempAvailable and ProgAvailable(progStr) and OutFolderAvailable(outFolder)) then
    Exit;

  var idx := -1;
  for var grnd in FProject.GroundList do begin
    inc(idx, 1);
    FMessageList.AddInfo(Format('FEM calculation "%s"', [grnd.name]));

    // Create JSON string and save to file
    inJSON := CreateJsonString(grnd);
    if not SaveInFile(inJSON, inFile) then begin
      Continue;
    end;

    outFile := IncludeTrailingPathDelimiter(outFolder) + 'results_' + idx.ToString + '.json';

    // Start external Fem-module and wait...
    params := GetParams(inFile, outFile);
    ExitCode := RunModule(progStr, params, outFile);
    if ExitCode <> 0 then
      Exit;

    var sl := TStringlist.Create;
    try
      sl.LoadFromFile(outFile);
      grnd.FemResults := TOursFemOutput.FromJsonString(sl.Text);
    finally
      sl.Free;
    end;
  end;
  FMessageList.AddInfo('------------------------------------------------');
  Result := True;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemCalculator.CreateJsonString(const grnd: TOursGroundScenario): string;
begin
  var dist := grnd.distance + 0.01; // Avoid rounding errors when calculating derived FEM results

  Result := '{' + CRLF +
            Format('    "Name"             : "%s",%s', [FProject.name, CRLF]) +
            Format('    "MaxCalcDist"      : %.f,%s',  [dist, CRLF]) +
            Format('    "MaxCalcDepth"     : %.f,%s',  [FProject.Settings.MaxCalcDepth, CRLF]) +
            Format('    "MinLayerThickness": %.f,%s',  [FProject.Settings.MinLayerThickness, CRLF]) +
            Format('    "MinElementSize"   : %.3f,%s', [FProject.Settings.minElementSize, CRLF]) +
            Format('    "SpectrumType"     : %d,%s',   [FProject.Settings.SpectrumType, CRLF]) +
            Format('    "LowFreq"          : %.f,%s',  [FProject.Settings.LowFreq, CRLF]) +
            Format('    "HighFreq"         : %.f,%s',  [FProject.Settings.HighFreq, CRLF]) +
//            Format('    "MaxFreqLimited"   : %.f,%s',  [FProject.Settings.HighFreq, CRLF]) + // Should not be part of the input
            Format('    "CalcType"         : %d,%s',   [FProject.Settings.calcType, CRLF]) +
            grnd.GroundAsJsonForFem +
            '}' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemCalculator.GetModuleName: string;
begin
  Result := NAME_MODULE;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemCalculator.GetParams(const inStr, outStr: string): string;
var
  txtFile: string;
begin
  Result := inherited;

  // Current FEM requires a 3rd parameter!
  // Example of execution Python script: python.exe naverwerking.py -i input.json -o outputfolder -r output.txt

  txtFile := ChangeFileExt(outStr, '.TXT');
  txtFile := StringReplace(txtFile, PathDelim, '/', [rfReplaceAll]);

  Result := Format('%s -r "%s"', [Result, txtFile]);
end;

// =================================================================================================

end.
