# use after installing the client to run the client
import sys
try:
    import pyOHOL.client as client
except ImportError:
    print("Client is not installed")
    sys.exit(1)
client.main()
