"""
Tools for OURS
"""
# import packages
from itertools import groupby
from operator import itemgetter
import numpy as np
import os
import sys
import json
import warnings
warnings.filterwarnings("ignore", category=np.VisibleDeprecationWarning)
# import OURS packages
from CPTtool import robertson
from CPTtool import inv_dist


def n_iter(n, qt, friction_nb, sigma_eff, sigma_tot, Pa):
    """
    Computation of stress exponent *n*

    :param n: initial stress exponent
    :param qt: tip resistance
    :param friction_nb: friction number
    :param sigma_eff: effective stress
    :param sigma_tot: total stress
    :param Pa: atmospheric pressure
    :return: updated n - stress exponent
    """

    # convergence of n
    Cn = (Pa / np.array(sigma_eff)) ** n

    Q = ((np.array(qt) - np.array(sigma_tot)) / Pa) * Cn
    F = (np.array(friction_nb) / (np.array(qt) - np.array(sigma_tot))) * 100

    # Q and F cannot be negative. if negative, log10 will be infinite.
    # These values are limited by the contours of soil behaviour of Robertson
    Q[Q <= 1.] = 1.
    F[F <= 0.1] = 0.1
    Q[Q >= 1000.] = 1000.
    F[F >= 10.] = 10.

    IC = ((3.47 - np.log10(Q)) ** 2. + (np.log10(F) + 1.22) ** 2.) ** 0.5

    n = 0.381 * IC + 0.05 * (sigma_eff / Pa) - 0.15
    n[n > 1.] = 1.
    return n


def interpolation(data_cpt, coordinates, power=1):
    """
    Inverse distance weight interpolation

    Perform the interpolation for the CPT attributes at the coordinates
    If power = 0 the result is the mean value
    If power > 0 the results is weighted with the distance

    :param data_cpt: list of cpts objects
    :param coordinates: coordinates for the interpolation point
    :param power: (optional) power to be used for the interpolation. Default is 1
    :return: results dictionary with the interpolated CPT at the requested location
    """
    # convert coordinates to float
    coordinates = list(map(float, coordinates))

    # result output dictionary
    results = {}

    # list of attributes to be interpolated
    attributes = ["Qtn", "Fr", "G0", "poisson", "rho", "damping", "IC"]
    attributes_var = ["Qtn_var", "Fr_var", "G0_var", "poisson_var", "rho_var", "damping_var", "IC_var"]
    # default cov for the attributes
    attibutes_cov = [1, 1, 2, 1, 0.5, 2, 1]

    # transform cpt data into a continuous list for all cpts
    coords = []  # cpt coordinates
    min_max_nap = []  # cpt min and max depths
    data_training = []  # np.empty(shape=[0, len(attributes)])  # training data. dimensions nb points x nb attributes
    depth_points = []  #
    # for each cpt
    for i in data_cpt:
        # at each depth get the coordinates
        coords.append([data_cpt[i].coord[0], data_cpt[i].coord[1]])
        # obtain the depths of the cpt
        min_max_nap.append([data_cpt[i].coord[0], data_cpt[i].coord[1],
                            min(data_cpt[i].depth_to_reference), max(data_cpt[i].depth_to_reference),
                            np.mean(np.diff(data_cpt[i].depth_to_reference))])
        depth_points.append(data_cpt[i].depth_to_reference)
    # get atttributes to interpolate
    for at in attributes:
        training = []
        for i in data_cpt:
            training.append(np.array(getattr(data_cpt[i], at), dtype=float))
        data_training.append(training)
    min_max_nap = np.array(min_max_nap, dtype=float)

    # interpolate the top and bottom depth at this point
    interp_top = inv_dist.InverseDistance(nb_points=len(data_cpt), pwr=power)
    # create interpolation object
    interp_top.interpolate(np.array(min_max_nap)[:, :2], np.array(min_max_nap)[:, 3], np.zeros(len(data_cpt)), 0)
    # predict
    interp_top.predict(np.array(coordinates).reshape(1, 2), point=True)
    # interpolate the distances
    interp_bot = inv_dist.InverseDistance(nb_points=len(data_cpt), pwr=power)
    # create interpolation object
    interp_bot.interpolate(np.array(min_max_nap)[:, :2], np.array(min_max_nap)[:, 2],  np.zeros(len(data_cpt)), 0)
    # predict
    interp_bot.predict(np.array(coordinates).reshape(1, 2), point=True)

    # create depth vector
    depth = np.linspace(interp_top.zn[0],
                        interp_bot.zn[0],
                        int(np.ceil((interp_bot.zn[0] - interp_top.zn[0]) / np.mean(np.array(min_max_nap)[:, 4])) + 1))
    # coordinates for interpolation
    # c_out = [[coordinates[0], coordinates[1], i] for i in depth]
    c_out = [coordinates[0], coordinates[1]]

    # for each attribute perform interpolation and assign it to the results dict
    for i, at in enumerate(attributes):
        interp = inv_dist.InverseDistance(nb_points=len(data_cpt), pwr=power, default_cov=attibutes_cov[i])
        # create interpolation object
        interp.interpolate(coords, data_training[i], depth_points, depth)
        # predict
        interp.predict(np.array(c_out).reshape(1, 2))
        # assign to result
        results.update({at: interp.zn,
                        attributes_var[i]: interp.var})

    # add depth to results
    results.update({"NAP": depth})
    results.update({"depth": np.abs(depth - depth[0])})
    return results


