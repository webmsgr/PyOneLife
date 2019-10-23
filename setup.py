import os
from distutils.core import Extension
from distutils.core import setup

from Cython.Build import cythonize


def dfunc(arg):
    return arg


exts = cythonize([
    Extension("pyOHOL.client",
              ["src/client.pyx", "src/mapchunkparser.pyx", "src/miniz.pyx"])], compiler_directives={'language_level': "3"})

setup(name="pyOHOL",
      version="1.0",
      ext_modules=exts,
      requires=["numpy", "pygame"])
