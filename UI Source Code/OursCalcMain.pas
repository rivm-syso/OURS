{ @abstract(This unit contains the calculator for the main formula.)
  The calculator executes the Python script "deformule.py" for each receptor, source, ground
  scenario, train and period.
}
unit OursCalcMain;

interface

uses
  OursData,
  OursCalcBase,
  OursResultFem,
  OursResultBuilding,
  OursResultMain;

type
  { @abstract(Class responsible for executing the Phyton script and loading and storing the results.)
  }
  TOursMainCalculator = class(TOursBaseCalculator)
  strict private
  const
    { @abstract(Name of the corresponding Python script.)
      This script needs to be present in the Python folder, which is located in the program folder.
    }
    NAME_MODULE = 'deformule.py';
  strict private
    { @abstract(Creates the JSON input file for the calculation.)
    }
    function CreateJsonString(AResults: TOursResults): string;

    { @abstract(Creates the JSON part of the speeds of all measurements for the receptor/source.)
      The speed is the average of the speed during day, evening and night.
    }
    function _snelheid(AResults: TOursResults): string;

    { @abstract(Creates the JSON part of the train classes of all measurements for the receptor/source.)
      Value 1 indicates passenger train and value 2 indicates freight train.
    }
    function _treinklasse(AResults: TOursResults): string;

    { @abstract(Creates the JSON part of the sourcetype for the receptor/source.)
      The result contains only 1 value. @br
      - 1 = track (welded rail)         @br
      - 2 = switch                      @br
      - 3 = weld                        @br
      - 4 = crossing
    }
    function _brontype(AResults: TOursResults): string;

    { @abstract(Creates the JSON part of the flow of trains per week voor day, evening and night for the receptor/source.)
      Value 1 indicates passenger train and value 2 indicates freight train.
    }
    function _aantaltreinenPerWeek(AResults: TOursResults): string;

    { @abstract(Creates the JSON part of the ?? Vd ?? for the receptor/source.)
      Fixed value: 'false'.
    }
    function _Vd(AResults: TOursResults): string;

    { @abstract(Creates the JSON part of the CgeoZ for the receptor/source.)
      Currently unknown; fixed value:[1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    }
    function _CgeoZ(AResults: TOursResults): string;

    { @abstract(Creates the JSON part of the CgeoX for the receptor/source.)
      Currently unknown; fixed value:[1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    }
    function _CgeoX(AResults: TOursResults): string;

    { @abstract(Creates the JSON part with the probabilities of the ground scenario's for the receptor/source.)
    }
    function _scenarioKansen(AResults: TOursResults): string;

    { @abstract(Creates the JSON part with the distance between receptor and source.)
    }
    function _R(AResults: TOursResults): string;

    { @abstract(Creates the JSON part with measurement data for all measurements for each train for the receptor/source.)
    }
    function _Bron(AResults: TOursResults): string;

    { @abstract(Creates the JSON part with FEM results for all ground scenario's for the receptor/source.)
    }
    function _FEM(AResults: TOursResults): string;

    { @abstract(Creates the JSON part with building results for all ground scenario's for the receptor/source.)
    }
    function _Hgebouw(AResults: TOursResults): string;
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
  OursUtils,
  OursStrings;

// =================================================================================================
// TOursMainCalculator
// =================================================================================================
// Berekening per punt, per bron en per bodem.
function TOursMainCalculator.Execute: Boolean;
var
  inJSON, inFile, outFolder, outFile: string;
  params, progStr: string;
  ExitCode: Cardinal;
begin
  Result := False;

  // Check if tempfolder and out-folder are available
  if not OutFolderAvailable(outFolder) then
    Exit;
  outFile := IncludeTrailingPathDelimiter(outFolder) + 'deformuleUit.json';

  // Check if external module is available
  if not ProgAvailable(progStr) then
    Exit;

  // Execute calculation for each receptor, each source and each ground scenario
  try
    for var rec in FProject.Receptors do begin
      FMessageList.AddInfo(Format('Main formula for receptor "%s"', [rec.name]));
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

        FMessageList.AddInfo(Format('- Source "%s"', [src.Track.name]));

        inJSON := CreateJsonString(src.Results);
        if not SaveInFile(inJSON, inFile) then
          Continue;

        params := GetParams(inFile, outFolder);
        ExitCode := RunModule(progStr, params, outFile);
        if ExitCode <> 0 then
          Exit;

        var sl := TStringlist.Create;
        sl.LoadFromFile(outFile);
        src.Results.MainResults.CopyFromJsonString(sl.Text);
        sl.Free;
      end;
    end;
  finally
    if FCanceled then begin
      FMessageList.AddInfo('Building module canceled')
    end else begin
      Result := (not FMessageList.HasError);
    end;
    FMessageList.AddInfo('------------------------------------------------');
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator.CreateJsonString(AResults: TOursResults): string;
begin
  Result := '{'                                                                        + CRLF +
            '    "Overig": {'                                                          + CRLF +
     Format('        "snelheid":[%s],', [_snelheid(AResults)])                         + CRLF +
     Format('        "treinklasse":[%s],', [_treinklasse(AResults)])                   + CRLF +
     Format('        "brontype":[%s],', [_brontype(AResults)])                         + CRLF +
     Format('        "aantaltreinenPerWeek":[%s],', [_aantaltreinenPerWeek(AResults)]) + CRLF +
     Format('        "Vd":%s,', [_Vd(AResults)])                                       + CRLF +
     Format('        "CgeoZ":%s,', [_CgeoZ(AResults)])                                 + CRLF +
     Format('        "CgeoX":%s,', [_CgeoX(AResults)])                                 + CRLF +
     Format('        "scenarioKansen":[%s],', [_scenarioKansen(AResults)])             + CRLF +
     Format('        "R":[%s]', [_R(AResults)])                                        + CRLF +
            '    },'                                                                   + CRLF +
            _Bron(AResults) +
            _FEM(AResults) +
            _Hgebouw(AResults) +
            '}'                                                                        + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._snelheid(AResults: TOursResults): string;
begin
  Result := '';
  for var train in AResults.Source.TrainMeasurements do begin
    if Result = '' then
      Result := Result + Format('%.f', [train.Key.getAverageV])
    else
      Result := Result + Format(', %.f', [train.Key.getAverageV]);
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._treinklasse(AResults: TOursResults): string;
begin
  Result := '';
  for var train in AResults.Source.TrainMeasurements do begin
    var tmp := train.Key.cat;

    if Result = '' then
      Result := Result + Format('%d', [tmp])
    else
      Result := Result + Format(', %d', [tmp]);
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._brontype(AResults: TOursResults): string;
begin
  Result := Format('%d', [AResults.Source.Track.sourcetype_id]);
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._aantaltreinenPerWeek(AResults: TOursResults): string;
begin
  Result := '';
  for var train in AResults.Source.TrainMeasurements do begin
    var tmp := Format('[%.f, %.f, %.f]', [train.Key.getQweek(1), train.Key.getQweek(2), train.Key.getQweek(3)]);

    if Result = '' then
      Result := Result + Format('%s', [tmp])
    else
      Result := Result + Format(', %s', [tmp]);
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._vd(AResults: TOursResults): string;
begin
  Result := 'false'; // Default value.
  if FProject.vd = 1 then
    Result := 'true';
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._CgeoZ(AResults: TOursResults): string;
begin
  Result := AResults.Source.TrackPart.CgeoZ.AsJsonText;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._CgeoX(AResults: TOursResults): string;
begin
  Result := AResults.Source.TrackPart.CgeoX.AsJsonText;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._scenarioKansen(AResults: TOursResults): string;
begin
  Result := '';
  for var scenario in AResults.Scenarios do begin
    if Result <> '' then
      Result := Result + ', ';

    Result := Result + Format('%.f', [scenario.probability]);
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._R(AResults: TOursResults): string;
begin
  Result := Format('%.f', [TOursMath.dist(AResults.Receptor.pos, AResults.Source.pos)]);
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._Bron(AResults: TOursResults): string;
begin
  Result := '';
  for var train in AResults.source.TrainMeasurements do begin
    var tmp := train.Value.AsJSON;

    if Result <> '' then
      Result := Result + ',' + CRLF;

    Result := Result + '        [' + CRLF + tmp + '        ]';
  end;

  Result := '    "Bron": [' + CRLF + Result + CRLF + '    ],' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._FEM(AResults: TOursResults): string;
begin
  Result := '';

  var json := '';
  for var scenario in AResults.Scenarios do begin
    if json <> '' then
      json := json + ',' + CRLF;

    json := json + scenario.FemForMainFormulaAsJSON;
  end;
  Result := '    "FEM": ['     + CRLF + json + CRLF + '    ],' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator._Hgebouw(AResults: TOursResults): string;
begin
  Result := '';

  var json := '';
  for var scenario in AResults.Scenarios do begin
    if json <> '' then
      json := json + ',' + CRLF;

    json := json + scenario.HBuilding.ToJsonString;
  end;
  Result := '    "Hgebouw": ['     + CRLF + json + CRLF + '    ]' + CRLF;
end;

// -------------------------------------------------------------------------------------------------

function TOursMainCalculator.GetModuleName: string;
begin
  Result := NAME_MODULE
end;

// =================================================================================================

end.
