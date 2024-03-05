{ @abstract(Mainform for the application.)
  The main dialogue has 3 different regions:    @br
  - Button row on top of the dialogue           @br
  - Page control in the middle of the dialogue  @br
  - Page control on the bottom of the dialogue. @br
                                                @br
  The top button row is only available when started in test-mode. It gives the user control
  over the program flow and enables control of execution for each calculation step:         @br
  - [Open] enables the user to open a XML-file                                              @br
  - [Calculate] calculates the full project                                                 @br
  - [Save] stores the results in the output XML-file and TXT-file for detailed results.     @br
                                                                                            @br
  The page control in the middle is only visible in test-mode and shows all input data,
  itermediate results and final results:                                                    @br
  - "Input" displays the input XML-file.                                                    @br
  - "Project" displays the extracted project information and the calculation settings.      @br
  - "Receptors" displays the receptor points loaded from the XML-file.                      @br
  - "Tracks" displays the tracks, track parts and trains loaded from the XML-file.          @br
  - "Sources" displays for each receptor point the calculated point sources, including the
    relevant measurement data from the database.                                            @br
  - "Ground" displays the retrieved ground data.                                            @br
  - "FEM" displays the results of the FEM-calculations for each ground scenario.            @br
  - "Postprocessing" displays the results of the post-processed FEM-calculations.           @br
  - "Uncertainty" displays the results of uncertainty of ground data and FEM-calculations.  @br
  - "Building" displays the results from the Building module.                               @br
  - "Results" displays the final results calculated by the main formula.                    @br
  - "Output" displays the output XML-file.                                                  @br
                                                                                            @br
  The bottom page control has 2 purposes. The first page ("Messages") is always visible
  (except in silent-mode) and gives information on progress, errors and warnings for the
  user. This information is always included in the XML output.                              @br
  The other pages, only visible in test-mode, show the contents of the database distributed
  with the software ("OURS.sqlite" located in the program folder).                          @br
                                                                                            @br
  For command line options see @link(OursMessage.TOursMessageList.ShowUsage)
}

unit F_Main;

interface

uses
  Forms, StdCtrls, ComCtrls, Controls, ExtCtrls, Classes, Generics.Collections,
  F_StamTabel, OursCalcBase, OursData, OursMessage, Vcl.Dialogs;

//--------------------------------------------------------------------------------------------------

