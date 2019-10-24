import pygame
import multiprocessing as mp
import requests
import numpy
cimport numpy
import os
import glob
from PIL import Image
DEF tilesize = 128

tilesperscreen = 5 # zoom

from console_progressbar import ProgressBar

cdef loadgrounds():
    grounds = {}
    for file in glob.glob("./OneLifeData/ground/ground_*.tga"):
        grounds[os.path.basename(file.replace("ground_","").replace(".tga",""))] = pygame.transform.scale(pygame.image.load(file),(tilesize,tilesize))
    return grounds

cpdef display_process(pipe):
    grounds = loadgrounds()
    pipe.send("READY")
    # Define some colors
    BLACK = (0, 0, 0)
    WHITE = (255, 255, 255)
    GREEN = (0, 255, 0)
    RED = (255, 0, 0)
    pygame.init()
    # Set the width and height of the screen [width, height]
    size = (tilesize*tilesperscreen, tilesize*tilesperscreen)
    screen = pygame.display.set_mode(size)
    pygame.display.set_caption("PyOHOL")
    # Loop until the user clicks the close button.
    done = False
    # Used to manage how fast the screen updates
    clock = pygame.time.Clock()
    screenSurface = pygame.Surface(size)
    while not done:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                done = True
        # command getter goes here
        changed = False
        while pipe.poll():
            changed = True
            command = pipe.recv()
            if command == "STOP":
                done = True
            if command.startswith("DRAWPIXEL"):
                command = command.split()
                _ = command.pop(0)
                x,y,r,g,b = map(int,command)
                pygame.draw.line(screenSurface,(r,g,b),(x,y),(x,y))
            if command.startswith("DRAWLINE"):
                command = command.split()
                _ = command.pop(0)
                x1,y1,x2,y2,r,g,b = map(int,command)
                pygame.draw.line(screenSurface,(r,g,b),(x1,y1),(x2,y2))
            if command.startswith("DRAWFLOOR"):
                command = command.split()
                _ = command.pop(0)
                x,y = map(int,[command[0],command[1]])
                id = command[2]
                x,y = x*tilesize,y*tilesize
                screenSurface.blit(grounds[id],(x,y))
            pipe.send("OK")
            # do things
        if changed:
            screen.fill(WHITE)
            screen.blit(screenSurface,(0,0))
            pygame.display.flip()
        clock.tick(60)
    pygame.quit()


cdef groundtest():
    return "DRAWFLOOR 0 0 0#DRAWFLOOR 1 0 1#DRAWFLOOR 2 0 2#DRAWFLOOR 3 0 3#DRAWFLOOR 4 0 4#DRAWFLOOR 0 1 5#DRAWFLOOR 1 1 6#DRAWFLOOR 2 1 U"
cdef fill(floor="0"):
    out = []
    cdef int x,y
    for x in range(tilesperscreen):
        for y in range(tilesperscreen):
            out.append("DRAWFLOOR {} {} {}".format(x,y,floor))
    return "#".join(out)
cdef tile():
    cdef int x,y
    out = []
    for x in range(tilesperscreen):
        for y in range(tilesperscreen):
            out.append("DRAWFLOOR {} {} {}".format(x,y,["0","1","2","3","4","5","6","U"][(y*(tilesperscreen-1)+x)%7]))
    return "#".join(out)
macros = {
    "GROUNDTEST": groundtest,
    "TILE": tile
}
cdef class Map():
    cdef public object map
    cdef public object camera
    cdef public object tilesper
    cdef public object changed
    def __init__(self,cx,cy,tilesper):
        self.map = {}
        self.camera = (cx,cy)
        self.tilesper = tilesper
        self.changed = []
    cpdef setat(self,x,y,ground,biome,tile):
        if x in self.map:
            self.map[x][y] = (ground,biome,tile)
        else:
            self.map[x] = {}
            self.map[x][y] = (ground,biome,tile)
        self.changed.append((x,y))
    cpdef getat(self,x,y):
        if x in self.map:
            if y in self.map[x]:
                return self.map[x][y]
        self.setat(x,y,"U","0","0")
        return ("U","0","0")
    cpdef draw(self):
        cdef int dx,dy
        out = []
        for dx in range(self.camera[0],self.camera[0]+self.tilesper):
            for dy in range(self.camera[1],self.camera[1]+self.tilesper):
                if (dx,dy) in self.changed:
                    out.append("DRAWFLOOR {} {} {}".format(dx-self.camera[0],dy-self.camera[1],self.getat(dx,dy)[0]))
        return out




def server_process(saddr,sport,pipe):
    pass
def main():
    display,d = mp.Pipe()
    display_proc = mp.Process(target=display_process,args=(d,))
    display_proc.start()
    while not display.poll():
        pass
    m = ""
    while display_proc.is_alive() and m != "q":
        m = input(">")
        if m.startswith("MACRO"):
            m = m.split()
            macroname = m[1]
            if macroname in macros:
                macroz = macros[macroname]().split("#")
                for macro in macroz:
                    display.send(macro)
                    display.recv()
            continue
        if m.startswith("MAP"):
            map = Map(0,1,tilesperscreen)
            map.setat(0,0,"1","0","0")
            map.setat(0,1,"2","0","0")
            drawn = map.draw()
            [display.send(x) for x in drawn]
        if m != "q":
            display.send(m)
            print(display.recv())
    print("Stopping")
    display.send("STOP")
    display_proc.join()

if __name__ == "__main__":
    main()
