#!/usr/bin/env python3

import csv
import matplotlib.pyplot as plt
import numpy as np
from math import sqrt
from scipy.signal import savgol_filter

plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.5
plt.rcParams['grid.color'] = "#cccccc"

def read_csv(file_path):
    x_values, y_values = [], []
    with open(file_path, "r") as file:
        csv_reader = csv.reader(file)
        for row in csv_reader:
            if len(row) != 5:
                # The log is not properly flushed when we exit Prunt right now.
                break
            x_values.append(float(row[1]))
            y_values.append(float(row[2]))
    return x_values, y_values

def plot_2d_points(x, y):
    plt.plot(x, y, "-")
    plt.show()

x_values, y_values = read_csv("tmp.csv")
# plot_2d_points(x_values, y_values)

step_time = 0.0005

def plot_kinematics(x, y):
    velocities = []
    velocities_x = []
    velocities_y = []
    for i in range(1, len(x)):
        velocity = sqrt((x[i] - x[i - 1])**2 + (y[i] - y[i - 1])**2)
        velocity_x = x[i] - x[i - 1]
        velocity_y = y[i] - y[i - 1]
        velocities.append(velocity / step_time)
        velocities_x.append(velocity_x / step_time)
        velocities_y.append(velocity_y / step_time)

    velocities = np.array(velocities)
    velocities_x = np.array(velocities_x)
    velocities_y = np.array(velocities_y)
    velocities = savgol_filter(velocities, 11, 2)
    velocities_x = savgol_filter(velocities_x, 11, 2)
    velocities_y = savgol_filter(velocities_y, 11, 2)
    derivatives = [velocities]
    derivatives_x = [velocities_x]
    derivatives_y = [velocities_y]
    for i in range(4):
        derivatives.append(savgol_filter(np.gradient(derivatives[-1], step_time), 11, 2))
        derivatives_x.append(savgol_filter(np.gradient(derivatives_x[-1], step_time), 11, 2))
        derivatives_y.append(savgol_filter(np.gradient(derivatives_y[-1], step_time), 11, 2))

    fig, axes = plt.subplots(6, 1)

    axes[0].plot(x, y, "-")
    axes[0].set_title("2D Points")

    axes[1].plot(velocities[:], "-")
    axes[1].plot(velocities_x[:], "--r")
    axes[1].plot(velocities_y[:], "--g")
    axes[1].set_title("Velocity")

    for i in range(4):
        axes[i+2].plot(derivatives[i+1][:], "-")
        axes[i+2].plot(derivatives_x[i+1][:], "--r")
        axes[i+2].plot(derivatives_y[i+1][:], "--g")
        names = ["Acceleration", "Jerk", "Snap", "Crackle", "Pop"]
        axes[i+2].set_title(names[i])

    plt.show()

plot_kinematics(x_values[27600:], y_values[27600:])
