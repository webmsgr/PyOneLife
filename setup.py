from distutils.core import setup, Extension
import os
from Cython.Build import cythonize

def dfunc(arg):
    return arg



exts = cythonize([Extension('pyOHOL', ['src/client.pyx','src/mapchunkparser.pyx','src/miniz.pxd'])])

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      requires=["numpy","pygame"]
      )
