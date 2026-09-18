"""
BRO geopackage CPT database reader, indexer and parser.

Enables searching of very large geopackage CPT database.
In order to speed up these operations, an index will
be created in the geopackage to connect the different tables in the geopackage
if it does not yet exist in the geopackage file.
"""
# import packages
import sys
import logging
from os.path import exists, join, dirname
import sqlite3
import geopandas as gpd
from shapely.ops import transform
import pandas as pd
import pyproj
from rtree import index
from shapely.geometry import shape, Point

req_columns = ["penetrationLength", "coneResistance", "localFriction", "frictionRatio"]
columns_gpkg = ['penetrationLength', 'depth', 'elapsed_time', 'coneResistance',
                'corrected_cone_resistance',
                'net_cone_resistance', 'magnetic_field_strength_x', 'magnetic_field_strength_y',
                'magnetic_field_strength_z',
                'magnetic_field_strength_total', 'electrical_conductivity', 'inclination_ew',
                'inclination_ns',
                'inclination_x', 'inclination_y', 'inclinationResultant',
                'magnetic_inclination',
                'magnetic_declination', 'localFriction',
                'pore_ratio', 'temperature', "porePressureU1", "porePressureU2", "porePressureU3",
                'frictionRatio', 'id', 'location_x', 'location_y', 'offset_z',
                'vertical_datum', 'local_reference', 'quality_class',
                'cpt_standard', 'research_report_date', 'predrilled_z']
float_columns = ['penetrationLength', 'depth', 'elapsed_time', 'coneResistance',
                'corrected_cone_resistance',
                'net_cone_resistance', 'magnetic_field_strength_x', 'magnetic_field_strength_y',
                'magnetic_field_strength_z',
                'magnetic_field_strength_total', 'electrical_conductivity', 'inclination_ew',
                'inclination_ns',
                'inclination_x', 'inclination_y', 'inclinationResultant',
                'magnetic_inclination',
                'magnetic_declination', 'localFriction',
                'pore_ratio', 'temperature', "porePressureU1", "porePressureU2", "porePressureU3",
                'frictionRatio', 'predrilled_z', 'offset_z']

def query_equals_according_to_length(keys):
    """
    Function that returns equals search query for geodatabase
    :param keys:
    :return:
    """
    if len(keys) == 1:
        if isinstance(keys[0], str):
            return f" = '{keys[0]}' "
        else:
            return f" = {keys[0]} "
    else:
        return " IN " + f"{tuple(keys)}"


def construct_query(cpt_keys):
    """
    Function that creates query to retrieve all data from cone_penetration_test_result,
    cpt_cone_penetrometer_survey and cpt_geotechnical_survey tables
    :param cpt_keys: List of ids of the cpts
    :return: str
    """

    selected_columns = "SELECT distinct cone_penetration_test_result.penetration_length,\
                               cone_penetration_test_result.depth,\
                               cone_penetration_test_result.elapsed_time,\
                               cone_penetration_test_result.cone_resistance,\
                               cone_penetration_test_result.corrected_cone_resistance,\
                               cone_penetration_test_result.net_cone_resistance,\
                               cone_penetration_test_result.magnetic_field_strength_x,\
                               cone_penetration_test_result.magnetic_field_strength_y,\
                               cone_penetration_test_result.magnetic_field_strength_z,\
                               cone_penetration_test_result.magnetic_field_strength_total,\
                               cone_penetration_test_result.electrical_conductivity,\
                               cone_penetration_test_result.inclination_ew,\
                               cone_penetration_test_result.inclination_ns,\
                               cone_penetration_test_result.inclination_x,\
                               cone_penetration_test_result.inclination_y,\
                               cone_penetration_test_result.inclination_resultant,\
                               cone_penetration_test_result.magnetic_inclination,\
                               cone_penetration_test_result.magnetic_declination,\
                               cone_penetration_test_result.local_friction,\
                               cone_penetration_test_result.pore_ratio,\
                               cone_penetration_test_result.temperature,\
                               cone_penetration_test_result.pore_pressure_u1,\
                               cone_penetration_test_result.pore_pressure_u2,\
                               cone_penetration_test_result.pore_pressure_u3,\
                               cone_penetration_test_result.friction_ratio,\
                               geotechnical_cpt_survey.bro_id,\
                               bro_point.x_or_lon,\
                               bro_point.y_or_lat,\
                               delivered_vertical_position.offset,\
                               delivered_vertical_position.vertical_datum,\
                               delivered_vertical_position.local_vertical_reference_point,\
                               geotechnical_cpt_survey.quality_regime,\
                               geotechnical_cpt_survey.cpt_standard,\
                               geotechnical_cpt_survey.research_report_date,\
                               trajectory.predrilled_depth \
               FROM geotechnical_cpt_survey \
                   join cone_penetration_test_result on cone_penetration_test_result.cone_penetration_test_fk = geotechnical_cpt_survey.geotechnical_cpt_survey_pk \
                   join delivered_vertical_position on delivered_vertical_position.geotechnical_cpt_survey_fk = geotechnical_cpt_survey.geotechnical_cpt_survey_pk \
                   join bro_point on bro_point.bro_location_fk = geotechnical_cpt_survey.geotechnical_cpt_survey_pk \
                   join trajectory on trajectory.cone_penetrometer_survey_fk = geotechnical_cpt_survey.geotechnical_cpt_survey_pk "
    where_clause = "WHERE geotechnical_cpt_survey.geotechnical_cpt_survey_pk "
    if len(cpt_keys) >= 8:
        in_clause = query_equals_according_to_length(cpt_keys)
        return selected_columns + where_clause + in_clause
    else:
        return [selected_columns + where_clause + f" = {int(i)} " for i in cpt_keys]

