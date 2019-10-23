# this python script will take all the transitions,objects,sprites,animations etc into a single npz file
import numpy
import pygame
import os
import glob
from PIL import Image
from console_progressbar import ProgressBar

def main():
    objects = []
    pb = ProgressBar(total=100,prefix="Objects:")
    perone = 1/len(glob.glob("./OneLifeData/objects/*.txt"))
    for num,obj in enumerate(glob.glob("./OneLifeData/objects/*.txt")):
        if "next" in obj:
            continue
        obj = open(obj)
        data = obj.read().split("\n")
        name = data.pop(1)
        oid = data[0].replace("=","").replace("id","")
        objects.append((oid,name,data))
        pb.print_progress_bar(num*perone*100)
    pb.print_progress_bar(100)
    spritebar = ProgressBar(prefix="Sprites:",total=100)
    perone = 1/len(glob.glob("./OneLifeData/sprites/*.tga"))
    imgs = []
    for num,sprite in enumerate(glob.glob("./OneLifeData/sprites/*.tga")):
        img = Image.open(sprite)
        iid = os.path.basename(sprite).replace(".tga","")
        imgs.append((iid,numpy.array(img)))
        spritebar.print_progress_bar(num*perone*100)
    spritebar.print_progress_bar(100)
    grounds = []
    groundbar = ProgressBar(prefix="Ground Tiles:",total=100)
    perone = 1/len(glob.glob("./OneLifeData/sprites/*.tga"))
    for num, ground in enumerate(glob.glob("./OneLifeData/ground/*.tga")):
        gi = os.path.basename(ground).replace("ground_","").replace(".tga","")
        grounds.append((gi,numpy.array(Image.open(ground))))
        groundbar.print_progress_bar(num*perone*100)
    groundbar.print_progress_bar(100)
    
    print("Saving")
    numpy.savez_compressed("OneLife.npz",sprites=imgs,objects=objects,grounds=grounds)
    print("Complete!")
if __name__ == "__main__":
    main()
                   
        
