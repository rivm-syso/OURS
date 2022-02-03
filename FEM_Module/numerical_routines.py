import numpy as np
import math
from scipy.sparse import csr_matrix, hstack, vstack
from scipy.sparse.linalg import spsolve
import pypardiso as pp
from wave_velocity import s_wave_velocity
from scipy.signal import welch, csd
from time import perf_counter
import datetime


def central_differences(nodes, node_id, glob_stiff, hyst_damp, inf_damp, lumped_mass, ext_force, data, file_name):
    """

    :param nodes: (float) array [NP, 2] with the radial and vertical coordinate of each node (NP: total number of nodes)
    :param node_id: (int) array [NP, 2] with the equation number of the radial and vertical displacement of each node
    :param glob_stiff: (float) csr_matrix [NEQ, NEQ] global stiffness matrix (NEQ: total number of equations)
    :param hyst_damp: (float) csr_matrix [NEQ, NEQ] global hysteretic stiffness matrix
    :param inf_damp: (float) csr_matrix [NEQ, NEQ] viscous damping matrix due to infinite boundaries
    :param lumped_mass: (float) array [NEQ] with diagonal components of the lumped mass matrix
    :param ext_force: (float) array [NEQ] with global external unit force vector
    :param data: (dict) with FEM input parameters
    :param file_name: (string) full path to the txt-file describing the determined FEM parameters
    :return: (dict) with the transfer compliance in radial and vertical direction
    """

    # Determine time sampling data
    time_step, total_steps, output_interval, time_end = time_sampling(data, glob_stiff, lumped_mass)
    output_number = math.floor(total_steps / output_interval) + 1

    top_nodes_idx = np.where(nodes[:, 1] == 0)[0]

    neq = lumped_mass.shape[0]
    # Allocate all arrays to save the solution
    disp = np.zeros(shape=neq, dtype=float)
    vel = np.zeros(shape=neq, dtype=float)
    disp_history_r = np.zeros(shape=(len(top_nodes_idx), output_number + 1), dtype=float)
    disp_history_z = np.zeros(shape=(len(top_nodes_idx), output_number + 1), dtype=float)
    force_history_z = np.zeros(shape=output_number, dtype=float)

    # Inverting the mass matrix
    lumped_mass = 1/lumped_mass

    try:
        with open(file_name, "a") as fid:
            fid.write("----------------------------------------------------------------\n\n")
            fid.write("Calculation started at %s\n" % (datetime.datetime.now().strftime("%B %d, %Y %I:%M:%S")))
            fid.write("    total simulation time of %12.6e\n" % time_end)
            fid.write("         with a time step of %12.6e\n" % time_step)
            fid.write("    total number of time steps %d\n" % total_steps)

    except OSError:
        exit(-102)

    # Generate white noise for the excitation
    np.random.seed(999)
    excitation_frequencies = np.arange(data["ForcingFreqIncrement"],
                                       data["HighFreq"] * 1.1,
                                       data["ForcingFreqIncrement"]) * 2 * math.pi
    # excitation_phases = np.random.rand(len(excitation_frequencies)) * 2 * math.pi
    excitation_phases = np.zeros(len(excitation_frequencies))

    time = time_step
    n = 1
    # Integrate through time
    for i1 in range(total_steps):
        force_magnitude = 1.0E6 * np.sum(np.sin(excitation_frequencies * time + excitation_phases))
        acc = np.multiply(force_magnitude * ext_force - glob_stiff.dot(disp) -
                          hyst_damp.dot(np.multiply(np.absolute(disp), np.sign(vel))) -
                          inf_damp.dot(vel), lumped_mass)

        vel = vel + acc * time_step
        disp = disp + vel * time_step

        # Only save the results of the top nodes
        if not((i1+1) % output_interval):
            print("time = %0.4f s" % time)
            disp_history_r[:, n] = np.append(disp, 0)[node_id[top_nodes_idx, 0]]
            disp_history_z[:, n] = np.append(disp, 0)[node_id[top_nodes_idx, 1]]
            force_history_z[n] = force_magnitude
            n += 1

        time += time_step

    # Perform transformation to the frequency domain
    result_r, _ = tfestimate(force_history_z, disp_history_r, fs=1/(time_step * output_interval),
                             window='hann', nperseg=output_number/2, noverlap=output_number/4, nfft=None,
                             detrend=False, axis=-1)
    result_z, frequencies = tfestimate(force_history_z, disp_history_z, fs=1/(time_step * output_interval),
                                       window='hann', nperseg=output_number/2, noverlap=output_number/4, nfft=None,
                                       detrend=False, axis=-1)

    frequency_idx = np.where((frequencies >= data["LowFreq"]) & (frequencies <= data["HighFreq"]))[0]

    result = {'RDisp_real': np.real(result_r[:, np.squeeze(frequency_idx)]).tolist(),
              'RDisp_imag': np.imag(result_r[:, np.squeeze(frequency_idx)]).tolist(),
              'ZDisp_real': np.real(result_z[:, np.squeeze(frequency_idx)]).tolist(),
              'ZDisp_imag': np.imag(result_z[:, np.squeeze(frequency_idx)]).tolist(),
              'Frequency': frequencies[np.squeeze(frequency_idx)].tolist(),
              'Rcoord': np.squeeze(nodes[top_nodes_idx, 0]).tolist()}

    if data["MaxFreqLimited"] != data["HighFreq"]:
        result["MaxFreqLimited"] = data["MaxFreqLimited"]

    try:
        with open(file_name, "a") as fid:
            fid.write("Calculation ended at %s\n" % (datetime.datetime.now().strftime("%B %d, %Y %I:%M:%S")))

    except OSError:
        exit(-102)

    return result


