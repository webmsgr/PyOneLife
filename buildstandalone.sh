mkdir build/
python3 setup.py install --inplace --cython
mkdir build/pyOHOL
cp *.so build/pyOHOL
pip3 install -r requirements.txt --target build/
cp entrypoint.py build/
