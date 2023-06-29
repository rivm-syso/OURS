"""
CPT tool
"""
# import packages
import os
import json
import argparse
import sys
# import OURS packages
from CPTtool import bro
from CPTtool import log_handler
from CPTtool import tools_utils
from CPTtool import cpt_module


def define_methods(input_file):
    """
    Defines correlations for the CPT

    :param input_file: json file with methods
    :return: methods: dictionary with the methods for CPT correlations
    """
    # possible keys:
    keys = ["gamma", "vs", "OCR", "radius"]
    # possible key-values
    gamma_keys = ["Lengkeek", "Robertson", "all"]
    vs_keys = ["Mayne", "Robertson", "Andrus", "Zang", "Ahmed", "all"]
    OCR_keys = ["Mayne", "Robertson"]
    rad = 600.

    # if no file is available: -> uses default values
    if not input_file:
        methods = {"gamma": gamma_keys[0],
                   "vs": vs_keys[0],
                   "OCR": OCR_keys[0],
                   "radius": rad,
                   }
        return methods

    # check if input file exists
    if not os.path.isfile(input_file):
        print("File with methods definition does not exist")
        sys.exit(4)

    # if the file is available
    with open(input_file, "r") as f:
        data = json.load(f)

    # # checks if the keys are correct
    for i in data.keys():
        if not any(i in k for k in keys):
            print("Error: Key " + i + " is not known. Keys must be: " + ', '.join(keys))
            sys.exit(5)

    # check if the key-values are correct for gamma
    if not any(data["gamma"] in k for k in gamma_keys):
        print("Error: gamma key is not known. gamma keys must be: " + ', '.join(gamma_keys))
        sys.exit(5)
    # check if the key-values are correct for vs
    if not any(data["vs"] in k for k in vs_keys):
        print("Error: gamma key is not known. vs keys must be: " + ', '.join(vs_keys))
        sys.exit(5)
    # check if the key-values are correct for OCR
    if not any(data["OCR"] in k for k in OCR_keys):
        print("Error: gamma key is not known. OCR keys must be: " + ', '.join(OCR_keys))
        sys.exit(5)
    # check if radius is a float
    if not isinstance(data["radius"], (int, float)):
        print("Error: radius is not known. must be a float")
        sys.exit(5)

    # add to dicionary
    methods = {"gamma": data["gamma"],
               "vs": data["vs"],
               "OCR": data["OCR"],
               "radius": float(data["radius"])
               }
    return methods


def define_settings(input_file):
    """
    Defines settings for the optional parameters of the CPT analysis

    :param input_file: json file with methods
    :return: settings dictionary
    """

    # keys for settings
    keys_dic = ["minimum_length", "minimum_samples", "minimum_ratio", "convert_to_kPa",
                "nb_points", "limit", "gamma_min", "gamma_max", "d_min", "Cu",
                "D50", "Ip", "freq", "lithologies", "key", "value", "power"]

    # if no file is available: -> uses default values
    if not input_file:
        # settings
        sett = {"minimum_length": 5,  # minimum length of CPT
                "minimum_samples": 50,  # minimum number of samples of CPT
                "minimum_ratio": 0.1,  # mimimum ratio of correct values in a CPT
                "convert_to_kPa": True,  # convert CPT to kPa
                "nb_points": 5,  # number of points for smoothing
                "limit": 0,  # lower bound of the smooth function
                "gamma_min": 10.5,  # minimum unit weight
                "gamma_max": 22,  # maximum unit weight
                "d_min": 2.,  # parameter for damping (minimum damping)
                "Cu": 2.,  # parameter for damping (coefficient of uniformity)
                "D50": 0.2,  # parameter for damping (median grain size)
                "Ip": 40.,  # parameter for damping (plastic index)
                "freq": 1.,  # parameter for damping (frequency)
                "lithologies": ["1", "2"],  # lithologies to filter
                "key": "G0",  # attribute to filder
                "value": 1e6,  # lower value to filter
                "power": 1,  # power for IDW interpolation
                }

        return sett

    # check if input file exists
    if not os.path.isfile(input_file):
        print("File with settings definition does not exist")
        sys.exit(4)

    # if the file is available
    with open(input_file, "r") as f:
        data = json.load(f)

    # # checks if the keys are correct
    for i in data.keys():
        if not any(i in k for k in keys_dic):
            print("Error: Key " + i + " is not known. Keys must be: " + ', '.join(keys_dic))
            sys.exit(5)

    # create setting dic
    sett = {}
    # add key to dic
    for k in keys_dic:
        sett.update({k: data[k]})

    return sett


