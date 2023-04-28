local ffi = require("ffi")

ffi.cdef[[
    typedef struct _xsltStylesheet xsltStylesheet;
    typedef xsltStylesheet *xsltStylesheetPtr;

    xsltStylesheetPtr xsltParseStylesheetDoc	(xmlDocPtr doc);
    xmlDocPtr	xsltApplyStylesheet	(xsltStylesheetPtr style, 
					 xmlDocPtr doc, 
					 const char ** params);
]]