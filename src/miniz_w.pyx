cimport minizwrapper as miniz
ctypedef miniz.mz_ulong culong
cdef mz_uncompress(unsigned char *pDest, unsigned long *pDest_len, const unsigned char *pSource, unsigned long source_len):
    miniz.mz_uncompress(pDest,pDest_len,pSource,source_len)
