from distutils.core import setup, Extension
import os
from Cython.Build import cythonize

def dfunc(arg):
    return arg



exts = cythonize([Extension('miniz',['src/miniz/miniz.pxd']),Extension('pyOHOL.client', ['src/client.pyx','src/mapchunkparser.pyx'])])

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      requires=["numpy","pygame"]
      )