type
  TfrmMain = class(TForm)
    { @abstract(Control to enlarge project panel or database panel.)
    }
    Splitter: TSplitter;

    { @abstract(Panel which contains all project related controls.)
    }
    pnlProject: TPanel;

    { @abstract(Notebook which contains all project related pages.)
    }
    pagesData: TPageControl;

    { @abstract(Panel which contains all database related controls, including the messagelist.)
    }
    pnlDB: TPanel;

    { @abstract(Notebook which contains all database related pages, including the messagelist.)
    }
    pagesDB: TPageControl;

    { @abstract(Pages which contains all messagelist related controls.)
    }
    tabMessages: TTabSheet;

    { @abstract(Memo which contains all messages given by the software.)
    }
    mmoMessages: TRichEdit;

    { @abstract(Contains memo for contents of input file.)
    }
    tabInput: TTabSheet;

    { @abstract(Contains contents of input file.)
    }
    mmoInput: TMemo;

    { @abstract(Contains memo for project as text.)
    }
    tabProject: TTabSheet;

    { @abstract(Contains project as text.)
    }
    mmoProject: TMemo;

    { @abstract(Contains memo for receptor points as text.)
    }
    tabReceptors: TTabSheet;

    { @abstract(Contains receptor points as text.)
    }
    mmoReceptors: TMemo;

    { @abstract(Contains memo for tracks, track parts and trains as text.)
    }
    tabTracks: TTabSheet;

    { @abstract(Contains tracks, track parts and trains as text.)
    }
    mmoTracks: TMemo;

    { @abstract(Contains memo for sources with measurements as text.)
    }
    tabSources: TTabSheet;

    { @abstract(Contains sources with measurements as text.)
    }
    mmoSources: TMemo;

    { @abstract(Contains memo for ground data as text.)
    }
    tabGround: TTabSheet;

    { @abstract(Contains ground data as text.)
    }
    mmoGround: TMemo;

    { @abstract(Contains memo for the results of the FEM calculation.)
    }
    tabFem: TTabSheet;

    { @abstract(Contains the results of the FEM calculation.)
    }
    mmoFem: TMemo;

    { @abstract(Contains memo for the results of the post processing of the FEM results.)
    }
    tabDerived: TTabSheet;

    { @abstract(Contains the results of the post processing of the FEM results.)
    }
    mmoDerived: TMemo;

    { @abstract(Contains memo for the uncertainty of the ground data.)
    }
    tabUncertainty: TTabSheet;

    { @abstract(Contains the uncertainty of the ground data.)
    }
    mmoUncertainty: TMemo;

    { @abstract(Contains memo for building results as text.)
    }
    tabBuilding: TTabSheet;

    { @abstract(Contains building results as text.)
    }
    mmoBuilding: TMemo;

    { @abstract(Contains memo for main results as text.)
    }
    tabResults: TTabSheet;

    { @abstract(Contains main results as text.)
    }
    mmoResults: TMemo;

    { @abstract(Contains memo for the contents of the output file.)
    }
    tabOutput: TTabSheet;

    { @abstract(Contains the contents of the output file.)
    }
    mmoOutput: TMemo;

    { @abstract(Button to close OURS_UI.)
    }
    btnExit: TButton;

    { @abstract(Button to cancel current calculation.)
    }
    btnCancel: TButton;

    { @abstract(Dialog to select input XML-file.)
    }
    openDlg: TOpenDialog;

    { @abstract(Dialog to select output XML-file, if not set yet.)
    }
    saveDlg: TSaveDialog;

    { @abstract(Panel containing all buttons to execute (part of) the calculation.)
    }
    pnlButtons: TPanel;

    { @abstract(Button to save all results in an output file.)
    }
    btnSave: TButton;

    { @abstract(Button to start the calculation.)
    }
    btnCalculate: TButton;

    { @abstract(Button to select a new input file.)
    }
    btnOpen: TButton;
    btnLicense: TButton;

    { @abstract(Event handler for the constructor of the mainform.)
      Method will setup the mainform, open the database, display table contents and process the
      command line parameters.
    }
    procedure FormCreate(Sender: TObject);

    { @abstract(Event handler for the destructor of the mainform.)
      Method will free all private data.
    }
    procedure FormDestroy(Sender: TObject);

    { @abstract(Event handler for activating the mainform.)
      Depending on the command line options the calculation will be started and/or the full
      user-interface will be visible. @br
      This event handler will only be called once.
    }
    procedure FormActivate(Sender: TObject);

    { @abstract(Event handler for resizing the mainform.)
      This method will distribute the tabs evenly depanding on the width of the mainform.
    }
    procedure FormResize(Sender: TObject);

    { @abstract(Event handler for the Exit button (Close OURS_UI).)
    }
    procedure btnExitClick(Sender: TObject);

    { @abstract(Event handler for the Open button (Select project).)
    }
    procedure btnOpenClick(Sender: TObject);

    { @abstract(Event handler for the Calculate button (Calculate project).)
    }
    procedure btnCalculateClick(Sender: TObject);

    { @abstract(Event handler for Save button.)
    }
    procedure btnSaveClick(Sender: TObject);

    { @abstract(Event handler for the Cancel button (cancel current calculation).)
    }
    procedure btnCancelClick(Sender: TObject);

    { @abstract(Event handler for Prorail button (splitting Prorail datafiles).)
    }
    procedure btnProrailClick(Sender: TObject);

    { @abstract(When calculation is running prevent changing tab and keep messages visible.)
    }
    procedure pagesDBChanging(Sender: TObject; var AllowChange: Boolean);
    procedure btnLicenseClick(Sender: TObject);
  private type
    TCalculateEvent = procedure of object;
  private
    { @abstract(Indicates if an error occured preventing execution of the software.)
    }
    FInError: Boolean;

    { @abstract(Indicates if the user has canceled the calculation.)
    }
    FCanceled: Boolean;

    { @abstract(List with references to the dialogues containing the database contents.)
    }
    FTableViews: TList<TfrmStamTabel>;

    { @abstract(Object to display progress, errors and warnings.)
    }
    FMessageList: TOursMessageList;

    { @abstract(The current project.)
    }
    FProject: TOursProject;

    { @abstract(If input and output are defined, the calculation is started immediately.)
    }
    FStartCalculation: Boolean;

    { @abstract(The current calculator (ground, fem, buiding, main). Enables canceling the calculation.)
    }
    FCalculator: TOursBaseCalculator;

    { @abstract(Sets the user-interface depending on state of the software.)
      Activates or de-activate buttons.
    }
    procedure SetForm(bActive: Boolean);

    { @abstract(Processes the command line parameters.)
      Determines input-file, output-file, test-mode and silent-mode.
    }
    procedure ProcessParams;

    { @abstract(Initialises the software.)
      Opens database and displays all table data.
    }
    procedure InitProgram;

    { @abstract(Select a new input file and load it.)
      Selects a new input file and calls Refresh.
    }
    procedure OpenFile;

    { @abstract(Loads and displays the XML input-file.)
      Loads the input file, creates project data and displays the input XML, project, receptors, tracks and sources.
    }
    procedure Refresh;

    { @abstract(Retrieves the ground data (CPT-tool) for each receptor and source.)
    }
    procedure CalculateGround;

    { @abstract(Executes the FEM calculation for each receptor, source and ground scenario.)
    }
    procedure CalculateFem;

    { @abstract(Executes the post processing of the FEM results for each receptor, source and ground scenario.)
    }
    procedure CalculateFemDerived;

    { @abstract(Calculates the uncertainty for each receptor, source and ground scenario.)
    }
    procedure CalculateUncertainty;

    { @abstract(Calculates the building effect for each receptor, source and ground scenario.)
    }
    procedure CalculateBuilding;

    { @abstract(Calculates the total results for each receptor and source.)
    }
    procedure CalculateResults;

    { @abstract(Creates the XML resulta file and displays it.)
    }
    procedure ShowResults;

    { @abstract(Save results to XML output-file and, if enabled, to detailed txt-file.)
    }
    procedure SaveResults;

    { @abstract(Executes next step of the calculation.)
      Could be further optimized to include code of Calculate*.
    }
    function NextCalculateStep(ACalculate: TCalculateEvent; NextTab: TTabSheet): Boolean;
  end;

