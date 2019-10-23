import pygame
import multiprocessing as mp
import requests
import numpy
cimport numpy

DEF tilesize = 128

tilesperscreen = 5 # zoom

from console_progressbar import ProgressBar
def read_config(folder):
    pass
def load(folder):
    pass
def client():
    pass
def display_process(pipe):
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
    while not done:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                done = True
    screen.fill(WHITE)
    # --- Drawing code should go here
    pygame.display.flip()
    clock.tick(60)
pygame.quit()


def server_process(saddr,sport,pipe):
    pass
def main():
    display,d = mp.Pipe()
    display_process(d)

if __name__ == "__main__":
    main()
