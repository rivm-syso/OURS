import numpy as np
from scipy.sparse import csr_matrix
from book_keeping import connectivity
from wave_velocity import *
import math


def lumped_mass_matrix(nodes, elements, elem_id, data, elem_count):
    """
    Assemble the global lumped mass matrix

    :param nodes: (float) array [NP, 2] with the radial and vertical coordinate of each node (NP: total number of nodes)
    :param elements: (int) array [NE, 4] with the node numbers of each finite element corner (NE: total number of elements)
    :param elem_id: (int) array [NE, 8] with the equation number of each dof in each element
    :param data: (dict) with FEM input parameters
    :param elem_count: (int) array [NL, 2] with number of elements in radial and vertical direction of each soil layer (NL: total number of layers)
    :return: lumped_mass: (float) array [NEQ] with diagonal components of the lumped mass matrix (NEQ: total number of equations)
    """

    # allocated lumped_mass
    lumped_mass = np.zeros(shape=(np.max(elem_id)+1), dtype=float)

    n = 0
    for i1 in range(data["NumLayers"]):  # in each soil layer
        rho = data["Ground"]["rho"][i1]    # the mass density is constant
        for i2 in range(elem_count[0][0]):   # and the element mass matrix only depends on the radius (R)
            elem_mass = elem_mass_matrix(nodes[elements[n]], rho, 3)  # so determine this only once for each R
            for i3 in range(elem_count[i1][1]):                         # and assemble it for all elements in Z
                lumped_mass[elem_id[n]] = lumped_mass[elem_id[n]] + elem_mass
                n += 1

    # delete the entries that are fixed
    lumped_mass = np.delete(lumped_mass, -1, 0)

    return lumped_mass


def consistent_mass_matrix(nodes, elements, elem_id, data, elem_count):
    """
    Assemble the global consistent mass matrix

    :param nodes: (float) array [NP, 2] with the radial and vertical coordinate of each node (NP: total number of nodes)
    :param elements: (int) array [NE, 4] with the node numbers of each finite element corner (NE: total number of elements)
    :param elem_id: (int) array [NE, 8] with the equation number of each dof in each element
    :param data: (dict) with FEM input parameters
    :param elem_count: (int) array [NL, 2] with number of elements in radial and vertical direction of each soil layer (NL: total number of layers)
    :return: (float) csr_matrix [NEQ, NEQ] with the global consistent mass matrix (NEQ: total number of equations)
    """

    # Initializing data to assemble the sparse matrix
    nnz = elements.shape[0]*32
    row = np.zeros(shape=[nnz], dtype=int)
    col = np.zeros(shape=[nnz], dtype=int)
    val = np.zeros(shape=[nnz], dtype=float)

    n = 0
    m = 0
    for i1 in range(data["NumLayers"]):  # in each soil layer
        rho = data["Ground"]["rho"][i1]    # the mass density is constant
        for i2 in range(elem_count[0][0]):   # and the element mass matrix only depends on the radius (R)
            elem_mass = elem_mass_matrix(nodes[elements[n]], rho, 2)  # so determine this only once for each R
            for i3 in range(elem_count[i1][1]):                         # and assemble it for all elements in Z
                # first assemble the components in radial direction
                row[m:m + 16] = elem_id[n, [0, 2, 4, 6, 0, 2, 4, 6, 0, 2, 4, 6, 0, 2, 4, 6]]
                col[m:m + 16] = elem_id[n, [0, 0, 0, 0, 2, 2, 2, 2, 4, 4, 4, 4, 6, 6, 6, 6]]
                val[m:m + 16] = elem_mass
                m += 16
                # then assemble the same components in vertical direction
                row[m:m + 16] = elem_id[n, [1, 3, 5, 7, 1, 3, 5, 7, 1, 3, 5, 7, 1, 3, 5, 7]]
                col[m:m + 16] = elem_id[n, [1, 1, 1, 1, 3, 3, 3, 3, 5, 5, 5, 5, 7, 7, 7, 7]]
                val[m:m + 16] = elem_mass
                m += 16
                n += 1

    neq = elem_id.max()
    # delete the entries that are fixed
    to_delete = np.where((row == np.max(row)) | (col == np.max(col)))
    row = np.delete(row, to_delete, 0)
    col = np.delete(col, to_delete, 0)
    val = np.delete(val, to_delete, 0)

    consistent_mass = csr_matrix((val, (row, col)), shape=(neq, neq))
    return consistent_mass


