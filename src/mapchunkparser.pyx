cdef extern from "miniz.h":
    int mz_uncompress(unsigned char *pDest, unsigned long *pDest_len, const unsigned char *pSource, unsigned long source_len);
    

cpdef parse_chunk(header,compressed):
    cdef bytes mpdata
    cdef unsigned long *csize 
    cdef unsigned long cbsize
    cdef unsigned long before
    header = header.split()
    _, width, height, x, y, size, cbuffersize = header
    cbsize = <int>cbuffersize
    before = <unsigned long>int(size)
    csize = &(before)
    
    
