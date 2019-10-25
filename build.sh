mkdir build
mkdir build/dist
python3 setup.py build_ext --inplace --cython
retVal=$?
if [ $retVal -ne 0 ]; then
    exit $retVal
fi
pip3 install shiv
pip3 install -r requirements.txt --target build/dist
mv *.so build/dist
mkdir build/dist/OneLifeData
cp -r OneLifeData/* build/dist/OneLifeData
shiv --site-packages build/dist -p "/usr/bin/env python3" --compressed -o pyOHOL.pyz -e pyOHOL.main
