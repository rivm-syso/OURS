{ @abstract(This unit contains the calculator to retrieve the ground data.)
  The calculator executes the Python script "cpt_tool.py" for each receptor - source combination.
  The ground scenario's are stored within FProject.GroundList. For each source a list with
  ground scenario's if stored (in Results.Scenarios) with the probability, distance to the receptor
  and a reference to the ground scenario.
  Before storing a new ground scenario, the existing list is checked to see if a scenario with the
  same data already exists. In which case the existing scenario is used.
}
unit OursCalcGround;

interface

uses
  OursCalcBase;

type
  { @abstract(Class responsible for executing the Phyton script and loading and storing the results.)
  }
  TOursGroundCalculator = class(TOursBaseCalculator)
  strict private
  const
    { @abstract(Name of the corresponding Python script.)
      This script needs to be present in the Python folder, which is located in the program folder.
    }
    NAME_MODULE = 'cpt_tool.py';
  strict private
    { @abstract(Checks if the file "ground.xml" is located in the common documents folder or, if
      not in the personal documents folder.)
    }
    function BroAvailable(out BroFile: string): Boolean;

    { @abstract(Creates the JSON input file for the calculation.)
    }
    function CreateJsonString(broFile: string): string;
  protected
    { @abstract(Returns the module name.)
    }
    function GetModuleName: string; override;
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
  OursData,
  OursResultGround,
  OursUtils,
  OursStrings;

// =================================================================================================
// TOursGroundCalculator
// =================================================================================================

function TOursGroundCalculator.Execute: Boolean;
var
  inJSON, inFile, broFile, outFolder: string;
  params, progStr: string;
  ExitCode: Cardinal;
begin
  Result := False;

  // Check if tempfolder, external module and BRO-data are available
  if not(TempAvailable and ProgAvailable(progStr) and BroAvailable(broFile)) then
    Exit;

  // Create JSON string and save to file
  inJSON := CreateJsonString(broFile);
  if not SaveInFile(inJSON, inFile) then
    Exit;

  // Get and check output-folder
  if not OutFolderAvailable(outFolder) then
    Exit;

  if FCanceled then
    Exit;

  // Start external ground-module and wait...
  FMessageList.AddInfo('------------------------------------------------');
  FMessageList.AddInfo('Ground module started');
  //if not FileExists(ChangeFileExt(broFile, '.idx')) then
  //  FMessageList.AddInfo('CPT not yet indexed. This could take upto 5 minutes extra.');
  params := GetParams(inFile, outFolder);
  ExitCode := RunModule(progStr, params, '');
  if ExitCode <> 0 then
    Exit;

  FMessageList.AddInfo('Ground module done');
  Result := True;

  var idx := -1;
  for var rec in FProject.Receptors do begin
    for var src in rec.Sources do begin
      inc(idx, 1);

      var outFile := IncludeTrailingPathDelimiter(outFolder) + 'results_' + idx.ToString + '.json';
      if not FileExists(outFile) then begin
        FMessageList.AddError(Format(rsExternalModuleNoGroundResults, [rec.Name, src.Track.Name]));
        Continue;
      end;

      var sl := TStringlist.Create;
      try
        sl.LoadFromFile(outFile);
        var _output := TOursGroundOutput.FromJsonString(sl.Text);

        for var scenario in _output.scenarios do begin
          if Round(100 * scenario.probability) = 0 then
            Continue;

          var _grnd := TOursGroundScenario.Create;

          _grnd.depth.AssignFromArray(scenario.data.depth);
          _grnd.E.AssignFromArray(scenario.data.E);
          _grnd.v.AssignFromArray(scenario.data.v);
          _grnd.rho.AssignFromArray(scenario.data.rho);
          _grnd.damping.AssignFromArray(scenario.data.damping);

          _grnd.var_depth.AssignFromArray(scenario.data.var_depth);
          _grnd.var_E.AssignFromArray(scenario.data.var_E);
          _grnd.var_v.AssignFromArray(scenario.data.var_v);
          _grnd.var_rho.AssignFromArray(scenario.data.var_rho);
          _grnd.var_damping.AssignFromArray(scenario.data.var_damping);

          var grndIdx := FProject.GroundList.IndexOf(_grnd);
          if grndIdx = -1 then begin
            FProject.GroundList.Add(_grnd);
            _grnd.name := 'Scenario ' + (FProject.GroundList.Count).ToString;
            for var i := 0 to Length(scenario.data.lithology)-1 do
              _grnd.lithology.Add(scenario.data.lithology[i]);
          end else begin
            _grnd.Free;
            _grnd := FProject.GroundList[grndIdx];
          end;
          _grnd.distance := TOursMath.dist(rec.pos, src.pos) + rec.CalcLength;

          var newScenario := src.Results.AddScenario(_grnd);
          newScenario.probability := scenario.probability;
          newScenario.distance := TOursMath.dist(rec.pos, src.pos);
        end;

        _output.Free;
      finally
        sl.Free;
      end;
    end;
  end;
  FMessageList.AddInfo('------------------------------------------------');
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundCalculator.BroAvailable(out BroFile: string): Boolean;
begin
  Result := False;

  var broFolder := TOursFileUtils.BroDir;
  broFile := TOursFileUtils.BroFile;

  if not FileExists(broFile) then begin
    FMessageList.AddError(Format(rsDocFolderBroNotFound, [broFile]));
    Exit;
  end;

  if not DirectoryExists(broFolder) then begin
    FMessageList.AddError(Format(rsDocFolderNotFound, [broFolder]));
    Exit;
  end;

  if not TOursFileUtils.IsFolderWriteable(broFolder) then begin
    FMessageList.AddError(Format(rsDocFolderNotWritable, [broFolder]));
    Exit;
  end;

  Result := True;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundCalculator.CreateJsonString(broFile: string): string;
