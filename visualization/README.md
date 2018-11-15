## Visualization Library
To visualize the 3D coordinates of our ping pong ball trajectory we are using the "vpython" library for it's ease of use and documentation. The code is written in python and documentation of the library can be found here: "http://www.glowscript.org/docs/VPythonDocs/index.html"

## Running the Program 
Before running the program please make sure: 

- Your Python version is `3.5.3` or later
- You have the "vpython" module installed. `conda install -c vpython vpython` or `pip install vpython`.

To run the program, simply open your terminal, and run: `python trajectory.py`

## Controlling the playback
We can control the playback of the pingpong balls by using the "up" key arrow. To run the animation automatically simply uncomment the LOC at 104. `scene.waitfor('keyup')`
