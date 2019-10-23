# use after installing the client to run the client
import sys
try:
    import pyOHOL
except ImportError as e:
    print("Client is not installed")
    raise e
pyOHOL.main()
