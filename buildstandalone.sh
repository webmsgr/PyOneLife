mkdir build/
python3 setup.py build_ext --inplace --cython
mkdir build/pyOHOL
cp *.so build/pyOHOL
pip3 install -r requirements.txt --target build
cp entrypoint.py build/__main__.py
python3 -m zipapp build -p "/usr/bin/env python3" -c -o "pyOHOL.pyz"

