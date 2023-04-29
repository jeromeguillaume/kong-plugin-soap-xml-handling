local ffi = require("ffi")

ffi.cdef[[
    int     xmlNodeDump			(xmlBufferPtr buf, 
                                xmlDocPtr doc, 
                                xmlNodePtr cur, 
                                int level, 
                                int format);
    xmlChar *	xmlGetNoNsProp	(const xmlNode * node, 
                                const xmlChar * name);
           
]]