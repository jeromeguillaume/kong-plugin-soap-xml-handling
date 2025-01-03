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
    
    typedef xmlParserInputPtr (*xmlExternalEntityLoader) (const char *URL, const char *ID, xmlParserCtxtPtr context);
    
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
    xmlExternalEntityLoader	xmlGetExternalEntityLoader	(void);
    xmlParserInputPtr	    xmlNewStringInputStream	    (xmlParserCtxtPtr ctxt, 
						                                const xmlChar * buffer);
    xmlParserInputPtr	    xmlNewInputFromFile	        (xmlParserCtxtPtr ctxt, 
						                                const char * filename);
    void	                xmlSetExternalEntityLoader	(xmlExternalEntityLoader f);
    int                     xmlSubstituteEntitiesDefault        (int val);
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
    
    void	                xmlSchemaSetParserStructuredErrors	(xmlSchemaParserCtxtPtr ctxt, 
                                                                xmlStructuredErrorFunc serror, 
                                                                void * ctx);
    void                    xmlSchemaSetValidStructuredErrors	(xmlSchemaValidCtxtPtr ctxt, 
                                                                xmlStructuredErrorFunc serror, 
                                                                void * ctx);
    void                    xmlSchemaFreeParserCtxt		        (xmlSchemaParserCtxtPtr ctxt);

    int	                    xmlC14NDocDumpMemory		        (xmlDocPtr doc, 
                                                                xmlNodeSetPtr nodes, 
                                                                int mode, 
                                                                xmlChar ** inclusive_ns_prefixes, 
                                                                int with_comments, 
                                                                xmlChar ** doc_txt_ptr);
]]