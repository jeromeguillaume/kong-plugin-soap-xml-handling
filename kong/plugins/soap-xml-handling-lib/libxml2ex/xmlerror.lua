local ffi = require("ffi")

ffi.cdef[[
xmlErrorPtr             xmlGetLastError		        (void);
void	                xmlResetLastError		    (void);
typedef void            xmlStructuredErrorFunc      (void* userData, xmlErrorPtr error);
void	                xmlSetStructuredErrorFunc   (void* ctx, xmlStructuredErrorFunc handler);
typedef void           	xmlGenericErrorFunc		    (void * ctx, const char * msg);
void	                initGenericErrorDefaultFunc	(xmlGenericErrorFunc * handler);
]]