var
  { @abstract(Pointer to the mainform. Execution will start when dialogue is created.)
  }
  frmMain: TfrmMain;

implementation

// -------------------------------------------------------------------------------------------------

uses
  Math, IOUtils, SysUtils, ShellApi, Windows,
  Xml.VerySimple,
  OursData_XML, OursDatabase, OursStrings,
  OursResultGround, OursResultFem, OursUtils,
  OursSplitProrailData;

{$R *.dfm}

// =================================================================================================
// TfrmMain
// =================================================================================================

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // We always use '.' as decimal seperator!
  FormatSettings.DecimalSeparator := '.';

  btnCancel.Visible := False;

  FTableViews := TList<TfrmStamTabel>.Create;
  mmoMessages.Clear;
  FMessageList := TOursMessageList.Create(mmoMessages);
  FMessageList.AddInfo(Caption + ' ' + rsStarted);

  InitProgram;
  ProcessParams;

  // Load data from FProject.inFile
  if FStartCalculation then begin
    if FProject.SilentMode then begin
      // Hide mainform
      Self.Visible := False;
      FormActivate(Sender);
    end else begin
      // Only show message memo. Format mainform for it.

      // Move progress from tab to mainform.
      mmoMessages.Parent := Self;
      mmoMessages.Margins.Bottom := pnlDB.Margins.Bottom;

      // Hide panels for buttons, project and database. Hide splitter
      pnlDB.Visible := False;
      pnlProject.Visible := False;
      pnlButtons.Visible := False;
      Splitter.Visible := False;

      // Move [Cancel] to [Exit] position.
      btnCancel.Left := btnExit.Left;
      btnCancel.Anchors := btnExit.Anchors;
      // Remove constraints and set usefull size.
      Constraints.MinHeight := 0;
      Constraints.MinWidth := 0;
      Height := 400;
      Width := 700;
      // Swap to a dialogue style form.
      BorderStyle := bsSingle;
      BorderIcons := [biSystemMenu];
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Remove database tabs
  while FTableViews.Count > 0 do begin
    FTableViews[FTableViews.Count - 1].Free;
    FTableViews.Delete(FTableViews.Count - 1);
  end;
  FTableViews.Free;

  if Assigned(FProject) then
    FProject.Free;

  if Assigned(FMessageList) then
    FMessageList.Free;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  Self.OnActivate := nil;
  if not FProject.SilentMode then
    Self.Show;

  // Load data from FProject.inFile, create sources from data and display all input data
  Refresh;

  if FStartCalculation then begin
    // Perform calculation
    btnCalculateClick(Sender);
    // Save results
    btnSaveClick(Sender);
    // Exit program. Need 'Halt', otherwise the full user-interface is shown.
    Close;
    Halt(0);
    Exit;
  end;

  // Full user-interface is used
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.FormResize(Sender: TObject);
begin
  // Spread tabs evenly
  pagesDB.TabWidth := (pagesDB.Width - 5) div pagesDB.PageCount;
  pagesData.TabWidth := Max((pagesData.Width - 5) div pagesData.PageCount, 86);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  OpenFile;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  SaveResults;
