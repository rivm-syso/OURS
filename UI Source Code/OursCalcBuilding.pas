{ @abstract(This unit contains the calculator for the building formula.)
  The calculator executes the Python script "Hgebouw.py" for each receptor, source and ground
  scenario.
}
unit OursCalcBuilding;

interface

uses
  OursResultBuilding,
  OursData,
  OursCalcBase;

type
  { @abstract(Class responsible for executing the Phyton script and loading and storing the results.)
  }
  TOursBuildingCalculator = class(TOursBaseCalculator)
  strict private
  const
    { @abstract(Name of the corresponding Python script.)
      This script needs to be present in the Python folder, which is located in the program folder.
    }
    NAME_MODULE = 'Hgebouw.py';
  strict private

    { @abstract(Creates the JSON input file for the calculation.)
    }
    function CreateJsonString(AScenario: TOursResultScenario): string;
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
// TOursBuildingCalculator
// =================================================================================================

function TOursBuildingCalculator.Execute: Boolean;
var
  inJSON, inFile, outFolder, outFile: string;
  params, progStr: string;
  ExitCode: Cardinal;
begin
  Result := False;

  // Check if temp folder and output folder are available.
  if not OutFolderAvailable(outFolder) then
    Exit;
  outFile := IncludeTrailingPathDelimiter(outFolder) + 'HgebouwUit.json';

  // Check of externe module beschikbaar is
  if not ProgAvailable(progStr) then
    Exit;

  // Execute calculation for each receptor, each source and each ground scenario
  try
    for var rec in FProject.Receptors do begin
      FMessageList.AddInfo(Format('Building module receptor "%s"', [rec.name]));
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
          FMessageList.AddInfo(Format('- Source "%s", ground "%s"', [src.Track.name, scenario.ground.name]));

          inJSON := CreateJsonString(scenario);
          if not SaveInFile(inJSON, inFile) then
            Exit;

          params := GetParams(inFile, outFolder);
          ExitCode := RunModule(progStr, params, outFile);
          if ExitCode <> 0 then
            Exit;

          var sl := TStringlist.Create;
          sl.LoadFromFile(outFile);
          var _result := TOursBuildingOutput.FromJsonString(sl.Text);
          sl.Free;
          scenario.HBuilding.SetFromOutput(_result);
          _result.Free;
        end;
        if FCanceled then
          Exit;
      end;
      if FCanceled then
        Exit;
    end;
  finally
    if FCanceled then begin
      FMessageList.AddInfo('Building module canceled')
    end else begin
      Result := not FMessageList.HasError;
    end;
    FMessageList.AddInfo('------------------------------------------------');
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursBuildingCalculator.CreateJsonString(AScenario: TOursResultScenario): string;
begin
  var hgebouw_input := TOursBuildingInput.Create;

  // "Bodem"
  hgebouw_input.ground.y.FillValues(AScenario.FemDerived.Y_0);
  hgebouw_input.ground.fase.FillValues(AScenario.FemDerived.fase_0);
  hgebouw_input.ground.c.FillValues(AScenario.FemDerived.c_X);
  hgebouw_input.ground.c_ratio.FillValues(AScenario.FemDerived.c_ratio_X);

  hgebouw_input.ground.var_y.FillValues(AScenario.FemUncertainty.var_Y_0);
  hgebouw_input.ground.var_fase.FillValues(AScenario.FemUncertainty.var_fase_0);
  hgebouw_input.ground.var_c.FillValues(AScenario.FemUncertainty.var_c_X);
  hgebouw_input.ground.var_c_ratio.FillValues(AScenario.FemUncertainty.var_c_ratio_X);

  // "Vloer"
  with AScenario.receptor.Floor do begin
    hgebouw_input.floor.quarterSpan.AddRange(frequenciesQuarterSpan);
    hgebouw_input.floor.midSpan.AddRange(frequenciesMidSpan);
    hgebouw_input.floor.floorSpan.AddRange(floorSpan);
    hgebouw_input.floor.wood.AddRange(woodenfloor);

    hgebouw_input.floor.varQuarterSpan.AddRange(varFrequenciesQuarterSpan);
    hgebouw_input.floor.varMidSpan.AddRange(varFrequenciesMidSpan);
    hgebouw_input.floor.varFloorSpan.AddRange(varFloorSpan);
    hgebouw_input.floor.varWood.AddRange(varWoodenFloor);
  end;

  // "Gebouw"
  with AScenario.receptor.Building do begin
    hgebouw_input.building.yearOfConstruction.AddRange(yearOfConstruction);
    hgebouw_input.building.apartment.AddRange(apartment);
    hgebouw_input.building.buildingHeight.AddRange(buildingHeight);
    hgebouw_input.building.numberOfFloors.AddRange(numberOfFloors);
    hgebouw_input.building.heightOfFloor.AddRange(heightOfFloor);
    hgebouw_input.building.floorNumber.AddRange(floorNumber);
    hgebouw_input.building.wallLength.AddRange(wallLength);
    hgebouw_input.building.facadeLength.AddRange(facadeLength);

    hgebouw_input.building.varYearOfConstruction.AddRange(varYearOfConstruction);
    hgebouw_input.building.varApartment.AddRange(varApartment);
    hgebouw_input.building.varBuildingHeight.AddRange(varBuildingHeight);
    hgebouw_input.building.varNumberOfFloors.AddRange(varNumberOfFloors);
    hgebouw_input.building.varHeightOfFloor.AddRange(varHeightOfFloor);
    hgebouw_input.building.varFloorNumber.AddRange(varFloorNumber);
    hgebouw_input.building.varWallLength.AddRange(varWallLength);
    hgebouw_input.building.varFacadeLength.AddRange(varFacadeLength);
  end;

  // Create JSON-string
  Result := hgebouw_input.ToJsonString;
  hgebouw_input.Free;
end;

// -------------------------------------------------------------------------------------------------

function TOursBuildingCalculator.GetModuleName: string;
begin
  Result := NAME_MODULE
end;

// =================================================================================================

end.
