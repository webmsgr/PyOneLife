# use after installing the client to run the client
import sys
try:
    import pyOHOL.client
except ImportError as e:
    print("Client is not installed")
    raise e
pyOHOL.client.main()
