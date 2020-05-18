"""
BRO XML CPT database reader, indexer and parser.

Enables searching of very large XML CPT database dumps.
In order to speed up these operations, an index will
be created by searching for `featureMember`s (CPTs) in the xml
if it does not yet exist next to the XML file.

The index is stored next to the file and stores the xml
filesize to validate the xml database is the same. If not,
we assume the database is new and a new index will be created
as well. The index itself is an array with columns that store
the x y location of the CPT and the start/end bytes in the XML file.

As of January 2019, almost a 100.000 CPTs are stored in the XML
and creating the index will take 5-10min depending on disk performance.

"""
# import packages
import sys
import mmap
import math
import logging
from io import StringIO
import pickle
from os.path import exists, splitext, join, dirname
from os import stat, name, path
from zipfile import ZipFile

# External modules
from lxml import etree
import numpy as np
from scipy.spatial import cKDTree as KDTree
from tqdm import tqdm
import pandas as pd
import pyproj
from rtree import index
from shapely.geometry import shape, Point


# Constants for XML parsing
searchstring = b"<gml:featureMember>"
footer = b"</gml:FeatureCollection>"

columns = ["penetrationLength", "depth", "elapsedTime", "coneResistance", "correctedConeResistance", "netConeResistance", "magneticFieldStrengthX", "magneticFieldStrengthY", "magneticFieldStrengthZ", "magneticFieldStrengthTotal", "electricalConductivity",
           "inclinationEW", "inclinationNS", "inclinationX", "inclinationY", "inclinationResultant", "magneticInclination", "magneticDeclination", "localFriction", "poreRatio", "temperature", "porePressureU1", "porePressureU2", "porePressureU3", "frictionRatio"]
req_columns = ["penetrationLength", "coneResistance", "localFriction", "frictionRatio"]

ns = "{http://www.broservices.nl/xsd/cptcommon/1.1}"
ns2 = "{http://www.broservices.nl/xsd/dscpt/1.1}"
ns3 = "{http://www.opengis.net/gml/3.2}"
ns4 = "{http://www.broservices.nl/xsd/brocommon/3.0}"
ns5 = "{http://www.opengis.net/om/2.0}"

nodata = -999999
to_epsg = "28992"
to_srs = pyproj.Proj(init='epsg:{}'.format(to_epsg))


def xml_to_byte_string(fn):
    """
    Opens an xml-file and returns a byte-string
    :param fn: xml file name
    :return: byte-string of the xml file
    """
    ext = splitext(fn)[1]
    if ext == ".xml":
        with open(fn, "r") as f:
            # memory-map the file, size 0 means whole file
            xml_bytes = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)[:]
    return xml_bytes

def writexml(data, id="test", path="debug"):
    """Quick function to write xml in memory to disk.
    :param data: lxml etree root.
    :param id: Filename to use."""
    with open("{}/{}.xml".format(path, id), "wb") as f:
        s = etree.tostring(data, pretty_print=True)
        f.write(s)


