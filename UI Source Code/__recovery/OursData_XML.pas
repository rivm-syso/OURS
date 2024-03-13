{ @abstract(This unit contains helper classes to read and write XML files.)
}
unit OursData_XML;

interface

uses
  Xml.VerySimple,
  OursMessage,
  OursData;

// -------------------------------------------------------------------------------------------------

type
  { @abstract(Helper class to read and write project fro and to XML.)
  }
  TOursProjectHelper = class helper for TOursProject
    { @abstract(Reads a project from a file and reports messages to a message list.)
    }
    function ReadFromXml(aFilename: string; aMessageList: TOursMessageList): Boolean;

    { @abstract(Returns a XML object containing the results of the project.)
      Results are per receptor, per source, per ground, per train and per period
    }
    function ResultsToXML: TXmlVerySimple;
  end;

// -------------------------------------------------------------------------------------------------

implementation

uses
  Types,
  Math,
  StrUtils,
  Classes,
  SysUtils,
  OursTypes,
  OursUtils,
  OursDatabase,
  OursResultMain,
  OursStrings;

// -------------------------------------------------------------------------------------------------

type
  TRPointsHelper = class helper for TRPoints
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;

  TOursTrainHelper = class helper for TOursTrain
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;
  TOursTrainsHelper = class helper for TOursTrains
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;

  TOursTrackPartHelper = class helper for TOursTrackPart
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;
  TOursTrackPartsHelper = class helper for TOursTrackParts
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;

  TOursTrackHelper = class helper for TOursTrack
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;
  TOursTracksHelper = class helper for TOursTracks
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;

  TOursReceptorBuildingHelper = class helper for TOursReceptorBuilding
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;
  TOursReceptorFloorHelper = class helper for TOursReceptorFloor
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;

  TOursReceptorHelper = class helper for TOursReceptor
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;
  TOursReceptorsHelper = class helper for TOursReceptors
    function ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
  end;

// =================================================================================================
// TOursXml
// =================================================================================================

type
  TOursXml = class(TObject)
    class function ReadStringFormNode(aNode: TXmlNode; aEntity: string; const default: string): string;
    class function ReadIntegerFormNode(aNode: TXmlNode; aEntity: string; const default: integer): integer;
    class function ReadDoubleFormNode(aNode: TXmlNode; aEntity: string; const default: Double): Double;
    class function ReadBooleanFormNode(aNode: TXmlNode; aEntity: string; const default: Boolean): Boolean;
  end;

// -------------------------------------------------------------------------------------------------

class function TOursXml.ReadBooleanFormNode(aNode: TXmlNode; aEntity: string;
  const default: Boolean): Boolean;
var
  str, def: string;
begin
  if default then
    def := 'Y'
  else
    def := 'N';

  str := UpperCase(TOursXml.ReadStringFormNode(aNode, aEntity, def));
  Result := (str = 'Y');
end;

// -------------------------------------------------------------------------------------------------

class function TOursXml.ReadDoubleFormNode(aNode: TXmlNode; aEntity: string;
  const default: Double): Double;
var
  str: string;
begin
  str := TOursXml.ReadStringFormNode(aNode, aEntity, default.ToString);
  Result := TOursConv.AsFloat(str, default);
end;

// -------------------------------------------------------------------------------------------------

class function TOursXml.ReadIntegerFormNode(aNode: TXmlNode; aEntity: string;
  const default: integer): integer;
var
  str: string;
begin
  str := TOursXml.ReadStringFormNode(aNode, aEntity, default.ToString);
  Result := TOursConv.AsInteger(str, default);
end;

// -------------------------------------------------------------------------------------------------

class function TOursXml.ReadStringFormNode(aNode: TXmlNode; aEntity: string;
  const default: string): string;
var
  EntityNode: TXmlNode;
begin
  Result := default;

  EntityNode := aNode.Find(aEntity);
  if assigned(EntityNode) then
    Result := Trim(EntityNode.Text);
end;

// =================================================================================================
// TOursReceptorHelper
// =================================================================================================

function TOursReceptorBuildingHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
begin
  try
    bagId := TOursXml.ReadStringFormNode(aNode, 'bagId', '');

    yearOfConstruction.FromString(TOursXml.ReadStringFormNode(aNode, 'yearOfConstruction', ''));
    apartment.FromString(TOursXml.ReadStringFormNode(aNode, 'apartment', ''));
    buildingHeight.FromString(TOursXml.ReadStringFormNode(aNode, 'buildingHeight', ''));
    numberOfFloors.FromString(TOursXml.ReadStringFormNode(aNode, 'numberOfFloors', ''));
    heightOfFloor.FromString(TOursXml.ReadStringFormNode(aNode, 'heightOfFloor', ''));
    floorNumber.FromString(TOursXml.ReadStringFormNode(aNode, 'floorNumber', ''));
    wallLength.FromString(TOursXml.ReadStringFormNode(aNode, 'wallLength', ''));
    facadeLength.FromString(TOursXml.ReadStringFormNode(aNode, 'facadeLength', ''));

    varYearOfConstruction.FromString(TOursXml.ReadStringFormNode(aNode, 'varYearOfConstruction', ''));
    varApartment.FromString(TOursXml.ReadStringFormNode(aNode, 'varApartment', ''));
    varBuildingHeight.FromString(TOursXml.ReadStringFormNode(aNode, 'varBuildingHeight', ''));
    varNumberOfFloors.FromString(TOursXml.ReadStringFormNode(aNode, 'varNumberOfFloors', ''));
    varHeightOfFloor.FromString(TOursXml.ReadStringFormNode(aNode, 'varHeightOfFloor', ''));
    varFloorNumber.FromString(TOursXml.ReadStringFormNode(aNode, 'varFloorNumber', ''));
    varWallLength.FromString(TOursXml.ReadStringFormNode(aNode, 'varWallLength', ''));
    varFacadeLength.FromString(TOursXml.ReadStringFormNode(aNode, 'varFacadeLength', ''));

    Result := True;
  except
    Result := False;
  end;
end;

//--------------------------------------------------------------------------------------------------

function TOursReceptorFloorHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
begin
  try
    frequenciesQuarterSpan.FromString(TOursXml.ReadStringFormNode(aNode, 'frequenciesQuarterSpan', ''));
    frequenciesMidSpan.FromString(TOursXml.ReadStringFormNode(aNode, 'frequenciesMidSpan', ''));
    floorSpan.FromString(TOursXml.ReadStringFormNode(aNode, 'floorSpan', ''));
    woodenFloor.FromString(TOursXml.ReadStringFormNode(aNode, 'woodenFloor', ''));

    varFrequenciesQuarterSpan.FromString(TOursXml.ReadStringFormNode(aNode, 'varFrequenciesQuarterSpan', ''));
    varFrequenciesMidSpan.FromString(TOursXml.ReadStringFormNode(aNode, 'varFrequenciesMidSpan', ''));
    varFloorSpan.FromString(TOursXml.ReadStringFormNode(aNode, 'varFloorSpan', ''));
    varWoodenFloor.FromString(TOursXml.ReadStringFormNode(aNode, 'varWoodenFloor', ''));

    Result := True;
  except
    Result := False;
  end;
end;

//--------------------------------------------------------------------------------------------------

function TOursReceptorHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  tmpStr: string;
  tmpValues: TStringDynArray;
begin
  Result := False;
  try
    name := TOursXml.ReadStringFormNode(aNode, 'name', name);
    description := TOursXml.ReadStringFormNode(aNode, 'description', description);

    tmpStr := TOursXml.ReadStringFormNode(aNode, 'location', '');
    tmpStr := ReplaceText(tmpStr, ',', FormatSettings.DecimalSeparator);
    tmpStr := ReplaceText(tmpStr, '.', FormatSettings.DecimalSeparator);
    tmpValues := SplitString(tmpStr, ' ');

    if Length(tmpValues) <> 2 then begin
      aMessageList.AddError(rsXmlCoordsReceptor);
      SetLength(tmpValues, 0);
      Exit;
    end;
    x := TOursConv.AsFloat(tmpValues[0]);
    y := TOursConv.AsFloat(tmpValues[1]);
    SetLength(tmpValues, 0);

    var _xmlBuilding := aNode.Find('Building');
    if assigned(_xmlBuilding) then
      Building.ReadFromXml(_xmlBuilding, aMessageList);

    var _xmlFloor := aNode.Find('Floor');
    if assigned(_xmlFloor) then
      Floor.ReadFromXml(_xmlFloor, aMessageList);

    Result := True;
  except

  end;
end;

// =================================================================================================
// TOursReceptorsHelper
// =================================================================================================

function TOursReceptorsHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  XmlReceptors, XmlReceptor: TXmlNodeList;
  Node: TXmlNode;
  newRec: TOursReceptor;