def elem_mass_matrix(xyz, rho, elem_type):
    """
    Construct the mass matrix for a 4-noded axi-symmetric element

    :param xyz: (float) array [4, 2] with the radial and vertical coordinate of each node of the element
    :param rho: (float) mass density in the element
    :param elem_type: (int) parameter to determine the consistency of the mass
        elem_type == 1: consistent mass matrix with integration points at nodes
        elem_type == 2: consistent mass matrix with exact numerical integration
        elem_type == 3: lumped mass matrix obtained by summing rows of consistent mass matrix with exact integration
        elem_type == 4: consistent mass matrix obtained with 1 integration point
        elem_type == 5: lumped mass matrix obtained by summing rows of consistent mass matrix with 1 integration point
    :return:
    """

    r0 = xyz[0][0]
    r1 = xyz[1][0]
    b = xyz[3][1] - xyz[0][1]
    if elem_type == 1:
        fac = ((r1 - r0) * b / 4) * rho
        elem_mass = np.zeros(shape=8, dtype='float')
        elem_mass[[0, 1, 6, 7]] = r0 * fac
        elem_mass[[2, 3, 4, 5]] = r1 * fac
    elif elem_type == 2:
        fac = ((r1 - r0) * b/72) * rho
        elem_mass = np.zeros(shape=16, dtype='float')
        elem_mass[[0, 15]] = (6*r0 + 2*r1) * fac
        elem_mass[[1, 4, 11, 14]] = (2*r0 + 2*r1) * fac
        elem_mass[[2, 7, 8, 13]] = (r0 + r1) * fac
        elem_mass[[3, 12]] = (3*r0 + r1) * fac
        elem_mass[[5, 10]] = (2*r0 + 6*r1) * fac
        elem_mass[[6, 9]] = (r0 + 3*r1) * fac
    elif elem_type == 3:
        fac = ((r1 - r0) * b/12) * rho
        elem_mass = np.zeros(shape=8, dtype='float')
        elem_mass[[0, 1, 6, 7]] = (2*r0 + r1) * fac
        elem_mass[[2, 3, 4, 5]] = (r0 + 2*r1) * fac
    elif elem_type == 4:
        elem_mass = np.ones(shape=16, dtype='float') * ((r1 - r0) * (r1 + r0) * b/128) * rho
    elif elem_type == 5:
        elem_mass = np.ones(shape=8, dtype='float') * ((r1 - r0) * (r1 + r0) * b/32)*rho
    else:
        elem_mass = -1

    return elem_mass


def glob_stiff_matrix(nodes, elements, elem_id, data, elem_count):
    nnz = elements.shape[0]*64
    row = np.zeros(shape=[nnz], dtype=int)
    col = np.zeros(shape=[nnz], dtype=int)
    val = np.zeros(shape=[nnz], dtype=float)

    n = 0
    m = 0
    row_i = np.tile(np.arange(8), 8)
    col_i = np.transpose(np.tile(np.arange(8), (8, 1))).reshape((1, 64))
    for i1 in range(data["NumLayers"]):
        e = data["Ground"]["E"][i1]
        nu = data["Ground"]["v"][i1]
        for i2 in range(elem_count[0][0]):
            elem_stiff = elem_stiff_matrix(nodes[elements[n]], e, nu)
            for i3 in range(elem_count[i1][1]):
                row[m:m + 64] = elem_id[n, row_i]
                col[m:m + 64] = elem_id[n, col_i]
                val[m:m + 64] = elem_stiff
                m += 64
                n += 1

    neq = elem_id.max()
    to_delete = np.where((row == np.max(row)) | (col == np.max(col)))
    row = np.delete(row, to_delete, 0)
    col = np.delete(col, to_delete, 0)
    val = np.delete(val, to_delete, 0)
    glob_stiff = csr_matrix((val, (row, col)), shape=(neq, neq))

    return glob_stiff


def hyst_damp_matrix(nodes, elements, elem_id, data, elem_count):
    nnz = elements.shape[0] * 64
    row = np.zeros(shape=[nnz], dtype=int)
    col = np.zeros(shape=[nnz], dtype=int)
    val = np.zeros(shape=[nnz], dtype=float)

    n = 0
    m = 0
    row_i = np.tile(np.arange(8), 8)
    col_i = np.transpose(np.tile(np.arange(8), (8, 1))).reshape((1, 64))
    for i1 in range(data["NumLayers"]):
        e = data["Ground"]["E"][i1]
        nu = data["Ground"]["v"][i1]
        eta = data["Ground"]["damping"][i1] * 2
        for i2 in range(elem_count[0][0]):
            elem_stiff = elem_stiff_matrix(nodes[elements[n]], e, nu)
            for i3 in range(elem_count[i1][1]):
                row[m:m + 64] = elem_id[n, row_i]
                col[m:m + 64] = elem_id[n, col_i]
                val[m:m + 64] = elem_stiff*eta
                m += 64
                n += 1

    neq = elem_id.max()
    to_delete = np.where((row == np.max(row)) | (col == np.max(col)))
    row = np.delete(row, to_delete, 0)
    col = np.delete(col, to_delete, 0)
    val = np.delete(val, to_delete, 0)
    hyst_damp = csr_matrix((val, (row, col)), shape=(neq, neq))

    return hyst_damp


