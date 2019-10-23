cimport minizwrapper as miniz
cpdef mz_uncompress(unsigned char *pDest, miniz.mz_ulong *pDest_len, const unsigned char *pSource, miniz.mz_ulong source_len):
    miniz.mz_uncompress(pDest,pDest_len,pSource,source_len)
