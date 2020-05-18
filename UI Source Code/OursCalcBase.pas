{ @abstract(This unit contains base class for all Python calculators.)
  This main class contains all base methods and data to be able to execute a calculation.
  Besides enabling a calculation it also contains methods to cancel a calculation.
}
unit OursCalcBase;

interface

uses
  Windows,
  Generics.Collections,
  OursMessage,
  OursData;

type
  { @abstract(This is the base class for all Python calculators.)
    Use the class functions to retrieve the corresponding calculators.
  }
  TOursBaseCalculator = class(TObject)
  private
    { @abstract(Enables access to the process handle and thread for terminating the calculation.)
    }
    FProcessInfo: TProcessInformation;

    { @abstract(Adds all child processes of aPID to aList.)
    }
    function AddChildProcesses(aList: TList<DWORD>; aPID: DWORD): Boolean;

    { @abstract(Ends a process with aPID.)
      Running Python creates an unknown number of child processes. To successfully terminate a
      calculation all child processes need to be identified and terminated seperately.
    }
    procedure EndModule(aPID: DWORD = 0);
  protected const
    { @abstract(Exitcode in case the calculation is terminated by the user.)
    }
    _exitcode_terminated = 999;

    { @abstract(Exitcode in case the script does not produce results. Probably due to an
      unsuspected error in the script.)
    }
    _exitcode_noResult = 998;
  protected
    { @abstract(Indicates if the calculation is canceled by the user.)
    }
    FCanceled: Boolean;

    { @abstract(Reference to the OURS project.)
    }
    FProject: TOursProject;

    { @abstract(Reference to the OURS message list to report progress and other messages.)
    }
    FMessageList: TOursMessageList;

    { @abstract(Starts the process "progStr" with parameters "params" and waits until the process is ended.)
      The function returns the exitcode of the process. 0 indicates success.
    }
    function RunModule(progStr, params, outputFile: string): Cardinal;

    { @abstract(Indicates if the OURS folder for temporary files is present and writable.)
      The OURS folder for temporary files is a folder located in the Windows temp-folder.
      The name of this folder is 'OURS_' followed by the process-id.

    }
    function TempAvailable: Boolean;

    { @abstract(Abstract function to retrieve the module name (filename of the Python script).)
    }
    function GetModuleName: string; virtual; abstract;

    { @abstract(Save the JSON string to a file and returns success.)
      If the data is successfully saved "inFile" contains the name of the file. @br
      The file is placed in the program tempfolder and is called "input.json"
    }
    function SaveInFile(inputJSON: string; out inFile: string): Boolean; virtual;

    { @abstract(Determines the name of the output folder and returns if this folder exists.)
      The output folder is located in the program tempfolder and is "OUT". @br
      If the folder already exists, any files in it will be deleted.
    }
    function OutFolderAvailable(out outFolder: string): Boolean; virtual;

    { @abstract(Returns the command line parameters which will start the Python script.)
      Python prefers '/' as path delimeter and not '\': all backslashes will be replaced.
    }
    function GetParams(const inStr, outStr: string): string; virtual;

    { @abstract(Property to return the module name. The getter needs to be implemented in each ancestor.)
    }
    property Modulename: string read GetModuleName;
  public
    { @abstract(Creates and returns the calculator for the ground data.)
    }
    class function GetGroundCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;

    { @abstract(Creates and returns the calculator for the fem calculations.)
    }
    class function GetFemCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;

    { @abstract(Creates and returns the calculator for the fem post processing.)
    }
    class function GetFemDerivedCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;

    { @abstract(Creates and returns the calculator for the ground uncertainty calculation.)
    }
    class function GetFemUncertaintyCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;

    { @abstract(Creates and returns the calculator for the building calculations.)
    }
    class function GetBuildingCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;

    { @abstract(Creates and returns the calculator for the main formula.)
    }
    class function GetMainCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;


    { @abstract(Checks if python.exe and the python script (modulename) exist.)
      python.exe and the Python script given by ModuleName need to be located in the folder Python
      which is located in the OURS program folder.
    }
    function ProgAvailable(out progStr: string): Boolean; virtual;

    { @abstract(Executes the Python script and loads/stores results. Needs to be implemented in each ancestor.)
    }
    function Execute: Boolean; virtual; abstract;

    { @abstract(Method is called if the user cancels the calculation.)
    }
    procedure Terminate; virtual;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  Forms,
  Dialogs,
  TLHelp32,
  Classes,
  Controls,
  SysUtils,
  OursStrings,
  OursUtils,
  OursCalcGround,
  OursCalcFem,
  OursCalcFemDerived,
  OursCalcFemUncertainty,
  OursCalcBuilding,
  OursCalcMain;

// =================================================================================================
// TOursBaseCalculator
// =================================================================================================

class function TOursBaseCalculator.GetGroundCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;
begin
  Result := TOursGroundCalculator.Create;

  Result.FProject := aProject;
  Result.FMessageList := aMessageList;
