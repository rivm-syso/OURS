import math


def s_wave_velocity(e, nu, rho):
    """
    Routine to compute the shear wave velocity

    :param e: (float) Young's modulus [N/m^2]
    :param nu: (float) Poisson ratio [-]
    :param rho: (float) Mass density [kg/m^3]
    :return: (float) Shear wave velocity [m/s]
    """

    return math.sqrt(e/2/(1 + nu)/rho)


def p_wave_velocity(e, nu, rho):
    """
    Routine to compute the compressive wave velocity

    :param e: (float) Young's modulus [N/m^2]
    :param nu: (float) Poisson ratio [-]
    :param rho: (float) Mass density [kg/m^3]
    :return: (float) Compressive wave velocity [m/s]
    """

    return math.sqrt(e*(1 - nu)/(1 + nu)/(1 - 2*nu)/rho)