def resource_path(file_name):
    r""""
    Define the relative path to the file

    Used to account for the compiling location of the shapefile

    Parameters
    ----------
    :param file_name: File name
    :return: relative path to the file
    """

    try:
        base_path = sys._MEIPASS
    except AttributeError:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, file_name)


def ceil_value(data, value):
    """
    Replaces the data values from data, that are are smaller of equal to value.
    It replaces the data values with the first non-zero value of the dataset.

    :param data:
    :param value:
    :return: data with the updated values
    """
    # collect indexes smaller than value
    idx = [i for i, val in enumerate(data) if val <= value]

    # get consecutive indexes on the list
    indx_conseq = []
    for k, g in groupby(enumerate(idx), lambda ix: ix[0] - ix[1]):
        indx_conseq.append(list(map(itemgetter(1), g)))

    # assigns the value of the first non-value
    for i in indx_conseq:
        for j in i:
            # if the sequence contains the last index of the data use the previous one
            if i[-1] + 1 >= len(data):
                data[j] = data[i[0] - 1]
            else:
                data[j] = data[i[-1] + 1]

    return data


def merge_thickness(cpt_data, min_layer_thick):
    r"""
    Reorganises the lithology based on the minimum layer thickness.
    This function call the functions merging_label, merging_index , merging_depth , merging_thickness.
    These functions merge the layers according to the min_layer_thick.
    For more information refer to those.

    Parameters
    ----------
    :param cpt_data : CPT data set
    :param min_layer_thick : Minimum layer thickness
    :return depth_json: depth merged
    :return indx_json: index of the merged list
    :return lithology_json: merged lithology

    """

    # compute lithology of interpolated cpt
    cpt_data["Qtn"][cpt_data["Qtn"] <= 1.] = 1.0
    cpt_data["Qtn"][cpt_data["Qtn"] >= 1000.] = 1000.
    cpt_data["Fr"][cpt_data["Fr"] <= 0.1] = 0.1
    cpt_data["Fr"][cpt_data["Fr"] >= 10.] = 10.

    classification = robertson.Robertson()
    classification.soil_types()
    lithology, _ = classification.lithology(cpt_data["Qtn"], cpt_data["Fr"])

    depth = cpt_data["depth"]

    # Find indices of local unmerged layers
    aux = ""
    idx = []
    for j, val in enumerate(lithology):
        if val != aux:
            aux = val
            idx.append(j)

    # Depth between local unmerged layers
    local_z_ini = [depth[i] for i in idx]
    # Thicknesses between local unmerged layers
    local_thick = np.append(np.diff(local_z_ini), depth[-1] - local_z_ini[-1])
    # Actual Merging
    new_thickness = merging_thickness(local_thick, min_layer_thick)

    depth_json = merging_depth(depth, new_thickness)
    indx_json = merging_index(depth, depth_json)
    lithology_json = merging_label(indx_json, lithology)

    return depth_json, indx_json, lithology_json


def merging_label(indx_json, lithology):
    r"""
    Function that joins the lithology labels of each merged layer.
    """
    new_label = []
    start = indx_json[:-1]
    finish = indx_json[1:]
    for i in range(len(start)):
        # sorted label list
        label_list = sorted(set(lithology[start[i]:finish[i]]),
                            key=lambda x: lithology[start[i]:finish[i]].index(x))
        new_label.append(r'/'.join(label_list))
    return new_label


def merging_index(depth, depth_json, tol=1e-12):
    r"""
    Function that produces the indexes of the merged layers by finding which depths are referred.
    """
    new_index = []

    for i in range(len(depth_json)):
        new_index.append(np.where(np.abs(depth_json[i] - np.array(depth)) <= tol)[0][0])

    return new_index


def merging_depth(depth, new_thickness):
    r"""
    Function that calculates the top level depth of each layer by summing the thicknesses.
    """
    new_depth = np.append(depth[0], new_thickness)
    new_depth = np.cumsum(new_depth)
    return new_depth


