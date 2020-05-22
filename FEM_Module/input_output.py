import json
import numpy as np
import datetime


def read_input(file_name, write_file):
    """
    Routine to read the FEM input parameter file. The output data has the following structure

    .. code-block:: python

            data["MaxCalcDist"] (float) maximum distance of calculation
            data["MaxCalcDepth"] (float) maximum depth of calculation
            data["MinLayerThickness"] (float) minimum layers thickness for the vertical discretisation (not used)
            data["MinElementSize"] (float) minimum element size
            data["LowFreq"] (float) minimum frequency of interest
            data["HighFreq"] (float) maximum frequency of interest
            data["CalcType"] (int) type of calculation 1=centdiff, 2=harmresp, 3=programme decides
            data["SolverType"] (int) solver type 1=scipy.spsolve, 2=umfpack, 3=pardiso
            data["Ground"]["Depth"] (float) array with depth of the top of each layer
            data["Ground"]["E"] (float) array with Young's modulus per layer
            data["Ground"]["Lithology"] (string) with lithology per layer
            data["Ground"]["damping"] (float) array with damping ratio per layer
            data["Ground"]["rho"] (float) array with mass density per layer
            data["Ground"]["v"] (float) array with Poisson's ratio per layer
            data["Ground"]["Thickness"] (float) array) with thickness per layer
            data["NumLayers"] (float) number of layers
            data("Bounds") (int) boundary condition type
            data("TimeIncrementFactor") (float) safety factor fro critical time step
            data("TimeIncrementMaxIterations") (int) maximum number of iterations to determine critical time step
            data("TimeIncrementTolerance") (float) relative tolerance to determine critical time step
            data("TimeEndFactor") (float) multiplication factor to determine simulation end time
            data("ForceRadius") (float) radius at which force is applied
            data("MethodDecisionFactor") (float) bias factor to decide which method is preferred
            data("MaxElementRatio") (float) maximum finite element geometry ratio
            data("ElementsPerWave") (float) number of elements per wave for discretization
            data("FreqIncrementFactor") (float) factor to scale number of frequency lines
            data("ForcingFreqIncrement") (float) frequency increment to generate white noise
            data("ConsistentInfStiffness") (bool) switch for consistent or lumped infinite stiffness
            data("ConsistentInfDamping") (bool) switch for consistent or lumped infinite damping

    :param file_name: (string) full path of JSON file containing the FEM input parameters
    :param write_file: (string) full path of TXT file to write the process updates
    :return: (dict) FEM input parameters
    """

    try:
        with open(file_name, "r") as fid:
            data = json.load(fid)
    except OSError:
        exit(-101)

    time1 = datetime.datetime.now()

    required_keys = ["MaxCalcDist", "MaxCalcDepth", "MinLayerThickness", "LowFreq", "HighFreq", "CalcType", "Ground"]
    if not(all(key in list(data.keys()) for key in required_keys)):
        exit(-102)

    required_keys = ["Depth", "E", "damping", "rho", "v"]
    if not(all(key in list(data["Ground"].keys()) for key in required_keys)):
        exit(-102)

    required_keys = iter(required_keys)
    target_length = len(data["Ground"][next(required_keys)])
    if not all(len(data["Ground"][key]) == target_length for key in required_keys):
        exit(-103)

    to_delete = np.where(np.absolute(data["Ground"]["Depth"]) >= data["MaxCalcDepth"])
    data["Ground"]["Depth"] = np.delete(data["Ground"]["Depth"], to_delete, 0)
    data["Ground"]["E"] = np.delete(data["Ground"]["E"], to_delete, 0)
    data["Ground"]["Lithology"] = np.delete(data["Ground"]["Lithology"], to_delete, 0)
    data["Ground"]["damping"] = np.delete(data["Ground"]["damping"], to_delete, 0)
    data["Ground"]["rho"] = np.delete(data["Ground"]["rho"], to_delete, 0)
    data["Ground"]["v"] = np.delete(data["Ground"]["v"], to_delete, 0)
    data["NumLayers"] = len(data["Ground"]["Lithology"])

    data["Ground"]["Thickness"] = [None] * data["NumLayers"]
    for i1 in range(data["NumLayers"] - 1):
        data["Ground"]["Thickness"][i1] = abs(data["Ground"]["Depth"][i1 + 1] - data["Ground"]["Depth"][i1])

    data["Ground"]["Thickness"][-1] = data["MaxCalcDepth"] - abs(data["Ground"]["Depth"][-1])
    data["Ground"]["Thickness"][-1] = max(data["Ground"]["Thickness"][-1], data["MinLayerThickness"])

    data.setdefault("SolverType", 3)
    data.setdefault("Bounds", 3)
    data.setdefault("TimeIncrementFactor", 0.6)
    data.setdefault("TimeIncrementMaxIterations", 1000)
    data.setdefault("TimeIncrementTolerance", 1E-5)
    data.setdefault("TimeEndFactor", 2.0)
    data.setdefault("ForceRadius", 1.0)
    data.setdefault("MethodDecisionFactor", 1.0)
    data.setdefault("MaxElementRatio", 3.0)
    data.setdefault("MinElementSize", 0.0)
    data.setdefault("ElementsPerWave", 10.0)
    data.setdefault("FreqIncrementFactor", 1.0)
    data.setdefault("ForcingFreqIncrement", 1E-2)
    data.setdefault("ConsistentInfStiffness", True)
    data.setdefault("ConsistentInfDamping", True)

    try:
        with open(write_file, "w") as fid:
            fid.write("----------------------------------------------------------------\n")
            fid.write("Reading input started at %s\n" % (time1.strftime("%B %d, %Y %I:%M:%S")))
            fid.write("  Input file: %s\n" % file_name)
            fid.write("Reading input ended at %s\n" % (datetime.datetime.now().strftime("%B %d, %Y %I:%M:%S")))
            fid.write("----------------------------------------------------------------\n\n")

    except OSError:
        exit(-102)

    return data


