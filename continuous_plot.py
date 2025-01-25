#!/usr/bin/env python3

import queue
import numpy as np
import matplotlib.pyplot as plt
from math import sqrt
from matplotlib.animation import FuncAnimation
import threading
from copy import deepcopy

plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.5
plt.rcParams['grid.color'] = "#cccccc"

animation_queue = queue.Queue(maxsize=1)

fig, axes = plt.subplots(6, 1, gridspec_kw={'height_ratios': [4, 1, 1, 1, 1, 1]}, constrained_layout=True)

axes[0].set_aspect(1)
axes[0].set_title("2D Points")
axes[1].set_title("Velocity")
axes[2].set_title("Acceleration")
axes[3].set_title("Jerk")
axes[4].set_title("Snap")
axes[5].set_title("Crackle")

def update_plot(_, q):
    if not q.empty():
        positions, derivatives = q.get()

        axes[0].clear()
        axes[0].plot(positions[0][5:-5], positions[1][5:-5], "b-")

        for i in range(0, len(derivatives)):
            axes[i + 1].clear()
            for j in range(0, len(derivatives[i])):
                axes[i + 1].plot(derivatives[i][j][5:-5], ["r", "g", "b", "m", "y"][j] + "-")

        axes[0].set_aspect(1)
        axes[0].set_title("2D Points")
        axes[1].set_title("Velocity")
        axes[2].set_title("Acceleration")
        axes[3].set_title("Jerk")
        axes[4].set_title("Snap")
        axes[5].set_title("Crackle")

def input_loop(q):
    step_time = 0.0001

    step = 0

    positions = [[0.0] * 10, [0.0] * 10, [0.0] * 10, [0.0] * 10]
    velocities = [[0.0] * 10, [0.0] * 10, [0.0] * 10, [0.0] * 10, [0.0] * 10]

    while True:
        new_pos = [float(x) for x in input().split(",")[1:]]

        step += 1

        velocity_square_sum = 0.0
        for i in range(0, len(new_pos)):
            positions[i].append(new_pos[i])
            if len(positions[i]) > 10000:
                del positions[i][:100]
            velocities[i].append((positions[i][-1] - positions[i][-2]) / step_time)
            velocity_square_sum += velocities[i][-1]**2
        velocities[-1].append(sqrt(velocity_square_sum))

        for i in range(0, len(velocities)):
            if len(velocities[i]) > 10000:
                del velocities[i][:100]

        if step == 100 or velocities[-1][-1] == 0.0:
            step = 0

            derivatives = [[np.array(x) for x in velocities]]

            for _ in range(4):
                derivatives.append([np.gradient(derivatives[-1][i], step_time) for i in range(0, len(derivatives[-1]))])

            q.put((deepcopy(positions), derivatives))

input_thread = threading.Thread(target=input_loop, args=(animation_queue,), daemon=True)
input_thread.start()

plot_animation = FuncAnimation(fig, update_plot, interval=100, fargs=(animation_queue,), cache_frame_data=False)
plt.show()
