local ffi = require("ffi")

ffi.cdef[[
typedef xmlError * xmlErrorPtr;
xmlErrorPtr             xmlGetLastError		        (void);
void	                xmlResetLastError		    (void);
typedef void            xmlStructuredErrorFunc      (void* userData, xmlErrorPtr error);
void	                xmlSetStructuredErrorFunc   (void* ctx, xmlStructuredErrorFunc handler);

// JeromeGuillaume:
// Change 3rd argument from the original definition as follows:
//         `...` -> `char *value type`
// because LuaJit's FFI cannot manage a variable number of arguments of C function
// See: 
//   https://android.googlesource.com/platform/external/libxslt/+/7d1dabff1598661db0018d89d16cca02f7c31ae2/libxslt/xsltutils.c#650
//   https://luajit.org/ext_ffi_semantics.html#callback
typedef void           	xmlGenericErrorFunc		    (void * ctx, const char * msg, const char * type);
//Original Definiton: typedef void           	xmlGenericErrorFunc		    (void * ctx, const char * msg, ...);

void	                initGenericErrorDefaultFunc	(xmlGenericErrorFunc * handler);
]]