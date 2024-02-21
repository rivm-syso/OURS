# -*- coding: utf-8 -*-
"""
Created on Sat Jan 15 16:50:53 2020

@author: bwakoop
"""

from __future__ import annotations
import argparse
import logging
import math
import json
import os
import traceback
import numpy as np
from scipy import signal
from sys import exit

# TODO put in config or central file
octaafbanden = np.array([2, 4, 8, 16, 31.5, 63])
aantalbanden = len(octaafbanden)
bovengrenzen = octaafbanden * math.sqrt(2)
ondergrenzen = octaafbanden / math.sqrt(2)
omega = 2 * np.pi * octaafbanden

referentie_afstand = 25  # tbv van Barkan waarop variatie is gebaseerd


# TODO define this in the CPT module, with a classmethod to initialize it using the CPT tool
class CPTData:
    """Stores output data of the CPT tool"""

    def __init__(
        self,
        depth: np.ndarray,
        E: np.ndarray,
        rho: np.ndarray,
        nu: np.ndarray,
        damping: np.ndarray,
        var_E: np.ndarray,
        var_rho: np.ndarray,
        var_nu: np.ndarray,
        var_damping: np.ndarray,
    ):
        self.depth = depth
        self.E = E
        self.rho = rho
        self.nu = nu
        self.damping = damping

        # variationcoefficients
        self.var_E = var_E
        self.var_rho = var_rho
        self.var_nu = var_nu
        self.var_damping = var_damping

    @classmethod
    def from_dict(cls, cpt_tool_output: dict) -> CPTData:
        """Initialize a CPTData object from a dictionary"""

        depth = np.array(cpt_tool_output["Depth"])
        E = np.array(cpt_tool_output["E"])
        rho = np.array(cpt_tool_output["rho"])
        nu = np.array(cpt_tool_output["v"])
        damping = np.array(cpt_tool_output["damping"])

        var_E = np.array(cpt_tool_output["var_E"])
        var_rho = np.array(cpt_tool_output["var_rho"])
        var_nu = np.array(cpt_tool_output["var_v"])
        var_damping = np.array(cpt_tool_output["var_damping"])

        return cls(depth, E, rho, nu, damping, var_E, var_rho, var_nu, var_damping)


class NaverwerkingData:
    """Stores output data of the naverwerking module"""

    def __init__(
        self, Y_ratio: np.ndarray, c: np.ndarray, c_ratio: np.ndarray, fase: np.ndarray, gevraagde_afstand: float
    ):
        """Extract the data from a dictionary to create a NaverwerkingData object"""

        # 1x6 matrices
        self.Y_ratio = Y_ratio
        self.c = c
        self.c_ratio = c_ratio
        self.fase = fase
        self.gevraagde_afstand = gevraagde_afstand

    @classmethod
    def from_dict(cls, naverwerking_dict: dict) -> NaverwerkingData:
        """Initialize a NaverwerkingData object from a dictionary"""

        Y_ratio = np.array(naverwerking_dict["Y_ratio"])
        c = np.array(naverwerking_dict["c"])
        c_ratio = np.array(naverwerking_dict["c_ratio"])
        fase = np.array(naverwerking_dict["fase"])
        gevraagde_afstand = float(naverwerking_dict["GevraagdeAfstand"])

        return cls(Y_ratio, c, c_ratio, fase, gevraagde_afstand)