def elem_stiff_matrix(xyz, e, nu):
    r0 = xyz[0][0]
    r1 = xyz[1][0]
    b = xyz[3][1] - xyz[0][1]
    elem_stiff = np.zeros(shape=64, dtype='float')

    efac = e / (1 + nu) / (1 - 2 * nu)
    fac1 = efac / (24 * b * (-r0**4 - 4 * r0**3 * r1 + 4 * r0 * r1**3 + r1**4))
    fac2 = efac / (24 * (r0 + r1))
    fac3 = efac / (36 * b * (r0**2 - r1**2))
    fac4 = fac3 / 2
    fac5 = (1 - 2 * nu)
    r0_2 = r0**2
    r0_4 = r0**4
    r1_2 = r1**2
    r1_4 = r1**4
    r01 = r0 * r1
    nu_2 = nu**2
    b_2 = b**2

    elem_stiff[0] = fac1 * (r0_4 * (10 * fac5 * r01 - 9 * fac5 * r1_2 + (7 - 2 * nu_2 - nu) * b_2 + 3 * fac5 * r0_2) +
                            r1_4 * ((9 - 2 * nu_2 - 15 * nu) * b_2 + 5 * fac5 * r0_2 + 6 * fac5 * r01 + fac5 * r1_2) +
                            r0_2 * ((30 - 12 * nu_2 - 6 * nu) * r01 * b_2 + (24 - 24 * nu - 20 * nu_2) * r1_2 * b_2 -
                                    16 * fac5 * r0 * r1**3) +
                            r1_2 * (26 - 12 * nu_2 - 50 * nu) * r01 * b_2)
    elem_stiff[1] = fac2 * (2 * r0 + r1) * (r0 * (1 + 2 * nu) + r1 * fac5)
    elem_stiff[2] = fac1 * (r0_4 * ((2 * nu_2 + nu - 1) * b_2 + fac5 * r0_2 - fac5 * r1_2 + 4 * fac5 * r01) +
                            r1_4 * ((2 * nu_2 + nu - 1) * b_2 - fac5 * r0_2 + 4 * fac5 * r01 + fac5 * r1_2) +
                            r0_2 * ((12 * nu_2 + 20 * nu - 20) * b_2 * r01 +
                                    (20 * b_2 * nu_2 + 54 * b_2 * nu + 16 * nu * r01) * r1_2) +
                            r1_2 * ((12 * nu_2 + 20 * nu - 20) * b_2 * r01 - (54 * b_2 + 8 * r01) * r0_2))
    elem_stiff[3] = fac2 * (r0_2 * (8 * nu - 2) + r01 * (14 * nu - 3) - r1_2 * fac5)
    elem_stiff[4] = fac1 * (r0_4 * ((1 - 2 * nu_2 - nu) * b_2 - fac5 * r0_2 - 4 * fac5 * r01 + fac5 * r1_2) +
                            r1_4 * ((1 - 2 * nu_2 - nu) * b_2 + fac5 * r0_2 - 4 * fac5 * r01 - fac5 * r1_2) +
                            r0_2 * ((4 * nu - 12 * nu_2 - 4) * b_2 * r01 + (42 * nu - 20 * nu_2) * b_2 * r1_2 -
                                    16 * nu * r0 * r1**3) +
                            r1_2 * ((4 * nu - 12 * nu_2 - 4) * b_2 * r01 + (8 * r01 - 42 * b_2) * r0_2))
    elem_stiff[5] = fac2 * (-r1_2 * fac5 - r01 * (3 + 2 * nu) - 2 * r0_2)
    elem_stiff[6] = fac1 * (r0_4 * ((2 * nu_2 + nu + 5) * b_2 - 3 * fac5 * r0_2 - 10 * fac5 * r01 + 9 * fac5 * r1_2) +
                            r1_4 * ((2 * nu_2 - 9 * nu + 3) * b_2 - 5 * fac5 * r0_2 - 6 * fac5 * r01 - fac5 * r1_2) +
                            r0_2 * ((12 * nu_2 + 6 * nu + 18) * b_2 * r01 + (20 * b_2 * nu_2 - 32 * nu * r01) * r1_2) +
                            r1_2 * ((12 * nu_2 - 46 * nu + 22) * b_2 * r01 + 16 * r0**3 * r1))
    elem_stiff[7] = fac2 * (2 * r0 + r1) * (r0 * (1 - 6 * nu) + r1 * fac5)

    elem_stiff[8] = elem_stiff[1]
    elem_stiff[9] = fac3 * (r0_4 * (2 * nu_2 + 9 * nu - 9) +
                            r1_4 * (2 * nu_2 + 3 * nu - 3) +
                            r0_2 * (-3 * fac5 * b_2 + (4 * nu_2 - 6 * nu + 6) * r01 + (12 - 12 * nu_2) * r1_2) +
                            r1_2 * (-3 * fac5 * b_2 + (4 * nu_2 + 6 * nu - 6) * r01 - 12 * nu * r0_2) -
                            6 * r01 * fac5 * b_2)
    elem_stiff[10] = fac2 * (r0_2 * fac5 + r01 * (3 - 14 * nu) + r1_2 * (2 - 8 * nu))
    elem_stiff[11] = fac3 * (r0_4 * (3 * nu - 2 * nu_2 - 3) +
                             r1_4 * (3 * nu - 2 * nu_2 - 3) +
                             r0_2 * (3 * fac5 * b_2 - 4 * nu_2 * r01 + (6 + 12 * nu_2) * r1_2) +
                             r1_2 * (3 * fac5 * b_2 - 4 * nu_2 * r01 - 6 * nu * r0_2) +
                             r01 * 6 * fac5 * b_2)
    elem_stiff[12] = fac2 * (-r0_2 * fac5 - r01 * (3 + 2 * nu) - 2 * r1_2)
    elem_stiff[13] = fac4 * (r0_4 * (4 * nu_2 - 6 * nu + 6) +
                             r1_4 * (4 * nu_2 - 6 * nu + 6) +
                             r0_2 * (3 * fac5 * b_2 + 8 * nu_2 * r01 - (24 * nu_2 + 12) * r1_2) +
                             r1_2 * (3 * fac5 * b_2 + 8 * nu_2 * r01 + 12 * nu * r0_2) +
                             r01 * 6 * fac5 * b_2)
    elem_stiff[14] = -elem_stiff[7]
    elem_stiff[15] = fac4 * (r0_4 * (18 - 4 * nu_2 - 18 * nu) +
                             r1_4 * (6 - 4 * nu_2 - 6 * nu) +
                             r0_2 * (-3 * fac5 * b_2 + (12 * nu - 8 * nu_2 - 12) * r01 + 24 * nu * (nu + 1) * r1_2) +
                             r1_2 * (-3 * fac5 * b_2 + (12 - 8 * nu_2 - 12 * nu) * r01 - 24 * r0_2) -
                             r01 * 6 * fac5 * b_2)

    elem_stiff[16] = elem_stiff[2]
    elem_stiff[17] = elem_stiff[10]
    elem_stiff[18] = fac1 * (r0_4 * ((9 - 2 * nu_2 - 15 * nu) * b_2 + fac5 * r0_2 + 6 * fac5 * r01 + 5 * fac5 * r1_2) +
                             r1_4 * ((7 - 2 * nu_2 - nu) * b_2 - 9 * fac5 * r0_2 + 10 * fac5 * r01 + 3 * fac5 * r1_2) +
                             r0_2 * ((26 - 50 * nu - 12 * nu_2) * b_2 * r01 +
                                     (32 * nu * r01 - 20 * b_2 * nu_2 - 24 * b_2 * nu) * r1_2) +
                             r1_2 * ((30 - 12 * nu_2 - 6 * nu) * b_2 * r01 + (24 * b_2 - 16 * r01) * r0_2))
    elem_stiff[19] = -fac2 * (r0 + 2 * r1) * (r0 * fac5 + r1 * (1 + 2 * nu))
    elem_stiff[20] = fac1 * (r0_4 * ((2 * nu_2 - 9 * nu + 3) * b_2 - fac5 * r0_2 - 6 * fac5 * r01 - 5 * fac5 * r1_2) +
                             r1_4 * ((2 * nu_2 + nu + 5) * b_2 + 9 * fac5 * r0_2 - 10 * fac5 * r01 - 3 * fac5 * r1_2) +
                             r0_2 * ((12 * nu_2 - 46 * nu + 22) * b_2 * r01 +
                                     (20 * b_2 * nu_2 - 32 * nu * r01) * r1_2) +
                             r1_2 * ((12 * nu_2 + 6 * nu + 18) * b_2 * r01 + 16 * r0**3 * r1))
    elem_stiff[21] = -fac2 * (r0 + 2 * r1) * (r0 * fac5 + r1 * (1 - 6 * nu))
    elem_stiff[22] = elem_stiff[4]
    elem_stiff[23] = -elem_stiff[12]

    elem_stiff[24] = elem_stiff[3]
    elem_stiff[25] = elem_stiff[11]
    elem_stiff[26] = elem_stiff[19]
    elem_stiff[27] = fac3 * (r0_4 * (2 * nu_2 + 3 * nu - 3) +
                             r1_4 * (2 * nu_2 + 9 * nu - 9) +
                             r0_2 * (-3 * fac5 * b_2 + (4 * nu_2 + 6 * nu - 6) * r01 + 12 * (1 - nu_2) * r1_2) +
                             r1_2 * (-3 * fac5 * b_2 + (4 * nu_2 - 6 * nu + 6) * r01 - 12 * nu * r0_2) -
                             r01 * 6 * fac5 * b_2)
    elem_stiff[28] = -elem_stiff[21]
    elem_stiff[29] = fac4 * (r0_4 * (6 - 4 * nu_2 - 6 * nu) +
                             r1_4 * (18 - 4 * nu_2 - 18 * nu) +
                             r0_2 * (-3 * fac5 * b_2 + (12 - 8 * nu_2 - 12 * nu) * r01 + 24 * (nu_2 - 1) * r1_2) +
                             r1_2 * (-3 * fac5 * b_2 + (12 * nu - 8 * nu_2 - 12) * r01 + 24 * nu * r0_2) -
                             r01 * 6 * fac5 * b_2)
    elem_stiff[30] = -elem_stiff[5]
    elem_stiff[31] = elem_stiff[13]

    elem_stiff[32] = elem_stiff[4]
    elem_stiff[33] = elem_stiff[12]
    elem_stiff[34] = elem_stiff[20]
    elem_stiff[35] = elem_stiff[28]
    elem_stiff[36] = elem_stiff[18]
    elem_stiff[37] = -elem_stiff[19]
    elem_stiff[38] = elem_stiff[2]
    elem_stiff[39] = -elem_stiff[10]

    elem_stiff[40] = elem_stiff[5]
    elem_stiff[41] = elem_stiff[13]
    elem_stiff[42] = elem_stiff[21]
    elem_stiff[43] = elem_stiff[29]
    elem_stiff[44] = elem_stiff[37]
    elem_stiff[45] = elem_stiff[27]
    elem_stiff[46] = -elem_stiff[3]
    elem_stiff[47] = elem_stiff[11]

    elem_stiff[48] = elem_stiff[6]
    elem_stiff[49] = elem_stiff[14]
    elem_stiff[50] = elem_stiff[22]
    elem_stiff[51] = elem_stiff[30]
    elem_stiff[52] = elem_stiff[38]
    elem_stiff[53] = elem_stiff[46]
    elem_stiff[54] = elem_stiff[0]
    elem_stiff[55] = -elem_stiff[1]

    elem_stiff[56] = elem_stiff[7]
    elem_stiff[57] = elem_stiff[15]
    elem_stiff[58] = elem_stiff[23]
    elem_stiff[59] = elem_stiff[31]
    elem_stiff[60] = elem_stiff[39]
    elem_stiff[61] = elem_stiff[47]
    elem_stiff[62] = elem_stiff[55]
    elem_stiff[63] = elem_stiff[9]

    return elem_stiff


