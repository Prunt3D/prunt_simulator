#!/usr/bin/env python3

import queue
import numpy as np
import matplotlib.pyplot as plt
from math import sqrt
from matplotlib.animation import FuncAnimation
import threading
from copy import deepcopy
from matplotlib.widgets import Slider, CheckButtons

plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.5
plt.rcParams['grid.color'] = "#cccccc"
plt.rcParams['axes.titley'] = 1.0
plt.rcParams['axes.titlepad'] = -14

animation_queue = queue.Queue(maxsize=1)

fig = plt.figure(constrained_layout=True)

position_fig, derivative_fig, control_fig = fig.subfigures(3, 1, height_ratios=[1, 2, 0.2])

position_axes = [position_fig.subplots(1, 1)]

position_axes[0].set_aspect(1)
position_axes[0].set_title("2D Points")

derivative_axes = derivative_fig.subplots(5, 1, gridspec_kw={'height_ratios': [1, 1, 1, 1, 1]}, sharex=True)

derivative_axes[0].set_title("Velocity")
derivative_axes[1].set_title("Acceleration")
derivative_axes[2].set_title("Jerk")
derivative_axes[3].set_title("Snap")
derivative_axes[4].set_title("Crackle")

control_axes = control_fig.subplots(1, 3)

control_axes[0].axis("off")
control_axes[1].axis("off")
control_axes[2].axis("off")

max_plot_length = 20000
slider_step = Slider(control_axes[0], "Step Size", 1, 500, valinit=100, valstep=1)
slider_length = Slider(control_axes[1], "Plot Length", 100, max_plot_length, valinit=10000, valstep=1)
checkbox_pause = CheckButtons(control_axes[2], ["Pause"], [False])

paused = False

def toggle_pause(_):
    global paused
    paused = not paused

checkbox_pause.on_clicked(toggle_pause)

last_positions = [[0.0] * 10] * 4
last_derivatives = [[[0.0] * 10] * 5] * 5

def update_plot(_, q):
    global last_positions
    global last_derivatives

    plot_length = int(slider_length.val)

    if not q.empty() and not paused:
        last_positions, last_derivatives = q.get()

    position_axes[0].clear()
    position_axes[0].plot(last_positions[0][-plot_length:], last_positions[1][-plot_length:], "b-")

    for i in range(0, len(last_derivatives)):
        derivative_axes[i].clear()
        for j in range(0, len(last_derivatives[i])):
            derivative_axes[i].plot(last_derivatives[i][j][-plot_length:], ["r", "g", "b", "m", "y"][j] + "-")

    position_axes[0].set_aspect(1)
    position_axes[0].set_title("2D Points")
    derivative_axes[0].set_title("Velocity")
    derivative_axes[1].set_title("Acceleration")
    derivative_axes[2].set_title("Jerk")
    derivative_axes[3].set_title("Snap")
    derivative_axes[4].set_title("Crackle")

flush_needed = False

def input_loop(q):
    global flush_needed

    step_time = 0.0001

    step = 0

    positions = [[0.0] * 10, [0.0] * 10, [0.0] * 10, [0.0] * 10]
    velocities = [[0.0] * 10, [0.0] * 10, [0.0] * 10, [0.0] * 10, [0.0] * 10]

    while True:
        # TODO: These are not thread-safe, but it appears to work for now.
        input_step_size = int(slider_step.val)

        new_pos = [float(x) for x in input().split(",")[1:]]

        step += 1

        velocity_square_sum = 0.0
        for i in range(0, len(new_pos)):
            positions[i].append(new_pos[i])
            velocities[i].append((positions[i][-1] - positions[i][-2]) / step_time)
            velocity_square_sum += velocities[i][-1]**2
        velocities[-1].append(sqrt(velocity_square_sum))

        if velocities[-1][-1] != 0.0:
            flush_needed = True

        if step >= input_step_size or (velocities[-1][-1] == 0.0 and flush_needed):
            flush_needed = False

            step = 0

            if len(positions[i]) > max_plot_length:
                del positions[i][:-max_plot_length]

            for i in range(0, len(velocities)):
                if len(velocities[i]) > max_plot_length:
                    del velocities[i][:-max_plot_length]

            derivatives = [[np.array(x) for x in velocities]]

            for j in range(1, 5):
                derivatives.append([np.diff(derivatives[0][i], n=j) / step_time**j for i in range(0, len(derivatives[-1]))])

            q.put((deepcopy(positions), derivatives))

input_thread = threading.Thread(target=input_loop, args=(animation_queue,), daemon=True)
input_thread.start()

plot_animation = FuncAnimation(fig, update_plot, interval=50, fargs=(animation_queue,), cache_frame_data=False)
plt.show()
