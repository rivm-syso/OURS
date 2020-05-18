unit SQLiteTable3;

{
  Simple classes for using SQLite's exec and get_table.

  TSQLiteDatabase wraps the calls to open and close an SQLite database.
  It also wraps SQLite_exec for queries that do not return a result set

  TSQLiteTable wraps execution of SQL query.
  It run query and read all returned rows to internal buffer.
  It allows accessing fields by name as well as index and can move through a
  result set forward and backwards, or randomly to any row.

  TSQLiteUniTable wraps execution of SQL query.
  It run query as TSQLiteTable, but reading just first row only!
  You can step to next row (until not EOF) by 'Next' method.
  You cannot step backwards! (So, it is called as UniDirectional result set.)
  It not using any internal buffering, this class is very close to Sqlite API.
  It allows accessing fields by name as well as index on actual row only.
  Very good and fast for sequentional scanning of large result sets with minimal
    memory footprint.

  Warning! Do not close TSQLiteDatabase before any TSQLiteUniTable,
    because query is closed on TSQLiteUniTable destructor and database connection
    is used during TSQLiteUniTable live!

  SQL parameter usage:
    You can add named parameter values by call set of AddParam* methods.
    Parameters will be used for first next SQL statement only.
    Parameter name must be prefixed by ':', '$' or '@' and same prefix must be
    used in SQL statement!
    Sample:
      table.AddParamText(':str', 'some value');
      s := table.GetTableString('SELECT value FROM sometable WHERE id=:str');

   Notes from Andrew Retmanski on prepared queries
   The changes are as follows:

   SQLiteTable3.pas
   - Added new boolean property Synchronised (this controls the SYNCHRONOUS pragma as I found that turning this OFF increased the write performance in my application)
   - Added new type TSQLiteQuery (this is just a simple record wrapper around the SQL string and a TSQLiteStmt pointer)
   - Added PrepareSQL method to prepare SQL query - returns TSQLiteQuery
   - Added ReleaseSQL method to release previously prepared query
   - Added overloaded BindSQL methods for Integer and String types - these set new values for the prepared query parameters
   - Added overloaded ExecSQL method to execute a prepared TSQLiteQuery

   Usage of the new methods should be self explanatory but the process is in essence:

   1. Call PrepareSQL to return TSQLiteQuery 2. Call BindSQL for each parameter in the prepared query 3. Call ExecSQL to run the prepared query 4. Repeat steps 2 & 3 as required 5. Call ReleaseSQL to free SQLite resources

   One other point - the Synchronised property throws an error if used inside a transaction.

   Acknowledments
   Adapted by Tim Anderson (tim@itwriting.com)
   Originally created by Pablo Pissanetzky (pablo@myhtpc.net)
   Modified and enhanced by Lukas Gebauer
}

interface

uses
  Windows, SQLite3, Classes, SysUtils;

{$M+}

const
  scDefaultDBName = 'main';

