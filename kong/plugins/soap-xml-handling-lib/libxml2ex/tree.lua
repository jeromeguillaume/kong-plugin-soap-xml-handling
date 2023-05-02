local ffi = require("ffi")

ffi.cdef[[
    int         xmlNodeDump		(xmlBufferPtr buf, 
                                xmlDocPtr doc, 
                                xmlNodePtr cur, 
                                int level, 
                                int format);
    
    void        xmlNodeDumpOutput(xmlOutputBufferPtr buf,
                                xmlDocPtr doc,
                                xmlNodePtr cur,
                                int level,
                                int format,
                                const char *encoding);
    xmlChar *	xmlGetNoNsProp	(const xmlNode * node, 
                                const xmlChar * name);  
    xmlChar *	xmlGetNodePath	(const xmlNode * node);
]]