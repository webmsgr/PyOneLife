cimport minizwrapper as miniz
ctypedef miniz.mz_ulong culong
cpdef mz_uncompress(unsigned char *pDest, culong *pDest_len, const unsigned char *pSource, culong source_len):
    miniz.mz_uncompress(pDest,pDest_len,pSource,source_len)
