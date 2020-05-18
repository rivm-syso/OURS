{ @abstract(This unit enables progress information for the end-user.)
}
unit OursMessage;

interface

uses
  Classes,
  ComCtrls,
  StdCtrls;

// -------------------------------------------------------------------------------------------------

type
  { @abstract(Class for displaying progress, warnings and errors.e.)
    The class also count the number of errors and warnings.
  }
  TOursMessageList = class(TObject)
  strict private
    { @abstract(Pointer to the control where all output is written (inherites from TRichEdit))
    }
    _lines: TRichEdit;

    { @abstract(Error count = number of times AddError is called after a Reset.)
    }
    _errorCount: Integer;

    { @abstract(Warning count = number of times AddWarning is called after a Reset.)
    }
    _warningCount: Integer;

    { @abstract(Adds a line to the pregress.)
      Format: sType <TAB> Time <TAB> sMessage
    }
    procedure AddString(const sType: string; const sMessage: string);

    { @abstract(Returns if error count > 0.)
    }
    function GetHasError: Boolean;
  public
    { @abstract( Constructor.)
      All messages will be displayed in a component which inherites from a TRichEdit
    }
    constructor Create(aLines: TRichEdit);
    { @abstract( Resets the error and warning count to zero.)
    }
    procedure Reset;

    { @abstract( Adds a information line to the progress.)
      The line is displayed in the standard font and starts with "Info".
    }
    procedure AddInfo(s: string);

    { @abstract( Adds an error line to the progress.)
      The line is displayed in Red and starts with "Error".
    }
    procedure AddError(s: string);

    { @abstract( Adds a warning line to the progress.)
      The line is displayed in Blue and starts with "Warning".
    }
    procedure AddWarning(s: string);

    { @abstract( Adds a progress line to the progress.)
      The line is displayed in the standard font and starts with "Progress".
    }
    procedure AddProgress(s: string);

    { @abstract( Adds an empty line to the progress.)
    }
    procedure AddSeparator;

    { @abstract( Displays message with correct usage of the software.)
      Behaviour depends on the number of command line options:                                    @br
      0: The software is started in test-mode with full user-interface and OURS_input.xml is used
         as inputfile.                                                                            @br
                                                                                                  @br
      1: The software is started in test-mode with full user-interface and <parameter1> is used
         as inputfile.                                                                            @br
                                                                                                  @br
      2: <parameter1> is used as inputfile, calculation is being executed and the results are
         written to <parameter2>.                                                                 @br
         Only the progress dialogue with progress and messages will be visible. Software will
         close when calculation is completed.                                                     @br
                                                                                                  @br
      3 or more: Same as 2 parameters, but with additional options (can be combined):             @br
        - '/TEST' : The software is started in test-mode and detailed results will be written to
           a TXT-file.                                                                            @br
        - '/SILENT' : The software is started in silent mode. No user-inteface will be
          visible and the software is closed when the calculation is completed.
    }
    procedure ShowUsage(str: string; bHalt: Boolean = True);

    { @abstract(Returns if at least 1 error is recorded with AddError.)
    }
    property HasError: Boolean read GetHasError;

    { @abstract(Returns the number of errors.)
    }
    property ErrorCount: Integer read _errorCount;

    { @abstract(Returns the number of warnings.)
    }
    property WarningCount: Integer read _warningCount;
  end;

implementation

// -------------------------------------------------------------------------------------------------

uses
  Forms,
  Controls,
  Messages,
  Windows,
  Graphics,
  Dialogs,
  SysUtils,
  OursStrings;

// =================================================================================================

procedure TOursMessageList.AddError(s: string);
begin
  _lines.SelAttributes.Color := clRed;
  AddString(Format('%s', [rsError]), s + '!');
  _lines.SelAttributes.Color := clBlack;

  Inc(_errorCount);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMessageList.AddWarning(s: string);
begin
  _lines.SelAttributes.Color := clBlue;
  AddString(Format('%s', [rsWarning]), s);
  _lines.SelAttributes.Color := clBlack;

  Inc(_warningCount);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMessageList.AddInfo(s: string);
begin
  AddString(Format('%s', [rsInfo]), s);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMessageList.AddProgress(s: string);
begin
  AddString(Format('%s', [rsProgress]), s);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMessageList.AddString(const sType, sMessage: string);
var
  activeControl: TWinControl;
begin
  _lines.Lines.Add(sType + #9 + DateTimeToStr(Now) + #9 + sMessage);

  if Application.MainForm <> nil then begin
    activeControl := Application.MainForm.activeControl;

    _lines.SetFocus;
    _lines.SelStart := _lines.GetTextLen;
    _lines.Perform(EM_SCROLLCARET, 0, 0);
    _lines.Invalidate;

    if (activeControl <> nil) then
      Application.MainForm.activeControl := activeControl;
  end;
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMessageList.AddSeparator;
begin
  _lines.Lines.Add('');
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMessageList.Reset;
begin
  _errorCount := 0;
  _warningCount := 0;
end;

// -------------------------------------------------------------------------------------------------

constructor TOursMessageList.Create(aLines: TRichEdit);
begin
  _lines := aLines;
end;

// -------------------------------------------------------------------------------------------------

function TOursMessageList.GetHasError: Boolean;
begin
  Result := (_errorCount > 0);
end;

// -------------------------------------------------------------------------------------------------

procedure TOursMessageList.ShowUsage(str: string; bHalt: Boolean);
begin
  ShowMessage(Format(rsUsage, [str]));

  if bHalt then
    Halt(1);
end;

// =================================================================================================

end.