def write_model_info(file_name, data, max_elem_size, elem_count, nodes, elements, node_id):
    """
    Routine to write information of the model into an ASCII file

    :param file_name: (string) full path of ASCII file to write the model info
    :param data:
    :param max_elem_size:
    :param elem_count:
    :param nodes:
    :param elements:
    :param node_id:
    :return: (void)
    """

    try:
        with open(file_name, "a") as fid:
            fid.write("project name         = %s\n" % data["Name"])
            fid.write("min. freq            = %12.10g Hz\n" % data["LowFreq"])
            fid.write("max. freq            = %12.10g Hz\n" % data["HighFreq"])
            if data["HighFreq"] != data["MaxFreqLimited"]:
                fid.write("max. freq limited to = %12.5g Hz\n" % data["MaxFreqLimited"])

            fid.write("max. distance        = %12.10g m\n" % data["MaxCalcDist"])
            fid.write("min. layer thickness = %12.10g m\n" % data["MinLayerThickness"])
            fid.write("calculation type     = %12s\n" % ["Explicit time", "Harmonic resp"][data["CalcType"] - 1])
            if data["CalcType"] == 2:
                fid.write("solver type          = %12s\n" % ["scipy.spsolve", "umfpack", "pardiso"][data["SolverType"] - 1])
            fid.write('number of equations  = %12d\n' % np.max(node_id))
            fid.write("\n       layer       E [Pa]       nu [-]  Rho [kg/m3]  damping [-]   height [m] el. size [m]    "
                      "el. num X    el. num Y\n")
            fid.write("------------------------------------------------------------------------------------------------"
                      "--------------------\n")
            for i1 in range(data["NumLayers"]):
                fid.write("%12u %12.6e %12.6e %12.6e %12.6e %12.6e %12.6e %12u %12u\n" %
                          (i1+1,
                           data["Ground"]["E"][i1],
                           data["Ground"]["v"][i1],
                           data["Ground"]["rho"][i1],
                           data["Ground"]["damping"][i1],
                           data["Ground"]["Thickness"][i1],
                           max_elem_size[i1],
                           elem_count[i1][0],
                           elem_count[i1][1]))
            fid.write("\n        node        R [m]        Z [m]\n")
            fid.write("--------------------------------------\n")
            for i1, node in enumerate(nodes):
                fid.write("%12d %12.6e %12.6e\n" % (i1+1, node[0], node[1]))

            fid.write("\n     element        node1        node2        node3        node4\n")
            fid.write("----------------------------------------------------------------\n")
            for i1, element in enumerate(elements):
                fid.write("%12d %12u %12u %12u %12u\n" % (i1+1, element[0]+1, element[1]+1, element[2]+1, element[3]+1))

    except OSError:
        exit(-102)


