# use after installing the client to run the client
import sys
import multiprocessing
try:
    import pyOHOL
except ImportError as e:
    print("Client is not installed")
    raise e
def main():
    multiprocessing.freeze_support()
    pyOHOL.main()
if __name__ == "__main__":
    main()