end;

// -------------------------------------------------------------------------------------------------

function TfrmMain.NextCalculateStep(ACalculate: TCalculateEvent; NextTab: TTabSheet): Boolean;
begin
  if btnCalculate.Enabled then begin
    SetForm(False);
    Application.ProcessMessages;

    ACalculate();

    pagesData.ActivePage := NextTab;
    Update;
  end;

  Result := (not FCanceled);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.btnCalculateClick(Sender: TObject);
begin
  SetForm(False);
  btnCalculate.Enabled := (not FMessageList.HasError);

  try
    // Just walk through the input data and wait 0.5 seconds on each tab
    for var i := 0 to 4 do begin
      pagesData.ActivePageIndex := i;
      Update;
      if not FStartCalculation then
        Sleep(500);
      if FCanceled then
        Exit;
    end;

    if not (NextCalculateStep(CalculateGround, tabGround)           and
            NextCalculateStep(CalculateFem, tabFem)                 and
            NextCalculateStep(CalculateFemDerived, tabDerived)      and
            NextCalculateStep(CalculateUncertainty, tabUncertainty) and
            NextCalculateStep(CalculateBuilding, tabBuilding)       and
            NextCalculateStep(CalculateResults, tabResults)         and
            NextCalculateStep(ShowResults, tabOutput))              then
      Exit;
  finally
    SetForm(True);
    FCanceled := False;
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  FCanceled := True;
  if FCalculator <> nil then
    FCalculator.Terminate;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.btnProrailClick(Sender: TObject);
begin
  TOursSplitProrailData.SplitProrailData;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnLicenseClick(Sender: TObject);
begin
  var s := '"' + TOursFileUtils.ProgDir + 'EUPL-1.2 EN.txt"';
  ShellExecute(self.handle, PChar('open'), PChar(s), '', '', SW_SHOW);
end;

// -------------------------------------------------------------------------------------------------
// Private methods
// -------------------------------------------------------------------------------------------------