def is_cpt_inside_buffered_track(file_track, point):
    """
    Check if a CPT in inside the buffered track geometry

    :param file_track: rtree index file location
    :param point: list of x and y coordinates
    :return: boolean if cpt is inside buffered track
    """
    idx = index.Index(file_track, interleaved=True)

    point = Point(point[0], point[1])
    possible_matches = list(idx.intersection(point.bounds))
    if len(possible_matches) == 0:
        return False
    else:
        return True


def construct_query_cone_surface_quotient(cpt_keys):
    """
    Function that returns query for retrieving the cone_surface_quotient
    from the cone_penetrometer table.

    :param cpt_keys: List of ids of the cpts (geotechnical_cpt_survey_pk)
    :return: str
    """
    base_query = """
        SELECT
            gcs.bro_id AS id,
            cp.cone_surface_quotient AS a
        FROM geotechnical_cpt_survey AS gcs
        JOIN cone_penetrometer_survey AS cps
          ON cps.geotechnical_cpt_survey_fk = gcs.geotechnical_cpt_survey_pk
        JOIN cone_penetrometer AS cp
          ON cp.cone_penetrometer_survey_fk = cps.cone_penetrometer_survey_pk
        WHERE gcs.geotechnical_cpt_survey_pk
    """
    return base_query + query_equals_according_to_length(cpt_keys)

def determine_if_all_data_is_available(data):
    """
    Determine if all data is available in dataframe
    :param data: pandas dataframe
    :return: boolean if all data is available
    """
    avail_columns = data.get("dataframe").columns
    data_excluding_dataframe = {x: data[x] for x in data if x not in {"dataframe", "a"}}
    meta_usable = all([x is not None for x in data_excluding_dataframe.values()])
    data_column_usable = all([col in avail_columns for col in req_columns])
    data_usable = all([not data["dataframe"][k].isnull().values.all() for k in req_columns])
    if not (meta_usable and data_usable and data_column_usable):
        logging.warning("CPT with id {} misses required data.".format(data["id"]))
        return False
    return True

