local ffi = require("ffi")

ffi.cdef[[
    typedef struct _xmlSchema xmlSchema;
    typedef xmlSchema * xmlSchemaPtr;
    typedef void (*xmlSchemaValidityErrorFunc)	(void * ctx, const char * msg);
    typedef void (*xmlSchemaValidityWarningFunc) (void * ctx, const char * msg);
    // typedef void xmlSchemaValidityErrorFunc	(void * ctx, const char * msg, ...);
    // typedef void xmlSchemaValidityWarningFunc (void * ctx, const char * msg, ...);
    
    typedef struct _xmlSchemaParserCtxt* xmlSchemaParserCtxtPtr;
    typedef struct _xmlSchemaValidCtxt* xmlSchemaValidCtxtPtr;
    
    
    typedef xmlDoc * xmlDocPtr;
    typedef struct xmlParserCtxt {} * xmlParserCtxtPtr;

    xmlSchemaParserCtxtPtr	xmlSchemaNewMemParserCtxt   (const char * buffer, int size);
    xmlSchemaPtr	        xmlSchemaParse		        (void * ctxt);
    xmlSchemaValidCtxtPtr	xmlSchemaNewValidCtxt	    (xmlSchemaPtr schema);
    void                    xmlSchemaFreeValidCtxt		(xmlSchemaValidCtxtPtr ctxt);
    xmlDocPtr	            xmlReadMemory               (const char * buffer, 
                                                        int size, 
                                                        const char * URL, 
                                                        const char * encoding, 
                                                        int options);
    int	                    xmlSchemaValidateDoc		(xmlSchemaValidCtxtPtr ctxt, xmlDocPtr doc);
    int                     xmlSchemaValidateOneElement	(xmlSchemaValidCtxtPtr ctxt, 
					                                    xmlNodePtr elem);
    int	                    xmlSchemaGetValidErrors		(xmlSchemaValidCtxtPtr ctxt, 
                                                        xmlSchemaValidityErrorFunc * err, 
                                                        xmlSchemaValidityWarningFunc * warn, 
                                                        void ** ctx);
    void	                xmlSchemaSetParserErrors	(xmlSchemaParserCtxtPtr ctxt, 
                                                        xmlSchemaValidityErrorFunc err, 
                                                        xmlSchemaValidityWarningFunc warn, 
                                                        void * ctx);
    
    xmlParserCtxtPtr	    xmlSchemaValidCtxtGetParserCtxt	    (xmlSchemaValidCtxtPtr ctxt);
    void	                xmlSchemaSetParserStructuredErrors	(xmlSchemaParserCtxtPtr ctxt, 
                                                                xmlStructuredErrorFunc serror, 
                                                                void * ctx);
    void                    xmlSchemaSetValidStructuredErrors	(xmlSchemaValidCtxtPtr ctxt, 
                                                                xmlStructuredErrorFunc serror, 
                                                                void * ctx);
    void                    xmlSchemaFreeParserCtxt		        (xmlSchemaParserCtxtPtr ctxt);
]]