def time_sampling(data, glob_stiff, lumped_mass):
    """
    Determine time stepping parameters

    :param data: (dict) with FEM input parameters
    :param glob_stiff: (float) csr_matrix [NEQ, NEQ] global stiffness matrix (NEQ: total number of equations)
    :param lumped_mass: (float) array [NEQ] with diagonal components of the lumped mass matrix
    :return: (float, int, int, float) with time step [s], total number of steps, interval at which output is generated,
    end time [s]
    """

    # Obtain critical time step
    time_step = max_time_step(glob_stiff, lumped_mass,
                              data["TimeIncrementFactor"],
                              data["TimeIncrementTolerance"],
                              data["TimeIncrementMaxIterations"])
    time_end = data["TimeEndFactor"] * data["MaxCalcDist"] / s_wave_velocity(data["Ground"]["E"][0],
                                                                             data["Ground"]["v"][0],
                                                                             data["Ground"]["rho"][0])

    total_steps = round(time_end / time_step)
    output_interval = round(1 / data["HighFreq"] / time_step / 4)
    output_number = math.floor(total_steps / output_interval)
    output_number = 2 ** math.ceil(math.log(output_number, 2))
    total_steps = output_number * output_interval

    return time_step, total_steps, output_interval, time_end


def frequency_sampling(data):
    """
    Determine frequencies at which harmonic response analysis is performed

    :param data:  (dict) with FEM input parameters
    :return: (float) array [NFREQ] with frequencies (NFREQ: total number of frequencies)
    """

    # Estimate a generic damping value
    eta = max(0.1, float(np.mean(data["Ground"]["damping"])))*2
    total_frequencies = data["FreqIncrementFactor"] * \
                        (math.ceil(math.log(data["HighFreq"]/data["LowFreq"])/math.log(1 + eta/2)) + 1)

    # Obtain frequency array based on resolving resonances with a damping equal eta
    return np.logspace(math.log10(data["LowFreq"]),
                       math.log10(data["HighFreq"]),
                       int(total_frequencies), endpoint=True)


