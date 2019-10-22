from distutils.core import setup, Extension
import sys

def dfunc(arg):
      return arg


try:
    from Cython.Build import cythonize
    ext = ".pyx"
    dfunc = lambda x: cythonize(x)
except:
    ext = ".c"



exts = dfunc([Extension('pyOHOL.OHOL', ['src/OHOL/OHOL'+ext])])+[Extension('pyOHOL',['src/__main__.py'])]

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      requires=["numpy","pygame"]
      )
