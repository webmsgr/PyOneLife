cimport miniz_w as miniz

cpdef parse_chunk(header,compressed):
    cdef bytes mpdata
    cdef int csize 
    cdef int cbsize
    header = header.split()
    _, width, height, x, y, size, cbuffersize = header
    cbsize = cbuffersize
    csize = size
    mapdata = miniz.py_uncompress(csize,compressed,cbsize)
    
    
