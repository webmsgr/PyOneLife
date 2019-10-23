cdef extern from "miniz.h":
    int mz_uncompress(unsigned char *pDest, unsigned long *pDest_len, const unsigned char *pSource, unsigned long source_len);
    

cpdef parse_chunk(bytes header,bytes compressed):
    cdef unsigned char *mpdata
    cdef unsigned long *csize 
    cdef unsigned long cbsize
    cdef unsigned long before
    cdef bytes *out
    cdef char beforetwo = compressed
    cdef char *step2 = &(beforetwo)
    cdef unsigned char *pSource = <unsigned char *>step2
    header = header.split()
    _, width, height, x, y, size, cbuffersize = header
    cbsize = <unsigned long>int(cbuffersize)
    before = <unsigned long>int(size)
    csize = &(before)
    mz_uncompress(mpdata,csize,pSource,cbsize)
    out = <bytes *>mpdata
    