begin
  Result := False;

  XmlReceptors := aNode.FindNodes('Receptors');
  if assigned(XmlReceptors) then begin
    if (XmlReceptors.Count = 1) then begin
      XmlReceptor := XmlReceptors[0].FindNodes('Receptor');
      if assigned(XmlReceptor) then begin
        for Node in XmlReceptor do begin
          newRec := TOursReceptor.Create;
          Result := newRec.ReadFromXml(Node, aMessageList);
          Add(newRec);
          if not Result then
            Exit;
        end;
        XmlReceptor.Free;
      end;
      if Count = 0 then begin
        aMessageList.AddError('Loading XML: file does not contain receptor points');
        Result := False;
      end;
    end else begin
      aMessageList.AddError('Loading XML: file contains more than 1 receptor nodes');
    end;
    XmlReceptors.Free;
  end else begin
    aMessageList.AddError(rsXmlNoReceptors);
  end;
end;

// =================================================================================================
// TOursProjectHelper
// =================================================================================================

function TOursProjectHelper.ReadFromXml(aFilename: string; aMessageList: TOursMessageList): Boolean;
var
  Xml: TXmlVerySimple;
  Books: TXmlNodeList;
begin
  // Assume file <aFilename> does exist and is a correct Xml file.
  Result := False;
  if not FileExists(aFilename) then begin
    aMessageList.AddError(Format(rsXmlFileNotFound, [aFilename]));
    Exit;
  end;

  // Create a new XML document and load content from aFilename
  Xml := TXmlVerySimple.Create;
  try
    Include(Xml.Options, doCaseInsensitive);
    Xml.LoadFromFile(aFilename);

    Books := Xml.DocumentElement.FindNodes('Project');
    if assigned(Books) then begin
      if (Books.Count = 1) then begin
        name := TOursXml.ReadStringFormNode(Books[0], 'name', name);
        description := TOursXml.ReadStringFormNode(Books[0], 'description', description);
        vd := TOursXml.ReadIntegerFormNode(Books[0], 'vd', -1);
        if vd<0 then vd := -1;
        if vd>0 then vd := +1;

        Result := Receptors.ReadFromXml(Books[0], aMessageList) and Tracks.ReadFromXml(Books[0], aMessageList);
      end else begin
        aMessageList.AddError(rsXmlMultipleProjectNodes);
      end;
      Books.Free;
    end else begin
      aMessageList.AddError(rsXmlNoProjectNodes);
    end;
  finally
    Xml.Free;
  end;
end;

// -------------------------------------------------------------------------------------------------

