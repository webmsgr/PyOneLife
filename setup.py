from distutils.core import setup, Extension
import sys

def dfunc(arg):
    return arg


cmdclass = {}
try:
    from Cython.Compiler import Options
    Options.embed = "main"
    from Cython.Build import cythonize, build_ext
    ext = ".pyx"
    dfunc = lambda x: cythonize(x)
except:
    ext = ".c"



exts = dfunc([Extension('pyOHOL', ['src/client'+ext])])

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      cmdclass=cmdclass,
      requires=["numpy","pygame"]
      )