def max_time_step(glob_stiff, lumped_mass, factor, tolerance, max_iterations):
    """
    Routine to determine the maximum time step at which central differences is stable

    In linear analysis the central difference method is unconditionally stable when the chosen time step (for
    integrating through time) :math:`\Delta t\le \frac{2}{\omega_{max}}`, where :math:`\omega_{max}` is the maximum
    circular frequency of the system.

    The procedure to determine the maximum circular frequency is based on the power method, which is an iterative method

    .. math::
        x^{(k)} = \left(M^{-1}K\rigth)^kx^{0}

    where :math:`M` and :math:`K` are the global mass and stiffness matrix, and :math:`x^{(k)}` is the eigenvector
    obtained at the :math:`k^{th}` iteration. As initial vector :math:`x^{(0)}` a random vector is chosen. The
    eigenvalue at the :math:`k^{th}` iteration is computed as

    ..math::
        \lambda^{(k)} = x^{(k)}\cdot x^{(k-1)}

    Relative convergence is checked on the eigenvalue.

    :param glob_stiff: (float) csr_matrix [NEQ, NEQ] global stiffness matrix (NEQ: total number of equations)
    :param lumped_mass: (float) array [NEQ] with diagonal components of the lumped mass matrix
    :param factor: (float) safety for determining time step
    :param tolerance: (float) iteration tolerance to determine the highest eigenfrequency
    :param max_iterations: (int) maximum number of iterations to determine the highest eigenfrequency
    :return: (float) time step [s]
    """

    neq = lumped_mass.shape[0]
    glob_stiff = csr_matrix((1/lumped_mass, (np.arange(neq, dtype=int), np.arange(neq, dtype=int))),
                            shape=(neq, neq)) * glob_stiff
    x_0 = np.random.rand(glob_stiff.shape[0], 1)
    x_1 = x_0/np.linalg.norm(x_0)
    lam_0 = 0
    lam_1 = np.vdot(x_0, x_1)
    iteration = 0
    while ((abs(lam_1 - lam_0)/lam_1) > tolerance) & (iteration < max_iterations):
        lam_0 = lam_1
        x_1 = x_0/np.linalg.norm(x_0)
        x_0 = glob_stiff * x_1
        lam_1 = np.vdot(x_0, x_1)
        iteration += 1

    return factor * 2 / math.sqrt(lam_1)


