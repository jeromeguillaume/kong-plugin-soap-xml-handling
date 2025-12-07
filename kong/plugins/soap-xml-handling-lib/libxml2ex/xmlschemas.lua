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
    
    typedef enum {
        /** unknown */
        XML_RESOURCE_UNKNOWN = 0,
        /** main document */
        XML_RESOURCE_MAIN_DOCUMENT,
        /** external DTD */
        XML_RESOURCE_DTD,
        /** external general entity */
        XML_RESOURCE_GENERAL_ENTITY,
        /** external parameter entity */
        XML_RESOURCE_PARAMETER_ENTITY,
        /** XIncluded document */
        XML_RESOURCE_XINCLUDE,
        /** XIncluded text */
        XML_RESOURCE_XINCLUDE_TEXT
    } xmlResourceType;

    typedef enum {
        /** The input buffer won't be changed during parsing. */
        XML_INPUT_BUF_STATIC            = (1 << 1),
        /** The input buffer is zero-terminated. (Note that the zero
            byte shouldn't be included in buffer size.) */
        XML_INPUT_BUF_ZERO_TERMINATED   = (1 << 2),
        /** Uncompress gzipped file input */
        XML_INPUT_UNZIP                 = (1 << 3),
        /** Allow network access. Unused internally. */
        XML_INPUT_NETWORK               = (1 << 4),
        /** Allow system catalog to resolve URIs. */
        XML_INPUT_USE_SYS_CATALOG       = (1 << 5)
    } xmlParserInputFlags;

    typedef struct _xmlParserInput 	xmlParserInput;

    typedef xmlParserErrors (* xmlResourceLoader) (void *ctxt, const char *url, const char *publicId, xmlResourceType type, xmlParserInputFlags flags, xmlParserInput **out);
    
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
    
    void 	                xmlSchemaSetResourceLoader          (xmlSchemaParserCtxtPtr ctxt, 
                                                                xmlResourceLoader loader, 
                                                                void *data);    
    
    void                    xmlCtxtSetErrorHandler	            (xmlParserCtxt *	ctxt,
                                                                xmlStructuredErrorFunc	handler,
                                                                void *	data );

    xmlParserCtxtPtr        xmlSchemaValidCtxtGetParserCtxt     (xmlSchemaValidCtxtPtr ctxt);
]]