def parse_bro_xml(xml):
    """Parse bro CPT xml.
    Searches for the cpt data, but also
    - location
    - offset z
    - id
    - predrilled_z
    TODO Replace iter by single search
    as iter can give multiple results

    :param xml: XML bytes
    :returns: dict -- parsed CPT data + metadata
    """
    root = etree.fromstring(xml)

    # Initialize data dictionary
    data = {"id": None, "location_x": None, "location_y": None,
            "offset_z": None, "predrilled_z": None, "a": 0.80,
            "vertical_datum": None, "local_reference": None,
            "quality_class": None, "cone_penetrometer_type": None,
            "cpt_standard": None, 'result_time': None}

    # Location
    x, y = parse_xml_location(xml)
    data["location_x"] = float(x)
    data["location_y"] = float(y)

    # BRO Id
    for loc in root.iter(ns4 + "broId"):
        data["id"] = loc.text

    # Norm of the cpt
    for loc in root.iter(ns2 + "cptStandard"):
        data["cpt_standard"] = loc.text

    # Offset to reference point
    for loc in root.iter(ns + "offset"):
        z = loc.text
        data["offset_z"] = float(z)

    # Local reference point
    for loc in root.iter(ns + "localVerticalReferencePoint"):
        data["local_reference"] = loc.text

    # Vertical datum
    for loc in root.iter(ns + "verticalDatum"):
        data["vertical_datum"] = loc.text

    # cpt class
    for loc in root.iter(ns + "qualityClass"):
        data["quality_class"] = loc.text

    # cpt type and serial number
    for loc in root.iter(ns + "conePenetrometerType"):
        data["cone_penetrometer_type"] = loc.text

    # cpt time of result
    for cpt in root.iter(ns + "conePenetrationTest"):
        for loc in cpt.iter(ns5 + "resultTime"):
            data["result_time"] = loc.text

    # Pre drilled depth
    for loc in root.iter(ns + "predrilledDepth"):
        z = loc.text
        # if predrill does not exist it is zero
        if not z:
            z = 0.
        data["predrilled_z"] = float(z)

    # Cone coefficient - a
    for loc in root.iter(ns + "coneSurfaceQuotient"):
        a = loc.text
        data["a"] = float(a)

    # Find which columns are not empty
    avail_columns = []
    for parameters in root.iter(ns + "parameters"):
        for parameter in parameters:
            if parameter.text == "ja":
                avail_columns.append(parameter.tag[len(ns):])

    # Determine if all data is available
    meta_usable = all([x is not None for x in data.values()])
    data_usable = all([col in avail_columns for col in req_columns])
    if not (meta_usable and data_usable):
        logging.warning("CPT with id {} misses required data.".format(data["id"]))
        return None

    # Parse data array, replace nodata, filter and sort
    for cpt in root.iter(ns + "conePenetrationTest"):
        for element in cpt.iter(ns + "values"):
            # Load string data and parse as 2d array
            sar = StringIO(element.text.replace(";", "\n"))
            ar = np.loadtxt(sar, delimiter=",", ndmin=2)

            # Check shape of array
            found_rows, found_columns = ar.shape
            if found_columns != len(columns):
                logging.warning("Data has the wrong size! {} columns instead of {}".format(found_columns, len(columns)))
                return None

            # Replace nodata constant with nan
            # Create a DataFrame from array
            # and sort by depth
            ar[ar == nodata] = np.nan
            df = pd.DataFrame(ar, columns=columns)
            df = df[avail_columns]
            df.sort_values(by=['penetrationLength'], inplace=True)

        data["dataframe"] = df

    return data


def parse_xml_location(tdata):
    """Return x y of location.
    TODO Don't user iter
    :param tdata: XML bytes
    :returns: list -- of x y string coordinates

    Will transform coordinates not in EPSG:28992
    """
    root = etree.fromstring(tdata)
    crs = None

    for loc in root.iter(ns2 + "deliveredLocation"):
        for point in loc.iter(ns3 + "Point"):
            srs = point.get("srsName")
            if srs is not None and "EPSG" in srs:
                crs = srs.split("::")[-1]
            break
        for pos in loc.iter(ns3 + "pos"):
            x, y = map(float, pos.text.split(" "))
            break

    if crs is not None and crs != to_epsg:
        logging.warning("Reprojecting from epsg::{}".format(crs))
        source_srs = pyproj.Proj('+init=epsg:{}'.format(crs))
        x, y = pyproj.transform(source_srs, to_srs, y, x)

    return x, y


