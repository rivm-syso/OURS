{ @abstract(This unit contains the calculator for calculating the uncertainty of the ground calculation.)
  The calculator executes the Python script "bodemonzekerheid.py" for each receptor, each source and
  each ground scenario.                                                           @br
  The script is called 3 times: for 0m, 25m and distance receptor-source.         @br
  Only the relevant results are taken and stored:                                 @br
  - distance 0m: "var_Y" and "var_fase"                                           @br
  - distance 25m: "var_Y" and "var_Y_ratio"                                       @br
  - distance receptor-source: "var_c", "var_c_ratio", "var_Y" and "var_Y_ratio".
}
unit OursCalcFemUncertainty;

interface

uses
  OursData,
  OursCalcBase,
  OursResultFem;

type
  { @abstract(Class responsible for executing the Phyton script, loading and storing all results.)
  }
  TOursFemUncertaintyCalculator = class(TOursBaseCalculator)
  strict private
  const
    NAME_MODULE = 'bodemonzekerheid.py';
  strict private
    FProgStr: string;
    FOutFile: string;
    FOutFolder: string;
    FScenario: TOursResultScenario;

    function ExecuteInternal(const idx: Integer; var results: TOursUncertaintyJSON): Integer;
  protected
    function GetModuleName: string; override;
  public
    function Execute: Boolean; override;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  SysUtils,
  Classes,
  OursStrings,
  OursUtils;

// =================================================================================================
// TOursFemUncertaintyCalculator
// =================================================================================================

function TOursFemUncertaintyCalculator.Execute: Boolean;
var
  results: TOursUncertaintyJSON;
begin
  results := nil;
  Result := False;

  // Check if tempfolder, external module and out-folder are available
  if not (TempAvailable and ProgAvailable(FProgStr) and OutFolderAvailable(FOutFolder)) then
    Exit;

  FOutFile := IncludeTrailingPathDelimiter(FOutFolder) + 'bodemonzekerheidUit.json';

  for var rec in FProject.Receptors do begin
    FMessageList.AddInfo(Format('FEM ground uncertainty receptor "%s"', [rec.name]));
    for var src in rec.Sources do begin
      var dist := TOursMath.dist(rec.pos, src.pos);
      if dist > FProject.Settings.MaxCalcDistance then begin
        // Receptor outside zone of source. Source has no (relevant) contribution to receptor
        FMessageList.AddWarning(Format(rsSourceDistanceTooLarge, [dist, FProject.Settings.MaxCalcDistance]));
        Continue;
      end;
      if src.Results.scenarios.Count=0 then begin
        FMessageList.AddWarning(Format(rsExternalModuleNoGround, [src.Track.name]));
        Continue;
      end;

      for var scenario in src.Results.scenarios do begin
        FScenario := scenario;
        if FCanceled then
          Exit;

        FMessageList.AddInfo(Format('- Source "%s", ground "%s"', [src.Track.name, scenario.ground.name]));

        if ExecuteInternal(0, results) <> 0 then
          Exit;

        FScenario.FemUncertainty.var_Y_0.FillFromArray(results.var_Y);
        FScenario.FemUncertainty.var_fase_0.FillFromArray(results.var_fase);

        if ExecuteInternal(1, results) <> 0 then
          Exit;

        FScenario.FemUncertainty.var_Y_25.FillFromArray(results.var_Y);
        FScenario.FemUncertainty.var_Y_ratio_25.FillFromArray(results.var_Y_ratio);

        if ExecuteInternal(2, results) <> 0 then
          Exit;

        FScenario.FemUncertainty.var_c_X.FillFromArray(results.var_c);
        FScenario.FemUncertainty.var_c_ratio_X.FillFromArray(results.var_c_ratio);
        FScenario.FemUncertainty.var_Y_X.FillFromArray(results.var_Y);
        FScenario.FemUncertainty.var_Y_ratio_X.FillFromArray(results.var_Y_ratio);
      end;
    end;
  end;
  FreeAndNil(results);

  FMessageList.AddInfo('------------------------------------------------');
  Result := True;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemUncertaintyCalculator.ExecuteInternal(const idx: Integer; var results: TOursUncertaintyJSON): Integer;
var
  params, inFile: string;
begin
  FreeAndNil(results);
  Result := _exitcode_noResult;

  var str := '';
  case idx of
    1: str := FScenario.FemDerived.JSON_25;
    2: str := FScenario.FemDerived.JSON_X;
  else str := FScenario.FemDerived.JSON_0;
  end;

  // >> Allign JSON properly...
  var strList :=TStringList.Create;
  strList.Text := str;

  for var i := 0 to strList.Count-1 do
    strList.Strings[i] := '        ' + strList.Strings[i];

  str := strList.Text;
  strList.Free;
  // <<

  var inStr := '{' + CRLF;

  var maxFreq := FScenario.ground.FemResults.MaxFreqLimited;
  if TOursMath.ge(maxFreq, 0.0) then begin
    inStr := inStr +
             '    "FEMOutput": {' + CRLF +
             '        "MaxFreqLimited":' + maxFreq.ToString + CRLF +
             '    },' + CRLF;
  end;

  inStr := inStr +
           FScenario.ground.GroundAsJsonForUncertainty + ',' + CRLF +
           '    "NaverwerkingOutput":'                       + CRLF +
           '    ['                                           + CRLF +
           str                                                      +
           '    ]'                                           + CRLF +
           '}'                                               + CRLF;

  if SaveInFile(inStr, inFile) then begin
    params := GetParams(inFile, FOutFolder);
    Result := RunModule(FProgStr, params, FOutFile);
    if Result <> 0 then
      Exit;

    with TStringlist.Create do begin
      LoadFromFile(FOutFile);
      results := TOursUncertaintyJSON.FromJsonString(Text);
      Free;
    end;
  end;

  if results=nil then begin
    Result := _exitcode_noResult;
    FMessageList.AddError(Format(rsExternalModuleNoResult, [Modulename, FOutFile]));
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemUncertaintyCalculator.GetModuleName: string;
begin
  Result := NAME_MODULE;
end;

// =================================================================================================

end.