def write_output(file_name, result):
    """
    Routine to write the results in a JSON file

    :param file_name: (string) full path to JSON file in which the results are written
    :param result: (dict) containing the compliance spectra from excitation to response points
    :return: (void)
    """

    try:
        with open(file_name, "w") as fid:
            json.dump(result, fid, separators=(',', ':'), sort_keys=True, indent=4)

    except OSError:
        exit(-103)


def check_input(data, file_name):
    """
    Routine to check the input data for errors

    :param data:
    :param file_name: (string) full path of ASCII file to write error messages
    :return: (void)
    """

    error_message = ''
    # for i1 in range(data["NumLayers"]):
    #     if not(isinstance(data["Ground"]["E"][i1], (int, float))) or not(1E5 <= data["Ground"]["E"][i1] <= 1E12):
    #         error_message = error_message + "Error: Layer(" + str(i1+1) + ").E = " + str(data["Ground"]["E"][i1]) + \
    #                         ". It should be between [1E5, 1E12]\n"
    #
    #     if not(isinstance(data["Ground"]["v"][i1], (int, float))) or not(0 < data["Ground"]["v"][i1] < 0.499):
    #         error_message = error_message + "Error: Layer(" + str(i1 + 1) + ").v = " + str(data["Ground"]["v"][i1]) + \
    #                         ". It should be between <0, 0.499>\n"
    #
    #     if not(isinstance(data["Ground"]["rho"][i1], (int, float))) or not(500 <= data["Ground"]["rho"][i1] <= 4000):
    #         error_message = error_message + "Error: Layer(" + str(i1 + 1) + ").rho = " + \
    #                         str(data["Ground"]["rho"][i1]) + ". It should be between [500, 4000]\n"
    #
    #     if not(isinstance(data["Ground"]["damping"][i1], (int, float))) or not(0 <= data["Ground"]["damping"][i1] <= 0.99):
    #         error_message = error_message + "Error: Layer(" + str(i1 + 1) + ").damping = " + \
    #                         str(data["Ground"]["damping"][i1]) + ". It should be between [0, 0.99]\n"
    #
    #     if not(isinstance(data["Ground"]["Thickness"][i1], (int, float))) or not(data["Ground"]["Thickness"][i1] >=
    #                                                                              data["MinLayerThickness"]):
    #         error_message = error_message + "Error: Layer(" + str(i1 + 1) + ").Thickness = " + \
    #                         str(data["Ground"]["Thickness"][i1]) + ". It should be at least " + \
    #                         str(data["Ground"]["MinLayerThickness"]) + "\n"

    if not(isinstance(data["MaxCalcDist"], (int, float))) or not(0.5 <= data["MaxCalcDist"] <= 300):
        error_message = error_message + "Error: MaxCalcDist = " + str(data["MaxCalcDist"]) + \
                        ". It should be [0.5, 300]\n"

    if not(isinstance(data["MaxCalcDepth"], (int, float))) or not(0.5 <= data["MaxCalcDepth"] <= 50):
        error_message = error_message + "Error: MaxCalcDepth = " + str(data["MaxCalcDepth"]) + \
                        ". It should be [0.5, 150]\n"

    if not(isinstance(data["MinLayerThickness"], (int, float))) or not(0.3 <= data["MinLayerThickness"] <= 3):
        error_message = error_message + "Error: MinLayerThickness = " + str(data["MinLayerThickness"]) + \
                        ". It should be [0.3, 3]\n"

    if not(isinstance(data["LowFreq"], (int, float))) or not(data["LowFreq"] > 0):
        error_message = error_message + "Error: LowFreq = " + str(data["LowFreq"]) + \
                        ". It should be <0, Inf]\n"

    if not(isinstance(data["HighFreq"], (int, float))) or not(0 < data["HighFreq"] <= 150):
        error_message = error_message + "Error: HighFreq = " + str(data["HighFreq"]) + \
                        ". It should be <0, 150]\n"

    if all(isinstance(val, (int, float)) for val in [data["LowFreq"], data["HighFreq"]]) and \
            (data["HighFreq"] < data["LowFreq"]):
        error_message = error_message + "Error: Highfreq = " + str(data["HighFreq"]) + " < " + \
                        "LowFreq = " + str(data["LowFreq"]) + "\n"

    if not(isinstance(data["CalcType"], int)) or not(data["CalcType"] in [1, 2, 3]):
        error_message = error_message + "Error: CalcType = " + str(data["CalcType"]) + \
                        ". It should be 1, 2 or 3\n"

    if not(isinstance(data["SolverType"], int)) or not(data["SolverType"] in [1, 2, 3]):
        error_message = error_message + "Error: SolverType = " + str(data["SolverType"]) + \
                        ". It should be 1, 2 or 3\n"

    if not(isinstance(data["Bounds"], int)) or not(data["Bounds"] in [0, 1, 2, 3]):
        error_message = error_message + "Error: Bounds = " + str(data["Bounds"]) + \
                        ". It should be 0, 1, 2 or 3\n"

    if not(isinstance(data["TimeIncrementFactor"], (int, float))) or not(0 < data["TimeIncrementFactor"] <= 1):
        error_message = error_message + "Error: TimeIncrementFactor = " + str(data["TimeIncrementFactor"]) + \
                        ". It should be <0, 1]\n"

    if not(isinstance(data["TimeIncrementMaxIterations"], int)) or not(data["TimeIncrementMaxIterations"] > 1):
        error_message = error_message + "Error: TimeIncrementMaxIterations = " + str(data["TimeIncrementMaxIterations"]) + \
                        ". It should be <1, Inf>\n"

    if not(isinstance(data["TimeIncrementTolerance"], float)) or not(0 < data["TimeIncrementTolerance"] < 1):
        error_message = error_message + "Error: TimeIncrementTolerance = " + str(data["TimeIncrementTolerance"]) + \
                        ". It should be <0, 1>\n"

    if not(isinstance(data["TimeEndFactor"], float)) or not(data["TimeEndFactor"] >= 1.0):
        error_message = error_message + "Error: TimeEndFactor = " + str(data["TimeEndFactor"]) + \
                        ". It should be [1, Inf>\n"

    if not(isinstance(data["ForceRadius"], float)) or not(data["ForceRadius"] >= 0.5):
        error_message = error_message + "Error: ForceRadius = " + str(data["ForceRadius"]) + \
                        ". It should be [0.5, Inf>\n"

    if not(isinstance(data["MethodDecisionFactor"], float)) or not(0 < data["MethodDecisionFactor"] <= 1.0):
        error_message = error_message + "Error: MethodDecisionFactor = " + str(data["MethodDecisionFactor"]) + \
                        ". It should be <0, 1]\n"

    if not(isinstance(data["MaxElementRatio"], float)) or not(1 <= data["MaxElementRatio"] <= 10):
        error_message = error_message + "Error: MaxElementRatio = " + str(data["MaxElementRatio"]) + \
                        ". It should be [1, 10]\n"

    if not(isinstance(data["ElementsPerWave"], float)) or not(1 <= data["ElementsPerWave"] <= 20):
        error_message = error_message + "Error: ElementsPerWave = " + str(data["ElementsPerWave"]) + \
                        ". It should be [1, 20]\n"

    if not(isinstance(data["FreqIncrementFactor"], float)) or not(0.5 <= data["FreqIncrementFactor"] <= 10):
        error_message = error_message + "Error: FreqIncrementFactor = " + str(data["FreqIncrementFactor"]) + \
                        ". It should be [0.5, 10]\n"

    if not(isinstance(data["ForcingFreqIncrement"], float)) or not(1.0E-3 <= data["ForcingFreqIncrement"] <= 2.0):
        error_message = error_message + "Error: ForcingFreqIncrement = " + str(data["ForcingFreqIncrement"]) + \
                        ". It should be [1.0E-3, 2]\n"

    if not(isinstance(data["ConsistentInfStiffness"], bool)):
        error_message = error_message + "Error: ConsistentInfStiffness = " + str(data["ConsistentInfStiffness"]) + \
                        ". It should be False or True\n"

    if not(isinstance(data["ConsistentInfDamping"], bool)):
        error_message = error_message + "Error: ConsistentInfDamping = " + str(data["ConsistentInfDamping"]) + \
                        ". It should be False or True\n"

    if error_message:
        try:
            with open(file_name, "a") as fid:
                fid.write("\n---------------------------\n")
                fid.write("  I N P U T   E R R O R S  \n")
                fid.write("---------------------------\n")
                fid.write(error_message)

        except OSError:
            exit(-102)

        exit(-110)