function TOursProjectHelper.ResultsToXML: TXmlVerySimple;
begin
  Result := TXmlVerySimple.Create;
  Result.Encoding := 'utf-8';
  Result.AddChild('OURS_Output').SetAttribute('version', 'V2.1');

  var Node := Result.DocumentElement.AddChild('Project', ntElement);
  Node.Attributes['name'] := name;
  Node.Attributes['description'] := description;

  Node := Node.AddChild('Receptors', ntElement);
  for var receptor in Receptors do begin
    var recNode := Node.AddChild('receptor', ntElement);
    with recNode.AddChild('name') do
      SetText(receptor.name);
    with recNode.AddChild('description') do
      SetText(receptor.description);

    for var source in receptor.Sources do begin
      var srcNode := recNode.AddChild('source', ntElement);
      with srcNode.AddChild('name') do
        SetText(source.Track.name);
      with srcNode.AddChild('description') do
        SetText(source.Track.description);
      with srcNode.AddChild('distance', ntElement) do
        SetText(TOursMath.dist(receptor.pos, source.pos).ToString);

      var resNode: TXmlNode;
      var _result := source.Results.MainResults;
      for var i := 0 to 2 do begin
        case i of
          0: resNode := srcNode.AddChild('alleTreinen', ntElement);
          1: resNode := srcNode.AddChild('goederen', ntElement);
          2: resNode := srcNode.AddChild('reizigers', ntElement);
        else Continue;
        end;

        var trainClass: TTrainClass := nil;
        case i of
          0: trainClass := _result.AlleTreinen;
          1: trainClass := _result.Goederen;
          2: trainClass := _result.Reizigers;
        end;

        var tmpNode: TXmlNode;

        tmpNode := resNode.AddChild('fundering', ntElement);
        with tmpNode.AddChild('vmax', ntElement) do
          SetText(trainClass.Fundering.Vmax.ToString);
        with tmpNode.AddChild('vmax_Dir', ntElement) do
          SetText(trainClass.Fundering.Vmax_Dir);
        with tmpNode.AddChild('vmax_Fdom', ntElement) do
          SetText(trainClass.Fundering.Vmax_Fdom);
        with tmpNode.AddChild('vmax_sigma', ntElement) do
          SetText(trainClass.Fundering.Vmax_sigma.ToString);
        with tmpNode.AddChild('vtop', ntElement) do
          SetText(trainClass.Fundering.Vtop.ToString);
        with tmpNode.AddChild('vtop_Dir', ntElement) do
          SetText(trainClass.Fundering.Vtop_Dir);
        with tmpNode.AddChild('vtop_Fdom', ntElement) do
          SetText(trainClass.Fundering.Vtop_Fdom);
        with tmpNode.AddChild('vtop_Vd', ntElement) do
          SetText(trainClass.Fundering.Vtop_Vd.ToString);
        with tmpNode.AddChild('vtop_sigma', ntElement) do
          SetText(trainClass.Fundering.Vtop_sigma.ToString);

        var str := '';
        for var j := 0 to Length(trainClass.Fundering.variatiecoeffs)-1 do begin
          if str<>'' then
            str := str + '; ';
          str := str + trainClass.Fundering.variatiecoeffs[j].ToString;
        end;
        with tmpNode.AddChild('variatiecoeffs', ntElement) do
          SetText(str);

        tmpNode := resNode.AddChild('gebouw', ntElement);
        with tmpNode.AddChild('vmax', ntElement) do
          SetText(trainClass.Gebouw.Vmax.ToString);
        with tmpNode.AddChild('vmax_Dir', ntElement) do
          SetText(trainClass.Gebouw.Vmax_Dir);
        with tmpNode.AddChild('vmax_Fdom', ntElement) do
          SetText(trainClass.Gebouw.Vmax_Fdom);
        with tmpNode.AddChild('vmax_sigma', ntElement) do
          SetText(trainClass.Gebouw.Vmax_sigma.ToString);

        str := '';
        for var j := 0 to Length(trainClass.Gebouw.Vper)-1 do begin
          if str<>'' then
            str := str + '; ';
          str := str + trainClass.Gebouw.Vper[j].ToString;
        end;
        with tmpNode.AddChild('vper', ntElement) do
          SetText(str);

        str := '';
        for var j := 0 to Length(trainClass.Gebouw.Vper_sigma)-1 do begin
          if str<>'' then
            str := str + '; ';
          str := str + trainClass.Gebouw.Vper_sigma[j].ToString;
        end;
        with tmpNode.AddChild('vper_sigma', ntElement) do
          SetText(str);

        str := '';
        for var j := 0 to Length(trainClass.Gebouw.variatiecoeffs)-1 do begin
          if str<>'' then
            str := str + '; ';
          str := str + trainClass.Gebouw.variatiecoeffs[j].ToString;
        end;
        with tmpNode.AddChild('variatiecoeffs', ntElement) do
          SetText(str);

        tmpNode := resNode.AddChild('maaiveld', ntElement);
        with tmpNode.AddChild('vrms', ntElement) do
          SetText(trainClass.Maaiveld.Vrms.ToString);
        with tmpNode.AddChild('vrms_sigmax', ntElement) do
          SetText(trainClass.Maaiveld.Vrms_sigma.ToString);

        str := '';
        for var j := 0 to Length(trainClass.Maaiveld.variatiecoeffs)-1 do begin
          if str<>'' then
            str := str + '; ';
          str := str + trainClass.Fundering.variatiecoeffs[j].ToString;
        end;
        with tmpNode.AddChild('variatiecoeffs', ntElement) do
          SetText(str);
      end;
    end;
  end;
end;

// =================================================================================================
// TRPointsHelper
// =================================================================================================

function TRPointsHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  coordStr: string;
  coords: TStringDynArray;
  pnt: TRPoint;
