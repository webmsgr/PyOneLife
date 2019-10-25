import pygame
import multiprocessing as mp
import requests
import numpy
cimport numpy
import os
import time
import glob
path = os.path.abspath(__file__)
dir_name = os.path.dirname(path)
from PIL import Image
DEF tilesize = 128
cdef extern from "miniz.h":
    pass
cdef extern from "miniz.c":
    int mz_uncompress(unsigned char *pDest, unsigned long *pDest_len, const unsigned char *pSource, unsigned long source_len);


cpdef parse_chunk(bytes header,bytes compressed):
    cdef unsigned char *mpdata
    cdef unsigned long *csize
    cdef unsigned long cbsize
    cdef unsigned long before
    cdef bytes out
    cdef char beforetwo = compressed
    cdef char *step2 = &(beforetwo)
    cdef unsigned char *pSource = <unsigned char *>step2
    header = header.split()
    _, width, height, x, y, size, cbuffersize = header
    cbsize = <unsigned long>int(cbuffersize)
    before = <unsigned long>int(size)
    csize = &(before)
    mz_uncompress(mpdata,csize,pSource,cbsize)
    out = <bytes>mpdata

tilesperscreen = 5 # zoom

from console_progressbar import ProgressBar

cdef loadgrounds():
    grounds = {}
    for file in glob.glob(os.path.join(dir_name,"OneLifeData/ground/ground_*.tga")):
        grounds[os.path.basename(file.replace("ground_","").replace(".tga",""))] = pygame.transform.scale(pygame.image.load(file),(tilesize,tilesize))
    return grounds

cpdef display_process(pipe):
    cdef int cx,cy
    grounds = loadgrounds()
    pipe.send("READY")
    # Define some colors
    cx,cy = 0,0
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
    nt = tilesperscreen+2
    screenSurface = pygame.Surface((tilesize*nt,tilesize*nt))
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
                continue
            if command.startswith("DRAWLINE"):
                command = command.split()
                _ = command.pop(0)
                x1,y1,x2,y2,r,g,b = map(int,command)
                pygame.draw.line(screenSurface,(r,g,b),(x1,y1),(x2,y2))
                continue
            if command.startswith("DRAWFLOOR"):
                command = command.split()
                _ = command.pop(0)
                x,y = map(int,[command[0],command[1]])
                x,y = x+1,y+1
                id = command[2]
                x,y = x*tilesize,y*tilesize
                screenSurface.blit(grounds[id],(x,y))
                continue
            if command.startswith("SETCAM"):
                command = command.split()
                _ = command.pop(0)
                cx,cy = map(int,command)
                continue
            # do things
        if changed:
            screen.fill(WHITE)
            screen.blit(screenSurface,(cx-128,cy-128))
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
    cdef public bint force
    cdef public object map
    cdef public object camera
    cdef public object tilesper
    cdef public object changed
    def __init__(self,cx,cy,tilesper):
        self.map = {}
        self.camera = (cx-1,cy-1)
        self.tilesper = tilesper+2
        self.changed = []
        self.force = True
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
                if (dx,dy) in self.changed or self.force:
                    out.append("DRAWFLOOR {} {} {}".format(dx-self.camera[0]-1,dy-self.camera[1]-1,self.getat(dx,dy)[0]))
                    if not self.force:
                        self.changed.remove((dx,dy))
                    if self.force:
                        self.changed = []
        self.force = False
        return out
    cpdef up(self,amt):
        self.camera = (self.camera[0],self.camera[1]-amt)
        self.force = True




def server_process(saddr,sport,pipe):
    pass

	
	
def main():
    cdef int i
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
            continue
        if m.startswith("MAP"):
            map = Map(-1,-1,tilesperscreen)
            map.setat(0,0,"0","0","0")
            map.setat(0,1,"1","0","0")
            map.setat(1,0,"2","0","0")
            map.setat(1,1,"3","0","0")
            drawn = map.draw()
            [display.send(x) for x in drawn]
            if map.draw() != []:
                raise RuntimeError
        if m.startswith("SLIDE"):
            map = Map(0,0,tilesperscreen)
            map.setat(0,-1,"1","0","0")
            [map.setat(0,y,"0","0","0") for y in range(10)]
            map.force = True
            drawn = map.draw()
            [display.send(x) for x in drawn]
            time.sleep(1)
            for i in range(0,129):
                display.force = True
                display.send("SETCAM 0 {}".format(i))
                time.sleep(0.1)
            map.up(1)
            drawn = ["SETCAM 0 0"] + map.draw()
            [display.send(x) for x in drawn]
        if m != "q":
            display.send(m)
    print("Stopping")
    display.send("STOP")
    display_proc.join()

if __name__ == "__main__":
    main()
