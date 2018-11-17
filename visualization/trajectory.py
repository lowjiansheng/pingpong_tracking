from vpython import *
import csv
import random

# Display texts below the 3D graphics
scene.title = "3D Ping Pong Ball Trajectory"

# Displaying X,Y,Z axis
L = 0
axis_size = 0.3
text_size = 0.15
axis_pos = 0.35
x_axis = arrow(pos=vector(0,0,0), color=color.white, axis=vector(axis_size,0,0))
y_axis = arrow(pos=vector(0,0,0), color=color.white, axis=vector(0,axis_size,0))
z_axis = arrow(pos=vector(0,0,0), color=color.white, axis=vector(0,0,axis_size))
# Displaying X,Y,Z label
T = text(text='x',align='center', color=color.white, pos=vector(axis_pos,-0.05,0), height=text_size)
T = text(text='y',align='center', color=color.white, pos=vector(0,axis_pos,0), height=text_size)
T = text(text='z',align='center', color=color.white, pos=vector(0,-0.05,axis_pos), height=text_size)

# Table properties
table_color = color.green
table_arrow_color = color.white
table_arrow_scale = 0.05

# Sphere properties:
sphere_radius = 0.05
sphere_colors = [ color.red, color.orange, color.cyan ]
sphere_make_trail = True
sphere_move_rate = 50 # The smaller the integer, the slower

# Sphere-arrow properties (direction of ping pong ball)
arrow_color = color.yellow
arrow_scale = 0.7

class DataParser:
    def __init__(self, folder_name, table_coordinates_file):
        # Go through each trajectory coordinates
        self.trajectories = { }
        for i in range(1, 11):
            file_name = './' + folder_name + '/trajectory_' + str(i) +'.csv'
            coordinates = []
            with open(file_name) as csv_file:
                csv_reader = csv.reader(csv_file, delimiter=',')
                row_count = 0
                for row in csv_reader:
                    if row_count > 0:
                        x_coor = float(row[0])
                        y_coor = float(row[1])
                        z_coor = float(row[2])
                        coordinates.append((x_coor, y_coor, z_coor))
                    row_count += 1
            self.trajectories[file_name] = coordinates
        print("> Done reading ball trajectory inputs")
        # Read in table coordinates
        file_name = './' + folder_name + '/' + table_coordinates_file + '.csv'
        with open(file_name) as csv_file:
            csv_reader = csv.reader(csv_file, delimiter=',')
            row_count = 0
            table_corners = []
            for row in csv_reader:
                if row_count > 0:
                    table_corners.append((float(row[0]), float(row[1]), float(row[2])))
                row_count += 1
        self.corners = table_corners
        print("> Done reading table coordinates")

# Parser initialization to read in data files
data = DataParser('data', 'table_coordinates')

# Table vector initialization
table_bottom_left_corner = data.corners[0]
table_bottom_right_corner = data.corners[3]
x_lc, y_lc, z_lc = table_bottom_left_corner
x_rc, y_rc, z_rc = table_bottom_right_corner
table_vector = ((x_rc - x_lc), (y_rc - y_lc), (z_rc - z_lc))
table_x, table_y, table_z = table_vector
table_vector = vector(table_x, table_y, table_z)

# Table initialization
table = box(
    pos=vector(0, 0, 0),
    axis=table_vector * 10,
    size=vector(5, 2.5, 0.04),
    color=table_color,
    shininess=0,
    opacity=0.2
    )

for key in data.trajectories:
    coordinates = data.trajectories[key]
    # Ball initialisation
    x, y, z = coordinates[0]
    sphere_color = random.choice(sphere_colors)
    ball = sphere(pos=vector(x, y, z), radius=sphere_radius, color=sphere_color, make_trail=sphere_make_trail)
    # Ball arrow direction initialisation
    forward_step = 5
    for_x, for_y, for_z = coordinates[forward_step]
    ball_forward_pos = vector(for_x, for_y, for_z)
    sphere_arrow = arrow(pos=ball.pos, color=arrow_color, axis=(ball_forward_pos - ball.pos))
    table_arrow = arrow(pos=ball.pos, color=table_arrow_color, axis=table_vector * table_arrow_scale)
    # Ball parallel 
    for i in range (1, len(coordinates)):
        scene.waitfor('keyup')  # wait for keyboard key release
        rate(sphere_move_rate) # limit animation rate, render scene
        x, y, z = coordinates[i]
        if i < len(coordinates) - forward_step:
            for_x, for_y, for_z = coordinates[i + forward_step]
            arrow_axis = (vector(for_x, for_y, for_z) - ball.pos) * arrow_scale
        else :
            for_z, for_y, for_z = coordinates[i] 
            arrow_axis = (vector(for_x, for_y, for_z) - ball.pos) * arrow_scale
        ball.pos = vector(x, y, z)
        # Update ball arrow direction
        sphere_arrow.pos = ball.pos
        sphere_arrow.axis = arrow_axis
        # Update table arrow vector
        table_arrow.pos = ball.pos
    # break # Comment To only run animation of 1 pingpong ball
