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
    Function that creates query to retrieve all data from cpt_cone_penetration_test_result,
    cpt_cone_penetrometer_survey and cpt_geotechnical_survey tables
    :param cpt_keys: List of ids of the cpts
    :return: str
    """
    selected_columns = "SELECT distinct cpt_cone_penetration_test_result.penetration_length,\
                               cpt_cone_penetration_test_result.depth,\
                               cpt_cone_penetration_test_result.elapsed_time,\
                               cpt_cone_penetration_test_result.cone_resistance,\
                               cpt_cone_penetration_test_result.corrected_cone_resistance,\
                               cpt_cone_penetration_test_result.net_cone_resistance,\
                               cpt_cone_penetration_test_result.magnetic_field_strength_x,\
                               cpt_cone_penetration_test_result.magnetic_field_strength_y,\
                               cpt_cone_penetration_test_result.magnetic_field_strength_z,\
                               cpt_cone_penetration_test_result.magnetic_field_strength_total,\
                               cpt_cone_penetration_test_result.electrical_conductivity,\
                               cpt_cone_penetration_test_result.inclination_ew,\
                               cpt_cone_penetration_test_result.inclination_ns,\
                               cpt_cone_penetration_test_result.inclination_x,\
                               cpt_cone_penetration_test_result.inclination_y,\
                               cpt_cone_penetration_test_result.inclination_resultant,\
                               cpt_cone_penetration_test_result.magnetic_inclination,\
                               cpt_cone_penetration_test_result.magnetic_declination,\
                               cpt_cone_penetration_test_result.local_friction,\
                               cpt_cone_penetration_test_result.pore_ratio,\
                               cpt_cone_penetration_test_result.temperature,\
                               cpt_cone_penetration_test_result.pore_pressure_u1,\
                               cpt_cone_penetration_test_result.pore_pressure_u2,\
                               cpt_cone_penetration_test_result.pore_pressure_u3,\
                               cpt_cone_penetration_test_result.friction_ratio,\
                               cpt_geotechnical_survey.bro_id,\
                               cpt_geotechnical_survey.x_or_lon,\
                               cpt_geotechnical_survey.y_or_lat,\
                               cpt_geotechnical_survey.offset,\
                               cpt_geotechnical_survey.vertical_datum,\
                               cpt_geotechnical_survey.local_vert_ref_point,\
                               cpt_geotechnical_survey.quality_regime,\
                               cpt_geotechnical_survey.cpt_standard,\
                               cpt_geotechnical_survey.research_report_date,\
                               cpt_cone_penetrometer_survey.predrilled_depth \
                        FROM cpt_geotechnical_survey \
                            join cpt_cone_penetration_test_result on cpt_cone_penetration_test_result.cone_penetration_test_id = cpt_geotechnical_survey.geotechnical_survey_id \
                            join cpt_cone_penetrometer_survey on cpt_cone_penetrometer_survey.cone_penetrometer_survey_id = cpt_geotechnical_survey.geotechnical_survey_id "
    where_clause = f"WHERE cpt_geotechnical_survey.geotechnical_survey_id "
    in_clause = query_equals_according_to_length(cpt_keys)
    return selected_columns + where_clause + in_clause


def construct_query_cone_surface_quotient(cpt_keys):
    """
    Function that returns query for retrieving the cone_surface_quotient from the cpt_cone_penetrometer table
    :param cpt_keys: List of ids of the cpts
    :return: str
    """
    return f"select bro_id, cone_surface_quotient  \
                FROM cpt_geotechnical_survey \
                join cpt_cone_penetrometer on cpt_cone_penetrometer.cone_penetrometer_id = cpt_geotechnical_survey.geotechnical_survey_id  \
                WHERE cpt_cone_penetrometer.cone_penetrometer_id " + query_equals_according_to_length(cpt_keys)


def determine_if_all_data_is_available(data):
    """
    Determine if all data is available in dataframe
    :param data: pandas dataframe
    :return:
    """
    avail_columns = data.get("dataframe").columns
    data_excluding_dataframe = {x: data[x] for x in data if x not in {"dataframe", "a"}}
    meta_usable = all([x is not None for x in data_excluding_dataframe.values()])
    data_usable = all([col in avail_columns for col in req_columns])
    if not (meta_usable and data_usable):
        logging.warning("CPT with id {} misses required data.".format(data["id"]))
        return False
    return True


def read_cpt_from_gpkg(polygon, fn):
    """
    Function that retrieves cpts that intercect a polygon
    :param polygon: shapely polygon
    :param fn: geopackage file location
    :return: list of dictionaries containing all cpt data
    """
    cpts_results = []
    # transform the polygon from epsg:28992 to epsg:4258
    rd_p = pyproj.CRS('epsg:28992')
    wgs84_p = pyproj.CRS('epsg:4258')
    project = pyproj.Transformer.from_proj(rd_p, wgs84_p, always_xy=True)
    polygon = transform(project.transform, polygon)
    # get bro_ids from the intersection with the polygon
    bro_ids = gpd.read_file(fn, mask=polygon, usecols='bro_id')
    if len(bro_ids) > 0:
        # connect with the geopackage using sqlite
        conn = sqlite3.connect(fn)
        cursor = conn.cursor()
        # get the keys of the database using the bro_ids found in the intersection
        query = "SELECT geotechnical_survey_id FROM cpt_geotechnical_survey WHERE cpt_geotechnical_survey.bro_id"
        cursor.execute(query + query_equals_according_to_length(bro_ids.bro_id))
        returned_ids = cursor.fetchall()
        returned_ids = [int(id[0]) for id in returned_ids]
        query = construct_query(returned_ids)
        cursor.execute(query)
        results = pd.DataFrame(cursor.fetchall(), columns=columns_gpkg)
        cursor.execute(construct_query_cone_surface_quotient(returned_ids))
        cone_surface_quotient = pd.DataFrame(cursor.fetchall(), columns=['id', 'a'])
        column_names_per_cpt = ['id', 'location_x', 'location_y']
        grouped_results = results.groupby(column_names_per_cpt)
        cpts_results = []
        for name, group in grouped_results:
            temporary_cpt_dict = dict(zip(column_names_per_cpt, name))
            temporary_cpt_dict['offset_z'] = list(group['offset_z'].fillna(0))[0]
            temporary_cpt_dict['vertical_datum'] = list(group['vertical_datum'])[0]
            temporary_cpt_dict['local_reference'] = list(group['local_reference'])[0]
            temporary_cpt_dict['quality_class'] = list(group['quality_class'])[0]
            temporary_cpt_dict['cpt_standard'] = list(group['cpt_standard'])[0]
            temporary_cpt_dict['predrilled_z'] = list(group['predrilled_z'].fillna(0))[0]
            temporary_cpt_dict['a'] = cone_surface_quotient[cone_surface_quotient['id'] == name[0]]['a'].values[0]
            cpt_group = group.copy(deep=True)
            cpt_group.sort_values(['penetrationLength', 'depth'], inplace=True)
            temporary_cpt_dict['dataframe'] = cpt_group
            if determine_if_all_data_is_available(temporary_cpt_dict):
                cpts_results.append(temporary_cpt_dict)
    return cpts_results


def create_index_if_it_does_not_exist(fn):
    """
    Function that creates index on the geopackage dataframe to improve performance
    """
    conn = sqlite3.connect(fn)
    cursor = conn.cursor()
    # get the keys of the database using the bro_ids found in the intersection
    logging.warning("Checking if index exists, if index does not exist it should be created, this may take a while...")
    cursor.execute("create index if not exists ix_test on cpt_cone_penetration_test_result(cone_penetration_test_id);")


def read_bro_gpkg_version(parameters):
    """Main function to read the BRO database.

    :param parameters: Dict of input `parameters` containing filename, location and radius.
    :type parameters: dict
    :return: Dict with multiple groupings of parsed CPTs as dicts
    :rtype: dict

    """
    fn = parameters["BRO_data"]
    x, y = parameters["Source_x"], parameters["Source_y"]
    r = parameters["Radius"]
    out = {}

    if not exists(fn):
        print("Cannot open provided BRO data file: {}".format(fn))
        sys.exit(2)

    create_index_if_it_does_not_exist(fn)

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

    geomorphs = list(gm_index.intersection((x - r, y - r, x + r, y + r), objects="raw"))
    circle = Point(x, y).buffer(r, resolution=32)
    for gm_code, polygon in geomorphs:
        poly = shape(polygon)
        if not poly.is_valid:
            poly = poly.buffer(0.01)  # buffering reconstructs the geometry, often fixing invalidity
        if circle.intersects(poly):
            perc = circle.intersection(poly).area / circle.area
            cpts = read_cpt_from_gpkg(poly, fn)
            total_cpts = total_cpts + len(cpts)
            if gm_code in out["polygons"]:
                out["polygons"][gm_code]["data"].extend(cpts)
            else:
                out["polygons"][gm_code] = {"data": cpts, "perc": perc}
    logging.warning("Found {} CPTs in intersecting polygons.".format(total_cpts))

    # Find CPT indexes in circle
    # create circle as polygon
    circle_polygon = Point(x, y).buffer(r, resolution=32)
    circle_cpts = read_cpt_from_gpkg(circle_polygon, fn)
    logging.warning("Found {} CPTs in circle.".format(len(circle_cpts)))
    out["circle"] = {"data": circle_cpts}

    return out


if __name__ == "__main__":
    input = {"BRO_data": "./bro/brocptvolledigeset.gpkg", "Source_x": 82860, "Source_y": 443400,
             "Radius": 1200}
    cpts = read_bro_gpkg_version(input)
    print(cpts.keys())
