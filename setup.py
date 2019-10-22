from distutils.core import setup, Extension
import sys

def dfunc(arg):
    return arg


cmdclass = {}
try:
    from Cython.Build import cythonize, build_ext
    ext = ".pyx"
    dfunc = lambda x: cythonize(x)
except:
    ext = ".c"



exts = dfunc([Extension('pyOHOL.OHOL', ['src/OHOL/OHOL'+ext])])
exts += [Extension('pyOHOL',['src/__main__.py'])]

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      cmdclass=cmdclass,
      requires=["numpy","pygame"]
      )
