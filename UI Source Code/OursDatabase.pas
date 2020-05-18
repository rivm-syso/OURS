{ @abstract(This unit provides access to the OURS database.)
}
unit OursDatabase;

interface

uses
  Classes,
  SQLiteTable3;

type
  { @abstract(TOursDatabase is a class object with routines to access the default database.)
    Trying to create an instance of this class will raise an exception.@br@br
    The database format is SQLite, located in the program folder and it is named "OURS.sqlite".
    The database is only used for reading general settings and data. No data is written to the
    database.
  }
  TOursDatabase = class(TObject)
  strict private
    { @abstract(Pointer to the SQLite database.)
    }
    class var _DB: TSQLiteDatabase;
  strict private
  const
    { @abstract(Name of the SQLite database.)
    }
    _DBNAME = 'OURS.sqlite';
  strict private
    { @abstract(Constructor private. No creation outside the class.)
      Only use class functions.
    }
    constructor Create;

    { @abstract(Returns full path and name of the SQLite database.)
      The database needs to be present in the program folder.
    }
    class function DBname: string;

    { @abstract(Returns the pointer to the SQLite database.)
      If needed the database will be openend.
    }
    class function DB: TSQLiteDatabase;
  public
    { @abstract(Gives a list of all tables in the database.)
      aList needs to be created. Nil is not allowed.
    }
    class procedure DBTableNames(aList: TStrings);

    { @abstract(Creates a table containing all data for the given table.)
    }
    class function GetFullTableContents(const tableName: string): TSQLiteTable;

    { @abstract(Returns if the database exists.)
    }
    class function DBExists: Boolean;

    { @abstract(Returns integer value from a given table, field and id-value.)
      The executed SQL-script is: @italic(SELECT <fieldname> FROM <tabelname> WHERE id = <id>;)
    }
    class function GetValueAsInteger(tableName, fieldname: string; id: integer): integer;

    { @abstract(Returns name and description from a given table and id-value.)
      The executed SQL-script is: @italic(SELECT name, description FROM <tabelname> WHERE id = <id>;)  @br
      The results is:  "@italic(<name> - <description>)"
    }
    class function GetDescriptionFromId(tableName: string; id: integer): string;

    { @abstract(Returns the id value for the name field of a given table.)
      The executed SQL-script is: @italic(SELECT id FROM <tabelname> WHERE name = "<name>";) @br
      If name is empty or not found, the result is -1.
    }
    class function GetIdFromName(tableName: string; name: string): integer;

    { @abstract(Executes the given SQL and returns the result as SQLiteTable.)
      For instance: @br
      @italic(SELECT * FROM measurement WHERE category_id=2 AND sourcetype_id=1))
    }
    class function GetTableFromSQL(aSQL: string): TSQLiteTable;

    { @abstract(Returns the maximum calculation depth from the parameters table.)
      The executed SQL-script is: @italic(SELECT max_calc_depth FROM parameters;) @br
      The default result is 30m.
    }
    class function GetMaxCalcDepth: Double;

    { @abstract(Returns the maximum calculation distance from the parameters table.)
      The executed SQL-script is: @italic(SELECT max_calc_dist FROM parameters;) @br
      The default result is 25m.
    }
    class function GetMaxCalcDistance: Double;

    { @abstract(Returns the minimum ground layer thickness from the parameters table.)
      The executed SQL-script is: @italic(SELECT min_ground_thickness FROM parameters;) @br
      The default result is 0.5m.
    }
    class function GetMinLayerThickness: Double;

    { @abstract(Returns the minimum element size in metre for the FEM calculation.)
      The executed SQL-script is: @italic(SELECT min_element_size FROM parameters;) @br
      The default result is 0.05m.
    }
    class function GetMinElementSize: Double;


    { @abstract(Returns the spectrum type from the parameters table.)
      The executed SQL-script is: @italic(SELECT spectrumtype FROM parameters;) @br
      The default result is 1 (=1/1-octave). Result 2 means 1/3-octave.
    }
    class function GetSpectrumType: integer;

    { @abstract(Returns the lowest frequency from the parameters table.)
      The executed SQL-script is: @italic(SELECT lowfreq FROM parameters;) @br
      The default result is 1 Hz.
    }
    class function GetLowFreq: Double;

    { @abstract(Returns the highest frequency from the parameters table.)
      The executed SQL-script is: @italic(SELECT highfreq FROM parameters;) @br
      The default result is 63 Hz.
    }
    class function GetHighFreq: Double;

    { @abstract(Returns the selected FEM calculation method from the parameters table.)
      The executed SQL-script is: @italic(SELECT calctype FROM parameters;) @br
      The default result is 2. Possible values are:@br
      1 = Central differences  @br
      2 = Harmonic response    @br
      3 = FEM-module decides if 1 or 2 is used.
    }
    class function GetCalcType: integer;
  end;