def create_index(fn, ifn, datasize):
    """Create an index into the large BRO xml database.

    :param fn: Filename for bro xml file.
    :param ifn: Filename for index of fn.
    :param datasize: int -- Size of bro xml file.
    :returns: list -- of locations and indices into file.
    """

    logging.warning("Creating index, this may take a while...")

    # Iterate over file to search for Features
    locations = []
    cpt_count = 0

    ext = splitext(fn)[1]

    # Memory map OS specifc options
    if name == 'nt':
        mm_options = {}

    if ext == ".xml":
        # Setup progress
        pbar = tqdm(total=datasize, unit_scale=1)

        with open(fn, "r") as f:
            len_ss = len(searchstring)
            # memory-map the file, size 0 means whole file
            with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
                i = 0
                while i != -1:
                    previ = i
                    i = mm.find(searchstring, i + 1)
                    data = mm[previ:i]

                    if cpt_count == 0:
                        header = data
                        footer = b"</gml:FeatureCollection>"
                    else:
                        tdata = header + data + footer
                        if i != -1:
                            pbar.update((i - previ))

                            (x, y) = parse_xml_location(tdata)
                            locations.append((x, y, previ, i))
                    cpt_count += 1

    # Stream through zipfile
    elif ext == ".zip":
        buffersize = 2**24
        position = 0
        buffer = b""
        logging.warning("Indexing ZIP file, this is experimental.")
        with ZipFile(fn) as zf:
            # Setup progress
            filesize = zf.getinfo("brocpt.xml").file_size
            pbar = tqdm(total=filesize, unit_scale=1)
            with zf.open("brocpt.xml") as f:
                while f:

                    i = buffer.find(searchstring, 1)

                    # Nothing found
                    if i == -1:
                        chunk = f.read(buffersize)
                        if len(chunk) == 0:  # EOF
                            break
                        buffer += chunk
                    else:
                        data = buffer[:i]  # up to found index is one feature
                        buffer = buffer[i:]  # feature is removed from buffer
                        if cpt_count == 0:
                            header = data
                            footer = b"</gml:FeatureCollection>"
                        else:
                            tdata = header + data + footer
                            pbar.update(len(data))

                            (x, y) = parse_xml_location(tdata)
                            locations.append((x, y, position, position + len(data)))
                        cpt_count += 1
                        position += len(data)
    else:
        raise Exception("Wrong database format.")

    pbar.close()

    # Write size and locations to file
    with open(ifn, "wb") as f:
        pickle.dump((datasize, locations), f)

    # But return index for immediate use
    return locations


def query_index(index, x, y, radius=1000.):
    """Query database for CPTs
    within radius of x, y.

    :param index: Index is a array with columns: x y begin end
    :type index: np.array
    :param x: X coordinate
    :type x: float
    :param y: Y coordinate
    :type y: float
    :param radius: Radius (m) to use for searching. Defaults to 1000.
    :type radius: float
    :return: 2d array of start/end (columns) for each location (rows).
    :rtype: np.array
    """

    # Setup KDTree based on points
    npindex = np.array(index)
    tree = KDTree(npindex[:, 0:2])

    # Query point and return slices
    points = tree.query_ball_point((x, y), radius)

    # Return slices
    return npindex[points, 2:4].astype(np.int64)


def query_index_polygon(index, polygon_geometry):
    """Query database for CPTs
    within given polygon."""

    # Setup KDTree based on points
    npindex = np.array(index)
    tree = KDTree(npindex[:, 0:2])

    # Find center of polygon bounding box
    # and circle encompasing bbox and thus polygon
    polygon = shape(polygon_geometry)
    minx, miny, maxx, maxy = polygon.bounds
    xr, yr = (maxx - minx) / 2, (maxy - miny) / 2
    radius = math.sqrt(xr ** 2 + yr ** 2)
    x, y = minx + xr, miny + yr

    # Find all points in circle and do
    # intersect with actual polygon
    indices = []
    points_slice = tree.query_ball_point((x, y), radius)
    points = npindex[points_slice, :]
    for point in points:
        x, y, start, end = point
        p = Point(x, y)
        if p.intersects(polygon):
            indices.append((int(start), int(end)))

    return indices


def read_bro_xml(fn, indices):
    """Read XML file at specific indices and parse these.

    :param fn: Bro XML filename.
    :type fn: str
    :param indices: List of tuples containing start/end bytes.
    :type indices: list
    :return: List of parsed CPTs as dicts
    :rtype: list

    """
    if len(indices) == 0:
        return []

    cpts = []

    ext = splitext(fn)[1]
    if ext == ".xml":
        with open(fn, "r") as f:
            # memory-map the file, size 0 means whole file
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            i = mm.find(searchstring, 0)
            header = mm[0:i]
            for (start, end) in indices:
                data = mm[start:end]
                tdata = header + data + footer
                cpt = parse_bro_xml(tdata)
                cpts.append(cpt)
            mm.close()

    elif ext == ".zip":
        logging.warning("Using the experimental ZIP reader.")

        indices = sorted(indices, key=lambda x: x[0])
        largest_index = indices[-1][-1]
        unique_chunks = set()
        chunkindex = {}
        buffersize = 2**24

        for i, (start, end) in enumerate(indices):
            chunkstart, chunkend = start // buffersize, end // buffersize
            unique_chunks.add(chunkstart)
            unique_chunks.add(chunkend)
            # TODO check if chunks are always bigger than one feature
            chunkindex[(i, chunkstart, chunkend)] = (start - chunkstart * buffersize, end - chunkend * buffersize)

        chunk = 0
        chunks = {}
        with ZipFile(fn) as zf:
            filesize = zf.getinfo("brocpt.xml").file_size
            logging.warning("Requires decompressing {:.1f}% of ZIP file ({:.2f}Gb)".format(largest_index/filesize*100, largest_index/1e9))
            pbar = tqdm(total=largest_index, unit="b", unit_scale=1)
            with zf.open("brocpt.xml") as f:
                while f:
                    buffer = f.read(buffersize)
                    pbar.update(len(buffer))
                    if len(buffer) == 0:
                        break  # EOF

                    if chunk == 0:
                        i = buffer.find(searchstring)
                        header = buffer[0:i]

                    if chunk in unique_chunks:
                        chunks[chunk] = buffer
                        unique_chunks.remove(chunk)

                    if len(unique_chunks) == 0:
                        break

                    chunk += 1
            pbar.close()
        for (_, chunkstart, chunkend), (start, end) in chunkindex.items():
            if chunkstart == chunkend:
                data = chunks[chunkstart][start:end]
            else:
                data = chunks[chunkstart][start:] + chunks[chunkend][:end]
            tdata = header + data + footer
            cpt = parse_bro_xml(tdata)
            cpts.append(cpt)

    return cpts