def read_cpt_from_gpkg(polygon, ctx, file_track):
    """
    Function that retrieves cpts that intercept a polygon

    :param polygon: shapely polygon
    :param ctx: BROContext with open SQLite connection and filename
    :param file_track: rtree index file location
    :return: list of dictionaries containing all cpt data
    """

    fn = ctx.fn
    conn = ctx.conn
    cursor = conn.cursor()

    cpts_results = []
    # transform the polygon from epsg:28992 to epsg:4258
    rd_p = pyproj.CRS('epsg:28992')
    wgs84_p = pyproj.CRS('epsg:4258')
    project = pyproj.Transformer.from_proj(rd_p, wgs84_p, always_xy=True)
    polygon = transform(project.transform, polygon)

    # get bro_ids from the intersection with the polygon
    bro_ids = gpd.read_file(fn, mask=polygon, usecols='bro_id')
    if len(bro_ids) == 0:
        return []

    # get the keys of the database using the bro_ids found in the intersection
    query = (
        "SELECT geotechnical_cpt_survey_pk FROM geotechnical_cpt_survey "
        "WHERE geotechnical_cpt_survey.bro_id"
    )
    cursor.execute(query + query_equals_according_to_length(bro_ids.bro_id))
    returned_ids = cursor.fetchall()
    returned_ids = [int(id[0]) for id in returned_ids]

    query = construct_query(returned_ids)
    if isinstance(query, list):
        results = []
        for q in query:
            cursor.execute(q)
            c = pd.DataFrame(cursor.fetchall(), columns=columns_gpkg)
            if not c.empty:
                results.append(c)
        if len(results) > 0:
            results = pd.concat(results)
        else:
            return []
    else:
        cursor.execute(query)
        results = pd.DataFrame(cursor.fetchall(), columns=columns_gpkg)

    # cone surface quotient
    cursor.execute(construct_query_cone_surface_quotient(returned_ids))
    cone_surface_quotient = pd.DataFrame(cursor.fetchall(), columns=['id', 'a'])

    column_names_per_cpt = ['id', 'location_x', 'location_y']
    grouped_results = results.groupby(column_names_per_cpt)
    cpts_results = []
    for name, group in grouped_results:
        temporary_cpt_dict = dict(zip(column_names_per_cpt, name))
        temporary_cpt_dict['offset_z'] = float(list(group['offset_z'].fillna(0))[0])
        temporary_cpt_dict['vertical_datum'] = list(group['vertical_datum'])[0]
        temporary_cpt_dict['local_reference'] = list(group['local_reference'])[0]
        temporary_cpt_dict['quality_class'] = list(group['quality_class'])[0]
        temporary_cpt_dict['cpt_standard'] = list(group['cpt_standard'])[0]
        temporary_cpt_dict['predrilled_z'] = list(group['predrilled_z'].fillna(0))[0]
        temporary_cpt_dict['a'] = cone_surface_quotient[
            cone_surface_quotient['id'] == name[0]
        ]['a'].values[0]
        temporary_cpt_dict['in_track'] = is_cpt_inside_buffered_track(
            file_track,
            [temporary_cpt_dict['location_x'], temporary_cpt_dict['location_y']]
        )
        cpt_group = group.copy(deep=True)
        cpt_group.sort_values(['penetrationLength', 'depth'], inplace=True)
        temporary_cpt_dict['dataframe'] = cpt_group
        if determine_if_all_data_is_available(temporary_cpt_dict):
            temporary_cpt_dict['dataframe'] = change_to_floats(temporary_cpt_dict['dataframe'])
            cpts_results.append(temporary_cpt_dict)

    return cpts_results

def change_to_floats(data):
    """
    Function that changes all data to floats
    :param data: pandas dataframe
    :return: pandas dataframe
    """
    data[float_columns] = data[float_columns].apply(pd.to_numeric)
    return data


def create_index_if_it_does_not_exist(fn):
    """Function that creates index on the geopackage to improve performance."""
    conn = sqlite3.connect(fn)
    cursor = conn.cursor()
    logging.warning(
        "Checking if index exists; if not, creating indexes (first run may take a while)..."
    )

    # Speed up index creation – acceptable risk if this is run once per file
    cursor.execute("PRAGMA journal_mode = OFF;")
    cursor.execute("PRAGMA synchronous = OFF;")
    cursor.execute("PRAGMA temp_store = MEMORY;")

    cursor.executescript("""
        CREATE INDEX IF NOT EXISTS idx_cptr_fk
            ON cone_penetration_test_result(cone_penetration_test_fk);

        CREATE INDEX IF NOT EXISTS idx_gcs_bro_id
            ON geotechnical_cpt_survey(bro_id);

        CREATE INDEX IF NOT EXISTS idx_cps_gcs_fk
            ON cone_penetrometer_survey(geotechnical_cpt_survey_fk);

        CREATE INDEX IF NOT EXISTS idx_cpt_cps_fk
            ON cone_penetration_test(cone_penetrometer_survey_fk);

        CREATE INDEX IF NOT EXISTS idx_cp_cps_fk
            ON cone_penetrometer(cone_penetrometer_survey_fk);
    """)

    conn.commit()
    conn.close()

class BROContext:
    """
    BRO context

    Holds shared resources for querying the BRO GeoPackage:
    - filename (BRO GPKG)
    - open SQLite connection
    - in-memory geomorph index (from geomorph vector file or pickle)
    """
    def __init__(self, fn, geomorph_vector_path=None, geomorph_layer=None):
        self.fn = fn

        if not exists(fn):
            print(f"Cannot open provided BRO data file: {fn}")
            sys.exit(2)

        # ensure DB indexes exist once
        create_index_if_it_does_not_exist(fn)

        # open one connection for all queries
        self.conn = sqlite3.connect(fn)

        # load geomorph polygons if provided
        self.geomorph_index = None
        self.geomorph_geoms = None
        if geomorph_vector_path is not None:
            self.geomorph_index, self.geomorph_geoms = load_geomorph_index(
                geomorph_vector_path, layer=geomorph_layer
            )

    def close(self):
        if self.conn is not None:
            self.conn.close()
            self.conn = None

    def __enter__(self):
        # so that "with BROContext(...) as bro_ctx" returns the context object
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        # always close DB connection, even on exceptions
        self.close()
        # return False so exceptions are not swallowed
        return False

