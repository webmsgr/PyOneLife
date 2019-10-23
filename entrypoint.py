# use after installing the client to run the client
import sys
try:
    import pyOHOL.client as client
except ImportError as e:
    print("Client is not installed")
    raise e
client.main()