class BodemOnzekerheidData:
    """A class that computes and stores bodemonzekerheid given CPT and naverwerking output data"""

    def __init__(
        self,
        gevraagde_afstand: float,
        var_Y: np.ndarray,
        var_c: np.ndarray,
        var_Y_ratio: np.ndarray,
        var_c_ratio: np.ndarray,
        var_fase: np.ndarray,
    ):
        self.gevraagde_afstand = gevraagde_afstand
        self.var_Y = var_Y
        self.var_c = var_c
        self.var_Y_ratio = var_Y_ratio
        self.var_c_ratio = var_c_ratio
        self.var_fase = var_fase

    @classmethod
    def from_dict(cls, bodemonzekerheid_dict: dict) -> BodemOnzekerheidData:
        """Initialize a BodemOnzekerheid object from a dictionary"""

        gevraagde_afstand = bodemonzekerheid_dict["GevraagdeAfstand"]
        var_Y = bodemonzekerheid_dict["var_Y"]
        var_c = bodemonzekerheid_dict["var_c"]
        var_Y_ratio = bodemonzekerheid_dict["var_Y_ratio"]
        var_c_ratio = bodemonzekerheid_dict["var_c_ratio"]
        var_fase = bodemonzekerheid_dict["var_fase"]

        return cls(gevraagde_afstand, var_Y, var_c, var_Y_ratio, var_c_ratio, var_fase)

    @classmethod
    def from_cpt_and_naverwerking(cls, cpt_data: CPTData, naverwerking_data: NaverwerkingData) -> BodemOnzekerheidData:
        """Calculate bodemonzekerheid data from cpt and naverwerking output data"""

        var_Y, var_c = BodemOnzekerheidData.get_var_Y_and_var_c(cpt_data, naverwerking_data)
        var_Y_ratio = BodemOnzekerheidData.calculate_variance(naverwerking_data.Y_ratio, True)
        var_c_ratio = BodemOnzekerheidData.calculate_variance(naverwerking_data.c_ratio, True)
        var_fase = BodemOnzekerheidData.calculate_variance(naverwerking_data.fase, False)

        # round results, like the original code
        round_decimals = 3
        var_Y = np.round(var_Y, decimals=round_decimals)
        var_c = np.round(var_c, decimals=round_decimals)
        var_Y_ratio = np.round(var_Y_ratio, decimals=round_decimals)
        var_c_ratio = np.round(var_c_ratio, decimals=round_decimals)
        var_fase = np.round(var_fase, decimals=round_decimals)

        return cls(naverwerking_data.gevraagde_afstand, var_Y, var_c, var_Y_ratio, var_c_ratio, var_fase)

    def to_dict(self) -> dict:
        """Return a dictionary containing the BodemOnzekerheid data"""

        return {
            "GevraagdeAfstand": self.gevraagde_afstand,
            "var_Y": self.var_Y.tolist(),
            "var_c": self.var_c.tolist(),
            "var_Y_ratio": self.var_Y_ratio.tolist(),
            "var_c_ratio": self.var_c_ratio.tolist(),
            "var_fase": self.var_fase.tolist(),
        }

    @staticmethod
    def get_var_Y_and_var_c(cpt_data: CPTData, naverwerking_data: NaverwerkingData) -> tuple[np.ndarray, np.ndarray]:
        """Calculate and return var_Y and var_c"""

        # make one big matrix of input data to vectorize computations as much as possible
        value_matrix = np.vstack(
            [
                cpt_data.E,
                cpt_data.rho,
                cpt_data.nu,
                cpt_data.damping,
                cpt_data.var_E,
                cpt_data.var_rho,
                cpt_data.var_nu,
                cpt_data.var_damping,
            ]
        )

        maatgevende_diepte = naverwerking_data.c / octaafbanden  # 1x6   1 golflengte
        aantal_lagen_list = [len(np.where(cpt_data.depth < maatgevende_diepte[band])[0]) for band in range(6)]

        # calculate means and standard deviations for each aantal lagen
        (
            E_means,
            rho_means,
            nu_means,
            damping_means,
            var_E_means,
            var_rho_means,
            var_nu_means,
            var_damping_means,
        ) = np.array(
            [
                np.mean(value_matrix[:, :aantal_lagen], axis=1) 
                for aantal_lagen 
                in aantal_lagen_list
            ]).T
        
        E_stds, rho_stds, nu_stds, damping_stds = np.array(
            [
                np.std(value_matrix[:4, :aantal_lagen], axis=1) 
                for aantal_lagen 
                in aantal_lagen_list
            ]
        ).T

        # compute var_Y and var_c
        damping_mu = damping_means
        nu_mu = nu_means
        var2E = var_E_means**2 + (E_stds / E_means) ** 2
        var2rho = var_rho_means**2 + (rho_stds / rho_means) ** 2
        var2nu = var_nu_means**2 + (nu_stds / nu_means) ** 2
        var2damping = var_damping_means**2 + (damping_stds / damping_means) ** 2

        alfa2 = (omega * damping_mu / naverwerking_data.c) ** 2
        var2c = var2E / 4 + var2rho / 4 + var2nu * (nu_mu / (1 + nu_mu)) ** 2
        var2Y = (
            var2E / 4
            + var2rho / 4
            + var2nu * (nu_mu**2 / (1 - nu_mu**2)) ** 2
            + var2c
            + alfa2 * (naverwerking_data.gevraagde_afstand - referentie_afstand) ** 2 * (var2damping + var2c)
        )

        var_Y = np.sqrt(var2Y)
        var_c = np.sqrt(var2c)

        return var_Y, var_c

    @staticmethod
    def calculate_variance(data: np.ndarray, normalize: bool) -> np.ndarray:
        """Calculate the variance over a trend"""

        # dan een lelijke manier om iets te zeggen over de ratio's:
        # we postuleren dat Y, c en fase spectra een lineaire trend volgen
        # de afwijking van de trend is een maat voor de onderzekerheid
        # misshcien x2 ?
        var_data = np.absolute(signal.detrend(data))
        if normalize:
            var_data = var_data / data

        # spectrum gladstrijken want afwijking per band is gebaseerd op hele spectrum
        var_data = np.polyval(np.polyfit(range(6), var_data, 1), range(6))

        # reparatie waar de var onder de 0 duikt
        var_data = np.maximum(var_data, 0.01)

        return var_data


