cimport minizwrapper as minizw
ctypedef minizw.mz_ulong ulong
cdef mz_compress(unsigned char *pDest, mz_ulong *pDest_len, const unsigned char *pSource, mz_ulong source_len)
