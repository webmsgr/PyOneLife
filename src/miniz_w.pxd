cimport minizwrapper as minizw
ctypedef minizw.mz_ulong ulong
cdef mz_uncompress(unsigned char *pDest, int pDest_len, const unsigned char *pSource, int source_len)
cpdef py_uncompress(destlen,source,sourcelen)