def bodemonzekerheid(cpt_tool_output: dict, naverwerking_output: list[dict]) -> list[dict]:
    """Compute the bodemonzekerheid and write the output to a json file"""

    # ensure naverwerking_output is a list
    if not isinstance(naverwerking_output, list):
        naverwerking_output = [naverwerking_output]

    # parse input dictionary to correct objects
    cpt_data = CPTData.from_dict(cpt_tool_output)
    naverwerking_data_list = [
        NaverwerkingData.from_dict(naverwerking_output_elem) for naverwerking_output_elem in naverwerking_output
    ]

    # compute bodemonzekerheid for each distance
    bodemonzekerheid_list = [
        BodemOnzekerheidData.from_cpt_and_naverwerking(cpt_data, naverwerking_data)
        for naverwerking_data in naverwerking_data_list
    ]

    # get dicts from bodemonzekerheid objects
    resultaten = [bodemonzekerheid.to_dict() for bodemonzekerheid in bodemonzekerheid_list]

    return resultaten


def read_bodemonzekerheid_input_json(file_name: str) -> dict:
    """Read json input for the bodemonzekerheid module"""

    try:
        with open(file_name, "r") as fid:
            data = json.load(fid)
    except OSError:
        logging.error(
            f"Something went wrong while trying to read the bodemonzekerheid input json: \n{traceback.format_exc()}"
        )
        exit(101)

    return data


def write_bodemonzekerheid_output_json(file_name: str, VmaxEtc: dict):
    """Write json output to a file for the bodemonzekerheid module"""

    try:
        with open(file_name, "w+") as fid:
            json.dump(VmaxEtc, fid, separators=(",", ": "), sort_keys=True, indent=4)
    except OSError:
        logging.error(
            f"Something went wrong while trying to write the bodemonzekerheid output json: \n{traceback.format_exc()}"
        )
        exit(102)

    return


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--json", help="input JSON file", required=True)
    parser.add_argument("-o", "--output", help="location of the output folder", required=True)
    args = parser.parse_args()

    # reads input json file
    invoer = read_bodemonzekerheid_input_json(args.json)
    uitvoer = bodemonzekerheid(invoer["CPTtoolOutput"], invoer["NaverwerkingOutput"])

    # NB: error -1 nog afvangen
    # write output to json file
    uitfile = os.path.join(args.output, "bodemonzekerheidUit.json")
    write_bodemonzekerheid_output_json(uitfile, uitvoer)
