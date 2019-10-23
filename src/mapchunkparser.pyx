cimport miniz_w as miniz

cpdef parse_chunk(header,compressed):
    cdef unsigned char *mapdata
    cdef bytes mpdata
    cdef int csize 
    cdef int cbsize
    header = header.split()
    _, width, height, x, y, size, cbuffersize = header
    cbsize = cbuffersize
    csize = size
    miniz.mz_uncompress(mapdata,csize,compressed,cbsize)
    
    
