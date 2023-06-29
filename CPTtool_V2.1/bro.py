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
import numpy as np

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
    where_clause = f"WHERE geotechnical_cpt_survey.geotechnical_cpt_survey_pk "
    if len(cpt_keys) >= 8:
        in_clause = query_equals_according_to_length(cpt_keys)
        return selected_columns + where_clause + in_clause
    else:
        return [selected_columns + where_clause + f" = {int(i)} " for i in cpt_keys]


def construct_query_cone_surface_quotient(cpt_keys):
    """
    Function that returns query for retrieving the cone_surface_quotient from the cpt_cone_penetrometer table
    :param cpt_keys: List of ids of the cpts
    :return: str
    """
    return f"select bro_id, cone_surface_quotient  \
                FROM geotechnical_cpt_survey \
                join cone_penetrometer on cone_penetrometer.cone_penetrometer_survey_fk = geotechnical_cpt_survey.geotechnical_cpt_survey_pk  \
                WHERE cone_penetrometer.cone_penetrometer_survey_fk " + query_equals_according_to_length(cpt_keys)


def change_to_floats(data):
    """
    Function that changes all data to floats
    :param data: pandas dataframe
    :return: pandas dataframe
    """
    data[float_columns] = data[float_columns].apply(pd.to_numeric)
    return data


def determine_if_all_data_is_available(data):
    """
    Determine if all data is available in dataframe
    :param data: pandas dataframe
    :return:
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


def read_cpt_from_gpkg(polygon, fn):
    """
    Function that retrieves cpts that intercept a polygon
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
        query = "SELECT geotechnical_cpt_survey_pk FROM geotechnical_cpt_survey WHERE geotechnical_cpt_survey.bro_id"
        cursor.execute(query + query_equals_according_to_length(bro_ids.bro_id))
        returned_ids = cursor.fetchall()
        returned_ids = [int(id[0]) for id in returned_ids]
        query = construct_query(returned_ids)
        # check type of query
        if isinstance(query, list):
            results = []
            for q in query:
                cursor.execute(q)
                c = pd.DataFrame(cursor.fetchall(), columns=columns_gpkg)
                if not(c.empty):
                    results.append(c)
            # check if results is not empty
            if len(results) > 0:
                results = pd.concat(results)
            else:
                return []
        else:
            cursor.execute(query)
            results = pd.DataFrame(cursor.fetchall(), columns=columns_gpkg)
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
            temporary_cpt_dict['a'] = cone_surface_quotient[cone_surface_quotient['id'] == name[0]]['a'].values[0]
            cpt_group = group.copy(deep=True)
            cpt_group.sort_values(['penetrationLength', 'depth'], inplace=True)
            temporary_cpt_dict['dataframe'] = cpt_group
            if determine_if_all_data_is_available(temporary_cpt_dict):
                temporary_cpt_dict['dataframe'] = change_to_floats(temporary_cpt_dict['dataframe'])
                # replace np.nan with None
                #temporary_cpt_dict['dataframe'] = temporary_cpt_dict['dataframe'].replace({np.nan: None})
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
    cursor.execute("create index if not exists ix_test on cone_penetration_test_result(cone_penetration_test_fk);")


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
    test_db = join(dirname(__file__), '../bro/test_v2_0_1.gpkg')
    input = {"BRO_data": test_db, "Source_x": 82860, "Source_y": 443400,
             "Radius": 1200}
    cpts = read_bro_gpkg_version(input)
    print(cpts.keys())
