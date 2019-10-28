pip3 install -r requirements.txt
python3 setup.py install --cython
if [ $? -ne 0 ]
then
    exit 1
fi
python3 entrypoint.py
