local ffi = require("ffi")

ffi.cdef[[
    typedef struct _xmlSchema xmlSchema;
    typedef xmlSchema * xmlSchemaPtr;
    typedef void (*xmlSchemaValidityErrorFunc)	(void * ctx, const char * msg);
    typedef void (*xmlSchemaValidityWarningFunc) (void * ctx, const char * msg);
    // typedef void xmlSchemaValidityErrorFunc	(void * ctx, const char * msg, ...);
    // typedef void xmlSchemaValidityWarningFunc (void * ctx, const char * msg, ...);
    typedef struct _xmlSchemaBucket xmlSchemaBucket;
    typedef xmlSchemaBucket *xmlSchemaBucketPtr;
    typedef struct _xmlSchemaItemList xmlSchemaItemList;
    typedef xmlSchemaItemList *xmlSchemaItemListPtr;
    struct _xmlSchemaItemList {
        void **items;  /* used for dynamic addition of schemata */
        int nbItems; /* used for dynamic addition of schemata */
        int sizeItems; /* used for dynamic addition of schemata */
    };
    
    typedef enum {
        XML_SCHEMA_TYPE_BASIC = 1, /* A built-in datatype */
        XML_SCHEMA_TYPE_ANY,
        XML_SCHEMA_TYPE_FACET,
        XML_SCHEMA_TYPE_SIMPLE,
        XML_SCHEMA_TYPE_COMPLEX,
        XML_SCHEMA_TYPE_SEQUENCE = 6,
        XML_SCHEMA_TYPE_CHOICE,
        XML_SCHEMA_TYPE_ALL,
        XML_SCHEMA_TYPE_SIMPLE_CONTENT,
        XML_SCHEMA_TYPE_COMPLEX_CONTENT,
        XML_SCHEMA_TYPE_UR,
        XML_SCHEMA_TYPE_RESTRICTION,
        XML_SCHEMA_TYPE_EXTENSION,
        XML_SCHEMA_TYPE_ELEMENT,
        XML_SCHEMA_TYPE_ATTRIBUTE,
        XML_SCHEMA_TYPE_ATTRIBUTEGROUP,
        XML_SCHEMA_TYPE_GROUP,
        XML_SCHEMA_TYPE_NOTATION,
        XML_SCHEMA_TYPE_LIST,
        XML_SCHEMA_TYPE_UNION,
        XML_SCHEMA_TYPE_ANY_ATTRIBUTE,
        XML_SCHEMA_TYPE_IDC_UNIQUE,
        XML_SCHEMA_TYPE_IDC_KEY,
        XML_SCHEMA_TYPE_IDC_KEYREF,
        XML_SCHEMA_TYPE_PARTICLE = 25,
        XML_SCHEMA_TYPE_ATTRIBUTE_USE,
        XML_SCHEMA_FACET_MININCLUSIVE = 1000,
        XML_SCHEMA_FACET_MINEXCLUSIVE,
        XML_SCHEMA_FACET_MAXINCLUSIVE,
        XML_SCHEMA_FACET_MAXEXCLUSIVE,
        XML_SCHEMA_FACET_TOTALDIGITS,
        XML_SCHEMA_FACET_FRACTIONDIGITS,
        XML_SCHEMA_FACET_PATTERN,
        XML_SCHEMA_FACET_ENUMERATION,
        XML_SCHEMA_FACET_WHITESPACE,
        XML_SCHEMA_FACET_LENGTH,
        XML_SCHEMA_FACET_MAXLENGTH,
        XML_SCHEMA_FACET_MINLENGTH,
        XML_SCHEMA_EXTRA_QNAMEREF = 2000,
        XML_SCHEMA_EXTRA_ATTR_USE_PROHIB
    } xmlSchemaTypeType;

    typedef struct _xmlSchemaBasicItem xmlSchemaBasicItem;
    typedef xmlSchemaBasicItem *xmlSchemaBasicItemPtr;
    struct _xmlSchemaBasicItem {
        xmlSchemaTypeType type;
        void *dummy; /* Fix alignment issues */
    };

    typedef struct _xmlSchemaRedef xmlSchemaRedef;
    typedef xmlSchemaRedef *xmlSchemaRedefPtr;
    struct _xmlSchemaRedef {
        xmlSchemaRedefPtr next;
        xmlSchemaBasicItemPtr item; /* The redefining component. */
        xmlSchemaBasicItemPtr reference; /* The referencing component. */
        xmlSchemaBasicItemPtr target; /* The to-be-redefined component. */
        const xmlChar *refName; /* The name of the to-be-redefined component. */
        const xmlChar *refTargetNs; /* The target namespace of the
                                    to-be-redefined comp. */
        xmlSchemaBucketPtr targetBucket; /* The redefined schema. */
    };
    typedef struct _xmlSchemaConstructionCtxt xmlSchemaConstructionCtxt;
    typedef xmlSchemaConstructionCtxt *xmlSchemaConstructionCtxtPtr;
    struct _xmlSchemaConstructionCtxt {
        xmlSchemaPtr mainSchema; /* The main schema. */
        xmlSchemaBucketPtr mainBucket; /* The main schema bucket */
        xmlDictPtr dict;
        xmlSchemaItemListPtr buckets; /* List of schema buckets. */
        /* xmlSchemaItemListPtr relations; */ /* List of schema relations. */
        xmlSchemaBucketPtr bucket; /* The current schema bucket */
        xmlSchemaItemListPtr pending; /* All Components of all schemas that
                                        need to be fixed. */
        xmlHashTablePtr substGroups;
        xmlSchemaRedefPtr redefs;
        xmlSchemaRedefPtr lastRedef;
    };

    struct _xmlSchemaParserCtxt {
        int type;
        void *errCtxt;             /* user specific error context */
        xmlSchemaValidityErrorFunc error;   /* the callback in case of errors */
        xmlSchemaValidityWarningFunc warning;       /* the callback in case of warning */
        int err;
        int nberrors;
        xmlStructuredErrorFunc serror;

        xmlSchemaConstructionCtxtPtr constructor;
        int ownsConstructor; /* TODO: Move this to parser *flags*. */

        /* xmlSchemaPtr topschema;	*/
        /* xmlHashTablePtr namespaces;  */

        xmlSchemaPtr schema;        /* The main schema in use */
        int counter;

        const xmlChar *URL;
        xmlDocPtr doc;
        int preserve;		/* Whether the doc should be freed  */

        const char *buffer;
        int size;

        /*
        * Used to build complex element content models
        */
        
        // ** Jerome Guillaume                             
        // ** UNCOMMENT those fields to get a proper access
        // **
        //xmlAutomataPtr am;
        //xmlAutomataStatePtr start;
        //xmlAutomataStatePtr end;
        //xmlAutomataStatePtr state;
        //
        //xmlDictPtr dict;		/* dictionary for interned string names */
        //xmlSchemaTypePtr ctxtType; /* The current context simple/complex type */
        //int options;
        //xmlSchemaValidCtxtPtr vctxt;
        //int isS4S;
        //int isRedefine;
        //int xsiAssemble;
        //int stop; /* If the parser should stop; i.e. a critical error. */
        //const xmlChar *targetNamespace;
        //xmlSchemaBucketPtr redefined; /* The schema to be redefined. */
        //
        //xmlSchemaRedefPtr redef; /* Used for redefinitions. */
        //int redefCounter; /* Used for redefinitions. */
        //xmlSchemaItemListPtr attrProhibs;
        
    } * xmlSchemaParserCtxtPtr;

    typedef struct _xmlHashEntry_JEG xmlHashEntry_JEG;
    typedef xmlHashEntry_JEG *xmlHashEntry_JEG_Ptr;    
    struct _xmlHashEntry_JEG {
        xmlHashEntry_JEG_Ptr next;
        xmlChar *name;
        xmlChar *name2;
        xmlChar *name3;
        void *payload;
        int valid;
    };
    
    typedef struct _xmlDictStrings xmlDictStrings;
    typedef xmlDictStrings *xmlDictStringsPtr;
    struct _xmlDictStrings {
        xmlDictStringsPtr next;
        xmlChar *free;
        xmlChar *end;
        size_t size;
        size_t nbStrings;
        xmlChar array[1];
    };
    typedef struct _xmlDict_JEG xmlDict_JEG;
    typedef xmlDict_JEG *xmlDictPtr_JEG;
    struct _xmlDict_JEG {
        int ref_counter;
    
        struct _xmlDictEntry *dict;
        size_t size;
        unsigned int nbElems;
        xmlDictStringsPtr strings;
    
        struct _xmlDict *subdict;
        /* used for randomization */
        int seed;
        /* used to impose a limit on size */
        size_t limit;
    };
    
    typedef struct _xmlHashTable_JEG xmlHashTable_JEG;
    typedef xmlHashTable_JEG *xmlHashTable_JEG_Ptr;    
    struct _xmlHashTable_JEG {
        xmlHashEntry_JEG_Ptr table;
        int size;
        int nbElems;
        xmlDictPtr dict;
    // Jerome Guillaume: lines below commented
    // #ifdef HASH_RANDOMIZATION
    //    int random_seed;
    //#endif
    };
    
    typedef struct _xmlSchemaAnnot xmlSchemaAnnot;
    typedef xmlSchemaAnnot *xmlSchemaAnnotPtr;
    struct _xmlSchemaAnnot {
        struct _xmlSchemaAnnot *next;
        xmlNodePtr content;         /* the annotation */
    };
    struct _xmlSchema {
        const xmlChar *name; /* schema name */
        const xmlChar *targetNamespace; /* the target namespace */
        const xmlChar *version;
        const xmlChar *id; /* Obsolete */
        xmlDocPtr doc;
        xmlSchemaAnnotPtr annot;
        int flags;
    
        xmlHashTablePtr typeDecl;
        xmlHashTablePtr attrDecl;
        xmlHashTablePtr attrgrpDecl;
        xmlHashTablePtr elemDecl;
        xmlHashTablePtr notaDecl;
    
        // Jerome Guillaume
        xmlHashTable_JEG_Ptr schemasImports;
    
        void *_private;        /* unused by the library for users or bindings */
        xmlHashTablePtr groupDecl;
        // Jerome Guillaume
        xmlDictPtr_JEG      dict;
        void *includes;     /* the includes, this is opaque for now */
        int preserve;        /* whether to free the document */
        int counter; /* used to give anonymous components unique names */
        xmlHashTablePtr idcDef; /* All identity-constraint defs. */
        void *volatiles; /* Obsolete */
    } *xmlSchemaPtr;

    typedef struct _xmlSchemaTreeItem xmlSchemaTreeItem;
    typedef xmlSchemaTreeItem *xmlSchemaTreeItemPtr;
    struct _xmlSchemaTreeItem {
        xmlSchemaTypeType type;
        xmlSchemaAnnotPtr annot;
        xmlSchemaTreeItemPtr next;
        xmlSchemaTreeItemPtr children;
    };

    typedef struct _xmlSchemaParticle xmlSchemaParticle;
    typedef xmlSchemaParticle *xmlSchemaParticlePtr;
    struct _xmlSchemaParticle {
        xmlSchemaTypeType type;
        xmlSchemaAnnotPtr annot;
        xmlSchemaTreeItemPtr next; /* next particle */
        xmlSchemaTreeItemPtr children; /* the "term" (e.g. a model group,
        a group definition, a XML_SCHEMA_EXTRA_QNAMEREF (if a reference),
            etc.) */
        int minOccurs;
        int maxOccurs;
        xmlNodePtr node;
    };

    typedef struct _xmlSchemaIDCStateObj xmlSchemaIDCStateObj;
    typedef xmlSchemaIDCStateObj *xmlSchemaIDCStateObjPtr;

    typedef struct _xmlRegExecCtxt xmlRegExecCtxt;
    typedef xmlRegExecCtxt *xmlRegExecCtxtPtr;

    typedef struct _xmlSchemaVal xmlSchemaVal;
    typedef xmlSchemaVal *xmlSchemaValPtr;

    typedef struct _xmlSchemaNodeInfo xmlSchemaNodeInfo;
    typedef xmlSchemaNodeInfo *xmlSchemaNodeInfoPtr;

    typedef struct _xmlSchemaIDC xmlSchemaIDC;
    typedef xmlSchemaIDC *xmlSchemaIDCPtr;

    typedef struct _xmlSchemaIDCAug xmlSchemaIDCAug;
    typedef xmlSchemaIDCAug *xmlSchemaIDCAugPtr;
    struct _xmlSchemaIDCAug {
        xmlSchemaIDCAugPtr next; /* next in a list */
        xmlSchemaIDCPtr def; /* the IDC definition */
        int keyrefDepth; /* the lowest tree level to which IDC
                            tables need to be bubbled upwards */
    };
    typedef struct _xmlSchemaIDCMatcher xmlSchemaIDCMatcher;
    typedef xmlSchemaIDCMatcher *xmlSchemaIDCMatcherPtr;

    typedef struct _xmlSchemaType xmlSchemaType;
    typedef xmlSchemaType *xmlSchemaTypePtr;

    typedef struct _xmlSchemaPSVIIDCKey xmlSchemaPSVIIDCKey;
    typedef xmlSchemaPSVIIDCKey *xmlSchemaPSVIIDCKeyPtr;
    struct _xmlSchemaPSVIIDCKey {
        xmlSchemaTypePtr type;
        xmlSchemaValPtr val;
    };

    /**
    * xmlSchemaPSVIIDCNode:
    *
    * The node table item of a node table.
    */
    typedef struct _xmlSchemaPSVIIDCNode xmlSchemaPSVIIDCNode;
    typedef xmlSchemaPSVIIDCNode *xmlSchemaPSVIIDCNodePtr;
    struct _xmlSchemaPSVIIDCNode {
        xmlNodePtr node;
        xmlSchemaPSVIIDCKeyPtr *keys;
        int nodeLine;
        int nodeQNameID;

    };
    typedef struct _xmlTextReader xmlTextReader;
    typedef xmlTextReader *xmlTextReaderPtr;

    typedef struct _xmlSchemaAttribute xmlSchemaAttribute;
    typedef xmlSchemaAttribute *xmlSchemaAttributePtr;
    struct _xmlSchemaAttribute {
        xmlSchemaTypeType type;
        struct _xmlSchemaAttribute *next; /* the next attribute (not used?) */
        const xmlChar *name; /* the name of the declaration */
        const xmlChar *id; /* Deprecated; not used */
        const xmlChar *ref; /* Deprecated; not used */
        const xmlChar *refNs; /* Deprecated; not used */
        const xmlChar *typeName; /* the local name of the type definition */
        const xmlChar *typeNs; /* the ns URI of the type definition */
        xmlSchemaAnnotPtr annot;

        xmlSchemaTypePtr base; /* Deprecated; not used */
        int occurs; /* Deprecated; not used */
        const xmlChar *defValue; /* The initial value of the value constraint */
        xmlSchemaTypePtr subtypes; /* the type definition */
        xmlNodePtr node;
        const xmlChar *targetNamespace;
        int flags;
        const xmlChar *refPrefix; /* Deprecated; not used */
        xmlSchemaValPtr defVal; /* The compiled value constraint */
        xmlSchemaAttributePtr refDecl; /* Deprecated; not used */
    };

    typedef struct _xmlSchemaAttributeUse xmlSchemaAttributeUse;
    typedef xmlSchemaAttributeUse *xmlSchemaAttributeUsePtr;
    struct _xmlSchemaAttributeUse {
        xmlSchemaTypeType type;
        xmlSchemaAnnotPtr annot;
        xmlSchemaAttributeUsePtr next; /* The next attr. use. */
        /*
        * The attr. decl. OR a QName-ref. to an attr. decl. OR
        * a QName-ref. to an attribute group definition.
        */
        xmlSchemaAttributePtr attrDecl;

        int flags;
        xmlNodePtr node;
        int occurs; /* required, optional */
        const xmlChar * defValue;
        xmlSchemaValPtr defVal;
    };
    typedef struct _xmlSchemaAttrInfo xmlSchemaAttrInfo;
    typedef xmlSchemaAttrInfo *xmlSchemaAttrInfoPtr;
    struct _xmlSchemaAttrInfo {
        int nodeType;
        xmlNodePtr node;
        int nodeLine;
        const xmlChar *localName;
        const xmlChar *nsName;
        const xmlChar *value;
        xmlSchemaValPtr val; /* the pre-computed value if any */
        xmlSchemaTypePtr typeDef; /* the complex/simple type definition if any */
        int flags; /* combination of node info flags */

        xmlSchemaAttributePtr decl; /* the attribute declaration */
        xmlSchemaAttributeUsePtr use;  /* the attribute use */
        int state;
        int metaType;
        const xmlChar *vcValue; /* the value constraint value */
        xmlSchemaNodeInfoPtr parent;
    };

    typedef struct _xmlSchemaValidCtxt xmlSchemaValidCtxt;
    typedef xmlSchemaValidCtxt *xmlSchemaValidCtxtPtr;
    struct _xmlSchemaValidCtxt {
        int type;
        void *errCtxt;             /* user specific data block */
        xmlSchemaValidityErrorFunc error;   /* the callback in case of errors */
        xmlSchemaValidityWarningFunc warning; /* the callback in case of warning */
        xmlStructuredErrorFunc serror;
    
        xmlSchemaPtr schema;        /* The schema in use */
        xmlDocPtr doc;
        xmlParserInputBufferPtr input;
        xmlCharEncoding enc;
        xmlSAXHandlerPtr sax;
        xmlParserCtxtPtr parserCtxt;
        void *user_data; /* TODO: What is this for? */
        char *filename;
    
        int err;
        int nberrors;
    
        xmlNodePtr node;
        xmlNodePtr cur;
        /* xmlSchemaTypePtr type; */
    
        xmlRegExecCtxtPtr regexp;
        xmlSchemaValPtr value;
    
        int valueWS;
        int options;
        xmlNodePtr validationRoot;
        xmlSchemaParserCtxtPtr pctxt;
        int xsiAssemble;
    
        int depth;
        xmlSchemaNodeInfoPtr *elemInfos; /* array of element information */
        int sizeElemInfos;
        xmlSchemaNodeInfoPtr inode; /* the current element information */
    
        xmlSchemaIDCAugPtr aidcs; /* a list of augmented IDC information */
    
        xmlSchemaIDCStateObjPtr xpathStates; /* first active state object. */
        xmlSchemaIDCStateObjPtr xpathStatePool; /* first stored state object. */
        xmlSchemaIDCMatcherPtr idcMatcherCache; /* Cache for IDC matcher objects. */
    
        xmlSchemaPSVIIDCNodePtr *idcNodes; /* list of all IDC node-table entries*/
        int nbIdcNodes;
        int sizeIdcNodes;
    
        xmlSchemaPSVIIDCKeyPtr *idcKeys; /* list of all IDC node-table entries */
        int nbIdcKeys;
        int sizeIdcKeys;
    
        int flags;
    
        xmlDictPtr dict;
    
    // Jerome Guillaume
    //#ifdef LIBXML_READER_ENABLED
        xmlTextReaderPtr reader;
    //#endif
    
        xmlSchemaAttrInfoPtr *attrInfos;
        int nbAttrInfos;
        int sizeAttrInfos;
    
        int skipDepth;
        xmlSchemaItemListPtr nodeQNames;
        int hasKeyrefs;
        int createIDCNodeTables;
        int psviExposeIDCNodeTables;
    
        /* Locator for error reporting in streaming mode */
        // Jerome Guillaume
        // xmlSchemaValidityLocatorFunc locFunc;
        void *locFunc;
        void *locCtxt;
    };
    
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