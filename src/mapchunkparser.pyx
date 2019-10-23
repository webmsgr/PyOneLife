import zlib

cpdef parse_chunk(header,compressed):
    header = header.split()
    _, width, height, x, y, size, buffersize = header
    mapdata = zlib.decompress(compressed,bufsize=int(buffersize))
    
