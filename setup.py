import os
import sys
from distutils.core import Extension
from distutils.core import setup

import numpy as np


if sys.version[0] == 2:
    sys.stdout.write("No python 2 support\n")
    sys.exit(1)


def dfunc(arg):
    return arg

if "--cython" in sys.argv:
    USE_CYTHON = True
    sys.argv.remove("--cython")
else:
    USE_CYTHON = False

ext = '.pyx' if USE_CYTHON else '.c'
exts = [Extension("pyOHOL", ["src/pyOHOL"+ext])]

if USE_CYTHON:
    from Cython.Build import cythonize
    exts = cythonize(exts,compiler_directives={"language_level": "3"}))

setup(
    name="pyOHOL",
    version="1.0",
    ext_modules=exts,
    include_dirs=[np.get_include(), "./src/"],
    requires=["numpy", "pygame", "console_progressbar", "requests", "Pillow"],
)
