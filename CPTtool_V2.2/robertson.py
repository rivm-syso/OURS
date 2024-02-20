"""
Robertson soil classification
"""
# import packages
import os
import numpy as np
import shapefile
from shapely.geometry import Polygon
from shapely.geometry import Point
# import OURS packages
from CPTtool import tools_utils


class Robertson:
    r"""
    Robertson soil classification.

    Classification of soils according to Robertson chart.

    .. _element:
    .. figure:: ./_static/robertson.png
        :width: 350px
        :align: center
        :figclass: align-center
    """

    def __init__(self):
        # In this generic way from the input file an arbitrary amount of polygons can be parsed from a shape file.
        self.soil_types_list = []
        self.polygons = []
        return

    def soil_types(self, path_shapefile=r"./shapefiles/", model_name='Robertson'):
        r"""
        Function that read shapes from shape file and passes them as Polygons.

        :param path_shapefile: Path to the shapefile
        :param model_name: Name of model and shapefile
        :return: list of the polygons defining the soil types
        """

        # define the path for the shape file
        path_shapefile = tools_utils.resource_path(os.path.join(os.path.join(os.path.dirname(__file__), path_shapefile), model_name))

        # read shapefile
        sf = shapefile.Reader(path_shapefile)
        list_of_polygons = []
        for polygon in list(sf.iterShapes()):
            list_of_polygons.append(Polygon(polygon.points))
        self.polygons = list_of_polygons
        return

    def lithology(self, Qtn, Fr):
        r"""
        Identifies lithology of CPT points, following Robertson and Cabal :cite:`robertson_cabal_2014`.

        Parameters
        ----------
        :param gamma_limit: Maximum value for gamma
        :param z_pwp: Depth pore water pressure
        :param iter_max: (optional) Maximum number of iterations
        :return: lithology array, Qtn, Fr
        """

        litho = [""] * len(Qtn)
        coords = np.zeros((len(Qtn), 2))

        # determine into which soil type the point is
        for i in range(len(Qtn)):
            pnt = Point(Fr[i], Qtn[i])
            aux = []
            for polygon in self.polygons:
                aux.append(polygon.contains(pnt))

            # check if point is within a boundary
            if all(not x for x in aux):
                aux = []
                for polygon in self.polygons:
                    aux.append(polygon.touches(pnt))

            idx = np.where(np.array(aux))[0][0]
            litho[i] = str(idx + 1)
            coords[i] = [Fr[i], Qtn[i]]

        return litho, np.array(coords)