def inf_stiff_matrix(nodes, node_id, data, elem_count, etype):
    neq = node_id.max()
    inf_stiff = csr_matrix((neq, neq), dtype=float)
    if data["Bounds"] == 0:
        return inf_stiff

    if etype:
        nzpe = 8
        row_i = [0, 0, 1, 1, 2, 2, 3, 3]
        col_i = [0, 2, 1, 3, 0, 2, 1, 3]
    else:
        nzpe = 4
        row_i = [0, 1, 2, 3]
        col_i = [0, 1, 2, 3]

    elem_stiff = np.zeros(shape=nzpe, dtype='float')
    idx_array = np.array([0, 1])
    if data["Bounds"] == 1 | data["Bounds"] == 3:
        total_elem_in_r = elem_count[0][0]
        total_elem_in_z = sum(i[1] for i in elem_count)
        elements = np.zeros(shape=(total_elem_in_z, 2), dtype=int)
        for i1 in range(total_elem_in_z):
            elements[i1, :] = (idx_array + i1 + 1)*(total_elem_in_r + 1) - 1

        elem_id = connectivity(elements, node_id)

        nnz = elements.shape[0]*nzpe
        row = np.zeros(shape=[nnz], dtype=int)
        col = np.zeros(shape=[nnz], dtype=int)
        val = np.zeros(shape=[nnz], dtype=float)

        n = 0
        m = 0
        r = nodes[elements[0, 0], 0]
        for i1 in range(data["NumLayers"]):
            vs = s_wave_velocity(data["Ground"]["E"][i1],
                                 data["Ground"]["v"][i1],
                                 data["Ground"]["rho"][i1])
            vp = p_wave_velocity(data["Ground"]["E"][i1],
                                 data["Ground"]["v"][i1],
                                 data["Ground"]["rho"][i1])
            ds = vs**2 * data["Ground"]["rho"][i1] / 2
            dp = vp**2 * data["Ground"]["rho"][i1] / 2
            for i2 in range(elem_count[i1][1]):
                b0 = nodes[elements[n, 0], 1]
                b1 = nodes[elements[n, 1], 1]
                rb = r * abs(b0 - b1)
                if etype:
                    sqrt3 = math.sqrt(3)
                    fac1 = math.sqrt((b0 * (sqrt3 + 3) - b1 * (sqrt3 - 3))**2 + 36 * r**2)
                    fac2 = math.sqrt((b0 * (sqrt3 - 3) - b1 * (sqrt3 + 3))**2 + 36 * r**2)
                    elem_stiff[0] = dp * rb * ((sqrt3 / 2 + 1) / fac1 - (sqrt3 / 2 - 1) / fac2)
                    elem_stiff[1] = dp * rb * (1 / fac1 + 1 / fac2) / 2
                    elem_stiff[2] = ds * rb * ((sqrt3 / 2 + 1) / fac1 - (sqrt3 / 2 - 1) / fac2)
                    elem_stiff[3] = ds * rb * (1 / fac1 + 1 / fac2) / 2
                    elem_stiff[4] = elem_stiff[1]
                    elem_stiff[5] = dp * rb * ((sqrt3 / 2 + 1) / fac2 - (sqrt3 / 2 - 1) / fac1)
                    elem_stiff[6] = elem_stiff[3]
                    elem_stiff[7] = ds * rb * ((sqrt3 / 2 + 1) / fac2 - (sqrt3 / 2 - 1) / fac1)
                else:
                    elem_stiff[0] = dp * rb / 2 / math.sqrt(b0**2 + r**2)
                    elem_stiff[1] = ds * rb / 2 / math.sqrt(b0**2 + r**2)
                    elem_stiff[2] = dp * rb / 2 / math.sqrt(b1**2 + r**2)
                    elem_stiff[3] = ds * rb / 2 / math.sqrt(b1**2 + r**2)

                row[m:m + nzpe] = elem_id[n, row_i]
                col[m:m + nzpe] = elem_id[n, col_i]
                val[m:m + nzpe] = elem_stiff
                m += nzpe
                n += 1

        to_delete = np.where((row == neq) | (col == neq))
        row = np.delete(row, to_delete, 0)
        col = np.delete(col, to_delete, 0)
        val = np.delete(val, to_delete, 0)
        inf_stiff = inf_stiff + csr_matrix((val, (row, col)), shape=(neq, neq))

    if data["Bounds"] == 2 | data["Bounds"] == 3:
        total_elem_in_r = elem_count[0][0]
        total_elem_in_z = sum(i[1] for i in elem_count)
        elements = np.zeros(shape=(total_elem_in_r, 2), dtype=int)
        for i1 in range(total_elem_in_r):
            elements[i1, :] = idx_array + (total_elem_in_r + 1) * total_elem_in_z + i1

        elem_id = connectivity(elements, node_id)

        nnz = elements.shape[0] * nzpe
        row = np.zeros(shape=[nnz], dtype=int)
        col = np.zeros(shape=[nnz], dtype=int)
        val = np.zeros(shape=[nnz], dtype=float)

        vs = s_wave_velocity(data["Ground"]["E"][-1],
                             data["Ground"]["v"][-1],
                             data["Ground"]["rho"][-1])
        vp = p_wave_velocity(data["Ground"]["E"][-1],
                             data["Ground"]["v"][-1],
                             data["Ground"]["rho"][-1])
        ds = vs**2 * data["Ground"]["rho"][-1] / 2
        dp = vp**2 * data["Ground"]["rho"][-1] / 2

        m = 0
        b = nodes[elements[0, 0], 1]
        for i1 in range(elem_count[0][0]):
            r0 = nodes[elements[i1, 0], 0]
            r1 = nodes[elements[i1, 1], 0]
            r01 = abs(r1 - r0)
            if etype:
                sqrt3 = math.sqrt(3)
                fac1 = math.sqrt(36 * b**2 + (r0 * (sqrt3 + 3) - r1 * (sqrt3 - 3))**2)
                fac2 = math.sqrt(36 * b**2 + (r0 * (sqrt3 - 3) - r1 * (sqrt3 + 3))**2)
                elem_stiff[0] = ds * r01 * (((9 + 5 * sqrt3) * r0 + (3 + sqrt3) * r1) / fac1 +
                                            ((9 - 5 * sqrt3) * r0 + (3 - sqrt3) * r1) / fac2) / 12
                elem_stiff[1] = ds * r01 * (((3 - sqrt3) * r0 + (3 + sqrt3) * r1) / fac2 +
                                            ((3 + sqrt3) * r0 + (3 - sqrt3) * r1) / fac1) / 12
                elem_stiff[2] = dp * r01 * (((9 + 5 * sqrt3) * r0 + (3 + sqrt3) * r1) / fac1 +
                                            ((9 - 5 * sqrt3) * r0 + (3 - sqrt3) * r1) / fac2) / 12
                elem_stiff[3] = dp * r01 * (((3 - sqrt3) * r0 + (3 + sqrt3) * r1) / fac2 +
                                            ((3 + sqrt3) * r0 + (3 - sqrt3) * r1) / fac1) / 12
                elem_stiff[4] = elem_stiff[1]
                elem_stiff[5] = ds * r01 * (((3 + sqrt3) * r0 + (9 + 5 * sqrt3) * r1) / fac2 -
                                            ((sqrt3 - 3) * r0 + (5 * sqrt3 - 9) * r1) / fac1) / 12
                elem_stiff[6] = elem_stiff[3]
                elem_stiff[7] = dp * r01 * (((3 + sqrt3) * r0 + (9 + 5 * sqrt3) * r1) / fac2 -
                                            ((sqrt3 - 3) * r0 + (5 * sqrt3 - 9) * r1) / fac1) / 12
            else:
                elem_stiff[0] = ds * r0 * r01 / math.sqrt(b**2 + r0**2) / 2
                elem_stiff[1] = dp * r0 * r01 / math.sqrt(b**2 + r0**2) / 2
                elem_stiff[2] = ds * r1 * r01 / math.sqrt(b**2 + r1**2) / 2
                elem_stiff[3] = dp * r1 * r01 / math.sqrt(b**2 + r1**2) / 2

            row[m:m + nzpe] = elem_id[i1, row_i]
            col[m:m + nzpe] = elem_id[i1, col_i]
            val[m:m + nzpe] = elem_stiff
            m += nzpe

        to_delete = np.where((row == neq) | (col == neq))
        row = np.delete(row, to_delete, 0)
        col = np.delete(col, to_delete, 0)
        val = np.delete(val, to_delete, 0)
        inf_stiff = inf_stiff + csr_matrix((val, (row, col)), shape=(neq, neq))

    return inf_stiff


