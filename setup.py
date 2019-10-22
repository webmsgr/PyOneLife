from distutils.core import setup, Extension
import os

def dfunc(arg):
    return arg


cmdclass = {}
try:
    import Cython
    os.system("cython src/client.pyx")
except:
    pass



exts = [Extension('pyOHOL.client', ['src/client.c'])]

setup(name='pyOHOL',
      version='1.0',
      ext_modules=exts,
      cmdclass=cmdclass,
      requires=["numpy","pygame"]
      )