def read_json(input_file):
    """
    Reads input json file

    :param input_file: json file with the input values
    :return: data: dictionary with the input files
    """
    # check if file exits
    if not os.path.isfile(input_file):
        print("Input JSON file does not exist")
        sys.exit(-3)

    # read file
    with open(input_file, "r") as f:
        data = json.load(f)
    return data


def read_cpt(cpt_BRO, methods, settings, output_folder, input_dictionary, make_plots, index_coordinate, log_file,
             jsn, scenario):
    """
    Read CPT

    Read and process cpt files: GEF format

    Parameters
    ----------
    :param cpt_BRO: cpt information from the BRO
    :param methods: Methods for the CPT correlations
    :param settings: Settings for the optional parameters for the CPT correlations
    :param output_folder: Folder to save the files
    :param input_dictionary: Dictionary with input settings
    :param make_plots: Bool to make plots
    :param index_coordinate: Index of the calculation coordinate point
    :param log_file: Log file for the analysis
    :param jsn: dictionary with the scenarios
    :param scenario: scenario number
    :return: json file with results, bool (True/False) if there results are not empty
    """

    is_jsn_modified = False
    # dictionary for the results
    results_cpt = {}
    for idx_cpt in range(len(cpt_BRO)):
        # add message to log file
        log_file.info_message("Reading CPT: " + cpt_BRO[idx_cpt]["id"])
        # initialise CPT module
        cpt = cpt_module.CPT(output_folder)
        # read data from BRO
        data_quality = cpt.parse_bro(cpt_BRO[idx_cpt],
                                     minimum_length=settings["minimum_length"], minimum_samples=settings["minimum_samples"],
                                     minimum_ratio=settings["minimum_ratio"], convert_to_kPa=settings["convert_to_kPa"])
        # check data quality from the BRO file
        if data_quality is not True:
            # If the quality is not good skip this cpt file
            log_file.error_message(data_quality)
            continue
        # smooth data
        cpt.smooth(nb_points=settings["nb_points"], limit=settings["limit"])
        # compute qc
        cpt.qt_calc()
        # compute unit weight
        cpt.gamma_calc(method=methods["gamma"], gamma_min=settings["gamma_min"], gamma_max=settings["gamma_max"])
        # compute density
        cpt.rho_calc()
        # compute water pressure level
        cpt.pwp_level_calc(input_dictionary['BRO_data'])
        # compute stresses: total, effective and pore water pressures
        cpt.stress_calc()
        # compute lithology
        cpt.lithology_calc()
        # compute IC
        cpt.IC_calc()
        # compute shear wave velocity and shear modulus
        cpt.vs_calc(method=methods["vs"])
        # compute damping
        cpt.damp_calc(method=methods["OCR"], d_min=settings["d_min"], Cu=settings["Cu"], D50=settings["D50"],
                      Ip=settings["Ip"], freq=settings["freq"])
        # compute Poisson ratio
        cpt.poisson_calc()
        # filter values
        cpt.filter(lithologies=settings["lithologies"], key=settings["key"], value=settings["value"])
        # make the plots (optional)
        if make_plots:
            cpt.write_csv()
            cpt.plot_cpt()
            cpt.plot_lithology()
        # update scenario
        results_cpt.update({cpt_BRO[idx_cpt]["id"]: cpt})
        # add to log file that the analysis is successful
        log_file.info_message("Analysis succeeded for: " + cpt_BRO[idx_cpt]["id"])

    # Check if the data of all the cpts are empty. If they are skip processing them
    if bool(results_cpt):
        # perform interpolation
        result_interp = tools_utils.interpolation(results_cpt, [input_dictionary['Receiver_x'][index_coordinate],
                                                                input_dictionary['Receiver_y'][index_coordinate]],
                                                  power=settings["power"])

        # merge the layers thickness
        depth_json, indx_json, lithology_json = tools_utils.merge_thickness(result_interp,
                                                                            float(input_dictionary["MinLayerThickness"]))
        # add results to the dictionary
        jsn = tools_utils.add_json(jsn, scenario, depth_json, indx_json, lithology_json, result_interp)
        is_jsn_modified = True
    return jsn, is_jsn_modified


