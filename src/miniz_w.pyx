cimport minizwrapper as miniz
ctypedef miniz.mz_ulong culong
cpdef mz_uncompress(unsigned char *pDest, int *pDest_len, const unsigned char *pSource, int source_len):
    miniz.mz_uncompress(pDest,<unsigned long *>pDest_len,pSource,<unsigned long>source_len)
