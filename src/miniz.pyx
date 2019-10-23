cimport minizwrapper as miniz
ctypedef miniz.mz_ulong ulong
cpdef mz_uncompress(unsigned char *pDest, ulong *pDest_len, const unsigned char *pSource, ulong source_len):
    miniz.mz_uncompress(pDest,pDest_len,pSource,source_len)