procedure TfrmMain.ProcessParams;
begin
  FProject.inFile := 'OURS_input.xml';
  FProject.outFile := 'OURS_output.xml';
  FProject.TestMode := True;
  FProject.SilentMode := False;
  FStartCalculation := False;

  if ParamCount > 0 then begin
    FProject.inFile := ChangeFileExt(ParamStr(1), '.xml');
  end;
  if not FileExists(FProject.inFile) then begin
    FMessageList.ShowUsage(Format(rsInputfileNotFound, [FProject.inFile]), True);
  end; // if

  if ParamCount > 1 then begin
    FProject.TestMode := False;
    FStartCalculation := True;
    FProject.outFile := ChangeFileExt(ParamStr(2), '.xml');
    if not TPath.HasValidFileNameChars(ExtractFileName(FProject.outFile), False) then begin
      FMessageList.ShowUsage(Format(rsOutputfileInvalid, [FProject.outFile]), True);
    end else if not DirectoryExists(ExtractFilePath(FProject.outFile)) then begin
      FMessageList.ShowUsage(Format(rsOutputfolderNotFound, [ExtractFilePath(FProject.outFile)]), True);
    end else if FProject.inFile = FProject.outFile then begin
      FMessageList.ShowUsage(Format(rsInputEqualsOutputfile, [FProject.inFile]), True);
    end;
  end;

  for var i := 3 to ParamCount do begin
    if UpperCase(ParamStr(i)) = '/TEST' then
      FProject.TestMode := True;
    if UpperCase(ParamStr(i)) = '/SILENT' then
      FProject.SilentMode := True;
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.InitProgram;
var
  tblNames: TStringlist;
  frm: TfrmStamTabel;
  page: TTabSheet;
begin
  FInError := False;
  FProject := TOursProject.Create;

  if not TOursDatabase.DBExists then begin
    FMessageList.AddError('Database not found. Unable to use program');
    FInError := True;
    btnOpen.Enabled := False;
    btnCalculate.Enabled := False;
    btnSave.Enabled := False;
    Exit;
  end;

  tblNames := TStringlist.Create;
  TOursDatabase.DBTableNames(tblNames);
  for var i := 0 to tblNames.Count - 1 do begin
    frm := TfrmStamTabel.Create(nil);
    frm.MessageList := FMessageList;
    FTableViews.Add(frm);

    page := TTabSheet.Create(pagesDB);
    page.PageControl := pagesDB;
    page.Caption := UpperCase(tblNames.Strings[i]);
    frm.grd.Parent := page;
    frm.ShowTableContents(page.Caption);
  end;
  tblNames.Free;

  // All information is displayed as text: choose a non-proportional font for better readability.
  for var i := 0 to PagesData.PageCount-1 do begin
    for var j := 0 to PagesData.Pages[i].ControlCount-1 do begin
      if PagesData.Pages[i].Controls[j].ClassName = 'TMemo' then
        (PagesData.Pages[i].Controls[j] as TMemo).Font.Name := 'Courier New';
    end;
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.Refresh;
begin
  btnCalculate.Enabled := False;
  btnSave.Enabled := False;

  FMessageList.Reset;
  FMessageList.AddSeparator;

  // >> Clear existing data
  FProject.Clear;

  mmoInput.Lines.Clear;
  mmoProject.Lines.Clear;
  mmoReceptors.Lines.Clear;
  mmoTracks.Lines.Clear;
  mmoSources.Lines.Clear;
  mmoGround.Lines.Clear;
  mmoFem.Lines.Clear;
  mmoDerived.Lines.Clear;
  mmoUncertainty.Lines.Clear;
  mmoBuilding.Lines.Clear;
  mmoResults.Lines.Clear;
  mmoOutput.Lines.Clear;

  // >> Display raw Xml in mainform
  pagesData.ActivePageIndex := 0;
  tabInput.Caption := ExtractFileName(FProject.inFile);

  // >> Load data from FProject.InFile
  FProject.ReadFromXml(FProject.inFile, FMessageList);

  // >> Create source from receptors and tracks
  FProject.CreateSources;

  // >> Display data in mainform
  mmoInput.Lines.LoadFromFile(FProject.inFile);
  mmoProject.Lines.Text := FProject.AsText;
  mmoReceptors.Lines.Text := FProject.Receptors.AsText;
  mmoTracks.Lines.Text := FProject.Tracks.AsText;
  mmoSources.Lines.Text := FProject.Receptors.SourcesAsText;

  pagesData.ActivePage := tabProject;
  SetForm(True);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.SetForm(bActive: Boolean);