def load_geomorph_index(geomorph_vector_path, layer=None):
    """
    Load geomorph polygons and build an in-memory Rtree index.

    If geomorph_vector_path ends with '.pkl', it is assumed to be a pickle file
    with a list of (gm_code, geometry) tuples.
    Otherwise, it is assumed to be a vector file (shapefile/GPKG).

    :param geomorph_vector_path: path to geomorph vector or pickle file
    :param layer: optional layer name for vector file
    :return: (rtree_index, list_of_(gm_code, geometry))
    """
    from rtree import index
    import geopandas as gpd
    import os
    import pickle

    geom_list = []

    if geomorph_vector_path.lower().endswith(".pkl"):
        # Load precomputed list of (gm_code, geometry)
        with open(geomorph_vector_path, "rb") as f:
            geom_list = pickle.load(f)
    else:
        # Read polygons from vector file
        if layer is None:
            gdf = gpd.read_file(geomorph_vector_path)
        else:
            gdf = gpd.read_file(geomorph_vector_path, layer=layer)

        # Handle different possible code columns
        if "identification" in gdf.columns:
            code_col = "identification"
        elif "identifica" in gdf.columns:
            code_col = "identifica"
        else:
            raise RuntimeError(
                f"Geomorph layer must contain an 'identification' or 'identifica' column. "
                f"Got columns: {gdf.columns}"
            )

        geom_list = [(row[code_col], row.geometry) for _, row in gdf.iterrows()]

    # Build in-memory Rtree
    props = index.Property()
    props.storage = index.RT_Memory
    rtree_idx = index.Index(properties=props)

    for i, (_, geom) in enumerate(geom_list):
        if geom is None or geom.is_empty:
            continue
        bbox = geom.bounds
        rtree_idx.insert(i, bbox)

    return rtree_idx, geom_list

def query_bro_at_point(ctx: BROContext, x, y, r):
    """
    Query BRO CPTs around (x, y) with radius r using an existing BROContext.

    Returns:
        {
            "polygons": { gm_code: {"data": [cpt_dict, ...], "perc": float}, ... },
            "circle":   { "data": [cpt_dict, ...] }
        }
    """
    out = {}
    out["polygons"] = {}
    total_cpts = 0

    # create circle around source point
    circle = Point(x, y).buffer(r, resolution=32)

    # path to buffered track index (same directory as BRO GPKG)
    file_track_idx = join(dirname(ctx.fn), 'buff_track')

    # accumulate area of polygons with same gm_code
    zone_overlap_area = {}

    # Polygon grouping from geomorphological_area (if index exists)
    if ctx.geomorph_index is not None:
        bbox = (x - r, y - r, x + r, y + r)
        candidate_ids = list(ctx.geomorph_index.intersection(bbox))
        for i in candidate_ids:
            gm_code, polygon = ctx.geomorph_geoms[i]
            poly = shape(polygon)
            if not poly.is_valid:
                poly = poly.buffer(0.01)  # buffering reconstructs the geometry

            if circle.intersects(poly):
                inter = circle.intersection(poly)
                area = inter.area
                # accumulate area per gm_code
                zone_overlap_area[gm_code] = zone_overlap_area.get(gm_code, 0.0) + area

                cpts = read_cpt_from_gpkg(poly, ctx, file_track=file_track_idx)
                total_cpts += len(cpts)
                if gm_code in out["polygons"]:
                    out["polygons"][gm_code]["data"].extend(cpts)
                else:
                    # perc will be set later based on total overlap area
                    out["polygons"][gm_code] = {"data": cpts, "perc": None}

    # set final perc per gm_code: total overlap area / circle area
    for gm_code in out["polygons"]:
        total_area = zone_overlap_area.get(gm_code, 0.0)
        out["polygons"][gm_code]["perc"] = total_area / circle.area

    logging.warning("Found {} CPTs in intersecting polygons.".format(total_cpts))

    # Find CPT indexes in circle
    circle_polygon = Point(x, y).buffer(r, resolution=32)
    circle_cpts = read_cpt_from_gpkg(circle_polygon, ctx, file_track=file_track_idx)
    logging.warning("Found {} CPTs in circle.".format(len(circle_cpts)))
    out["circle"] = {"data": circle_cpts}

    return out