def harmonic_response(nodes, node_id, glob_stiff, hyst_damp, inf_damp, consistent_mass, ext_force, data, file_name):
    """

    :param nodes: (float) array [NP, 2] with the radial and vertical coordinate of each node (NP: total number of nodes)
    :param node_id: (int) array [NP, 2] with the equation number of the radial and vertical displacement of each node
    :param glob_stiff: (float) csr_matrix [NEQ, NEQ] global stiffness matrix (NEQ: total number of equations)
    :param hyst_damp: (float) csr_matrix [NEQ, NEQ] global hysteretic stiffness matrix
    :param inf_damp: (float) csr_matrix [NEQ, NEQ] viscous damping matrix due to infinite boundaries
    :param consistent_mass: (float) csr_matrix [NEQ, NEQ] with the global consistent mass matrix
    :param ext_force: (float) array [NEQ] with global external unit force vector
    :param data: (dict) with FEM input parameters
    :param file_name: (string) full path to the txt-file describing the determined FEM parameters
    :return: (dict) with the transfer compliance in radial and vertical direction
    """

    # Obtain frequencies at which harmonic response analysis has to be performed
    frequencies = frequency_sampling(data)

    omegas = frequencies * 2 * math.pi
    neq = ext_force.shape[0]

    # Allocate the array with results
    harm_response = np.zeros(shape=(neq, frequencies.shape[0]), dtype=complex)

    try:
        with open(file_name, "a") as fid:
            fid.write("----------------------------------------------------------------\n\n")
            fid.write("Calculation started at %s\n" % (datetime.datetime.now().strftime("%B %d, %Y %I:%M:%S")))
            fid.write(" total number of frequency steps %d\n" % np.size(frequencies))

    except OSError:
        exit(-102)

    # Cycle through all frequencies and solve the harmonic response analysis
    for i1, w in enumerate(omegas):
        if data["SolverType"] == 1:
            matrix = -consistent_mass * (w ** 2) + glob_stiff + 1j * (inf_damp * w + hyst_damp)
            harm_response[:, i1] = spsolve(matrix, ext_force, use_umfpack=True)
        elif data["SolverType"] == 2:
            matrix = -consistent_mass * (w ** 2) + glob_stiff + 1j * (inf_damp * w + hyst_damp)
            harm_response[:, i1] = spsolve(matrix, ext_force, use_umfpack=True)
        elif data["SolverType"] == 3:
            matrix_real = -consistent_mass * (w ** 2) + glob_stiff
            matrix_imag = inf_damp * w + hyst_damp
            matrix = vstack([hstack([matrix_real, -matrix_imag]),
                             hstack([matrix_imag, matrix_real])], format='csr')
            solution = pp.spsolve(matrix, np.concatenate([ext_force, np.zeros(shape=ext_force.shape)], axis=0))
            harm_response[:, i1] = solution[0:neq] + 1j * solution[neq:2*neq]

        print("freq = %0.4f Hz" % (frequencies[i1]))

    harm_response = np.append(harm_response, np.zeros(shape=(1, frequencies.shape[0])), axis=0)

    # Only save the results of the top nodes
    top_nodes_idx = np.where(nodes[:, 1] == 0)
    result = {'RDisp_real': np.squeeze(np.real(harm_response[node_id[top_nodes_idx, 0], :])).tolist(),
              'RDisp_imag': np.squeeze(np.imag(harm_response[node_id[top_nodes_idx, 0], :])).tolist(),
              'ZDisp_real': np.squeeze(np.real(harm_response[node_id[top_nodes_idx, 1], :])).tolist(),
              'ZDisp_imag': np.squeeze(np.imag(harm_response[node_id[top_nodes_idx, 1], :])).tolist(),
              'Frequency': frequencies.tolist(),
              'Rcoord': np.squeeze(nodes[top_nodes_idx, 0]).tolist()}

    if data["MaxFreqLimited"] != data["HighFreq"]:
        result["MaxFreqLimited"] = data["MaxFreqLimited"]

    try:
        with open(file_name, "a") as fid:
            fid.write("Calculation ended at %s\n" % (datetime.datetime.now().strftime("%B %d, %Y %I:%M:%S")))

    except OSError:
        exit(-102)

    return result


