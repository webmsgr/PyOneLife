@echo off
mkdir build
mkdir "build/dist"
py -3 setup.py build_ext --inplace --cython
pip3 install shiv
pip3 install -r requirements.txt --target build/dist
move *.pyd "build/dist"
mkdir "build/dist/OneLifeData"
robocopy OneLifeData "build/dist/OneLifeData" /MIR /S /NJH
shiv --site-packages build/dist -p "/usr/bin/env python3" --compressed -o pyOHOL.pyz -e pyOHOL.main