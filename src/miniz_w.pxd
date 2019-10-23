cimport minizwrapper as minizw
ctypedef minizw.mz_ulong ulong
cdef mz_uncompress(unsigned char *pDest, unsigned long *pDest_len, const unsigned char *pSource, unsigned long source_len)
cpdef py_uncompress(int destlen,bytes source,int sourcelen)