end;

// -------------------------------------------------------------------------------------------------

class function TOursBaseCalculator.GetFemCalculator(const aProject: TOursProject; const aMessageList: TOursMessageList): TOursBaseCalculator;
begin
  Result := TOursFemCalculator.Create;

  Result.FProject := aProject;
  Result.FMessageList := aMessageList;
end;

// -------------------------------------------------------------------------------------------------

class function TOursBaseCalculator.GetFemDerivedCalculator(const aProject: TOursProject;
  const aMessageList: TOursMessageList): TOursBaseCalculator;
begin
  Result := TOursFemDerivedCalculator.Create;

  Result.FProject := aProject;
  Result.FMessageList := aMessageList;
end;

// -------------------------------------------------------------------------------------------------

class function TOursBaseCalculator.GetFemUncertaintyCalculator(const aProject: TOursProject;
  const aMessageList: TOursMessageList): TOursBaseCalculator;
begin
  Result := TOursFemUncertaintyCalculator.Create;

  Result.FProject := aProject;
  Result.FMessageList := aMessageList;
end;

// -------------------------------------------------------------------------------------------------

class function TOursBaseCalculator.GetBuildingCalculator(const aProject: TOursProject;
  const aMessageList: TOursMessageList): TOursBaseCalculator;
begin
  Result := TOursBuildingCalculator.Create;

  Result.FProject := aProject;
  Result.FMessageList := aMessageList;
end;

// -------------------------------------------------------------------------------------------------

class function TOursBaseCalculator.GetMainCalculator(const aProject: TOursProject;
  const aMessageList: TOursMessageList): TOursBaseCalculator;
begin
  Result := TOursMainCalculator.Create;

  Result.FProject := aProject;
  Result.FMessageList := aMessageList;
end;

// -------------------------------------------------------------------------------------------------

function TOursBaseCalculator.GetParams(const inStr, outStr: string): string;
begin
  // Example of execution Python script: python.exe naverwerking.py -i input.json -o outputfolder
  Result := Format('"%s%s" -i "%s" -o "%s"', [TOursFileUtils.PythonDir, Modulename, inStr, outStr]);

  // Python prefers '/' as path delimeter and not '\'.
  Result := StringReplace(Result, PathDelim, '/', [rfReplaceAll]);
end;

// -------------------------------------------------------------------------------------------------

function TOursBaseCalculator.OutFolderAvailable(out outFolder: string): Boolean;
begin
  Result := False;

  outFolder := TOursFileUtils.TempDir + 'OUT';
  if DirectoryExists(outFolder) then
    TOursFileUtils.DeleteDir(outFolder);

  if not DirectoryExists(outFolder) then begin
    Result := ForceDirectories(outFolder);
  end;

  if not Result then begin
    FMessageList.AddError(Format(rsOutFolderWriteError, [outFolder]));
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursBaseCalculator.ProgAvailable(out progStr: string): Boolean;
begin
  // Test 2 things:
  // 1. is python.exe available
  // 2. is "ModuleName" available (=name python-script)

  // Make sure script "ModuleName" is located in folder "PROG-folder\Python\"
  var script := TOursFileUtils.PythonDir + Modulename;
  if not FileExists(script) then begin
    FMessageList.AddError(Format(rsExternalModuleNotFound, [Modulename]));
    Result := False;
    Exit;
  end;

  // progStr is the full path of the executable (Python.exe)
  progStr := TOursFileUtils.PythonDir + 'Python.exe';
  if not FileExists(progStr) then begin
    FMessageList.AddError(Format(rsExternalModuleNotFound, ['Python.exe']));
    Result := False;
    Exit;
  end;

  Result := True;
end;

// -------------------------------------------------------------------------------------------------

function TOursBaseCalculator.AddChildProcesses(aList: TList<DWORD>; aPID: DWORD): Boolean;
var
  _handle: THandle;
  _processEntry: TProcessEntry32;
begin
  Result := False;
  _handle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
  _processEntry.dwSize := SizeOf(TProcessEntry32);

  if Process32First(_handle, _processEntry) then begin
    if (_processEntry.th32ProcessID <> aPID) and // skip self
      (_processEntry.th32ParentProcessID = aPID) and
      (aList.IndexOf(_processEntry.th32ProcessID) = -1) then begin
      Result := True;
      aList.Add(_processEntry.th32ProcessID);
    end;

    while Process32Next(_handle, _processEntry) do begin
      if (_processEntry.th32ProcessID <> aPID) and // skip self
        (_processEntry.th32ParentProcessID = aPID) and
        (aList.IndexOf(_processEntry.th32ProcessID) = -1) then begin
        Result := True;
        aList.Add(_processEntry.th32ProcessID);
      end;
    end;
  end;

  CloseHandle(_handle);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursBaseCalculator.EndModule(aPID: DWORD);
