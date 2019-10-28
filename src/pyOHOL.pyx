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
DEF spriteoffset = tilesize//2
cdef extern from "miniz.h":
    pass
cdef extern from "miniz.c":
    int mz_uncompress(unsigned char *pDest, unsigned long *pDest_len, const unsigned char *pSource, unsigned long source_len);

cdef get_dir():
    if "OneLifeData" in os.listdir("."):
        return os.path.abspath(".")
    else:
        return dir_name
cdef parse_chunk(bytes header,bytes compressed):
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
        sprites[int(os.path.basename(file.replace(".tga","")))] = pygame.image.load(file)
    return sprites
ctypedef (int,int,int) pygameColor

cpdef display_process(pipe):
    cdef int cx,cy
    cdef pygamecommand command
    cdef pygameColor BLACK,WHITE,GREEN,RED,BLUE
    BLACK = (0, 0, 0)
    WHITE = (255, 255, 255)
    GREEN = (0, 255, 0)
    RED = (255, 0, 0)
    BLUE = (0,0,255)
    oldfps = 0
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
            if command.command == STOP:
                done = True
            if command.command == DRAWFLOOR:
                x,y = map(int,[command.args[0],command.args[1]])
                x,y = x+1,y+1
                id = command.args[2]
                x,y = x*tilesize,y*tilesize
                screenSurface.blit(grounds[str(id)],(x,y))
                continue
            if command.command == CAMERA:
                cx,cy = map(int,command.args)
                continue
            if command.command == DRAWSPRITE:
                tx,ty,id = map(int,command.args)
                dx,dy = (tx+1)*tilesize,(ty+1)*tilesize
                screenSurface.blit(sprites[id],(dx,dy))
                continue
            # do things
        if changed:
            screen.fill(WHITE)
            screen.blit(screenSurface,(cx-128,cy-128))
            pygame.display.flip()
        fps = int(clock.get_fps())
        clock.tick(60)
    pygame.quit()

cdef class OHOLObject:
    cdef public int id
    cdef public list contains
    cdef public object data
    def __init__(self,id,contains=[],data=""):
        self.id = id
        self.contains = contains
        self.data = data
cdef class Tile:
    cdef public int ground
    cdef public int x,y
    cdef public int biome
    cdef public OHOLObject tile
    def __init__(self,x,y,ground,biome,tile):
        self.x,self.y = x,y
        self.ground = ground
        self.biome = biome
        self.tile = tile
cdef enum commands:
    DRAWFLOOR,
    DRAWSPRITE,
    CAMERA,
    STOP
cdef struct s_GridPos:
    int x
    int y
ctypedef s_GridPos GridPos

ctypedef (int,int) pos
cdef class pygamecommand:
    cdef public commands command
    cdef public list args
    def __init__(self,command,args=[]):
        self.command = command
        self.args = args
cdef GridPos postogridpos(pos cords):
    cdef GridPos out
    out.x, out.y = cords
    return out
cdef GridPos fromcords(int x,int y):
    cdef GridPos out
    out.x,out.y = x,y
cdef class Map():
    cdef public bint force
    cdef public list map
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
    cdef setat(self,int x,int y,int ground,int biome,int tileid):
        cdef Tile tiletmp
        cdef OHOLObject obj
        obj = OHOLObject(tileid,[],"")
        tiletmp = Tile(x,y,ground,biome,obj)
        self.setatTile(x,y,tiletmp)
    cdef setatTile(self,int x,int y, Tile tile):
        self.removepos(x,y)
        self.map.append(tile)
        self.changed.append((x,y))
    cdef Tile getat(self,int x,int y):
        if not self.ispos(x,y):
            self.setat(x,y,4,0,0)
            return self.getat(x,y)
        else:
            for tile in self.map:
                if tile.x == x and tile.y == y:
                    return tile
    cdef draw(self):
        cdef int dx,dy
        out = []
        for dx in range(self.camera[0],self.camera[0]+self.tilesper):
            for dy in range(self.camera[1],self.camera[1]+self.tilesper):
                if (dx,dy) in self.changed or self.force:
                    argsGround = [dx-self.camera[0]-1,dy-self.camera[1]-1,self.getat(dx,dy).ground]
                    out.append(pygamecommand(DRAWFLOOR,argsGround))
                    if self.getat(dx,dy).tile.id != 0:
                        argsSprite = [dx-self.camera[0]-1,dy-self.camera[1]-1,self.getat(dx,dy).tile.id]
                        out.append(pygamecommand(DRAWSPRITE,argsSprite))

                    if not self.force:
                        self.changed.remove((dx,dy))
                    if self.force:
                        if (dx,dy) in self.changed:
                            self.changed.remove((dx,dy))
        self.force = False
        return out
    cdef up(self,int amt):
        self.camera = (self.camera[0],self.camera[1]-amt)
        self.force = True
    cdef down(self,int amt):
        self.force = True
        self.camera = (self.camera[0],self.camera[1]+amt)
    cdef right(self,int amt):
        self.force = True
        self.camera = (self.camera[0]-amt,self.camera[1])
    cdef left(self,int amt):
        self.force = True
        self.camera = (self.camera[0]+amt,self.camera[1])




cpdef server_process(saddr,sport,pipe):
    pass



cpdef main():
    cdef int i,yslide
    mp.freeze_support()
    display,d = mp.Pipe()
    display_proc = mp.Process(target=display_process,args=(d,))
    display_proc.start()
    while not display.poll():
        pass
    m = ""
    while display_proc.is_alive() and m != "q":
        m = input(">")
        if m.startswith("MAP"):
            map = Map(-1,-1,tilesperscreen)
            map.setat(0,0,0,0,996)
            map.setat(0,1,1,0,998)
            map.setat(1,0,2,0,997)
            map.setat(1,1,3,0,999)
            drawn = map.draw()
            [display.send(x) for x in drawn]
            if map.draw() != []:
                raise RuntimeError
            continue
        if m.startswith("SLIDE"):
            map = Map(0,0,tilesperscreen)
            map.setat(0,-1,1,0,978)
            map.setat(1,-1,1,0,983)
            for yslide in range(10):
                map.setat(0,yslide,0,0,372)
                map.setat(1,yslide,0,0,918)
            map.force = True
            drawn = map.draw()
            [display.send(x) for x in drawn]
            time.sleep(1)
            for i in range(0,129):
                map.force = True
                display.send(pygamecommand(CAMERA,[0,i]))
                time.sleep(0.01)
            map.up(1)
            drawn = [pygamecommand(CAMERA,[0,0])] + map.draw()
            [display.send(x) for x in drawn]
            for i in range(0,129):
                map.force = True
                display.send(pygamecommand(CAMERA,[i,0]))
                time.sleep(0.01)
            map.right(1)
            drawn = [pygamecommand(CAMERA,[0,0])] + map.draw()
            [display.send(x) for x in drawn]
            continue
    print("Stopping")
    display.send(pygamecommand(STOP,[]))
    display_proc.join()