begin
  pagesDB.ActivePageIndex := 0;

  btnExit.Enabled := bActive;
  btnOpen.Enabled := bActive;
  btnCalculate.Enabled := bActive;
  btnSave.Enabled := bActive;
  btnCancel.Visible := not bActive;
  btnCancel.Enabled := not bActive;
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.CalculateGround;
var
  bCalcSuccess: Boolean;
begin
  FCalculator := TOursBaseCalculator.GetGroundCalculator(FProject, FMessageList);
  try
    bCalcSuccess := FCalculator.Execute;
  finally
    FreeAndNil(FCalculator);
    SetForm(True);
  end;

  mmoGround.Lines.Text := FProject.GroundAsText;
  btnCalculate.Enabled := bCalcSuccess and (not FMessageList.HasError);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.CalculateFem;
var
  bCalcSuccess: Boolean;
begin
  FCalculator := TOursBaseCalculator.GetFemCalculator(FProject, FMessageList);
  try
    bCalcSuccess := FCalculator.Execute;
  finally
    FreeAndNil(FCalculator);
    SetForm(True);
  end;

  mmoFem.Lines.Text := FProject.FemAsText;
  btnCalculate.Enabled := bCalcSuccess and (not FMessageList.HasError);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.CalculateFemDerived;
var
  bCalcSuccess: Boolean;
begin
  FCalculator := TOursBaseCalculator.GetFemDerivedCalculator(FProject, FMessageList);
  try
    bCalcSuccess := FCalculator.Execute;
  finally
    FreeAndNil(FCalculator);
    SetForm(True);
  end;

  mmoDerived.Lines.Text := FProject.FemDerivedAsText;
  btnCalculate.Enabled := bCalcSuccess and (not FMessageList.HasError);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.CalculateUncertainty;
var
  bCalcSuccess: Boolean;
begin
  FCalculator := TOursBaseCalculator.GetFemUncertaintyCalculator(FProject, FMessageList);
  try
    bCalcSuccess := FCalculator.Execute;
  finally
    FreeAndNil(FCalculator);
    SetForm(True);
  end;

  mmoUncertainty.Lines.Text := FProject.FemUncertaintyAsText;
  btnCalculate.Enabled := bCalcSuccess and (not FMessageList.HasError);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.CalculateBuilding;
var
  bCalcSuccess: Boolean;
begin
  FCalculator := TOursBaseCalculator.GetBuildingCalculator(FProject, FMessageList);
  try
    bCalcSuccess := FCalculator.Execute;
  finally
    FreeAndNil(FCalculator);
    SetForm(True);
  end;

  mmoBuilding.Lines.Text := FProject.HBuildingAsText;
  btnCalculate.Enabled := bCalcSuccess and (not FMessageList.HasError);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.CalculateResults;
var
  bCalcSuccess: Boolean;
begin
  FCalculator := TOursBaseCalculator.GetMainCalculator(FProject, FMessageList);
  try
    bCalcSuccess := FCalculator.Execute;
  finally
    FreeAndNil(FCalculator);
    SetForm(True);
  end;

  mmoResults.Lines.Text := FProject.MainResultsAsText;
  btnCalculate.Enabled := bCalcSuccess and (not FMessageList.HasError);
end;

// -------------------------------------------------------------------------------------------------

