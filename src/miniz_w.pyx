cimport minizwrapper as miniz
ctypedef miniz.mz_ulong culong
cdef mz_uncompress(unsigned char *pDest, unsigned long *pDest_len, const unsigned char *pSource, unsigned long source_len):
    miniz.mz_uncompress(pDest,pDest_len,pSource,source_len)

cpdef py_uncompress(int outlen,bytes source,int sourcelen):
    cdef unsigned char *out
    cdef unsigned long *destlen = &(<unsigned long>outlen)
    cdef unsigned long slen = <unsigned long>sourcelen
    cdef unsigned char *inp = &(<unsigned char>source)
    mz_uncompress(out,destlen,inp,slen)
    pyout = <bytes>out
    return pyout