def merging_thickness(local_thick, min_layer_thick):
    r"""
     In this function the merging og the layers is achieved according to the min_layer thick.

     .._element:
     .. figure:: ./_static/Merge_Flowchart.png
         :width: 350px
         :align: center
         :figclass: align-center

     """

    new_thickness = []
    now_thickness = 0
    counter = 0
    while counter <= len(local_thick) - 1:
        while now_thickness < min_layer_thick:
            now_thickness += local_thick[counter]
            counter += 1
            if int(counter) == len(local_thick) and now_thickness < min_layer_thick:
                new_thickness[-1] += now_thickness
                return new_thickness
        new_thickness.append(now_thickness)
        now_thickness = 0
    return new_thickness


def add_json(jsn, id, depth_json, indx_json, lithology_json, data_cpt):
    """
    Add to json file the results.

    Parameters
    ----------
    :param jsn: Json data structure
    :param id: Scenario (index)
    """

    # create data
    data = {"lithology": [],
            "depth": [],
            "E": [],
            "v": [],
            "rho": [],
            "damping": [],
            "var_depth": [],
            "var_E": [],
            "var_v": [],
            "var_rho": [],
            "var_damping": [],
            }

    # populate structure
    for i in range(len(indx_json) - 1):
        # lithology
        data["lithology"].append(str(lithology_json[i]))
        # depth: variance is the same as for IC
        data["depth"].append(np.round(depth_json[i], 2))
        IC = data_cpt["IC"][indx_json[i]:indx_json[i + 1]]
        IC_var = data_cpt["IC_var"][indx_json[i]:indx_json[i + 1]]
        mean = np.mean(IC)
        var = np.mean(IC_var)
        new_var = var * (data_cpt["depth"][indx_json[i + 1]] - data_cpt["depth"][indx_json[i]]) / mean
        data["var_depth"].append(np.round(np.sqrt(new_var) / mean, 3))
        # Young modulus: variance same as G0. poisson is already accounted for in poisson
        E = 2. * data_cpt["G0"][indx_json[i]:indx_json[i + 1]] * (1. + data_cpt["poisson"][indx_json[i]:indx_json[i + 1]])
        E_var = data_cpt["G0_var"][indx_json[i]:indx_json[i + 1]] * E / data_cpt["G0"][indx_json[i]:indx_json[i + 1]]
        mean = np.mean(E)
        var = np.mean(E_var)
        data["E"].append(np.round(mean))
        data["var_E"].append(np.round(np.sqrt(var) / mean, 3))
        # poisson ratio
        poisson = data_cpt["poisson"][indx_json[i]:indx_json[i + 1]]
        poisson_var = data_cpt["poisson_var"][indx_json[i]:indx_json[i + 1]]
        mean = np.mean(poisson)
        var = np.mean(poisson_var)
        data["v"].append(np.round(mean, 3))
        data["var_v"].append(np.round(np.sqrt(var) / mean, 3))
        # density
        rho = data_cpt["rho"][indx_json[i]:indx_json[i + 1]]
        rho_var = data_cpt["rho_var"][indx_json[i]:indx_json[i + 1]]
        mean = np.mean(rho)
        var = np.mean(rho_var)
        data["rho"].append(np.round(mean))
        data["var_rho"].append(np.round(np.sqrt(var) / mean, 3))
        # damping
        damp = data_cpt["damping"][indx_json[i]:indx_json[i + 1]]
        damp_var = data_cpt["damping_var"][indx_json[i]:indx_json[i + 1]]
        mean = np.mean(damp)
        var = np.mean(damp_var)
        data["damping"].append(np.round(mean, 5))
        data["var_damping"].append(np.round(np.sqrt(var) / mean, 3))

    jsn["scenarios"].append({"Name": "Scenario " + str(id + 1)})
    jsn["scenarios"][id].update({"data": data})

    return jsn


def dump_json(jsn, index, output_folder):
    """
    Computes the probability of the scenario and dump json file into output file.

    Parameters
    ----------
    :param jsn: json file with data structure
    :param input_dic: dictionary with the input information
    :param index: index of the calculation point
    """

    # write file
    with open(os.path.join(output_folder, "results_" + str(index) + ".json"), "w") as fo:
        json.dump(jsn, fo, indent=2)
    return


def smooth(sig, window_len=10, lim=None):
    r"""
    Smooth signal

    It uses a moving average with window to smooth the signal

    :param sig: original signal
    :param window_len: (optional) number of samples for the smoothing window: default 10
    :param lim: (optional) limit the minimum value of the array: default None: does not apply limit.
    :return: smoothed signal
    """

    # if window length bigger that the size of the signal: window is the same size as the signal
    if window_len > len(sig):
        window_len = len(sig)

    s = np.r_[2 * sig[0] - sig[window_len:1:-1], sig, 2 * sig[-1] - sig[-1:-window_len:-1]]
    # constant window
    w = np.ones(window_len)
    # convolute signal
    y = np.convolve(w / w.sum(), s, mode='same')
    # limit the value is exits
    if lim is not None:
        y[y < lim] = lim
    return y[window_len - 1:-window_len + 1]