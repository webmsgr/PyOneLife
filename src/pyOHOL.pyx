import pygame
import multiprocessing as mp
import requests
import socket
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

cpdef get_dir():
    if "OneLifeData" in os.listdir("."):
        return os.path.abspath(".")
    else:
        return dir_name
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
    di = get_dir()
    grounds = {}
    for file in glob.glob(os.path.join(di,"OneLifeData/ground/ground_*.tga")):
        grounds[os.path.basename(file.replace("ground_","").replace(".tga",""))] = pygame.transform.scale(pygame.image.load(file),(tilesize,tilesize))
    return grounds

cdef loadsprites():
    sprites = {}
    di = get_dir()
    for file in glob.glob(os.path.join(di,"OneLifeData/sprites/*.tga")):
        sprites[os.path.basename(file.replace(".tga",""))] = pygame.image.load(file)
    return sprites
ctypedef (int,int,int) pygameColor

cpdef display_process(pipe):
    cdef int cx,cy
    cdef pygameColor BLACK,WHITE,GREEN,RED,BLUE
    BLACK = (0, 0, 0)
    WHITE = (255, 255, 255)
    GREEN = (0, 255, 0)
    RED = (255, 0, 0)
    BLUE = (0,0,255)
    cdef (int,int) size
    print("Loading ground")
    grounds = loadgrounds()
    print("Loading sprites")
    sprites = loadsprites()
    pipe.send("READY")
    # Define some colors
    cx,cy = 0,0
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
            if command.startswith("DRAWSPRITE"):
                command = command.split()
                _ = command.pop(0)
                tx,ty,id = map(int,command)
                offset = tilesize//2
                dx,dy = tx*tilesize+offset,ty*tilesize+offset
                screenSurface.blit(sprites[str(id)],(dx,dy))
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


cdef class OHOLObject:
    cdef public int id
    cdef public list contains
    cdef public object data
    def __init__(self,id,contains=[],data=""):
        self.id = id
        self.contains = contains
        self.data = data
cdef struct s_Tile:
    int ground
    int x,y
    int biome
    OHOLObject tile
ctypedef s_Tile Tile

cdef struct s_GridPos:
    int x
    int y
ctypedef s_GridPos GridPos

ctypedef (int,int) pos

cdef GridPos postogridpos(pos cords):
    cdef GridPos out
    out.x, out.y = cords
    return out
cdef GridPos fromcords(int x,int y):
    cdef GridPos out
    out.x,out.y = x,y
cdef class Map():
    cdef public bint force
    cdef public Tile[] map
    cdef public pos camera
    cdef public int tilesper
    cdef public list changed
    def __init__(self,cx,cy,tilesper):
        self.map = []
        self.camera = (cx-1,cy-1)
        self.tilesper = tilesper+2
        self.changed = []
        self.force = True
    cdef bint ispos(self,int x,int y):
        for tile in self.map:
            if tile.x == x:
                if tile.y == y:
                    return True
        return False
    cdef bint removepos(self,int x,int y):
        if not self.ispos(x,y):
            return False
        for posnum,tile in enumerate(self.map):
            if tile.x == x and tile.y == y:
                self.map.pop(posnum)
        return True
    cdef setat(self,int x,int y,int ground,int biome,tile):
        cdef Tile tiletmp
        cdef OHOLObject obj
        obj = OHOLObject(0,[],tile)
        tiletmp.x,tiletmp.y =x,y
        tiletmp.ground = ground
        tiletmp.biome = biome
        tiletmp.tile = obj
        self.removepos(x,y)
        self.map.append(tiletmp)
        self.changed.append((x,y))
    cdef Tile getat(self,int x,int y):
        if not self.ispos(x,y):
            self.setat(x,y,4,0,"0")
            return self.getat(x,y)
        else:
            for tile in self.map:
                if tile.x == x and tile.y == y:
                    return tile
    cpdef draw(self):
        cdef int dx,dy
        out = []
        for dx in range(self.camera[0],self.camera[0]+self.tilesper):
            for dy in range(self.camera[1],self.camera[1]+self.tilesper):
                if (dx,dy) in self.changed or self.force:
                    out.append("DRAWFLOOR {} {} {}".format(dx-self.camera[0]-1,dy-self.camera[1]-1,self.getat(dx,dy).ground))
                    if not self.force:
                        self.changed.remove((dx,dy))
                    if self.force:
                        self.changed = []
        self.force = False
        return out
    cpdef up(self,int amt):
        self.camera = (self.camera[0],self.camera[1]-amt)
        self.force = True
    cpdef down(self,int amt):
        self.force = True
        self.camera = (self.camera[0],self.camera[1]+amt)
    cpdef right(self,int amt):
        self.force = True
        self.camera = (self.camera[0]+amt,self.camera[1])
    cpdef left(self,int amt):
        self.force = True
        self.camera = (self.camera[0]-amt,self.camera[1])




def server_process(saddr,sport,pipe):
    pass



cpdef main():
    cdef int i
    mp.freeze_support()
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
            map.setat(0,0,0,0,"0")
            map.setat(0,1,1,0,"0")
            map.setat(1,0,2,0,"0")
            map.setat(1,1,3,0,"0")
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
