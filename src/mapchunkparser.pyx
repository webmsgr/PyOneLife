cimport miniz

cpdef parse_chunk(header,compressed):
    cdef unsigned char *mapdata
    cdef bytes mpdata
    cdef miniz.ulong csize 
    cdef miniz.ulong cbsize
    header = header.split()
    _, width, height, x, y, size, cbuffersize = header
    cbsize = cbuffersize
    csize = size
    miniz.mz_uncompress(mapdata,&(csize),compressed,cbsize)
    
    