var
  _pid: DWORD;
  _pidList: TList<DWORD>;
  bAdded: Boolean;
begin
  // Python starts a number of child processes. All these processes need to be terminated.
  if FProcessInfo.hProcess <> 0 then begin
    if aPID = 0 then begin
      _pid := GetCurrentProcessId;
    end else begin
      _pid := aPID;
    end;
    _pidList := TList<DWORD>.Create;
    _pidList.Add(_pid);

    bAdded := True;
    while bAdded do begin
      bAdded := False;

      for var pid in _pidList do begin
        if AddChildProcesses(_pidList, pid) then begin
          bAdded := True;
          Break;
        end;
      end;
    end;

    _pidList.Remove(_pid); // Remove own process.
    for var pid in _pidList do begin
      var
      killHandle := OpenProcess(PROCESS_TERMINATE, False, pid);
      TerminateProcess(killHandle, 0);
    end;
    _pidList.Free;
  end;

  if aPID = 0 then begin
    if FProcessInfo.hProcess <> 0 then begin
      TerminateProcess(FProcessInfo.hProcess, 0);
      CloseHandle(FProcessInfo.hProcess);
    end;
    FProcessInfo.hProcess := 0;

    if FProcessInfo.hThread <> 0 then begin
      CloseHandle(FProcessInfo.hThread);
    end;
    FProcessInfo.hThread := 0;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursBaseCalculator.RunModule(progStr, params, outputFile: string): Cardinal;
var
  p1, p2: string;
  curDir: string;
  startupInfo: TStartupInfo;
begin
  EndModule;

  // Store current folder
  curDir := GetCurrentDir;
  // Change to program folder
  SetCurrentDir(ExtractFilePath(progStr));

  FCanceled := False;
  Result := 0;

  FProcessInfo.hProcess := 0;
  FProcessInfo.hThread := 0;

  FillChar(startupInfo, SizeOf(TStartupInfo), 0);
  startupInfo.cb := SizeOf(TStartupInfo);
  startupInfo.dwFlags := STARTF_USESHOWWINDOW;
  startupInfo.wShowWindow := SW_HIDE;

  p1 := progStr + ' ' + params;
  p2 := ExtractFilePath(progStr);

  if CreateProcess(nil, PChar(p1), nil, nil, False, NORMAL_PRIORITY_CLASS, nil, PChar(p2), startupInfo, FProcessInfo) then begin
    try
      Screen.Cursor := crHourGlass;

      while ((WaitForSingleObject(FProcessInfo.hProcess, 2000) + 1) = STILL_ACTIVE) do begin
        Application.ProcessMessages;
        if FCanceled then
          EndModule;
      end;
    finally
      if FCanceled then
        Result := _exitcode_terminated
      else
        GetExitCodeProcess(FProcessInfo.hProcess, Result);
      EndModule;

      // Return to original folder
      SetCurrentDir(curDir);

      FCanceled := False;
      Screen.Cursor := crDefault;
    end;
  end;

  var bShowError := False;
  if Result <> 0 then begin
    if Result = _exitcode_terminated then begin
      FMessageList.AddWarning(rsCalculationTerminated);
    end else begin
      FMessageList.AddError(Format(rsExternalModuleError, [Modulename, ExitCode]));
      bShowError := True;
    end;
  end else if (outputFile<>'') and (not FileExists(outputFile)) then begin
    FMessageList.AddError(Format(rsExternalModuleNoResult, [Modulename, outputFile]));
    bShowError := True;
  end;

  if bShowError and FProject.testMode then begin
      ShowMessage('Error in script "'+Modulename+'" during calculation.' + #13 +
                  'Input JSON is now located in "' + TOursFileUtils.TempDir + '".;');
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursBaseCalculator.SaveInFile(inputJSON: string; out inFile: string): Boolean;
begin
  Result := False;

  inFile := TOursFileUtils.TempDir + 'input.json';
  if FileExists(inFile) then begin
    DeleteFile(inFile);
  end;

  if not FileExists(inFile) then begin
    with TStringlist.Create do begin
      Text := inputJSON;
      SaveToFile(inFile);
      Free;
    end;
    Result := FileExists(inFile);
  end;

  if not Result then begin
    FMessageList.AddError(Format(rsInFileWriteError, [inFile]));
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursBaseCalculator.TempAvailable: Boolean;
var
  tmpStr: string;
begin
  Result := False;

  tmpStr := TOursFileUtils.TempDir;
  if not DirectoryExists(tmpStr) then begin
    FMessageList.AddError(Format(rsTempFolderNotFound, [tmpStr]));
    Exit;
  end;
  if not TOursFileUtils.IsFolderWriteable(tmpStr) then begin
    FMessageList.AddError(Format(rsTempFolderNotWritable, [tmpStr]));
    Exit;
  end;

  Result := True;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursBaseCalculator.Terminate;
begin
  FCanceled := True;
end;

// =================================================================================================

end.