def inf_damp_matrix(nodes, node_id, data, elem_count, etype):
    neq = node_id.max()
    inf_damp = csr_matrix((neq, neq), dtype=float)
    if data["Bounds"] == 0:
        return inf_damp

    if etype:
        nzpe = 8
        row_i = [0, 0, 1, 1, 2, 2, 3, 3]
        col_i = [0, 2, 1, 3, 0, 2, 1, 3]
    else:
        nzpe = 4
        row_i = [0, 1, 2, 3]
        col_i = [0, 1, 2, 3]

    elem_damp = np.zeros(shape=nzpe, dtype='float')
    idx_array = np.array([0, 1])
    if data["Bounds"] == 1 | data["Bounds"] == 3:
        total_elem_in_r = elem_count[0][0]
        total_elem_in_z = sum(i[1] for i in elem_count)
        elements = np.zeros(shape=(total_elem_in_z, 2), dtype=int)
        for i1 in range(total_elem_in_z):
            elements[i1, :] = (idx_array + i1 + 1) * (total_elem_in_r + 1) - 1

        elem_id = connectivity(elements, node_id)

        nnz = elements.shape[0] * nzpe
        row = np.zeros(shape=[nnz], dtype=int)
        col = np.zeros(shape=[nnz], dtype=int)
        val = np.zeros(shape=[nnz], dtype=float)

        n = 0
        m = 0
        for i1 in range(data["NumLayers"]):
            vs = s_wave_velocity(data["Ground"]["E"][i1],
                                 data["Ground"]["v"][i1],
                                 data["Ground"]["rho"][i1])
            vp = p_wave_velocity(data["Ground"]["E"][i1],
                                 data["Ground"]["v"][i1],
                                 data["Ground"]["rho"][i1])
            ds = vs * data["Ground"]["rho"][i1]
            dp = vp * data["Ground"]["rho"][i1]
            rb = nodes[elements[n, 0], 0] * abs(nodes[elements[n, 0], 1] - nodes[elements[n, 1], 1])
            if etype:
                elem_damp[0] = dp * rb / 3
                elem_damp[1] = elem_damp[0] / 2
                elem_damp[2] = ds * rb / 3
                elem_damp[3] = elem_damp[2] / 2
                elem_damp[4:8] = elem_damp[[1, 0, 3, 2]]
            else:
                elem_damp[0] = dp * rb / 2
                elem_damp[1] = ds * rb / 2
                elem_damp[2] = elem_damp[0]
                elem_damp[3] = elem_damp[1]

            for i2 in range(elem_count[i1][1]):
                row[m:m + nzpe] = elem_id[n, row_i]
                col[m:m + nzpe] = elem_id[n, col_i]
                val[m:m + nzpe] = elem_damp
                m += nzpe
                n += 1

        to_delete = np.where((row == neq) | (col == neq))
        row = np.delete(row, to_delete, 0)
        col = np.delete(col, to_delete, 0)
        val = np.delete(val, to_delete, 0)
        inf_damp = inf_damp + csr_matrix((val, (row, col)), shape=(neq, neq))

    if data["Bounds"] == 2 | data["Bounds"] == 3:
        total_elem_in_r = elem_count[0][0]
        total_elem_in_z = sum(i[1] for i in elem_count)
        elements = np.zeros(shape=(total_elem_in_r, 2), dtype=int)
        for i1 in range(total_elem_in_r):
            elements[i1, :] = idx_array + (total_elem_in_r + 1) * total_elem_in_z + i1

        elem_id = connectivity(elements, node_id)

        nnz = elements.shape[0] * nzpe
        row = np.zeros(shape=[nnz], dtype=int)
        col = np.zeros(shape=[nnz], dtype=int)
        val = np.zeros(shape=[nnz], dtype=float)

        vs = s_wave_velocity(data["Ground"]["E"][-1],
                             data["Ground"]["v"][-1],
                             data["Ground"]["rho"][-1])
        vp = p_wave_velocity(data["Ground"]["E"][-1],
                             data["Ground"]["v"][-1],
                             data["Ground"]["rho"][-1])
        ds = vs * data["Ground"]["rho"][-1]
        dp = vp * data["Ground"]["rho"][-1]

        m = 0
        for i1, element in enumerate(elements):
            r0 = nodes[element[0], 0]
            r1 = nodes[element[1], 0]
            r01 = abs(r1 - r0) / 2
            if etype:
                elem_damp[0] = ds*r01*(3*r0 + r1)/6
                elem_damp[1] = ds*r01*(r0 + r1)/6
                elem_damp[2] = dp*r01*(3*r0 + r1)/6
                elem_damp[3] = dp*r01*(r0 + r1)/6
                elem_damp[4] = elem_damp[1]
                elem_damp[5] = ds*r01*(r0 + 3*r1)/6
                elem_damp[6] = elem_damp[3]
                elem_damp[7] = dp*r01*(r0 + 3*r1)/6
            else:
                elem_damp[0] = ds * r0 * r01
                elem_damp[1] = dp * r0 * r01
                elem_damp[2] = ds * r1 * r01
                elem_damp[3] = dp * r1 * r01

            row[m:m + nzpe] = elem_id[i1, row_i]
            col[m:m + nzpe] = elem_id[i1, col_i]
            val[m:m + nzpe] = elem_damp
            m += nzpe

        to_delete = np.where((row == neq) | (col == neq))
        row = np.delete(row, to_delete, 0)
        col = np.delete(col, to_delete, 0)
        val = np.delete(val, to_delete, 0)
        inf_damp = inf_damp + csr_matrix((val, (row, col)), shape=(neq, neq))

    return inf_damp


def external_force(nodes, node_id, r0):
    top_nodes = nodes[np.where(nodes[:, 1] == 0)]
    outer_node_idx = np.argmin(abs(top_nodes[:, 0] - r0))
    outer_node_idx = max(1, outer_node_idx)
    outer_node = top_nodes[outer_node_idx]
    area = math.pi * outer_node[0]**2
    pressure = 1/area

    neq = node_id.max()
    ext_force = np.zeros(shape=neq, dtype=float)
    for i1 in range(1, outer_node_idx + 1):
        row = node_id[i1-1:i1+1, 1]
        ext_force[row] = ext_force[row] + pressure * (top_nodes[i1, 0] - top_nodes[i1 - 1, 0]) * \
            np.array([top_nodes[i1, 0] + 2*top_nodes[i1 - 1, 0], 2*top_nodes[i1, 0] + top_nodes[i1 - 1, 0]]) / 6

    return ext_force
