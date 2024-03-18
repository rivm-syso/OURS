object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'OURS 2.10'
  ClientHeight = 800
  ClientWidth = 1200
  Color = clBtnFace
  Constraints.MinHeight = 600
  Constraints.MinWidth = 1000
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  DesignSize = (
    1200
    800)
  TextHeight = 13
  object Splitter: TSplitter
    Left = 0
    Top = 607
    Width = 1200
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    Beveled = True
    ResizeStyle = rsLine
    ExplicitLeft = 16
    ExplicitTop = 76
    ExplicitWidth = 801
  end
  object pnlProject: TPanel
    AlignWithMargins = True
    Left = 0
    Top = 41
    Width = 1200
    Height = 566
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pagesData: TPageControl
      AlignWithMargins = True
      Left = 0
      Top = 0
      Width = 1200
      Height = 566
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      ActivePage = tabDerived
      Align = alClient
      MultiLine = True
      TabOrder = 0
      TabWidth = 86
      object tabInput: TTabSheet
        Caption = 'Input'
        object mmoInput: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabProject: TTabSheet
        Caption = 'Project'
        ImageIndex = 1
        object mmoProject: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabReceptors: TTabSheet
        Caption = 'Receptors'
        ImageIndex = 2
        object mmoReceptors: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabTracks: TTabSheet
        Caption = 'Tracks'
        ImageIndex = 3
        object mmoTracks: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabSources: TTabSheet
        Caption = 'Sources'
        ImageIndex = 4
        object mmoSources: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabGround: TTabSheet
        Caption = 'Ground'
        ImageIndex = 5
        object mmoGround: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabFem: TTabSheet
        Caption = 'FEM'
        ImageIndex = 6
        object mmoFem: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabDerived: TTabSheet
        Caption = 'Derived'
        ImageIndex = 9
        object mmoDerived: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
          ExplicitTop = 4
        end
      end
      object tabUncertainty: TTabSheet
        Caption = 'Uncertainty'
        ImageIndex = 10
        object mmoUncertainty: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabBuilding: TTabSheet
        Caption = 'Building'
        ImageIndex = 7
        object mmoBuilding: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabResults: TTabSheet
        Caption = 'Results'
        ImageIndex = 8
        object mmoResults: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tabOutput: TTabSheet
        Caption = 'Output'
        ImageIndex = 11
        object mmoOutput: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 538
          Align = alClient
          BorderStyle = bsNone
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
    end
  end
  object pnlDB: TPanel
    AlignWithMargins = True
    Left = 0
    Top = 610
    Width = 1200
    Height = 150
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 40
    Align = alBottom
    BevelOuter = bvNone
    Constraints.MinHeight = 100
    Constraints.MinWidth = 200
    TabOrder = 1
    VerticalAlignment = taAlignTop
    object pagesDB: TPageControl
      AlignWithMargins = True
      Left = 0
      Top = 0
      Width = 1200
      Height = 150
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      ActivePage = tabMessages
      Align = alClient
      MultiLine = True
      TabOrder = 0
      TabWidth = 100
      OnChanging = pagesDBChanging
      object tabMessages: TTabSheet
        Caption = 'Messages'
        object mmoMessages: TRichEdit
          AlignWithMargins = True
          Left = 0
          Top = 0
          Width = 1192
          Height = 122
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alClient
          BorderStyle = bsNone
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
    end
  end
  object btnExit: TButton
    Left = 1111
    Top = 767
    Width = 85
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Exit'
    TabOrder = 2
    OnClick = btnExitClick
  end
  object btnCancel: TButton
    Left = 8
    Top = 767
    Width = 85
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = btnCancelClick
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 4
    object btnOpen: TButton
      AlignWithMargins = True
      Left = 4
      Top = 8
      Width = 85
      Height = 25
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 8
      Align = alLeft
      Caption = 'Open...'
      TabOrder = 0
      OnClick = btnOpenClick
    end
    object btnSave: TButton
      AlignWithMargins = True
      Left = 182
      Top = 8
      Width = 85
      Height = 25
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 8
      Align = alLeft
      Caption = 'Save'
      TabOrder = 2
      OnClick = btnSaveClick
    end
    object btnCalculate: TButton
      AlignWithMargins = True
      Left = 93
      Top = 8
      Width = 85
      Height = 25
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 8
      Align = alLeft
      Caption = 'Calculate'
      TabOrder = 1
      OnClick = btnCalculateClick
    end
    object btnLicense: TButton
      AlignWithMargins = True
      Left = 1111
      Top = 8
      Width = 85
      Height = 25
      Margins.Left = 0
      Margins.Top = 8
      Margins.Right = 4
      Margins.Bottom = 8
      Align = alRight
      Caption = 'License...'
      TabOrder = 3
      OnClick = btnLicenseClick
    end
  end
  object saveDlg: TSaveDialog
    DefaultExt = 'xml'
    Filter = 'XML-file|*.xml'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofNoReadOnlyReturn, ofEnableSizing]
    Left = 160
    Top = 536
  end
  object openDlg: TOpenDialog
    DefaultExt = 'xml'
    Filter = 'XML-file|*.xml'
    Options = [ofReadOnly, ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 224
    Top = 536
  end
end
