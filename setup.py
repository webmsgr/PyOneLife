from distutils.core import setup, Extension
import sys
from Cython.Build import cythonize



exts = cythonize([Extension('PyOHOL.OHOL', ['src/OHOL.pyx']),Extension('PyOHOL',['src/__main__.py'])])

setup(name='PyOHOL',
      version='1.0',
      ext_modules=exts,
      )