type
  TSQLiteDataType = (dtInt = SQLITE_INTEGER,
                     dtNumeric = SQLITE_FLOAT,
                     dtStr = SQLITE_TEXT,
                     dtBlob = SQLITE_BLOB,
                     dtNull = SQLITE_NULL);

  TSQLiteDatabase = class;

  ESQLiteException = class(Exception)
  protected
    FSQL: string;
    FDBPath: widestring;
  public
    constructor Create(DBFile: widestring; Message: string); overload;
    constructor Create(DB: TSQLiteDatabase; Message: string); overload;
    constructor Create(DB: TSQLiteDatabase; SQL: string; Message: string); overload;
    property SQL: string read FSQL;
    property Database: widestring read FDBPath;
  end;

  TSQLiteParam = class
  public
    name: string;
    valuetype: TSQLiteDataType;
    valueinteger: int64;
    valuefloat: double;
    valuedata: UTF8String;
    valueblob: TStream;

    constructor Create(Name: string; Value: int64); overload;
    constructor Create(Name: string; Value: double); overload;
    constructor Create(Name: string; Value: WideString); overload;
    constructor Create(Name: string; Value: AnsiString); overload;
    constructor Create(Name: string; Value: TStream); overload;
    destructor  Destroy; override;

    procedure SetValue(Value: int64); overload;
    procedure SetValue(Value: double); overload;
    procedure SetValue(Value: WideString); overload;
    procedure SetValue(Value: AnsiString); overload;
    procedure SetValue(Value: TStream); overload;
  end;

  TSQLiteQuery = record
  private
    function GetSQL: string;
  public
    Statement: TSQLiteStmt;
    procedure Release;
    property SQL: string  read GetSQL;
  end;


  TSQLiteTable = class;
  TSQLiteUniTable = class;

  TSQLiteDatabase = class
  private
    fFilename: WideString;
    fDB: TSQLiteDB;
    fInTrans: boolean;
    fSync: boolean;
    fParams: TList;
    procedure RaiseError(Context: string; SQL: string);
    procedure SetParams(Stmt: TSQLiteStmt);
    function getRowsChanged: integer;
  protected
    procedure SetSynchronised(Value: boolean);
  public
    constructor Create(const FileName: Widestring); overload;
    constructor Create(const FileName: string); overload;
    destructor Destroy; override;
    function GetTable(const SQL: string): TSQLiteTable; overload;
    function GetTable(const Query: TSQLiteQuery): TSQLiteTable; overload;
    function ExecSQL(const SQL: string): string; overload;
    procedure ExecSQL(Query: TSQLiteQuery); overload;
    function PrepareSQL(const SQL: string): TSQLiteQuery;
    procedure BindSQL(Query: TSQLiteQuery; const Index: Integer; const Value: Integer); overload;
    procedure BindSQL(Query: TSQLiteQuery; const Index: Integer; const Value: String); overload;
    procedure ReleaseSQL(Query: TSQLiteQuery);
    function GetUniTable(const SQL: string): TSQLiteUniTable; overload;
    function GetUniTable(const Query: TSQLiteQuery): TSQLiteUniTable; overload;
    function GetTableValue(const SQL: string): int64; overload;
    function GetTableValue(const Query: TSQLiteQuery): int64; overload;
    function GetTableString(const SQL: string): string; overload;
    function GetTableString(const Query: TSQLiteQuery): string; overload;
    procedure UpdateBlob(const SQL: string; BlobData: TStream);
    procedure BeginTransaction;
    procedure Commit;
    procedure Rollback;
    procedure SavePoint(SavepointName: string); overload;
    procedure SavePoint(SavepointName: string; Args: array of const); overload;
    procedure Release(SavepointName: string); overload;
    procedure Release(SavepointName: string; Args: array of const); overload;
    procedure RollbackTo(SavepointName: string); overload;
    procedure RollbackTo(SavepointName: string; Args: array of const); overload;
    function TableExists(TableName: string): boolean;
    function GetLastInsertRowID: int64;
    function GetLastChangedRows: int64;
    procedure SetTimeout(Value: integer);
    function version: string;

    procedure BackupTo(const DestDB: TSQLiteDatabase; const DestName: string = scDefaultDBName; const SourceName: string = scDefaultDBName); overload;
    procedure BackupTo(const DestDB: string; const SourceName: string = scDefaultDBName); overload;
    procedure RestoreFrom(const SourceDB: TSQLiteDatabase; const SourceName: string = scDefaultDBName; const DestName: string = scDefaultDBName); overload; inline;
    procedure RestoreFrom(const SourceDB: string; const DestName: string = scDefaultDBName); overload;

    procedure AddCustomCollate(name: string; xCompare: TCollateXCompare);
    //adds collate named SYSTEM for correct data sorting by user's locale
    Procedure AddSystemCollate;
    procedure ParamsClear;
    procedure AddParam(Param: TSQliteParam);
    procedure AddParamInt(name: string; value: int64); overload;
    procedure AddParamInt(name: string; value: int64; nullIfValue: int64); overload;
    procedure AddParamFloat(name: string; value: double); overload;
    procedure AddParamFloat(name: string; value: double; nullIfValue: double); overload;
    procedure AddParamText(name: string; value: widestring); overload;
    procedure AddParamText(name: string; value: widestring; nullIfValue: widestring); overload;
    procedure AddParamText(name: string; value: ansistring); overload;
    procedure AddParamText(name: string; value: ansistring; nullIfValue: ansistring); overload;
    procedure AddParamBlob(name: string; value: TStream);
    procedure AddParamNull(name: string);
    property DB: TSQLiteDB read fDB;
  published
    property Filename: WideString         read fFilename;
    property isTransactionOpen: boolean   read fInTrans;
    //database rows that were changed (or inserted or deleted) by the most recent SQL statement
    property RowsChanged : integer        read getRowsChanged;
    property Synchronised: boolean        read FSync write SetSynchronised;

  end;

  TSQLiteTable = class
  private
    fResults: TList;
    fResTypes: TList;
    fRowCount: cardinal;
    fColCount: cardinal;
    fCols: TStringList;
    fColTypes: TList;
    fRow: cardinal;
    fDBFile: widestring;
    function GetFields(I: cardinal): UTF8String;
    function GetEOF: boolean;
    function GetBOF: boolean;
    function GetColumns(I: integer): string;
    function GetFieldByName(FieldName: string): string;
    function GetFieldIndex(FieldName: string): integer;
    function GetCount: integer;
    function GetCountResult: integer;
    procedure Initialize(const DB: TSQLiteDatabase; const Stmt: TSQLiteStmt);
  public
    constructor Create(DB: TSQLiteDatabase; const SQL: string); reintroduce; overload;
    constructor Create(DB: TSQLiteDatabase; const Query: TSQLiteQuery); reintroduce; overload;
    destructor Destroy; override;
    function ExportToStrings(const FormatSettings: TFormatSettings; const LineSep: string = #13#10; const QuoteChar: Char = '"'): TStrings; overload;
    function ExportToStrings(const Strings: TStrings; const FormatSettings: TFormatSettings): Integer; overload;
    function ExportToStrings(const ColSep: Char = #9; const LineSep: string = #13#10; const QuoteChar: Char = '"'): TStrings; overload;
    function ExportToStrings(const Strings: TStrings; const ColSep: Char = #9): Integer; overload;
    function FieldAsInteger(Index: cardinal; NullValue: Int64 = 0): int64; overload;
    function FieldAsInteger(Name: string; NullValue: Int64 = 0): int64; overload;
    function FieldAsBlob(Index: cardinal): TMemoryStream; overload;
    function FieldAsBlob(Name: string): TMemoryStream; overload;
    function FieldAsBlobText(Index: cardinal; NullValue: AnsiString = ''): AnsiString; overload;
    function FieldAsBlobText(Name: string; NullValue: AnsiString = ''): AnsiString; overload;
    function FieldIsNull(Index: cardinal): boolean; overload;
    function FieldIsNull(Name: string): boolean; overload;
    function FieldAsString(Index: cardinal; NullValue: WideString = ''): WideString; overload;
    function FieldAsString(Name: string; NullValue: WideString = ''): WideString; overload;
    function FieldAsDouble(Index: cardinal; NullValue: double = 0): double; overload;
    function FieldAsDouble(Name: string; NullValue: double = 0): double; overload;
    function FieldType(Index: cardinal): integer; overload;
    function FieldType(Name: string): integer; overload;
    function Next: boolean;
    function Previous: boolean;
    property EOF: boolean read GetEOF;
    property BOF: boolean read GetBOF;
    property Fields[I: cardinal]: UTF8String read GetFields;
    property FieldByName[FieldName: string]: string read GetFieldByName;
    property FieldIndex[FieldName: string]: integer read GetFieldIndex;
    property Columns[I: integer]: string read GetColumns;
    property ColCount: cardinal read fColCount;
    property RowCount: cardinal read fRowCount;
    property Row: cardinal read fRow;
    function MoveFirst: boolean;
    function MoveLast: boolean;
    function MoveTo(position:Cardinal): boolean;
    property Count: integer read GetCount;
    // The property CountResult is used when you execute count(*) queries.
    // It returns 0 if the result set is empty or the value of the
    // first field as an integer.
    property CountResult: integer read GetCountResult;
  end;

  TSQLiteUniTable = class
  private
    fColCount: integer;
    fCols: TStringList;
    fColTypes: TList;
    fRow: cardinal;
    fEOF: boolean;
    fStmt: TSQLiteStmt;
    fOwnsStmt: Boolean;
    fDB: TSQLiteDatabase;
    fSQL: UTF8string;
    procedure Initialize;
    function GetFields(I: cardinal): UTF8String;
    function GetColumns(I: integer): string;
    function GetFieldByName(FieldName: string): string;
    function GetFieldIndex(FieldName: string): integer;
  public
    constructor Create(DB: TSQLiteDatabase; const SQL: string); overload;
    constructor Create(DB: TSQLiteDatabase; const Query: TSQLiteQuery); overload;
    destructor Destroy; override;
    function FieldAsInteger(I: cardinal): int64; overload;
    function FieldAsBlob(I: cardinal): TMemoryStream; overload;
    function FieldAsBlobText(I: cardinal): AnsiString; overload;
    function FieldIsNull(I: cardinal): boolean; overload;
    function FieldAsString(I: cardinal): Widestring; overload;
    function FieldAsDouble(I: cardinal): double; overload;
    function FieldAsInteger(Name: string): int64; overload;
    function FieldAsBlob(Name: string): TMemoryStream; overload;
    function FieldAsBlobText(Name: string): AnsiString; overload;
    function FieldIsNull(Name: string): boolean; overload;
    function FieldAsString(Name: string): Widestring; overload;
    function FieldAsDouble(Name: string): double; overload;
    function Next: boolean;
    property DB: TSQLiteDatabase  read fDB;
    property EOF: boolean read FEOF;
    property Fields[I: cardinal]: UTF8String read GetFields;
    property FieldByName[FieldName: string]: string read GetFieldByName;
    property FieldIndex[FieldName: string]: integer read GetFieldIndex;
    property Columns[I: integer]: string read GetColumns;
    property ColCount: integer read fColCount;
    property Row: cardinal read fRow;
  end;

procedure DisposePointer(ptr: pointer); cdecl;

function SystemCollate(Userdta: pointer; Buf1Len: integer; Buf1: pointer;
    Buf2Len: integer; Buf2: pointer): integer; cdecl;

////////////////////////////////////////////////////////////////////////////////////////////////////
implementation

{ ------------------------------------------------------------------------------------------------ }
procedure DisposePointer(ptr: pointer); cdecl;
begin
  if assigned(ptr) then
    freemem(ptr);
end;

{ ------------------------------------------------------------------------------------------------ }
function SystemCollate(Userdta: pointer; Buf1Len: integer; Buf1: pointer;
    Buf2Len: integer; Buf2: pointer): integer; cdecl;
begin
  Result := CompareStringW(LOCALE_USER_DEFAULT, 0, PWideChar(Buf1), Buf1Len,
    PWideChar(Buf2), Buf2Len) - 2;
end;

//------------------------------------------------------------------------------
// TSQLiteDatabase
//------------------------------------------------------------------------------

constructor TSQLiteDatabase.Create(const FileName: string);
begin
  Create(WideString(Filename));
end;
{ ------------------------------------------------------------------------------------------------ }
constructor TSQLiteDatabase.Create(const FileName: Widestring);
var
  Msg: pAnsichar;
  iResult: integer;
  utf8FileName: UTF8String;
begin
  fFilename := Filename;
  inherited Create;
  fParams := TList.Create;

  self.fInTrans := False;

  Msg := nil;
  try
    utf8FileName := UTF8Encode(FileName);
    iResult := SQLite3_Open(PAnsiChar(utf8FileName), Fdb);

    if iResult <> SQLITE_OK then
      if Assigned(Fdb) then
      begin
        Msg := Sqlite3_ErrMsg(Fdb);
        raise ESqliteException.CreateFmt('Failed to open database "%s" : %s',
          [FileName, Msg]);
      end
      else
        raise ESqliteException.CreateFmt('Failed to open database "%s" : unknown error',
          [FileName]);

//set a few configs
//L.G. Do not call it here. Because busy handler is not setted here,
// any share violation causing exception!

//    self.ExecSQL('PRAGMA SYNCHRONOUS=NORMAL;');
//    self.ExecSQL('PRAGMA temp_store = MEMORY;');

  finally
    if Assigned(Msg) then
      SQLite3_Free(Msg);
  end;

end;

//..............................................................................

destructor TSQLiteDatabase.Destroy;
var
  Code: integer;
begin
  if self.fInTrans then
    self.Rollback;  //assume rollback
  ParamsClear;
  fParams.Free;
  if Assigned(fDB) then begin
    Code := SQLite3_Close(fDB);
    {--- MCO 15-10-2010: Ik zet hier een assertion neer; bij het debuggen treedt de fout dan op;
                          maar in het definitieve product wordt de fout stilletjes verzwegen. ---}
    Assert(Code = SQLITE_OK, string(SQLiteErrorStr(Code)));
//    if Code <> SQLITE_OK then begin
//      raise ESQLiteException.Create(fFilename, SQLiteErrorStr(Code));
//    end;
  end;
  inherited;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetLastInsertRowID: int64;
begin
  Result := Sqlite3_LastInsertRowID(self.fDB);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetLastChangedRows: int64;
begin
//  Result := SQLite3_TotalChanges(self.fDB);
  Result := SQLite3_Changes(self.fDB);
end;

//..............................................................................

{ ------------------------------------------------------------------------------------------------ }

procedure TSQLiteDatabase.RaiseError(Context: string; SQL: string);
//look up last error and raise an exception with an appropriate message
var
  Msg: PAnsiChar;
  ErrCode : integer;
begin

  Msg := nil;

  ErrCode := sqlite3_errcode(self.fDB);
  if ErrCode <> SQLITE_OK then
    Msg := sqlite3_errmsg(self.fDB);

  if Msg <> nil then
    raise ESqliteException.Create(Self, SQL, Format(Context +'.'#13'Error [%d]: %s.'#13'%s', [ErrCode, SQLiteErrorStr(ErrCode), Msg]))
  else
    raise ESqliteException.Create(Self, SQL, Context);

end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.SetSynchronised(Value: boolean);
begin
  if Value <> fSync then
  begin
    if Value then
      ExecSQL('PRAGMA synchronous = ON;')
    else
      ExecSQL('PRAGMA synchronous = OFF;');
    fSync := Value;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteDatabase.ExecSQL(const SQL: string): string;
var
  Stmt: TSQLiteStmt;
  NextSQLStatement: PAnsiChar;
  iStepResult: integer;
  ParsedSQL: string;
begin
  Stmt := nil;
  if Sqlite3_Prepare_v2(self.fDB, PAnsiChar(UTF8String(SQL)), -1, Stmt, NextSQLStatement) <> SQLITE_OK then begin
    RaiseError('Error executing SQL', SQL);
  end;
  if (Stmt = nil) then begin
    if SQLite3_ErrCode(fDB) <> 0 then begin
      RaiseError('Could not prepare SQL statement', SQL);
    end else begin
      Result := '';
      Exit;
    end;
  end;
  try
    SetParams(Stmt);
    iStepResult := Sqlite3_step(Stmt);
    if (iStepResult <> SQLITE_DONE) then begin
      ParsedSQL := UTF8String(SQLite3_SQL(stmt));
      if ParsedSQL = '' then ParsedSQL := SQL;
      SQLite3_reset(stmt);
      RaiseError('Error executing SQL statement', ParsedSQL);
    end;
    Result := UTF8String(NextSQLStatement);
  finally
    if Assigned(Stmt) then begin
      Sqlite3_Finalize(stmt);
    end;
  end;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }

procedure TSQLiteDatabase.ExecSQL(Query: TSQLiteQuery);
var
  iStepResult: integer;
begin
  if Assigned(Query.Statement) then
  begin
    SetParams(Query.Statement);
    iStepResult := Sqlite3_step(Query.Statement);

    if (iStepResult <> SQLITE_DONE) then
      begin
      SQLite3_reset(Query.Statement);
      RaiseError('Error executing prepared SQL statement', Query.SQL);
      end;
    Sqlite3_Reset(Query.Statement);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }

function TSQLiteDatabase.PrepareSQL(const SQL: string): TSQLiteQuery;
var
  Stmt: TSQLiteStmt;
  NextSQLStatement: PAnsiChar;
begin
  //Result.SQL := SQL;
  Result.Statement := nil;

  if SQLite3_Prepare_v2(self.fDB, PAnsiChar(UTF8String(SQL)), -1, Stmt, NextSQLStatement) <>
    SQLITE_OK then
    RaiseError('Error executing SQL', SQL)
  else
    Result.Statement := Stmt;

  if (Result.Statement = nil) then
    RaiseError('Could not prepare SQL statement', SQL);
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
procedure TSQLiteDatabase.BindSQL(Query: TSQLiteQuery; const Index: Integer; const Value: Integer);
begin
  if Assigned(Query.Statement) then
    Sqlite3_Bind_Int(Query.Statement, Index, Value)
  else
    RaiseError('Could not bind integer to prepared SQL statement', Query.SQL);
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
procedure TSQLiteDatabase.BindSQL(Query: TSQLiteQuery; const Index: Integer; const Value: String);
begin
  if Assigned(Query.Statement) then
    Sqlite3_Bind_Text(Query.Statement, Index, PAnsiChar(Value), Length(Value), Pointer(SQLITE_STATIC))
  else
    RaiseError('Could not bind string to prepared SQL statement', Query.SQL);
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
procedure TSQLiteDatabase.ReleaseSQL(Query: TSQLiteQuery);
begin
  if Assigned(Query.Statement) then
  begin
    Sqlite3_Finalize(Query.Statement);
    Query.Statement := nil;
  end
//  else
//    RaiseError('Could not release prepared SQL statement', Query.SQL);
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.UpdateBlob(const SQL: string; BlobData: TStream);
var
  iSize: integer;
  ptr: pointer;
  Stmt: TSQLiteStmt;
  Msg: PAnsichar;
  NextSQLStatement: PAnsiChar;
  iStepResult: integer;
  iBindResult: integer;
begin
  //expects SQL of the form 'UPDATE MYTABLE SET MYFIELD = ? WHERE MYKEY = 1'
  if pos('?', SQL) = 0 then
    RaiseError('SQL must include a ? parameter', SQL);

  Stmt := nil;
  Msg := nil;
  try

    if Sqlite3_Prepare_v2(self.fDB, PAnsiChar(UTF8String(SQL)), -1, Stmt, NextSQLStatement) <>
      SQLITE_OK then
      RaiseError('Could not prepare SQL statement', SQL);

    if (Stmt = nil) then
      RaiseError('Could not prepare SQL statement', SQL);

    //now bind the blob data
    iSize := BlobData.size;

    GetMem(ptr, iSize);

    if (ptr = nil) then
      raise ESqliteException.Create(Self, SQL, 'Error getting memory to save blob');

    BlobData.position := 0;
    BlobData.Read(ptr^, iSize);

    iBindResult := SQLite3_Bind_Blob(stmt, 1, ptr, iSize, @DisposePointer);

    if iBindResult <> SQLITE_OK then
      RaiseError('Error binding blob to database', SQL);

    iStepResult := Sqlite3_step(Stmt);

    if (iStepResult <> SQLITE_DONE) then
      begin
      SQLite3_reset(stmt);
      RaiseError('Error executing SQL statement', SQL);
      end;

  finally

    if Assigned(Stmt) then
      Sqlite3_Finalize(stmt);

    if Assigned(Msg) then
      SQLite3_Free(Msg);
  end;

end;

//..............................................................................

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetTable(const SQL: string): TSQLiteTable;
begin
  Result := TSQLiteTable.Create(Self, SQL);
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetTable(const Query: TSQLiteQuery): TSQLiteTable;
begin
  Result := TSQLiteTable.Create(Self, Query);
end;


{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetUniTable(const SQL: string): TSQLiteUniTable;
begin
  Result := TSQLiteUniTable.Create(Self, SQL);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetUniTable(const Query: TSQLiteQuery): TSQLiteUniTable;
begin
  Result := TSQLiteUniTable.Create(Self, Query);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetTableValue(const Query: TSQLiteQuery): int64;
var
  Table: TSQLiteUniTable;
begin
  Result := 0;
  Table := self.GetUniTable(Query);
  try
    if not Table.EOF then
      Result := Table.FieldAsInteger(0);
  finally
    Table.Free;
  end;
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetTableValue(const SQL: string): int64;
var
  Table: TSQLiteUniTable;
begin
  Result := 0;
  Table := self.GetUniTable(SQL);
  try
    if not Table.EOF then
      Result := Table.FieldAsInteger(0);
  finally
    Table.Free;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetTableString(const Query: TSQLiteQuery): string;
var
  Table: TSQLiteUniTable;
begin
  Result := '';
  Table := self.GetUniTable(Query);
  try
    if not Table.EOF then
      Result := Table.FieldAsString(0);
  finally
    Table.Free;
  end;
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.GetTableString(const SQL: string): String;
var
  Table: TSQLiteUniTable;
begin
  Result := '';
  Table := self.GetUniTable(SQL);
  try
    if not Table.EOF then
      Result := Table.FieldAsString(0);
  finally
    Table.Free;
  end;
end;


{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
procedure TSQLiteDatabase.BackupTo(const DestDB: TSQLiteDatabase; const DestName,
  SourceName: string);
var
  Backup: TSQLiteBackup;
  Dest, Src: UTF8String;
begin
  Dest := UTF8String(DestName);
  Src := UTF8String(SourceName);
  Backup := SQLite3_BackupInit(DestDB.fDB, PAnsiChar(Dest), fDB, PAnsiChar(Src));
  if Backup = nil then
    raise ESQLiteException.Create(Self, UTF8String(SQLite3_ErrMsg(DestDB.fDB)));
  try
    if not SQLite3_BackupStep(Backup, -1) in [SQLITE_OK, SQLITE_DONE] then begin
      raise ESQLiteException.Create(Self, UTF8String(SQLite3_ErrMsg(DestDB.fDB)));
    end;
  finally
    if SQLite3_BackupFinish(Backup) <> SQLITE_OK then
      raise ESQLiteException.Create(Self, UTF8String(SQLite3_ErrMsg(DestDB.fDB)));
  end;
end;
{$WARNINGS ON}
{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.BackupTo(const DestDB: string; const SourceName: string);
var
  FileDB: TSQLiteDatabase;
begin
  if (DestDB = '') or SameText(DestDB, ':memory:') then
    raise ESQLiteException.Create('Cannot back up to a volatile database.');

  FileDB := TSQLiteDatabase.Create(DestDB);
  try
    BackupTo(FileDB, scDefaultDBName, SourceName);
  finally
    FileDB.Free;
  end;
end;


{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.RestoreFrom(const SourceDB: TSQLiteDatabase; const SourceName,
  DestName: string);
begin
  SourceDB.BackupTo(Self, DestName, SourceName);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.RestoreFrom(const SourceDB, DestName: string);
var
  FileDB: TSQLiteDatabase;
begin
  FileDB := TSQLiteDatabase.Create(SourceDB);
  try
    RestoreFrom(FileDB, scDefaultDBName, DestName);
  finally
    FileDB.Free;
  end;
end;


{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.BeginTransaction;
begin
  if not self.fInTrans then
  begin
    self.ExecSQL('BEGIN TRANSACTION');
    OutputDebugString(PChar('BEGIN TRANSACTION'));
    self.fInTrans := True;
  end
  else
    raise ESqliteException.Create(Self, 'Transaction already open');
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.Commit;
begin
  self.ExecSQL('COMMIT');
  OutputDebugString(PChar('COMMIT'));
  self.fInTrans := False;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.Rollback;
begin
  self.ExecSQL('ROLLBACK');
  OutputDebugString(PChar('ROLLBACK'));
  self.fInTrans := False;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.SavePoint(SavepointName: string);
begin
  self.ExecSQL('SAVEPOINT ''' + StringReplace(SavepointName, '''', '''''', [rfReplaceAll]) + ''';');
  OutputDebugString(PChar('SAVEPOINT "' + SavepointName + '"'));
end;
{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.SavePoint(SavepointName: string; Args: array of const);
begin
  Self.SavePoint(Format(SavepointName, Args));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.Release(SavepointName: string);
begin
  self.ExecSQL('RELEASE SAVEPOINT ''' + StringReplace(SavepointName, '''', '''''', [rfReplaceAll]) + ''';');
  OutputDebugString(PChar('SAVEPOINT "' + SavepointName + '" RELEASED'));
end;
{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.Release(SavepointName: string; Args: array of const);
begin
  Self.Release(Format(SavepointName, Args));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.RollbackTo(SavepointName: string);
begin
  self.ExecSQL('ROLLBACK TO SAVEPOINT ''' + StringReplace(SavepointName, '''', '''''', [rfReplaceAll]) + ''';');
  OutputDebugString(PChar('SAVEPOINT ROLLED BACK TO "' + SavepointName + '"'));
  self.Release(SavepointName);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.RollbackTo(SavepointName: string; Args: array of const);
begin
  Self.RollbackTo(Format(SavepointName, Args));
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteDatabase.TableExists(TableName: string): boolean;
var
  Separator: integer;
  dbs: TSQLiteUniTable;
  Repository, Prefix, SQL: string;
begin
  Repository := 'sqlite_master';
  Separator := Pos('.', TableName);
  if Separator > 0 then begin
    // first, check if the attached database exists
    Prefix := Copy(TableName, 1, Separator - 1);
    TableName := Copy(TableName, Separator + 1);
    if SameText(Prefix, 'temp') then begin
      Prefix := '';
      Repository := 'sqlite_temp_master';
    end else begin
      dbs := self.GetUniTable('PRAGMA database_list');
      try
        Result := False;
        while not dbs.EOF do begin
          if LowerCase(dbs.FieldAsString(dbs.FieldIndex['name'])) = LowerCase(Prefix) then begin
            Result := True;
          end;
          dbs.Next;
        end;
      finally
        dbs.Free;
      end;
      if Result = False then begin
        Exit;
      end;
      Repository := Prefix + '.' + Repository;
    end;
  end else begin
    Prefix := '';
  end;
  //returns true if table exists in the database
  SQL := 'SELECT count(*) FROM ' + Repository + ' WHERE [type] = ''table'' AND lower(name) = :TableName';
  self.AddParamText(':TableName', LowerCase(TableName));
  Result := (self.GetTableValue(SQL) > 0);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.SetTimeout(Value: integer);
begin
  SQLite3_BusyTimeout(self.fDB, Value);
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteDatabase.version: string;
begin
  Result := UTF8String(SQLite3_Version);
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddCustomCollate(name: string;
  xCompare: TCollateXCompare);
begin
  sqlite3_create_collation(fdb, PAnsiChar(UTF8String(name)), SQLITE_UTF8, nil, xCompare);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddSystemCollate;
begin
  sqlite3_create_collation(fdb, 'SYSTEM', SQLITE_UTF16LE, nil, @SystemCollate);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.ParamsClear;
var
  n: integer;
begin
  for n := fParams.Count - 1 downto 0 do
    TSQLiteParam(fParams[n]).Free;
  fParams.Clear;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamInt(name: string; value: int64);
begin
  fParams.Add(TSQliteParam.Create(name, value));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamFloat(name: string; value: double);
begin
  fParams.Add(TSQliteParam.Create(name, value));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamText(name: string; value: widestring);
begin
  fParams.Add(TSQliteParam.Create(name, value));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamText(name: string; value: ansistring);
begin
  fParams.Add(TSQliteParam.Create(name, value));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParam(Param: TSQliteParam);
begin
  if Assigned(Param) then begin
    fParams.Add(Param);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamBlob(name: string; value: TStream);
begin
  fParams.Add(TSQliteParam.Create(name, value));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamNull(name: string);
begin
  fParams.Add(TSQliteParam.Create(name, nil));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamInt(name: string; value, nullIfValue: int64);
begin
  if value = nullIfValue then begin
    Self.AddParamNull(name);
  end else begin
    Self.AddParamInt(name, value);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamFloat(name: string; value, nullIfValue: double);
begin
  if value = nullIfValue then begin
    Self.AddParamNull(name);
  end else begin
    Self.AddParamFloat(name, value);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamText(name: string; value, nullIfValue: widestring);
begin
  if value = nullIfValue then begin
    Self.AddParamNull(name);
  end else begin
    Self.AddParamText(name, value);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.AddParamText(name: string; value, nullIfValue: ansistring);
begin
  if value = nullIfValue then begin
    Self.AddParamNull(name);
  end else begin
    Self.AddParamText(name, value);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteDatabase.SetParams(Stmt: TSQLiteStmt);
var
  n: integer;
  i: integer;
  par: TSQliteParam;
  iSize, iBindResult: integer;
  ptr: pointer;
begin
  try
    for n := 0 to fParams.Count - 1 do begin
      par := TSQliteParam(fParams[n]);
      i := sqlite3_bind_parameter_index(Stmt, PAnsiChar(UTF8String(par.name)));
      if i > 0 then begin
        case par.valuetype of
          dtInt:
            sqlite3_bind_int64(Stmt, i, par.valueinteger);
          dtNumeric:
            sqlite3_bind_double(Stmt, i, par.valuefloat);
          dtStr:
            sqlite3_bind_text(Stmt, i, pAnsichar(par.valuedata),
              length(par.valuedata), SQLITE_TRANSIENT);
          dtBlob: begin
            //now bind the blob data
            iSize := par.valueblob.Size;
            GetMem(ptr, iSize);
            if (ptr = nil) then begin
              raise ESqliteException.Create(Self, Format('Error getting memory to save blob (%s)',
                                                         [par.name]));
            end;
            par.valueblob.position := 0;
            par.valueblob.Read(ptr^, iSize);
            iBindResult := SQLite3_Bind_Blob(stmt, i, ptr, iSize, @DisposePointer);
            if iBindResult <> SQLITE_OK then
              RaiseError(Format('Error binding blob "%s" to database', [par.name]), '');
          end;
          dtNull:
            sqlite3_bind_null(Stmt, i);
        end;
      end;
    end;
  finally
    ParamsClear;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
//database rows that were changed (or inserted or deleted) by the most recent SQL statement
function TSQLiteDatabase.getRowsChanged: integer;
begin
 Result := SQLite3_Changes(self.fDB);
end;

//------------------------------------------------------------------------------
// TSQLiteTable
//------------------------------------------------------------------------------

constructor TSQLiteTable.Create(DB: TSQLiteDatabase; const SQL: string);
var
  Stmt: TSQLiteStmt;
  NextSQLStatement: PAnsiChar;
begin
  inherited create;
  Stmt := nil;
  try
    self.fRowCount := 0;
    self.fColCount := 0;
    //if there are several SQL statements in SQL, NextSQLStatment points to the
    //beginning of the next one. Prepare only prepares the first SQL statement.
    if Sqlite3_Prepare_v2(DB.fDB, PAnsiChar(UTF8String(SQL)), -1, Stmt, NextSQLStatement) <> SQLITE_OK then
      DB.RaiseError('Error executing SQL', SQL);
    if (Stmt = nil) then
      DB.RaiseError('Could not prepare SQL statement', SQL);

    Initialize(DB, Stmt);
  finally
    if Assigned(Stmt) then
      Sqlite3_Finalize(stmt);
  end;
end;
{ ------------------------------------------------------------------------------------------------ }
constructor TSQLiteTable.Create(DB: TSQLiteDatabase; const Query: TSQLiteQuery);
begin
  Initialize(DB, Query.Statement);
end;

{ ------------------------------------------------------------------------------------------------ }
destructor TSQLiteTable.Destroy;
var
  i: cardinal;
begin
  if Assigned(fResults) then
  begin
    if fResults.Count > 0 then begin
      for i := 0 to fResults.Count - 1 do begin
        //check for blob type
        case TSQLIteDataType(fResTypes[i]) of
          dtBlob:
            TMemoryStream(fResults[i]).Free;
          dtStr:
            if fResults[i] <> nil then
            begin
              setstring(string(fResults[i]^), nil, 0);
              dispose(fResults[i]);
            end;
        else
          dispose(fResults[i]);
        end;
      end;
    end;
    fResults.Free;
    fResTypes.Free;
  end;
  if Assigned(fCols) then
    fCols.Free;
  if Assigned(fColTypes) then
    for i := 0 to fColTypes.Count - 1 do
      dispose(fColTypes[i]);
  fColTypes.Free;
  inherited;
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
procedure TSQLiteTable.Initialize(const DB: TSQLiteDatabase; const Stmt: TSQLiteStmt);
var
  iStepResult: integer;
  ptr: pointer;
  iNumBytes: integer;
  thisBlobValue: TMemoryStream;
  thisStringValue: pstring;
  thisDoubleValue: pDouble;
  thisIntValue: pInt64;
  thisColType: pInteger;
  i: integer;
  DeclaredColType: PAnsiChar;
  ActualColType: integer;
  ptrValue: PAnsiChar;
  SQL: string;
begin
  DB.SetParams(Stmt);

  iStepResult := Sqlite3_step(Stmt);

  //get data types
  fCols := TStringList.Create;
  fCols.CaseSensitive := False;
  fColTypes := TList.Create;
  fColCount := SQLite3_ColumnCount(stmt);
  for i := 0 to Pred(fColCount) do
    fCols.Add(Utf8ToAnsi(Sqlite3_ColumnName(stmt, i)));
  for i := 0 to Pred(fColCount) do
  begin
    new(thisColType);
    DeclaredColType := Sqlite3_ColumnDeclType(stmt, i);
    if (DeclaredColType = nil) then
      if iStepResult = SQLITE_ROW then begin
        thisColType^ := Sqlite3_ColumnType(stmt, i) //use the actual column type instead
      end else begin
        thisColType^ := SQLITE_NULL;
      end
    // seems to be needed for last_insert_rowid
    else
      if (UpperCase(DeclaredColType) = 'INTEGER') or (UpperCase(DeclaredColType) = 'BOOLEAN') then
        thisColType^ := SQLITE_INTEGER
      else
        if (UpperCase(DeclaredColType) = 'NUMERIC') or
          (UpperCase(DeclaredColType) = 'FLOAT') or
          (UpperCase(DeclaredColType) = 'DOUBLE') or
          (UpperCase(DeclaredColType) = 'REAL') then
          thisColType^ := SQLITE_FLOAT
        else
          if UpperCase(DeclaredColType) = 'BLOB' then
            thisColType^ := SQLITE_BLOB
          else
            thisColType^ := SQLITE_TEXT;
    fColTypes.Add(thiscoltype);
  end;
  fResults := TList.Create;
  fResTypes := TList.Create;

  while (iStepResult <> SQLITE_DONE) do
  begin
    case iStepResult of
      SQLITE_ROW:
        begin
          Inc(fRowCount);

        //get column values
          for i := 0 to Pred(ColCount) do
          begin
            // TODO: preserve actual field type, especially when it differs from the column's affinity
            ActualColType := Sqlite3_ColumnType(stmt, i);
            if (ActualColType = SQLITE_NULL) then begin
              fResults.Add(nil);
              fResTypes.Add(Pointer(dtNull));
            end else begin
              if pInteger(fColTypes[i])^ = SQLITE_INTEGER then
              begin
                new(thisintvalue);
                thisintvalue^ := Sqlite3_ColumnInt64(stmt, i);
                fResults.Add(thisintvalue);
                fResTypes.Add(Pointer(dtInt));
              end
              else
                if pInteger(fColTypes[i])^ = SQLITE_FLOAT then
                begin
                  new(thisdoublevalue);
                  thisdoublevalue^ := Sqlite3_ColumnDouble(stmt, i);
                  fResults.Add(thisdoublevalue);
                  fResTypes.Add(Pointer(dtNumeric));
                end
                else
                  if pInteger(fColTypes[i])^ = SQLITE_BLOB then
                  begin
                    iNumBytes := Sqlite3_ColumnBytes(stmt, i);
                    if iNumBytes = 0 then
                      thisblobvalue := nil
                    else
                    begin
                      thisblobvalue := TMemoryStream.Create;
                      thisblobvalue.position := 0;
                      ptr := Sqlite3_ColumnBlob(stmt, i);
                      thisblobvalue.writebuffer(ptr^, iNumBytes);
                    end;
                    fResults.Add(thisblobvalue);
                    fResTypes.Add(Pointer(dtBlob));
                  end
                  else
                  begin
                    new(thisstringvalue);
                    ptrValue := Sqlite3_ColumnText(stmt, i);
                    setstring(thisstringvalue^, ptrvalue, strlen(ptrvalue));
                    fResults.Add(thisstringvalue);
                    fResTypes.Add(Pointer(dtStr));
                  end;
            end;
          end;
        end;
      SQLITE_BUSY: begin
        SQL := UTF8String(SQLite3_SQL(Stmt));
        raise ESqliteException.Create(DB, SQL, 'Could not prepare SQL statement: SQLite is busy');
      end
    else
      begin
      SQLite3_reset(stmt);
      SQL := UTF8String(SQLite3_SQL(Stmt));
      DB.RaiseError('Could not retrieve data', SQL);
      end;
    end;
    iStepResult := Sqlite3_step(Stmt);
  end;
  SQLite3_reset(stmt);
  fRow := 0;
  fDBFile := DB.Filename;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.ExportToStrings(const ColSep: Char; const LineSep: string; const QuoteChar: Char): TStrings;
var
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.ListSeparator := ColSep;
  Result := ExportToStrings(TFormatSettings.Create, LineSep, QuoteChar);
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.ExportToStrings(const Strings: TStrings; const ColSep: Char): Integer;
var
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.ListSeparator := ColSep;
  Result := ExportToStrings(Strings, FS);
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.ExportToStrings(const FormatSettings: TFormatSettings;
                                      const LineSep: string;
                                      const QuoteChar: Char): TStrings;
begin
  Result := TStringList.Create;
  Result.LineBreak := LineSep;
  Result.QuoteChar := QuoteChar;
  ExportToStrings(Result, FormatSettings);
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.ExportToStrings(const Strings: TStrings; const FormatSettings: TFormatSettings): Integer;
var
  ri: Integer;
  Cols: TStringList;
  Value: string;
  ci: Integer;
begin
  Result := 0;
  MoveFirst;

  Cols := TStringList.Create;
  try
    if FormatSettings.ListSeparator = #0 then
      Cols.Delimiter := Strings.Delimiter
    else
      Cols.Delimiter := FormatSettings.ListSeparator;
    Cols.QuoteChar := Strings.QuoteChar;
    Cols.Capacity := ColCount;

//    if Strings.Count = 0 then
//      Strings.Add('Sep=' + Cols.Delimiter);

    for ci := 0 to integer(ColCount) - 1 do begin
      Cols.Add(Columns[ci]);
    end{col};
    Strings.Add(Cols.DelimitedText);

    for ri := 0 to integer(RowCount) - 1 do begin
      MoveTo(ri);
      Cols.Clear;
      for ci := 0 to integer(ColCount) - 1 do begin
        case FieldType(ci) of
          SQLITE_INTEGER: Value := IntToStr(FieldAsInteger(ci));
          SQLITE_FLOAT:   Value := FloatToStr(FieldAsDouble(ci), FormatSettings);
          SQLITE_NULL:    Value := '';
          else            Value := FieldAsString(ci);
        end;
        Cols.Add(Value);
      end{col};
      Strings.Add(Cols.DelimitedText);
      Inc(Result);
    end{row};

  finally
    Cols.Free;
  end;
end {TSQLiteTable.ExportToStrings};

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.GetColumns(I: integer): string;
begin
  Result := fCols[I];
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteTable.GetCountResult: integer;
begin
  if not EOF then
    Result := StrToInt(Fields[0])
  else
    Result := 0;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.GetCount: integer;
begin
  Result := FRowCount;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.GetEOF: boolean;
begin
  Result := fRow >= fRowCount;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.GetBOF: boolean;
begin
  Result := fRow <= 0;
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteTable.GetFieldByName(FieldName: string): string;
begin
  Result := GetFields(self.GetFieldIndex(FieldName));
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.GetFieldIndex(FieldName: string): integer;
begin
  if (fCols = nil) or (fCols.count = 0) then begin
    raise ESqliteException.Create(fDBFile, 'Field "' + fieldname + '" not found; empty dataset.');
    exit;
  end;

  Result := fCols.IndexOf(FieldName);

  if (result < 0) then begin
    raise ESqliteException.Create(fDBFile, 'Field "' + fieldname + '" not found in dataset.');
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
{$Warnings Off}
function TSQLiteTable.GetFields(I: cardinal): UTF8String;
var
  thisvalue: pstring;
  thistype: TSQLiteDataType;
begin
  Result := '';
  if EOF then
    raise ESqliteException.Create(fDBFile, 'Table is at End of File');
  //integer types are not stored in the resultset
  //as strings, so they should be retrieved using the type-specific
  //methods
//  thistype := pInteger(self.fColTypes[I])^;
  thistype := TSQLiteDataType(fResTypes[(fRow * fColCount) + i]);

  case thistype of
    dtStr:
      begin
        thisvalue := self.fResults[(self.frow * self.fColCount) + i];
        if (thisvalue <> nil) then
          Result := thisvalue^
        else
          Result := '';
      end;
    dtInt:
      Result := IntToStr(self.FieldAsInteger(i));
    dtNumeric:
      Result := FloatToStr(self.FieldAsDouble(i));
    dtBlob:
      Result := UTF8String(self.FieldAsBlobText(i));
  else
    Result := '';
  end;
end;
{$Warnings On}

{ ------------------------------------------------------------------------------------------------ }
function TSqliteTable.FieldAsBlob(Index: cardinal): TMemoryStream;
begin
  if EOF then
    raise ESqliteException.Create(fDBFile, 'Table is at End of File');
  if (self.fResults[(self.frow * self.fColCount) + Index] = nil) then
    Result := nil
  else
//    if pInteger(self.fColTypes[Index])^ = dtBlob then
    if TSQLiteDataType(self.fResTypes[(self.frow * self.fColCount) + Index]) = dtBlob then begin
      Result := TMemoryStream(self.fResults[(self.frow * self.fColCount) + Index]);
      Result.Position := 0;
    end else begin
      raise ESqliteException.Create(fDBFile, Format('Field %s is not a BLOB field.', [Index]));
    end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSqliteTable.FieldAsBlobText(Index: cardinal; NullValue: AnsiString = ''): AnsiString;
var
  MemStream: TMemoryStream;
  Buffer: PChar;
begin
  Result := NullValue;
  MemStream := self.FieldAsBlob(Index);
  if MemStream <> nil then
    if MemStream.Size > 0 then
    begin
      MemStream.position := 0;
      Buffer := stralloc(MemStream.Size + 1);
      MemStream.readbuffer(Buffer[0], MemStream.Size);
      (Buffer + MemStream.Size)^ := chr(0);
      SetString(Result, Buffer, MemStream.size);
      strdispose(Buffer);
    end;
end;


{ ------------------------------------------------------------------------------------------------ }
function TSqliteTable.FieldAsInteger(Index: cardinal; NullValue: int64): int64;
var
  i: integer;
begin
  if EOF then
    raise ESqliteException.Create(fDBFile, 'Table is at End of File');
  i := (self.frow * self.fColCount) + Index;
  if (self.fResults[i] = nil) then begin
    Result := NullValue
  end else begin
    case TSQLiteDataType(fResTypes[i]) of
      dtInt: Result := pInt64(self.fResults[i])^;
      dtNumeric: Result := trunc(strtofloat(pString(self.fResults[i])^)); // TODO: Why StrToFloat?!?
      else raise ESqliteException.Create(fDBFile, 'Not an integer or numeric field');
    end;
//    if pInteger(self.fColTypes[Index])^ = dtInt then
//      Result := pInt64(self.fResults[(self.frow * self.fColCount) + Index])^
//    else
//      if pInteger(self.fColTypes[Index])^ = dtNumeric then
//        Result := trunc(strtofloat(pString(self.fResults[(self.frow * self.fColCount) + Index])^))
//      else
//        raise ESqliteException.Create('Not an integer or numeric field');
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSqliteTable.FieldAsDouble(Index: cardinal; NullValue: double = 0): double;
begin
  if EOF then
    raise ESqliteException.Create(fDBFile, 'Table is at End of File');
  if (self.fResults[(self.frow * self.fColCount) + Index] = nil) then
    Result := NullValue
  else begin
    case TSQLiteDataType(fResTypes[(self.frow * self.fColCount) + Index]) of
      dtInt: Result := pInt64(self.fResults[(self.frow * self.fColCount) + Index])^;
      dtNumeric: Result := pDouble(self.fResults[(self.frow * self.fColCount) + Index])^;
      else raise ESqliteException.Create(fDBFile, 'Not an integer or numeric field');
    end;
  end;
//    if pInteger(self.fColTypes[Index])^ = dtInt then
//      Result := pInt64(self.fResults[(self.frow * self.fColCount) + Index])^
//    else
//      if pInteger(self.fColTypes[Index])^ = dtNumeric then
//        Result := pDouble(self.fResults[(self.frow * self.fColCount) + Index])^
//      else
//        raise ESqliteException.Create('Not an integer or numeric field');
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSqliteTable.FieldAsString(Index: cardinal; NullValue: WideString = ''): WideString;
begin
  if EOF then
    raise ESqliteException.Create(fDBFile, 'Table is at End of File');
  if (self.fResults[(self.frow * self.fColCount) + Index] = nil) then
    Result := NullValue
  else
    Result := self.GetFields(Index);
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
function TSqliteTable.FieldIsNull(Index: cardinal): boolean;
begin
  if EOF then
    raise ESqliteException.Create(fDBFile, 'Table is at End of File');
  Result := (self.fResults[(self.frow * self.fColCount) + Index] = nil);
end;

//..............................................................................

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.Next: boolean;
begin
  Result := False;
  if not EOF then begin
    Inc(fRow);
    Result := not EOF;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.Previous: boolean;
begin
  Result := False;
  if not BOF then
  begin
    Dec(fRow);
    Result := not BOF;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.MoveFirst: boolean;
begin
  Result := False;
  if self.fRowCount > 0 then
  begin
    fRow := 0;
    Result := True;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.MoveLast: boolean;
begin
  Result := False;
  if self.fRowCount > 0 then
  begin
    fRow := fRowCount - 1;
    Result := True;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.MoveTo(position: Cardinal): boolean;
begin
  Result := False;
  if (self.fRowCount > 0) and (self.fRowCount > position) then
  begin
    fRow := position;
    Result := True;
  end;
end;



////////////////////////////////////////////////////////////////////////////////////////////////////
{ TSQLiteUniTable }

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
constructor TSQLiteUniTable.Create(DB: TSQLiteDatabase; const SQL: string);
var
  NextSQLStatement: PAnsiChar;
begin
  inherited Create;
  self.fDB := db;
  self.fEOF := false;
  self.fRow := 0;
  self.fColCount := 0;
  self.fSQL := SQL;
  if Sqlite3_Prepare_v2(DB.fDB, PAnsiChar(self.fSQL), -1, fStmt, NextSQLStatement) <> SQLITE_OK then
    DB.RaiseError('Error executing SQL', SQL);
  if (fStmt = nil) then
    DB.RaiseError('Could not prepare SQL statement', SQL);
  fOwnsStmt := True;

  Initialize;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
constructor TSQLiteUniTable.Create(DB: TSQLiteDatabase; const Query: TSQLiteQuery);
begin
  inherited Create;
  self.fDB := db;
  self.fEOF := false;
  self.fRow := 0;
  self.fColCount := 0;
  self.fSQL := Query.SQL;

  fStmt := Query.Statement;
  fOwnsStmt := False;

  Initialize;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteUniTable.Initialize;
var
  thisColType: pInteger;
  i: integer;
  DeclaredColType: PAnsiChar;
begin
  DB.SetParams(fStmt);

  //get data types
  fCols := TStringList.Create;
  fCols.CaseSensitive := False;
  fColTypes := TList.Create;
  fColCount := SQLite3_ColumnCount(fstmt);
  for i := 0 to Pred(fColCount) do
    fCols.Add(Utf8ToAnsi(Sqlite3_ColumnName(fstmt, i)));
  for i := 0 to Pred(fColCount) do
  begin
    new(thisColType);
    DeclaredColType := Sqlite3_ColumnDeclType(fstmt, i);
    if DeclaredColType = nil then
      thisColType^ := Sqlite3_ColumnType(fstmt, i) //use the actual column type instead
    //seems to be needed for last_insert_rowid
    else
      if (DeclaredColType = 'INTEGER') or (DeclaredColType = 'BOOLEAN') then
        thisColType^ := SQLITE_INTEGER
      else
        if (DeclaredColType = 'NUMERIC') or
          (DeclaredColType = 'FLOAT') or
          (DeclaredColType = 'DOUBLE') or
          (DeclaredColType = 'REAL') then
          thisColType^ := SQLITE_FLOAT
        else
          if DeclaredColType = 'BLOB' then
            thisColType^ := SQLITE_BLOB
          else
            thisColType^ := SQLITE_TEXT;
    fColTypes.Add(thiscoltype);
  end;
  Next;
end;

{ ------------------------------------------------------------------------------------------------ }
destructor TSQLiteUniTable.Destroy;
var
  i: integer;
begin
  if Assigned(fStmt) then begin
    if fOwnsStmt then
      Sqlite3_Finalize(fstmt)
    else
      Sqlite3_Reset(fStmt);
  end;
  if Assigned(fCols) then
    fCols.Free;
  if Assigned(fColTypes) then
    for i := 0 to fColTypes.Count - 1 do
      dispose(fColTypes[i]);
  fColTypes.Free;
  inherited;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsBlob(I: cardinal): TMemoryStream;
var
  iNumBytes: integer;
  ptr: pointer;
begin
  Result := TMemoryStream.Create;
  iNumBytes := Sqlite3_ColumnBytes(fstmt, i);
  if iNumBytes > 0 then
  begin
    ptr := Sqlite3_ColumnBlob(fstmt, i);
    Result.writebuffer(ptr^, iNumBytes);
    Result.Position := 0;
  end;
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsBlob(Name: string): TMemoryStream;
begin
  Result := FieldAsBlob(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsBlobText(I: cardinal): Ansistring;
var
  MemStream: TMemoryStream;
  Buffer: PChar;
begin
  Result := '';
  MemStream := self.FieldAsBlob(I);
  if MemStream <> nil then
    if MemStream.Size > 0 then
    begin
      MemStream.position := 0;
      Buffer := stralloc(MemStream.Size + 1);
      MemStream.readbuffer(Buffer[0], MemStream.Size);
      (Buffer + MemStream.Size)^ := chr(0);
      SetString(Result, Buffer, MemStream.size);
      strdispose(Buffer);
    end;
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsBlobText(Name: string): AnsiString;
begin
  Result := FieldAsBlobText(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsDouble(I: cardinal): double;
begin
  Result := Sqlite3_ColumnDouble(fstmt, i);
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsDouble(Name: string): double;
begin
  Result := FieldAsDouble(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsInteger(I: cardinal): int64;
begin
  Result := Sqlite3_ColumnInt64(fstmt, i);
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsInteger(Name: string): int64;
begin
  Result := FieldAsInteger(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteUniTable.FieldAsString(I: cardinal): Widestring;
begin
  Result := self.GetFields(I);
end;
{$WARNINGS ON}
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldAsString(Name: string): Widestring;
begin
  Result := FieldAsString(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldIsNull(I: cardinal): boolean;
begin
  Result := Sqlite3_ColumnText(fstmt, i) = nil;
end;
{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.FieldIsNull(Name: string): boolean;
begin
  Result := FieldIsNull(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldAsBlob(Name: string): TMemoryStream;
begin
  Result := FieldAsBlob(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldAsBlobText(Name: string; NullValue: AnsiString): AnsiString;
begin
  Result := FieldAsBlobText(FieldIndex[Name], NullValue);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldAsDouble(Name: string; NullValue: double): double;
begin
  Result := FieldAsDouble(FieldIndex[Name], NullValue);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldAsInteger(Name: string; NullValue: Int64): int64;
begin
  Result := FieldAsInteger(FieldIndex[Name], NullValue);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldAsString(Name: string; NullValue: WideString): WideString;
begin
  Result := FieldAsString(FieldIndex[Name], NullValue);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldIsNull(Name: string): boolean;
begin
  Result := FieldIsNull(FieldIndex[Name]);
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldType(Index: cardinal): integer;
begin
  if Self.EOF then begin
    Result := integer(fColTypes[Index]);
  end else begin
    Result := integer(fResTypes[(fRow * fColCount) + Index]);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteTable.FieldType(Name: string): integer;
begin
  Result := Self.FieldType(Self.GetFieldIndex(Name));
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.GetColumns(I: integer): string;
begin
  Result := fCols[I];
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteUniTable.GetFieldByName(FieldName: string): string;
begin
  Result := GetFields(self.GetFieldIndex(FieldName));
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.GetFieldIndex(FieldName: string): integer;
begin
  if (fCols = nil) then
  begin
    raise ESqliteException.Create(fDB, 'Field ' + fieldname + ' Not found. Empty dataset');
    exit;
  end;

  if (fCols.count = 0) then
  begin
    raise ESqliteException.Create(fDB, 'Field ' + fieldname + ' Not found. Empty dataset');
    exit;
  end;

  Result := fCols.IndexOf(FieldName);

  if (result < 0) then
  begin
    raise ESqliteException.Create(fDB, 'Field not found in dataset: ' + fieldname)
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
function TSQLiteUniTable.GetFields(I: cardinal): UTF8String;
begin
  Result := Sqlite3_ColumnText(fstmt, i);
end;

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteUniTable.Next: boolean;
var
  iStepResult: integer;
begin
  fEOF := true;
  iStepResult := Sqlite3_step(fStmt);
  case iStepResult of
    SQLITE_ROW:
      begin
        fEOF := false;
        inc(fRow);
      end;
    SQLITE_DONE:
      // we are on the end of dataset
      // return EOF=true only
      ;
  else
    begin
    SQLite3_reset(fStmt);
    fDB.RaiseError('Could not retrieve data', fSQL);
    end;
  end;
  Result := not fEOF;
end;
{$WARNINGS ON}

////////////////////////////////////////////////////////////////////////////////////////////////////
{ TSQliteParam }

{ ------------------------------------------------------------------------------------------------ }
constructor TSQliteParam.Create(Name: string; Value: int64);
begin
  Self.name := Name;
  SetValue(Value);
end;
{ ------------------------------------------------------------------------------------------------ }
constructor TSQliteParam.Create(Name: string; Value: double);
begin
  Self.name := Name;
  SetValue(Value);
end;
{ ------------------------------------------------------------------------------------------------ }
constructor TSQliteParam.Create(Name: string; Value: AnsiString);
begin
  Self.name := Name;
  SetValue(Value);
end;
{ ------------------------------------------------------------------------------------------------ }
constructor TSQliteParam.Create(Name: string; Value: WideString);
begin
  Self.name := Name;
  SetValue(Value);
end;
{ ------------------------------------------------------------------------------------------------ }
constructor TSQliteParam.Create(Name: string; Value: TStream);
begin
  Self.name := Name;
  SetValue(Value);
end;

{ ------------------------------------------------------------------------------------------------ }
destructor TSQliteParam.Destroy;
begin
  try
    if Assigned(valueblob) then begin
      valueblob.Free;
    end;
  finally
    inherited;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteParam.SetValue(Value: double);
begin
  valuetype := dtNumeric;
  valuefloat := Value;
end;
{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteParam.SetValue(Value: int64);
begin
  valuetype := dtInt;
  valueinteger := Value;
end;
{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteParam.SetValue(Value: WideString);
begin
  valuetype := dtStr;
  valuedata := UTF8Encode(Value);
end;
{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
procedure TSQLiteParam.SetValue(Value: AnsiString);
begin
  valuetype := dtStr;
  valuedata := Value;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteParam.SetValue(Value: TStream);
begin
  if Assigned(Value) then begin
    valuetype := dtBlob;
    valueblob := TMemoryStream.Create;
    Value.Position := 0;
    valueblob.CopyFrom(Value, Value.Size);
  end else begin
    valuetype := dtNull;
    if Assigned(valueblob) then begin
      valueblob.Free;
    end;
    valueblob := nil;
  end;
end;

{ ================================================================================================ }
{ ESQLiteException }

{ ------------------------------------------------------------------------------------------------ }
constructor ESQLiteException.Create(DB: TSQLiteDatabase; Message: string);
begin
  Self.Create(DB, '', Message);
end;
{ ------------------------------------------------------------------------------------------------ }
constructor ESQLiteException.Create(DB: TSQLiteDatabase; SQL, Message: string);
begin
  FDBPath := DB.Filename;
  FSQL := SQL;
  inherited Create(Message);
end;
{ ------------------------------------------------------------------------------------------------ }
constructor ESQLiteException.Create(DBFile: widestring; Message: string);
begin
  FDBPath := DBFile;
  inherited Create(Message);
end;

{ ================================================================================================ }
{ TSQLiteQuery }

{ ------------------------------------------------------------------------------------------------ }
{$WARNINGS OFF}
function TSQLiteQuery.GetSQL: string;
begin
  if Assigned(Self.Statement) then begin
    Result := UTF8String(SQLite3_SQL(Self.Statement));
  end else begin
    Result := '';
  end;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------------------------ }
procedure TSQLiteQuery.Release;
begin
  if Assigned(Self.Statement) then begin
    Sqlite3_Finalize(Self.Statement);
    Self.Statement := nil;
  end;
end;

end.