def pick_method(data, glob_stiff, lumped_mass, consistent_mass, hyst_damp, inf_damp, ext_force, file_name):
    """
    Routine to estimate the required CPU time to perform the simulation using central difference and harmonic response
    analysis. The fastest method is then chosen

    :param data: (dict) with FEM input parameters
    :param glob_stiff: (float) csr_matrix [NEQ, NEQ] global stiffness matrix (NEQ: total number of equations)
    :param lumped_mass: (float) array [NEQ] with diagonal components of the lumped mass matrix
    :param consistent_mass: (float) csr_matrix [NEQ, NEQ] with the global consistent mass matrix
    :param hyst_damp: (float) scr_matrix [NEQ, NEQ] with the global hysteretic damping matrix
    :param inf_damp: (float) scr_matrix [NEQ, NEQ] with the viscous damping matrix due to infinite boundaries
    :param ext_force: (float) array [NEQ] with global external unit force vector
    :param file_name: (string) full path to the txt-file describing the determined FEM parameters
    :return: (dict) with the update data dictionary
    """

    time_step, total_steps, output_interval, time_end = time_sampling(data, glob_stiff, lumped_mass)

    neq = lumped_mass.shape[0]
    disp = np.ones(shape=neq, dtype=float)
    vel = np.ones(shape=neq, dtype=float)

    # Time the CPU time to solve 10 time step with central differences
    time = time_step
    excitation_frequencies = np.arange(data["ForcingFreqIncrement"],
                                       data["HighFreq"] * 1.1,
                                       data["ForcingFreqIncrement"]) * 2 * math.pi
    excitation_phases = np.ones(shape=excitation_frequencies.shape, dtype=float)
    t1_start = perf_counter()
    for i1 in range(10):
        force_magnitude = 1.0E6 * np.sum(np.sin(excitation_frequencies * time + excitation_phases))
        result = (force_magnitude - (glob_stiff * disp) -
                  hyst_damp * (np.absolute(disp) * np.sign(vel)) -
                  (inf_damp * vel)) * lumped_mass

    time1 = (perf_counter() - t1_start) * total_steps/10
    del result

    # Time the CPU time to solve the harmonic response at 1 frequency
    frequencies = frequency_sampling(data) * 2 * math.pi
    t2_start = perf_counter()
    if data["SolverType"] == 1:
        matrix = -consistent_mass * (frequencies[-1] ** 2) + glob_stiff + 1j * (inf_damp * frequencies[-1] + hyst_damp)
        result = spsolve(matrix, ext_force)
    elif data["SolverType"] == 2:
        matrix = -consistent_mass * (frequencies[-1] ** 2) + glob_stiff + 1j * (inf_damp * frequencies[-1] + hyst_damp)
        result = spsolve(matrix, ext_force, use_umfpack=True)
    elif data["SolverType"] == 3:
        matrix_real = -consistent_mass * (frequencies[-1] ** 2) + glob_stiff
        matrix_imag = inf_damp * frequencies[-1] + hyst_damp
        matrix = vstack([hstack([matrix_real, -matrix_imag]),
                         hstack([matrix_imag, matrix_real])], format='csr')
        result = pp.spsolve(matrix, np.concatenate([ext_force, np.zeros(shape=ext_force.shape)], axis=0))

    time2 = (perf_counter() - t2_start) * frequencies.size
    del result

    # Make a decision
    if time1 < time2 * data["MethodDecisionFactor"]:
        data["CalcType"] = 1
    else:
        data["CalcType"] = 2

    try:
        with open(file_name, "a") as fid:
            fid.write("----------------------------------------------------------------\n\n")
            fid.write("CPU time estimation finished at %s\n"
                      % (datetime.datetime.now().strftime("%B %d, %Y %I:%M:%S")))
            fid.write("    estimated CPU time for explicit %12.6e\n" % time1)
            fid.write("    estimated CPU time for harmonic %12.6e\n" % time2)
            if data["CalcType"] == 1:
                fid.write("        Texplicit > %12.6e x Tharmonic\n" % data["MethodDecisionFactor"])
                fid.write("               explicit time integration is chosen\n")
            else:
                fid.write("       Texplicit <= %12.6e x Tharmonic\n" % data["MethodDecisionFactor"])
                fid.write("              harmonic response analysis is chosen\n")

    except OSError:
        exit(-102)

    return data


def tfestimate(x, y, *args, **kwargs):
    """
    Routine to compute the transfer function between input x and output y

    :param x: (float) array [NS] with the input trace (NS: total number of samples)
    :param y: (float) array [NS] with the output trace
    :param args: optional arguments (valid for scipy.signal.csd and scipy.signal.welch)
    :param kwargs: optional arguments (valid for scipy.signal.csd and scipy.signal.welch)
    :return: (complex, float) arrays [NF] with transfer spectrum and frequencies (NF number of frequencies)
    """

    # return csd(y, x, *args, **kwargs) / psd(x, *args, **kwargs)
    # result = tfestimate(x, y, fs=1.0, window='hann', nperseg=N/2, noverlap=N/4, nfft=None, axis=-1)
    # return csd(y, x, *args, **kwargs) / welch(x, *args, **kwargs)

    result1 = csd(y, x, *args, **kwargs)
    result2 = welch(x, *args, **kwargs)

    return result1[1] / result2[1], result1[0]


# def gen_signal():
#     n = 1000
#     t = np.linspace(0, 1, n, endpoint=True)
#     x = np.zeros(shape=n, dtype=float)
#     y = np.zeros(shape=(10, n), dtype=float)
#     for i1 in range(y.shape[0]):
#         x[:] = x[:] + np.sin(100*(i1+1)/2/math.pi*t)
#         y[i1, :] = np.sin(100*(i1+1)/2/math.pi*t)
#
#     return t, x, y