def analysis(properties, methods_cpt, settings_cpt, output, plots):
    """
    Analysis of CPT

    Extracts the CPT from the BRO PDOK database, based on coordinate location and processes the cpt

    :param properties: JSON file with the properties of the analysis: opened json file
    :param methods_cpt: methods to use for the CPT interpretation
    :param settings_cpt: settings for the optional parameters for the CPT interpretation
    :param output: path for the output results
    :param plots: boolean create the plots
    :return:
    """
    # number of points
    nb_points = len(properties["Source_x"])

    # for each calculation point
    for idx in range(nb_points):

        # probability of scenarios
        prob = []

        # variables
        jsn = {"scenarios": []}  # json dictionary
        scenario = 0  # scenario number

        # Define log file
        log_file = log_handler.LogFile(output, idx)
        log_file.info_message("Analysis started for coordinate point: (" + properties["Source_x"][idx] + ", "
                              + properties["Source_y"][idx] + ")")

        # read BRO data base
        inpt = {"BRO_data": properties["BRO_data"],
                "Source_x": float(properties["Source_x"][idx]), "Source_y": float(properties["Source_y"][idx]),
                "Radius": float(methods_cpt["radius"]),
                }
        cpts = bro.read_bro_gpkg_version(inpt)

        results = {}
        # check points within polygons
        cpts_polygons = {}
        polygons_names = []
        for zone in cpts['polygons']:
            cpts_polygons.update({zone: {"data": list(filter(None, cpts['polygons'][zone]['data'])),
                                         "perc": cpts['polygons'][zone]['perc']
                                         }
                                  })

            for c in cpts_polygons[zone]["data"]:
                polygons_names.append(c["id"])

        # process cpts polygons
        results.update({"polygons": {}})
        for zone in cpts_polygons:
            # remove the nones
            data = list(filter(None, cpts['polygons'][zone]['data']))
            if data:
                jsn, is_jsn_modified = read_cpt(data, methods_cpt, settings_cpt, output, properties, plots, idx,
                                                log_file, jsn, scenario)
                if is_jsn_modified:
                    results["polygons"].update({zone: True})
                    prob.append(cpts['polygons'][zone]['perc'])
                    jsn["scenarios"][scenario].update({"coordinates": [properties["Receiver_x"][idx], properties["Receiver_y"][idx]],
                                                       "probability": prob[-1]})
                    scenario += 1

        # check points within circle
        cpts_circle = list(filter(None, cpts['circle']['data']))
        # get cpts that are not in polygons
        circle_names = []
        circle_idx = []
        for j, c in enumerate(cpts_circle):
            circle_names.append(c["id"])
            circle_idx.append(j)

        # process only the ones that are not part of polygons
        names_diff = list(set(circle_names) - set(polygons_names))
        # get the indexes of the circle cpts to be processed
        circle_idx = [circle_names.index(n) for n in names_diff]
        cpts_circle = [cpts_circle[j] for j in circle_idx]

        # remove the nones
        data = list(filter(None, cpts_circle))

        # get indexes of
        results.update({"circle": []})
        if data:
            # if data exists in the circle
            jsn, is_jsn_modified = read_cpt(data, methods_cpt, settings_cpt, output, properties, plots, idx, log_file,
                                            jsn, scenario)
            if is_jsn_modified:
                results["circle"] = True
                jsn["scenarios"][scenario].update({"coordinates": [properties["Receiver_x"][idx], properties["Receiver_y"][idx]],
                                                   "probability": 1. - sum(prob)})
                scenario += 1
        elif jsn["scenarios"]:
            # if circle is empty and polygons exist: update probability of polygons
            for i in range(len(jsn["scenarios"])):
                jsn["scenarios"][i]["probability"] = jsn["scenarios"][i]["probability"] / sum(prob)

        # check if cpts have data or are all empty: this mean that this point has no data
        if not results["circle"] and not results["polygons"]:
            log_file.error_message("No data in this coordinate point")
            log_file.info_message("Analysis finished for coordinate point: (" + str(properties["Source_x"][idx]) + ", "
                                  + str(properties["Source_y"][idx]) + ")")
            log_file.close()
            continue

        # round probability to two decimals
        for i in range(len(jsn["scenarios"])):
            jsn["scenarios"][i]["probability"] = round(jsn["scenarios"][i]["probability"], 3)

        # dump json
        tools_utils.dump_json(jsn, idx, output)

        # processed cpts
        log_file.info_message("Analysis finished for coordinate point: (" + str(properties["Source_x"][idx]) + ", "
                              + str(properties["Source_y"][idx]) + ")")
        log_file.close()
    return


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--json', help='input JSON file', required=True)
    parser.add_argument('-o', '--output', help='location of the output folder', required=True)
    parser.add_argument('-p', '--plots', help='make plots', required=False, default=False)
    parser.add_argument('-m', '--methods', help='methods for CPT correlations', required=False, default=False)
    parser.add_argument('-s', '--settings', help='settings for CPT correlations', required=False, default=False)
    args = parser.parse_args()

    # reads input json file
    props = read_json(args.json)
    # define methods for the analysis of CPT
    methods = define_methods(args.methods)
    # define settings
    settings = define_settings(args.settings)

    # do analysis
    analysis(props, methods, settings, args.output, args.plots)