begin
  Result := False;

  try
    coordStr := TOursXml.ReadStringFormNode(aNode, 'location', '');
    coordStr := ReplaceText(coordStr, ',', FormatSettings.DecimalSeparator);
    coordStr := ReplaceText(coordStr, '.', FormatSettings.DecimalSeparator);
    coords := SplitString(coordStr, ' ');

    if Length(coords) < 2 then begin
      aMessageList.AddError(rsXmlTrackCoordsCount);
      Exit;
    end;
    if Odd(Length(coords)) then begin
      aMessageList.AddError(rsXmlTrackCoordsXY);
      Exit;
    end;
    for var i := 0 to Length(coords) - 1 do begin
      if Odd(i) then begin
        pnt.y := TOursConv.AsFloat(coords[i]);
        Add(pnt);
      end else begin
        pnt.x := TOursConv.AsFloat(coords[i]);
      end;
    end;
    Result := True;
  finally
    SetLength(coords, 0);
  end;
end;

// =================================================================================================
// TOursTrainHelper
// =================================================================================================

function TOursTrainHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
begin
  try
    material_id := TOursXml.ReadIntegerFormNode(aNode, 'material_id', material_id);
    qd := TOursXml.ReadDoubleFormNode(aNode, 'qd', qd);
    vd := TOursXml.ReadDoubleFormNode(aNode, 'vd', vd);
    qe := TOursXml.ReadDoubleFormNode(aNode, 'qe', qe);
    ve := TOursXml.ReadDoubleFormNode(aNode, 've', ve);
    qn := TOursXml.ReadDoubleFormNode(aNode, 'qn', qn);
    vn := TOursXml.ReadDoubleFormNode(aNode, 'vn', vn);

    Result := True;
  except
    Result := False;
  end;

end;

// =================================================================================================
// TOursTrainsHelper
// =================================================================================================

function TOursTrainsHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  XmlTrain: TXmlNodeList;
  Node: TXmlNode;
  newTrain: TOursTrain;
begin
  Result := False;

  XmlTrain := aNode.FindNodes('Train');
  if assigned(XmlTrain) then begin
    for Node in XmlTrain do begin
      newTrain := TOursTrain.Create;
      Result := newTrain.ReadFromXml(Node, aMessageList);
      Add(newTrain);
      if not Result then
        Exit;
    end;
    XmlTrain.Free;
  end;
  if Count = 0 then begin
    aMessageList.AddError(rsXmlTrainNoTrainNode);
    Result := False;
  end;
end;

// =================================================================================================
// TOursTrackPartHelper
// =================================================================================================

function TOursTrackPartHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  cGeoStr: string;
begin
  Result := False;

  try
    name := TOursXml.ReadStringFormNode(aNode, 'name', name);
    description := TOursXml.ReadStringFormNode(aNode, 'description', description);
    kmstart := TOursXml.ReadIntegerFormNode(aNode, 'kmstart', kmstart);
    kmend := TOursXml.ReadIntegerFormNode(aNode, 'kmend', kmend);

    CgeoX.FillValue(1.0);
    cGeoStr := TOursXml.ReadStringFormNode(aNode, 'cGeoX', '');
    if cGeoStr <> '' then begin
      cGeoStr := ReplaceText(cGeoStr, ',', FormatSettings.DecimalSeparator);
      cGeoStr := ReplaceText(cGeoStr, '.', FormatSettings.DecimalSeparator);
      var cGeos := SplitString(cGeoStr, ' ');
      if Length(cGeos) = 6 then begin
        for var i := 0 to 5 do
          CgeoX.Value[i] := TOursConv.AsFloat(cGeos[i], -1.0);
      end else begin
        aMessageList.AddWarning('Incorrect number of values for CgeoX. Revert to default');
      end;
      SetLength(cGeos, 0);
    end;

    CgeoZ.FillValue(1.0);
    cGeoStr := TOursXml.ReadStringFormNode(aNode, 'cGeoZ', '');
    if cGeoStr <> '' then begin
      cGeoStr := ReplaceText(cGeoStr, ',', FormatSettings.DecimalSeparator);
      cGeoStr := ReplaceText(cGeoStr, '.', FormatSettings.DecimalSeparator);
      var cGeos := SplitString(cGeoStr, ' ');
      if Length(cGeos) = 6 then begin
        for var i := 0 to 5 do
          CgeoZ.Value[i] := TOursConv.AsFloat(cGeos[i], -1.0);
      end else begin
        aMessageList.AddWarning('Incorrect number of values for CgeoZ. Revert to default');
      end;
      SetLength(cGeos, 0);
    end;

    if kmend < kmstart then begin
      aMessageList.AddError(rsXmlTrackKmError);
      Exit;
    end;

    Result := Trains.ReadFromXml(aNode, aMessageList);
  except

  end;
