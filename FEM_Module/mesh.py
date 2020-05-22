import numpy as np
from wave_velocity import *


def element_size(data):
    data["MaxFreqLimited"] = data["HighFreq"]
    max_elem_size = [0] * data["NumLayers"]
    for i1 in range(data["NumLayers"]):
        max_elem_size[i1] = s_wave_velocity(data["Ground"]["E"][i1],
                                            data["Ground"]["v"][i1],
                                            data["Ground"]["rho"][i1])/data["ElementsPerWave"]/data["HighFreq"]
        if max_elem_size[i1] < data["MinElementSize"]:
            data["MaxFreqLimited"] = min(data["MaxFreqLimited"],
                                         data["HighFreq"]*max_elem_size[i1]/data["MinElementSize"])
            max_elem_size[i1] = data["MinElementSize"]

    return max_elem_size


def elements_per_layer(data, max_elem_size):
    elem_count = [[0 for i2 in range(2)] for i1 in range(data["NumLayers"])]
    dr = data["MaxCalcDist"]/math.floor(data["MaxCalcDist"]/min(max_elem_size))
    for i1 in range(data["NumLayers"]):
        elem_count[i1][0] = int(data["MaxCalcDist"]/dr)
        elem_count[i1][1] = max([math.floor(data["Ground"]["Thickness"][i1]/max_elem_size[i1]), 1])
        dz = data["Ground"]["Thickness"][i1]/elem_count[i1][1]
        dz = max(dz, dr/data["MaxElementRatio"])
        dz = min(dz, dr*data["MaxElementRatio"])
        elem_count[i1][1] = int(max(1, data["Ground"]["Thickness"][i1]/dz))

    return elem_count


def node_coordinates(data, elem_count):
    total_nodes_in_r = elem_count[0][0] + 1
    total_nodes_in_z = sum(i[1] for i in elem_count) + 1
    total_nodes = total_nodes_in_r*total_nodes_in_z

    nodes = np.zeros(shape=(total_nodes, 2))
    r_coordinates = np.linspace(0, data["MaxCalcDist"], total_nodes_in_r)
    z_coordinates = np.array([])
    z0 = 0
    for i1 in range(data["NumLayers"]):
        z_coordinates = np.append(z_coordinates, np.linspace(z0, z0-data["Ground"]["Thickness"][i1],
                                                             elem_count[i1][1], endpoint=False))
        z0 -= data["Ground"]["Thickness"][i1]

    z_coordinates = np.append(z_coordinates, -np.sum(data["Ground"]["Thickness"]))

    n = 0
    for i1 in range(total_nodes_in_z):
        for i2 in range(total_nodes_in_r):
            nodes[n] = [r_coordinates[i2], z_coordinates[i1]]
            n += 1

    return nodes


def elem_nodes(elem_count):
    total_elem_in_r = elem_count[0][0]
    total_elem_in_z = sum(i[1] for i in elem_count)
    total_elem = total_elem_in_r*total_elem_in_z
    total_nodes_in_r = total_elem_in_r + 1

    elements = np.zeros(shape=(total_elem, 4), dtype=int)
    n = 0
    for layer, n_elem in enumerate(elem_count):
        first_layer_node = total_nodes_in_r*sum(i[1] for i in elem_count[0:layer])
        for cen in range(elem_count[layer][0]):
            first_col_node = first_layer_node + cen + 1
            for ren in range(elem_count[layer][1]):
                first_elem_node = first_col_node + ren*(total_elem_in_r + 1)
                elements[n] = np.add(first_elem_node, [total_elem_in_r, total_elem_in_r + 1, 0, -1])
                n = n + 1
    return elements
