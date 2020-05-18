{ @abstract(This unit contains a dialogue to display the contents of a table from the database.)
  Data will be loaded by "ShowTableContents". This method needs the name of a table. @br
  An exception will be raised if TableName is empty or does not exist.               @br
  All data is shown without any formatting.
}
unit F_Stamtabel;

interface

uses
  Forms, Classes, Controls, Grids,
  SQLiteTable3,
  OursMessage;

type
  { @abstract(Class which loads and displays the contents of the database table.)
  }
  TfrmStamTabel = class(TForm)
    { @abstract(Table is which the data is diplayed.)
    }
    grd: TStringGrid;
  private
    { @abstract(Reference to the message list for displaying progress and messages.)
      Assigned by property MessageList
    }
    FMessageList: TOursMessageList;
  public
    { @abstract(Loads the contents of TableName and displays it in the grid.)
    }
    procedure ShowTableContents(const TableName: string);

    { @abstract(Reference to the message list for displaying progress and messages.)
    }
    property MessageList: TOursMessageList write FMessageList;
  end;

// -------------------------------------------------------------------------------------------------

implementation

{$R *.dfm}

uses
  SysUtils,
  OursStrings,
  OursDatabase;

// =================================================================================================
// TfrmStamTabel
// =================================================================================================

procedure TfrmStamTabel.ShowTableContents(const TableName: string);
var
  aTable: TSQLiteTable;
begin
  if (Caption = '') and (TableName = '') then begin
    raise Exception.Create('TfrmStamTabel.ShowTableContents called with empty table name');
  end;

  if (TableName = '') then
    aTable := TOursDatabase.GetFullTableContents(Caption)
  else
    aTable := TOursDatabase.GetFullTableContents(TableName);

  if Assigned(aTable) then begin
    grd.ColCount := aTable.ColCount;
    grd.RowCount := aTable.RowCount + 1;

    for var col := 0 to aTable.ColCount - 1 do
      grd.Cells[col, 0] := aTable.Columns[col];

    var aRow := 1;
    while not aTable.EOF do begin
      for var col := 0 to aTable.ColCount - 1 do
        grd.Cells[col, aRow] := aTable.FieldAsString(col, '--');
      aTable.Next;
      inc(aRow);
    end;

    aTable.Free;
  end;

  for var col := 0 to grd.ColCount - 1 do begin
    if (col = 0) and (grd.Cells[0, 0] <> 'id') then
      grd.FixedCols := 0;

    var WMax: integer := grd.DefaultColWidth;
    for var row := 0 to (grd.RowCount - 1) do begin
      var W := grd.Canvas.TextWidth(grd.Cells[col, row]);
      if W > WMax then
        WMax := W;
    end;
    grd.ColWidths[col] := WMax + 10;
  end;

  if Assigned(FMessageList) then begin
    if grd.RowCount = 0 then begin
      FMessageList.AddError(Format(rsTableNotFound, [TableName]));
    end else if grd.RowCount <= 1 then begin
      FMessageList.AddWarning(Format(rsTableIsEmpty, [TableName]));
    end else begin
      FMessageList.AddInfo(Format(rsTableLoaded, [TableName]));
    end;
  end;
end;

// =================================================================================================

end.