def read_bro(parameters):
    """Main function to read the BRO database.

    :param parameters: Dict of input `parameters` containing filename, location and radius.
    :type parameters: dict
    :return: Dict with multiple groupings of parsed CPTs as dicts
    :rtype: dict

    """
    fn = parameters["BRO_data"]
    ifn = splitext(fn)[0] + ".idx"  # index
    x, y = parameters["Source_x"], parameters["Source_y"]
    r = parameters["Radius"]
    out = {}

    if not exists(fn):
        print("Cannot open provided BRO data file: {}".format(fn))
        sys.exit(2)

    # Check and use or create index
    # we use the size of the several GB xml file as a validity check
    # which we've saved in the index
    datasize = stat(fn).st_size
    if exists(ifn):
        with open(ifn, "rb") as f:
            (size, bro_index) = pickle.load(f)
        if size != datasize:
            logging.warning("BRO datafile differs from index, recreating index.")
            bro_index = create_index(fn, ifn, datasize)
    else:
        bro_index = create_index(fn, ifn, datasize)

    # Polygon grouping method:
    # Find all geomorphological polygons intersecting the circle with midpoint
    # x, y and radius r, calculate percentage of overlap and retrieve all CPTs
    # inside those polygons.
    out["polygons"] = {}
    total_cpts = 0
    file_idx = join(dirname(fn), 'geomorph')
    idx_fn = join(dirname(fn), 'geomorph.idx')
    if not exists(idx_fn):
        print("Cannot open provided geomorphological data files (.dat & .idx): {}".format(idx_fn))
        sys.exit(2)
    gm_index = index.Index(file_idx)  # created by auxiliary_code/gen_geomorph_idx.py

    geomorphs = list(gm_index.intersection((x-r, y-r, x+r, y+r), objects="raw"))
    circle = Point(x, y).buffer(r, resolution=32)
    for gm_code, polygon in geomorphs:
        indices = query_index_polygon(bro_index, polygon)
        poly = shape(polygon)
        if not poly.is_valid:
            poly = poly.buffer(0.01)  # buffering reconstructs the geometry, often fixing invalidity
        if circle.intersects(poly):
            total_cpts += len(indices)
            perc = circle.intersection(poly).area / circle.area
            cpts = read_bro_xml(fn, indices)
            if gm_code in out["polygons"]:
                out["polygons"][gm_code]["data"].extend(cpts)
            else:
                out["polygons"][gm_code] = {"data": cpts, "perc": perc}
    logging.warning("Found {} CPTs in intersecting polygons.".format(total_cpts))

    # Find CPT indexes in circle
    indices = query_index(bro_index, x, y, radius=r)
    logging.warning("Found {} CPTs in circle.".format(len(indices)))
    circle_cpts = read_bro_xml(fn, indices)
    out["circle"] = {"data": circle_cpts}

    return out


if __name__ == "__main__":
    input = {"BRO_data": "./bro/brocpt.xml", "Source_x": 65980, "Source_y": 395544, "Radius": 5500}
    cpts = read_bro(input)
    print(cpts.keys())