var
  broXML, srcX, srcY, recX, recY: string;
begin
  Result := '';
  broXML := broFile;
  broXML := StringReplace(broXML, PathDelim, '/', [rfReplaceAll]);

  srcX := '';
  srcY := '';
  recX := '';
  recY := '';
  for var rec in FProject.Receptors do begin
    for var src in rec.Sources do begin
      if srcX <> '' then
        srcX := srcX + ', ';

      if srcY <> '' then
        srcY := srcY + ', ';

      if recX <> '' then
        recX := recX + ', ';

      if recY <> '' then
        recY := recY + ', ';

      srcX := srcX + '"' + Round(src.x).ToString + '"';
      srcY := srcY + '"' + Round(src.y).ToString + '"';
      recX := recX + '"' + Round(rec.x).ToString + '"';
      recY := recY + '"' + Round(rec.y).ToString + '"';
    end;
  end;

  Result := '{' + CRLF +
            Format('    "Name"             : "%s",%s', [FProject.Name, CRLF]) +
            Format('    "MaxCalcDist"      : %.1f,%s', [FProject.Settings.MaxCalcDistance, CRLF]) +
            Format('    "MaxCalcDepth"     : %.1f,%s', [FProject.Settings.MaxCalcDepth, CRLF]) +
            Format('    "MinLayerThickness": %.1f,%s', [FProject.Settings.MinLayerThickness, CRLF]) +
            Format('    "MinElementSize"   : %.3f,%s', [FProject.Settings.minElementSize, CRLF]) +
            Format('    "SpectrumType"     : %d,%s',   [FProject.Settings.SpectrumType, CRLF]) +
            Format('    "LowFreq"          : %.f,%s',  [FProject.Settings.LowFreq, CRLF]) +
            Format('    "HighFreq"         : %.f,%s',  [FProject.Settings.HighFreq, CRLF]) +
            Format('    "CalcType"         : %d,%s',   [FProject.Settings.CalcType, CRLF]) +
            Format('    "Source_x"         : [%s],%s', [srcX, CRLF]) +
            Format('    "Source_y"         : [%s],%s', [srcY, CRLF]) +
            Format('    "Receiver_x"       : [%s],%s', [recX, CRLF]) +
            Format('    "Receiver_y"       : [%s],%s', [recY, CRLF]) +
            Format('    "BRO_data"         : "%s" %s', [broXML, CRLF]) +
            '}' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursGroundCalculator.GetModuleName: string;
begin
  Result := NAME_MODULE
end;

// =================================================================================================

end.