procedure TfrmMain.ShowResults;
begin
  var Xml := FProject.ResultsToXML;

  // Add messages...
  var node := Xml.DocumentElement.AddChild('Messages', ntElement);
  for var i := 0 to mmoMessages.Lines.Count - 1 do begin
    with node.AddChild('lines' + i.ToString, ntElement) do
      SetText(mmoMessages.Lines[i]);
  end;

  var str := Xml.Text;
  str := StringReplace(str, '&quot;',  '"',  [rfReplaceAll]);

  if str[1] = #$FEFF then
    Delete(str, 1, 1);

  mmoOutput.Text := str;
  Xml.Free;
end;
// -------------------------------------------------------------------------------------------------

procedure TfrmMain.OpenFile;
begin
  if FInError then begin
    Exit;
  end;

  if (FProject.inFile <> '') then begin
    if ExtractFilePath(FProject.inFile) = '' then begin
      FProject.inFile := IncludeTrailingPathDelimiter(GetCurrentDir) + FProject.inFile;
    end;
  end;

  openDlg.FileName := FProject.inFile;
  if ExtractFilePath(FProject.inFile) <> '' then begin
    openDlg.InitialDir := ExtractFilePath(FProject.inFile);
  end else begin
    openDlg.InitialDir := TOursFileUtils.ProgDir;
  end;
  if openDlg.Execute then begin
    FProject.inFile := openDlg.FileName;
  end;

  Refresh;
end;

//--------------------------------------------------------------------------------------------------

procedure TfrmMain.pagesDBChanging(Sender: TObject; var AllowChange: Boolean);
begin
  AllowChange := (FCalculator = nil);
end;

//--------------------------------------------------------------------------------------------------

procedure TfrmMain.SaveResults;
var
  txtFile: string;
begin
  if (FProject.outFile <> '') then begin
    if ExtractFilePath(FProject.outFile) = '' then begin
      FProject.outFile := IncludeTrailingPathDelimiter(GetCurrentDir) + FProject.outFile;
    end;
  end;

  if (not FStartCalculation) or (FProject.outFile = '') then begin
    saveDlg.FileName := FProject.outFile;
    if ExtractFilePath(FProject.outFile) <> '' then begin
      saveDlg.InitialDir := ExtractFilePath(FProject.outFile);
    end else begin
      saveDlg.InitialDir := TOursFileUtils.ProgDir;
    end;
    if saveDlg.Execute then begin
      FProject.outFile := saveDlg.FileName;
    end;
  end;

  mmoOutput.Lines.SaveToFile(FProject.outFile);

  if FProject.testMode then begin
    txtFile := ChangeFileExt(FProject.outFile, '.txt');

    var txt := TStringlist.Create;
    txt.Add('====================================================================================');
    txt.Add(tabInput.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoInput.Text);

    txt.Add('====================================================================================');
    txt.Add(tabProject.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoProject.Text);

    txt.Add('====================================================================================');
    txt.Add(tabReceptors.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoReceptors.Text);

    txt.Add('====================================================================================');
    txt.Add(tabTracks.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoTracks.Text);

    txt.Add('====================================================================================');
    txt.Add(tabSources.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoSources.Text);

    txt.Add('====================================================================================');
    txt.Add(tabGround.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoGround.Text);

    txt.Add('====================================================================================');
    txt.Add(tabFem.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoFem.Text);

    txt.Add('====================================================================================');
    txt.Add(tabDerived.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoDerived.Text);

    txt.Add('====================================================================================');
    txt.Add(tabUncertainty.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoUncertainty.Text);

    txt.Add('====================================================================================');
    txt.Add(TabBuilding.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoBuilding.Text);

    txt.Add('====================================================================================');
    txt.Add(TabResults.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoResults.Text);

    txt.Add('====================================================================================');
    txt.Add(tabOutput.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoOutput.Text);

    txt.Add('====================================================================================');
    txt.Add(tabMessages.Caption);
    txt.Add('====================================================================================');
    txt.Add(mmoMessages.Text);

    if FileExists(txtFile) then
      SysUtils.DeleteFile(txtFile);

    txt.SaveToFile(txtFile);
    txt.Free;
  end;
end;

// =================================================================================================

end.
