"""
Inverse distance interpolation
"""
# import packages
import numpy as np
from scipy.spatial import cKDTree
from scipy.interpolate import interp1d


class InverseDistance:
    """
    Inverse distance interpolator
    """
    def __init__(self, nb_points=6, pwr=1, tol=1e-9, default_cov=10.):
        """
        Initialise Inverse distance interpolation

        :param nb_points: (optional) number of k-nearest neighbours used for interpolation. Default is 6
        :param pwr: (optional) power of the inverse. Default is 1
        :param tol: (optional) tolerance added to the point distance to overcome division by zero. Default is 1e-9
        :param default_cov: (optional) default covariance for the case of only one datapoint. Default is 10
        """
        # define variables
        self.tree = []  # KDtree with nearest neighbors
        self.zn = []  # interpolation results
        self.var = []  # interpolation variance
        self.training_data = []  # training data
        self.training_points = []  # training points
        self.depth_data = []  # training points depth
        self.depth_prediction = []  # interpolation depth
        # settings
        self.nb_near_points = nb_points
        self.power = pwr
        self.tol = tol
        self.cov_default = default_cov
        return

    def interpolate(self, training_points, training_data, depth_points, depth):
        """
        Define the KDtree

        :param training_points: array with the training points
        :param training_data: data at the training points
        :param depth_points: depth at the at the training points
        :param depth: data at the interpolation points
        :return:
        """

        # assign to variables
        self.training_points = training_points  # training points
        self.training_data = training_data  # data at the training points
        self.depth_data = depth_points  # depth from the training points
        self.depth_prediction = depth  # depth for the interpolation points

        # compute Euclidean distance from grid to training
        self.tree = cKDTree(self.training_points)

        return

    def predict(self, prediction_point, point=False):
        """
        Perform interpolation with inverse distance method

        The mean and variance are computed based on :cite:`deutsch_2009`, :cite:`calle_1`, :cite:`calle_2`.

        :param prediction_point: prediction points
        :param point: (optional) boolean for the case of being a single point
        :return:
        """

        # get distances and indexes of the closest nb_points
        dist, idx = self.tree.query(prediction_point, self.nb_near_points)
        dist += self.tol  # to overcome division by zero
        dist = np.array(dist).reshape(self.nb_near_points)
        idx = np.array(idx).reshape(self.nb_near_points)

        # for every dataset
        point_aver = []
        point_val = []
        point_var = []
        point_depth = []
        for p in range(self.nb_near_points):
            # compute the weights
            wei = (1. / dist[p]**self.power) / np.sum(1. / dist ** self.power)
            # if single point
            if point:
                point_aver.append(self.training_data[idx[p]] * wei)
                point_val.append(self.training_data[idx[p]])
            # for multiple points
            else:
                point_aver.append(np.log(self.training_data[idx[p]]) * wei)
                point_val.append(np.log(self.training_data[idx[p]]))
            point_depth.append(self.depth_data[idx[p]])

        # compute average
        if point:
            zn = [np.sum(point_aver)]
        else:
            new = []
            for i in range(self.nb_near_points):
                f = interp1d(point_depth[i], point_aver[i], fill_value=(point_aver[i][-1], point_aver[i][0]), bounds_error=False)
                new.append(f(self.depth_prediction))
            zn = np.sum(np.array(new), axis=0)

        # compute variance
        if point:
            for p in range(self.nb_near_points):
                # compute the weighs
                wei = (1. / dist[p] ** self.power) / np.sum(1. / dist ** self.power)
                point_var.append((point_val[p] - zn) ** 2 * wei)
        else:
            # compute mean
            new = []
            for i in range(self.nb_near_points):
                f = interp1d(point_depth[i], point_val[i], fill_value=(point_val[i][-1], point_val[i][0]), bounds_error=False)
                new.append(f(self.depth_prediction))
            # compute variance
            for p in range(self.nb_near_points):
                # compute the weights
                wei = (1. / dist[p] ** self.power) / np.sum(1. / dist ** self.power)
                # compute var
                point_var.append((new[p] - zn) ** 2 * wei)

        var = np.sum(np.array(point_var), axis=0)

        # add to variables
        if point:
            # update to normal parameters
            self.zn = zn
            self.var = var
        else:
            # update to lognormal parameters
            self.zn = np.exp(zn + var / 2)
            self.var = np.exp(2 * zn + var) * (np.exp(var) - 1)

        # if only 1 data point is available (var = 0 for all points) -> var is default value
        if self.nb_near_points == 1:
            self.var = np.full(len(self.var), (self.cov_default * np.array(self.zn)) ** 2)
        return
