{ @abstract(The OURS_UI project)
  Imports all relevant units, initializes the application, creates the mainform and starts the
  application.
}

program OURS_UI;

uses
  Forms,
  Xml.VerySimple,
  SQLite3,
  sqlite3udf,
  SQLiteTable3,
  F_Main in 'F_Main.pas' {frmMain},
  F_Stamtabel in 'F_Stamtabel.pas' {frmStamTabel},
  OursCalcBuilding in 'OursCalcBuilding.pas',
  OursCalcGround in 'OursCalcGround.pas',
  OursCalcBase in 'OursCalcBase.pas',
  OursData in 'OursData.pas',
  OursData_XML in 'OursData_XML.pas',
  OursDatabase in 'OursDatabase.pas',
  OursMessage in 'OursMessage.pas',
  OursResultBuilding in 'OursResultBuilding.pas',
  OursResultFem in 'OursResultFem.pas',
  OursResultGround in 'OursResultGround.pas',
  OursSplitProrailData in 'OursSplitProrailData.pas',
  OursStrings in 'OursStrings.pas',
  OursTypes in 'OursTypes.pas',
  OursUtils in 'OursUtils.pas',
  OursCalcMain in 'OursCalcMain.pas',
  OursResultMain in 'OursResultMain.pas',
  OursCalcFem in 'OursCalcFem.pas',
  OursCalcFemDerived in 'OursCalcFemDerived.pas',
  OursCalcFemUncertainty in 'OursCalcFemUncertainty.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;

end.
