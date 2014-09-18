#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2014 KuoE0 <kuoe0.tw@gmail.com>
#
# Distributed under terms of the MIT license.

"""

"""

import os
import sys
import csv
import numpy as np
from numpy import linalg
from os import listdir
from os.path import join

def calibrate_accel(sample_x_list, sample_y_list, sample_z_list):

    sample_x_list = np.array(sample_x_list)
    sample_y_list = np.array(sample_y_list)
    sample_z_list = np.array(sample_z_list)

    A = np.array([sample_x_list, sample_y_list, sample_z_list, -(sample_y_list ** 2), -(sample_z_list ** 2), np.ones([len(sample_x_list), 1])])
    A = np.transpose(A)
    B = sample_x_list ** 2

    # solve Ax = B by least squares method
    (X, residues, rank, shape) = linalg.lstsq(A, B)

    x0 = X[0] / 2
    y0 = X[1] / (2 * X[3])
    z0 = X[2] / (2 * X[4])

    sf_x = np.sqrt(X[5] + x0 ** 2 + (y0 * X[3]) ** 2 + (z0 * X[4]) ** 2)
    sf_y = np.sqrt(sf_x ** 2 / X[3])
    sf_z = np.sqrt(sf_x ** 2 / X[4])

    return ([x0, y0, z0], [sf_x, sf_y, sf_z])

if __name__ == "__main__":

    if len(sys.argv) != 2:
        print "Usage: ./calibrate.py [directory of sample files]"
        exit()

    pwd = os.path.dirname(os.path.abspath(__file__))
    sample_dir = join(pwd, sys.argv[1])
    csv_files = [join(sample_dir, f) for f in listdir(sample_dir) if f.endswith(".csv")]

    accel_x = []
    accel_y = []
    accel_z = []

    for filename in csv_files:
        with open(filename) as f:
            reader = csv.reader(f, delimiter=',')
            for sample in reader:
                accel_x.append(float(sample[0]))
                accel_y.append(float(sample[1]))
                accel_z.append(float(sample[2]))

    zero_g, scale_factor = calibrate_accel(accel_x, accel_y, accel_z)

    print zero_g
    print scale_factor

