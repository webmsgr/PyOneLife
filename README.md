# PyOneLife
"Hack" client for OHOL

# Installation
1. clone the repo
2. update the submodules with `git submodule update --init`
3. install the requirements with `pip3 install -r requirements.txt`
4. run `python setup.py install` to install the game, add `--cython` to compile from source
5. run `entrypoint.py` to launch


# Commands
While testing, there will be a number of commands to emulate the game client code. These are as follows: 
1. `DRAWPIXEL x y r g b`
2. `DRAWLINE x1 y1 x2 y2 r g b`
3. `DRAWFLOOR x y id` where id is any number 0-6
4. `MACRO name` execute a macro
5. `q` quit
# Macros
The following macros are avalable:
1. `GROUNDTEST` display all ground tiles
2. `MAP` display a test map
3. `TILE` Display all tiles over the entire screen
