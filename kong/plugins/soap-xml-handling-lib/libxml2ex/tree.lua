local ffi = require("ffi")

ffi.cdef[[
    int         xmlNodeDump		(xmlBufferPtr buf, 
                                xmlDocPtr doc, 
                                xmlNodePtr cur, 
                                int level, 
                                int format);
    int         xmlSaveFormatFile(const char * filename, 
					            xmlDocPtr cur, 
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
    xmlNode *   xmlDocCopyNodeList  (xmlDoc *doc, xmlNode *node);
    xmlNode *   xmlDocCopyNode      (xmlNode *node, xmlDoc *doc, int extended);   
    xmlNode * 	xmlAddChildList (xmlNode *parent, xmlNode *cur);
]]