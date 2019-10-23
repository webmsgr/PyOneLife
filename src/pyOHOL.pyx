import pygame
import multiprocessing as mp
import requests
import numpy
cimport numpy
import glob
from PIL import Image
DEF tilesize = 128

tilesperscreen = 5 # zoom

from console_progressbar import ProgressBar

def loadgrounds():
    grounds = []
    for file in glob.glob("./OneLifeData/ground/ground_*.tga"):
        grounds.append(pygame.transform.scale(pygame.image.load(file),(tilesize,tilesize)))
    return grounds

cpdef display_process(pipe,grounds):
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
                x,y,id = map(int,command)
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


macros = {
    "GROUNDTEST":"DRAWFLOOR 0 0 0#DRAWFLOOR 1 0 1#DRAWFLOOR 2 0 2#DRAWFLOOR 3 0 3#DRAWFLOOR 4 0 4#DRAWFLOOR 0 1 5#DRAWFLOOR 1 1 6#DRAWFLOOR 2 1 7"
}


def server_process(saddr,sport,pipe):
    pass
def main():
    display,d = mp.Pipe()
    grounds = loadgrounds()
    display_proc = mp.Process(target=display_process,args=(d,grounds))
    display_proc.start()
    m = ""
    while display_proc.is_alive() and m != "q":
        m = input(">")
        if m.startswith("MACRO"):
            m = m.split()
            macroname = m[1]
            if macroname in macros:
                macroz = macros[macroname].split("#")
                for macro in macroz:
                    display.send(macro)
                    display.recv()
            continue
        if m != "q":
            display.send(m)
            print(display.recv())
    print("Stopping")
    display.send("STOP")
    display_proc.join()

if __name__ == "__main__":
    main()