implementation

uses
  DIALOGS,
  Forms,
  SysUtils,
  OursUtils;

// =================================================================================================
// TOursDatabase
// =================================================================================================

constructor TOursDatabase.Create;
begin

end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.DB: TSQLiteDatabase;
begin
  if _DB = nil then begin
    try
      _DB := TSQLiteDatabase.Create(TOursDatabase.DBname);
      _DB.ExecSQL('PRAGMA foreign_keys = ON');
    except
      _DB := nil;
    end;
  end;
  Result := _DB;
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.DBExists: Boolean;
begin
  Result := FileExists(DBname) and (DB <> nil);
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.DBname: string;
begin
  Result := TOursFileUtils.ProgDir + _DBNAME;
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetFullTableContents(const tableName: string): TSQLiteTable;
begin
  Result := DB.GetTable(Format('SELECT * FROM %s;', [tableName]));
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetValueAsInteger(tableName, fieldname: string; id: integer): integer;
var
  aTable: TSQLiteTable;
begin
  Result := 0;

  aTable := DB.GetTable(Format('SELECT %s FROM %s WHERE id = %d;', [fieldname, tableName, id]));
  if assigned(aTable) then begin
    if aTable.Count > 0 then
      Result := aTable.FieldAsInteger(0);
    aTable.Free;
  end;
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetTableFromSQL(aSQL: string): TSQLiteTable;
begin
  Result := DB.GetTable(aSQL);
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetIdFromName(tableName: string; name: string): integer;
var
  aTable: TSQLiteTable;
begin
  Result := -1;
  if name = '' then
    Exit;

  aTable := DB.GetTable(Format('SELECT id FROM %s WHERE name = "%s";', [tableName, name]));
  if assigned(aTable) then begin
    if aTable.Count > 0 then
      Result := aTable.FieldAsInteger(0, Result);
    aTable.Free;
  end;
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetDescriptionFromId(tableName: string; id: integer): string;
var
  aTable: TSQLiteTable;
begin
  Result := '--';

  aTable := DB.GetTable(Format('SELECT name, description FROM %s WHERE id = %d;', [tableName, id]));
  if assigned(aTable) then begin
    if aTable.Count > 0 then
      Result := aTable.FieldAsString(0, Result) + ' - ' + aTable.FieldAsString(1, Result);
    aTable.Free;
  end;
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetMaxCalcDepth: Double;
begin
  Result := TOursConv.AsFloat(DB.GetTableString('SELECT max_calc_depth FROM parameters;'), 30.0)
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetMaxCalcDistance: Double;
begin
  Result := TOursConv.AsFloat(DB.GetTableString('SELECT max_calc_dist FROM parameters;'), 25.0)
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetMinLayerThickness: Double;
begin
  Result := TOursConv.AsFloat(DB.GetTableString('SELECT min_ground_thickness FROM parameters;'), 0.5)
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetMinElementSize: Double;
begin
  Result := TOursConv.AsFloat(DB.GetTableString('SELECT min_element_size FROM parameters;'), 0.5)
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetSpectrumType: integer; // 1 = 1/1-octave, 2 = 1/3-octave
begin
  Result := TOursConv.AsInteger(DB.GetTableString('SELECT spectrumtype FROM parameters;'), 1)
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetLowFreq: Double;
begin
  Result := TOursConv.AsFloat(DB.GetTableString('SELECT lowfreq FROM parameters;'), 1)
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetHighFreq: Double;
begin
  Result := TOursConv.AsFloat(DB.GetTableString('SELECT highfreq FROM parameters;'), 63)
end;

// -------------------------------------------------------------------------------------------------

class function TOursDatabase.GetCalcType: integer;
begin
  Result := TOursConv.AsInteger(DB.GetTableString('SELECT calctype FROM parameters;'), 2)
end;

// -------------------------------------------------------------------------------------------------

class procedure TOursDatabase.DBTableNames(aList: TStrings);
var
  aTable: TSQLiteTable;
begin
  if aList = nil then
    raise Exception.Create('TOursDatabase.DBTableNames called with nil list');

  aList.Clear;
  aTable := DB.GetTable('SELECT name FROM sqlite_master WHERE type=''table'' ORDER BY name;');
  if assigned(aTable) then begin
    while not aTable.EOF do begin
      aList.Add(aTable.FieldAsString(0));
      aTable.Next;
    end;
    aTable.Free;
  end;
end;

// =================================================================================================
initialization
  TOursDatabase.Create;
end.