end;

// =================================================================================================
// TOursTrackPartsHelper
// =================================================================================================

function TOursTrackPartsHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  XmlBaanvak: TXmlNodeList;
  Node: TXmlNode;
  newBaanvak: TOursTrackPart;
begin
  Result := False;

  XmlBaanvak := aNode.FindNodes('Trackpart');
  if assigned(XmlBaanvak) then begin
    for Node in XmlBaanvak do begin
      newBaanvak := TOursTrackPart.Create;
      Result := newBaanvak.ReadFromXml(Node, aMessageList);
      Add(newBaanvak);
      if not Result then
        Exit;
    end;
    XmlBaanvak.Free;
  end;
  if Count = 0 then begin
    aMessageList.AddError(rsXmlTrackCount);
    Result := False;
  end;
end;

// =================================================================================================
// TOursTrackHelper
// =================================================================================================

function TOursTrackHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  baanvak: TOursTrackPart;
  tot: integer;
  s: string;
begin
  Result := False;
  try
    name := TOursXml.ReadStringFormNode(aNode, 'name', name);
    description := TOursXml.ReadStringFormNode(aNode, 'description', description);
    branch := TOursXml.ReadStringFormNode(aNode, 'branch', branch);
    kmstart := TOursXml.ReadIntegerFormNode(aNode, 'kmstart', kmstart);
    kmend := TOursXml.ReadIntegerFormNode(aNode, 'kmend', kmend);

    if kmend < kmstart then begin
      aMessageList.AddError(rsXmlTrackKmError);
      Exit;
    end;

    s := TOursXml.ReadStringFormNode(aNode, 'sourcetype', '');
    sourcetype_id := TOursDatabase.GetIdFromName('sourcetype', LowerCase(s));

    if not(Location.ReadFromXml(aNode, aMessageList) and TrackParts.ReadFromXml(aNode, aMessageList)) then
      Exit;

    tot := 0;
    for baanvak in TrackParts do begin
      tot := tot + (baanvak.kmend - baanvak.kmstart);
      if (baanvak.kmstart < kmstart) or (baanvak.kmend > kmend) then begin
        aMessageList.AddError(Format(rsXmlTrackKmMatchError1, [name]));
        Exit;
      end;
    end;
    if tot > kmend - kmstart then begin
      aMessageList.AddError(Format(rsXmlTrackKmMatchError2, [name]));
      Exit;
    end;

    if tot < kmend - kmstart then begin
      aMessageList.AddWarning(Format(rsXmlTrackKmMatchWarning1, [name]));
    end;

    for var i := 0 to TrackParts.Count - 2 do begin
      for var j := i + 1 to TrackParts.Count - 1 do begin
        if InRange(TrackParts[j].kmstart, TrackParts[i].kmstart + 1, TrackParts[i].kmend - 1) or
           InRange(TrackParts[j].kmend, TrackParts[i].kmstart + 1, TrackParts[i].kmend - 1) then begin
          aMessageList.AddError(Format(rsXmlTrackKmOverlapping, [name]));
          Exit;
        end;
      end;
    end;

    Result := True;
  except
  end;
end;

// =================================================================================================
// TOursTracksHelper
// =================================================================================================

function TOursTracksHelper.ReadFromXml(aNode: TXmlNode; aMessageList: TOursMessageList): Boolean;
var
  XmlSporen, XmlSpoor: TXmlNodeList;
  Node: TXmlNode;
  newSpoor: TOursTrack;
begin
  Result := False;

  XmlSporen := aNode.FindNodes('Tracks');
  if assigned(XmlSporen) then begin
    if (XmlSporen.Count = 1) then begin
      XmlSpoor := XmlSporen[0].FindNodes('Track');
      if assigned(XmlSpoor) then begin
        for Node in XmlSpoor do begin
          newSpoor := TOursTrack.Create;
          Result := newSpoor.ReadFromXml(Node, aMessageList);
          Add(newSpoor);
          if not Result then
            Exit;
        end;
        XmlSpoor.Free;
      end;
      if Count = 0 then begin
        aMessageList.AddError(rsXmlTracksMissing);
        Result := False;
      end;
    end else begin
      aMessageList.AddError(rsXmlMultipleTrackNodes);
    end;
    XmlSporen.Free;
  end else begin
    aMessageList.AddError(rsXmlTracksMissing);
  end;
end;

// =================================================================================================

end.
