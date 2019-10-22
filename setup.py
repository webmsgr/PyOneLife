from distutils.core import setup, Extension
import sys
from Cython.Build import cythonize



exts = cythonize([Extension('pyOHOL.OHOL', ['src/OHOL/OHOL.pyx'])])+[Extension('pyOHOL',['src/__main__.py'])]

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      )
