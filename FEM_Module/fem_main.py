def axi(file_in, file_out, write_file):
    """
    Main routine that reads the input, sets up the FEM model, performs the simulation and write the results

    :param file_in: (string) full path to the json-file describing the input for the FEM model
    :param file_out: (string) full path to the json-file with the output of the FEM calculations
    :param write_file: (string) full path to the txt-file describing the determined FEM parameters
    :return: void
    """

    import input_output as io
    import book_keeping as bk
    import mesh
    import fem_routines as fem
    import numerical_routines as num
    # from scikits.umfpack import spsolve

    # Read and validate soil data
    data = io.read_input(file_in, write_file)
    # io.check_input(data, write_file)

    # Generate mesh
    max_elem_size = mesh.element_size(data)
    elem_count = mesh.elements_per_layer(data, max_elem_size)
    nodes = mesh.node_coordinates(data, elem_count)
    elements = mesh.elem_nodes(elem_count)

    # Set up bookkeeping
    node_id = bk.mapping(nodes, data["Bounds"])
    elem_id = bk.connectivity(elements, node_id)

    # Assemble system matrices
    glob_stiff = fem.glob_stiff_matrix(nodes, elements, elem_id, data, elem_count)
    glob_stiff = glob_stiff + fem.inf_stiff_matrix(nodes, node_id, data, elem_count, data["ConsistentInfStiffness"])
    hyst_damp = fem.hyst_damp_matrix(nodes, elements, elem_id, data, elem_count)
    inf_damp = fem.inf_damp_matrix(nodes, node_id, data, elem_count, data["ConsistentInfDamping"])
    ext_force = fem.external_force(nodes, node_id, data["ForceRadius"])

    # Determine which solution method is used
    lumped_mass = None
    consistent_mass = None
    if data["CalcType"] == 3:
        lumped_mass = fem.lumped_mass_matrix(nodes, elements, elem_id, data, elem_count)
        consistent_mass = fem.consistent_mass_matrix(nodes, elements, elem_id, data, elem_count)
        data = num.pick_method(data, glob_stiff, lumped_mass, consistent_mass, hyst_damp, inf_damp, ext_force,
                               write_file)

    io.write_model_info(write_file, data, max_elem_size, elem_count, nodes, elements, node_id)

    # Perform simulation
    if data["CalcType"] == 1:  # In case central differences is used
        if lumped_mass is None:
            lumped_mass = fem.lumped_mass_matrix(nodes, elements, elem_id, data, elem_count)

        result = num.central_differences(nodes, node_id, glob_stiff, hyst_damp, inf_damp, lumped_mass, ext_force,
                                         data, write_file)
    elif data["CalcType"] == 2:  # In case harmonic response analysis is used
        if consistent_mass is None:
            consistent_mass = fem.consistent_mass_matrix(nodes, elements, elem_id, data, elem_count)

        result = num.harmonic_response(nodes, node_id, glob_stiff, hyst_damp, inf_damp, consistent_mass, ext_force,
                                       data, write_file)

    # Write results to file_out
    io.write_output(file_out, result)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--inp_filename', help='input file name', required=True)
    parser.add_argument('-o', '--out_filename', help='output file name', required=True)
    parser.add_argument('-r', '--write_filename', help='write output file name', required=True)
    args = parser.parse_args()
    axi(args.inp_filename, args.out_filename, args.write_filename)

