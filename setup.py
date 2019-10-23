from distutils.core import setup, Extension
import os

def dfunc(arg):
    return arg


cmdclass = {}
try:
    import Cython
    os.system("cython src/client.pyx")
    os.system("cython src/mapchunkparser.pyx)
except:
    pass



exts = [Extension('pyOHOL.client', ['src/client.c','src/mapchunkparser.c'])]

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      cmdclass=cmdclass,
      requires=["numpy","pygame"]
      )
