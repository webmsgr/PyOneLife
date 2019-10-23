cimport minizwrapper as minizw
ctypedef minizw.mz_ulong ulong
cdef mz_uncompress(unsigned char *pDest, ulong *pDest_len, const unsigned char *pSource, ulong source_len)
