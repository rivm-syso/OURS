{ @abstract(This unit contains the calculator for calculating the octave results from the frequency based FEM results.)
  The calculator executes the Python script "naverwerking.py" for each receptor, each source and
  each ground scenario.                                                   @br
  The script is called 3 times: for 0m, 25m and distance receptor-source. @br
  Only the relevant results are taken and stored:                         @br
  - distance 0m: "Y" and "fase"                                           @br
  - distance 25m: "Y" and "Y_ratio"                                       @br
  - distance receptor-source: "c", "c_ratio", "Y" and "Y_ratio".
}
unit OursCalcFemDerived;

interface

uses
  OursData,
  OursCalcBase,
  OursResultFem;

type
  { @abstract(Class responsible for executing the Phyton script, loading and storing all results.)
  }
  TOursFemDerivedCalculator = class(TOursBaseCalculator)
  strict private
  const
    NAME_MODULE = 'naverwerking.py';
  strict private
    FProgStr: string;
    FOutFile: string;
    FOutFolder: string;
    FScenario: TOursResultScenario;

    function ExecuteInternal(const dist, len: Double; var results: TOursNaverwerkingJSON): Integer;
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
// TOursFemDeried
// =================================================================================================

function TOursFemDerivedCalculator.Execute: Boolean;
var
  results: TOursNaverwerkingJSON;
begin
  results := nil;
  Result := False;

  // Check if tempfolder, external module and out-folder are available
  if not (TempAvailable and ProgAvailable(FProgStr) and OutFolderAvailable(FOutFolder)) then
    Exit;

  FOutFile := IncludeTrailingPathDelimiter(FOutFolder) + 'FEMverwerkt.json';

  for var rec in FProject.Receptors do begin
    FMessageList.AddInfo(Format('FEM post processing receptor "%s"', [rec.name]));
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

        if ExecuteInternal(0.0, 2.0, results) <> 0 then
          Exit;

        FScenario.FemDerived.Y_0.FillFromArray(results.Y);
        FScenario.FemDerived.fase_0.FillFromArray(results.fase);
        FScenario.FemDerived.JSON_0 := results.GetJSON;

        if ExecuteInternal(24.0, 2.0, results) <> 0 then
          Exit;

        FScenario.FemDerived.Y_25.FillFromArray(results.Y);
        FScenario.FemDerived.Y_ratio_25.FillFromArray(results.Y_ratio);
        FScenario.FemDerived.JSON_25 := results.GetJSON;

        if ExecuteInternal(dist, rec.CalcLength, results) <> 0 then
          Exit;

        FScenario.FemDerived.c_X.FillFromArray(results.c);
        FScenario.FemDerived.c_ratio_X.FillFromArray(results.c_ratio);
        FScenario.FemDerived.Y_X.FillFromArray(results.Y);
        FScenario.FemDerived.Y_ratio_X.FillFromArray(results.Y_ratio);
        FScenario.FemDerived.JSON_X := results.GetJSON;
      end;
    end;
  end;
  FreeAndNil(results);

  FMessageList.AddInfo('------------------------------------------------');
  Result := True;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemDerivedCalculator.ExecuteInternal(const dist, len: Double; var results: TOursNaverwerkingJSON): Integer;
var
  params, inFile: string;
begin
  FreeAndNil(results);
  Result := _exitcode_noResult;

  if SaveInFile(FScenario.ground.FemResults.ToJsonForDerived(dist, len), inFile) then begin
    params := GetParams(inFile, FOutFolder);
    Result := RunModule(FProgStr, params, FOutFile);
    if Result <> 0 then
      Exit;

    with TStringlist.Create do begin
      LoadFromFile(FOutFile);
      results := TOursNaverwerkingJSON.FromJsonString(Text);
      Free;
    end;
  end;

  if results=nil then begin
    Result := _exitcode_noResult;
    FMessageList.AddError(Format(rsExternalModuleNoResult, [Modulename, FOutFile]));
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursFemDerivedCalculator.GetModuleName: string;
begin
  Result := NAME_MODULE;
end;

// =================================================================================================

end.
