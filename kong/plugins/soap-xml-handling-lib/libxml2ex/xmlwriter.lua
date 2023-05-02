local ffi = require("ffi")

ffi.cdef[[
 
    typedef struct _xmlTextWriter {
    } * xmlTextWriterPtr;
    
    int	xmlTextWriterStartDocument	(xmlTextWriterPtr writer, 
    const char * version, 
    const char * encoding, 
    const char * standalone);
    xmlTextWriterPtr	xmlNewTextWriterTree	(xmlDocPtr doc, 
						 xmlNodePtr node, 
						 int compression);
    xmlTextWriterPtr	xmlNewTextWriterDoc	(xmlDocPtr * doc, 
						 int compression);
    void	xmlFreeTextWriter		(xmlTextWriterPtr writer);
    int	    xmlTextWriterWriteString	(xmlTextWriterPtr writer, const xmlChar * content);

]]