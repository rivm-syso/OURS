import numpy as np


def mapping(nodes, bounds):
    """
    Assign each degree of freedom of each node to an equation number

    :param nodes: (float) array [NP, 2] with the radial and vertical coordinate of each node (NP: total number of nodes)
    :param bounds: (int) parameter to determine the set of boundary conditions
        bounds == 0: left = symmetric, bottom = fixed, right = free
        bounds == 1: left = symmetric, bottom = fixed, right = infinite
        bounds == 2: left = symmetric, bottom = infinite, right = infinite
        bounds == 3: left = symmetric, bottom = infinite, right = infinite
    :return: node_id: (int) array [NP, 2] with the equation number of the radial and vertical displacement of each node
    """

    # initiate node_id as 1 and set each entry referring to a fixed dof to 0
    node_id = np.ones(shape=nodes.shape, dtype=int)
    node_id[np.where(nodes[:, 0] == 0), 0] = 0
    if bounds == 0 or bounds == 1:
        node_id[np.where(nodes[:, 1] == min(nodes[:, 1])), :] = 0

    # Go through each dof and add 1 to neq (total number of equations)
    # Replace each 1 in node_id with the corresponding equation number
    neq = 0
    for i1 in range(node_id.shape[0]):
        for i2 in range(node_id.shape[1]):
            if node_id[i1, i2]:
                neq += 1
                node_id[i1, i2] = neq

    # Refer each fixed dof to neq + 1. After concatenating a 0 to the resulting vector, these entries will refer to that 0
    node_id[np.where(node_id == 0)] = neq + 1

    # In python indexing starts with 0 (not with 1 as in Matlab in which the code in initially written)
    node_id = node_id - 1

    return node_id


def connectivity(elements, node_id):
    """
    Determine the equation numbers of each dof in each element (i.e. connectivity matrix)

    :param elements: (int) array [NE, 4] with the node numbers of each finite element corner (NE: total number of elements)
    :param node_id: (int) array [NP, 2] with the equation number of the radial and vertical displacement of each node (NP: total number of nodes)
    :return: elem_id: (int) array [NE, 8] with the equation number of each dof in each element
    """

    # For each element collect the equation number of each dof from node_id and fill elem_id with these numbers
    elem_id = np.ones(shape=(elements.shape[0], elements.shape[1]*2), dtype=int)
    for i1, element in enumerate(elements):
        elem_id[i1] = np.reshape(node_id[element, :], (1, elements.shape[1]*2))

    return elem_id


