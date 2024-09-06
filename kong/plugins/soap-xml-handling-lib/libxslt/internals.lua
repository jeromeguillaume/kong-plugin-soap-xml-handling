local ffi = require("ffi")

ffi.cdef[[
    //typedef struct _xsltStylesheet xsltStylesheet;
    struct _xsltDocument {
        struct _xsltDocument *next;	/* documents are kept in a chained list */
        int main;			/* is this the main document */
        xmlDocPtr doc;		/* the parsed document */
        void *keys;			/* key tables storage */
        struct _xsltDocument *includes; /* subsidiary includes */
        int preproc;		/* pre-processing already done */
        int nbKeysComputed;
    };
    typedef struct _xsltDocument xsltDocument;
    typedef xsltDocument *xsltDocumentPtr;
    
    typedef struct _xsltStylePreComp xsltStylePreComp;
    typedef xsltStylePreComp *xsltStylePreCompPtr;

    typedef struct _xsltStackElem xsltStackElem;
    typedef xsltStackElem *xsltStackElemPtr;
    struct _xsltStackElem {
        struct _xsltStackElem *next;/* chained list */
        xsltStylePreCompPtr comp;   /* the compiled form */
        int computed;		/* was the evaluation done */
        const xmlChar *name;	/* the local part of the name QName */
        const xmlChar *nameURI;	/* the URI part of the name QName */
        const xmlChar *select;	/* the eval string */
        xmlNodePtr tree;		/* the sequence constructor if no eval
                        string or the location */
        xmlXPathObjectPtr value;	/* The value if computed */
        xmlDocPtr fragment;		/* The Result Tree Fragments (needed for XSLT 1.0)
                    which are bound to the variable's lifetime. */
        int level;                  /* the depth in the tree;
                                    -1 if persistent (e.g. a given xsl:with-param) */
        xsltTransformContextPtr context; /* The transformation context; needed to cache
                                            the variables */
        int flags;
    };
    typedef struct _xsltTemplate xsltTemplate;
    typedef xsltTemplate *xsltTemplatePtr;
    struct _xsltTemplate {
        struct _xsltTemplate *next;/* chained list sorted by priority */
        struct _xsltStylesheet *style;/* the containing stylesheet */
        xmlChar *match;	/* the matching string */
        float priority;	/* as given from the stylesheet, not computed */
        const xmlChar *name; /* the local part of the name QName */
        const xmlChar *nameURI; /* the URI part of the name QName */
        const xmlChar *mode;/* the local part of the mode QName */
        const xmlChar *modeURI;/* the URI part of the mode QName */
        xmlNodePtr content;	/* the template replacement value */
        xmlNodePtr elem;	/* the source element */

        /*
        * TODO: @inheritedNsNr and @inheritedNs won't be used in the
        *  refactored code.
        */
        int inheritedNsNr;  /* number of inherited namespaces */
        xmlNsPtr *inheritedNs;/* inherited non-excluded namespaces */

        /* Profiling information */
        int nbCalls;        /* the number of time the template was called */
        unsigned long time; /* the time spent in this template */
        void *params;       /* xsl:param instructions */

        int              templNr;		/* Nb of templates in the stack */
        int              templMax;		/* Size of the templtes stack */
        xsltTemplatePtr *templCalledTab;	/* templates called */
        int             *templCountTab;  /* .. and how often */

        /* Conflict resolution */
        int position;
    };
    typedef struct _xsltDecimalFormat xsltDecimalFormat;
    typedef xsltDecimalFormat *xsltDecimalFormatPtr;
    struct _xsltDecimalFormat {
        struct _xsltDecimalFormat *next; /* chained list */
        xmlChar *name;
        /* Used for interpretation of pattern */
        xmlChar *digit;
        xmlChar *patternSeparator;
        /* May appear in result */
        xmlChar *minusSign;
        xmlChar *infinity;
        xmlChar *noNumber; /* Not-a-number */
        /* Used for interpretation of pattern and may appear in result */
        xmlChar *decimalPoint;
        xmlChar *grouping;
        xmlChar *percent;
        xmlChar *permille;
        xmlChar *zeroDigit;
        const xmlChar *nsUri;
    };
    typedef struct _xsltElemPreComp xsltElemPreComp;
    typedef xsltElemPreComp *xsltElemPreCompPtr;
    typedef enum {
        XSLT_ERROR_SEVERITY_ERROR = 0,
        XSLT_ERROR_SEVERITY_WARNING
    } xsltErrorSeverityType;
    
    typedef struct _xsltCompilerNodeInfo xsltCompilerNodeInfo;
    typedef xsltCompilerNodeInfo *xsltCompilerNodeInfoPtr;
    typedef enum {
        XSLT_FUNC_COPY=1,
        XSLT_FUNC_SORT,
        XSLT_FUNC_TEXT,
        XSLT_FUNC_ELEMENT,
        XSLT_FUNC_ATTRIBUTE,
        XSLT_FUNC_COMMENT,
        XSLT_FUNC_PI,
        XSLT_FUNC_COPYOF,
        XSLT_FUNC_VALUEOF,
        XSLT_FUNC_NUMBER,
        XSLT_FUNC_APPLYIMPORTS,
        XSLT_FUNC_CALLTEMPLATE,
        XSLT_FUNC_APPLYTEMPLATES,
        XSLT_FUNC_CHOOSE,
        XSLT_FUNC_IF,
        XSLT_FUNC_FOREACH,
        XSLT_FUNC_DOCUMENT,
        XSLT_FUNC_WITHPARAM,
        XSLT_FUNC_PARAM,
        XSLT_FUNC_VARIABLE,
        XSLT_FUNC_WHEN,
        XSLT_FUNC_EXTENSION
    } xsltStyleType;

    typedef struct _xsltNsListContainer xsltNsListContainer;
    typedef xsltNsListContainer *xsltNsListContainerPtr;
    struct _xsltNsListContainer {
        xmlNsPtr *list;
        int totalNumber;
        int xpathNumber;
    };

    typedef struct _xsltPointerList xsltPointerList;
    typedef xsltPointerList *xsltPointerListPtr;
    struct _xsltPointerList {
        void **items;
        int number;
        int size;
    };
    typedef struct _xsltStyleItemLRElementInfo xsltStyleItemLRElementInfo;
    typedef xsltStyleItemLRElementInfo *xsltStyleItemLRElementInfoPtr;
    typedef struct _xsltEffectiveNs xsltEffectiveNs;
    typedef xsltEffectiveNs *xsltEffectiveNsPtr;
    struct _xsltEffectiveNs {
        xsltEffectiveNsPtr nextInStore; /* storage next */
        xsltEffectiveNsPtr next; /* next item in the list */
        const xmlChar *prefix;
        const xmlChar *nsName;
        /*
        * Indicates if eclared on the literal result element; dunno if really
        * needed.
        */
        int holdByElem;
    };
    struct _xsltStyleItemLRElementInfo {
        xsltNsListContainerPtr inScopeNs;
        /*
        * @effectiveNs is the set of effective ns-nodes
        *  on the literal result element, which will be added to the result
        *  element if not already existing in the result tree.
        *  This means that excluded namespaces (via exclude-result-prefixes,
        *  extension-element-prefixes and the XSLT namespace) not added
        *  to the set.
        *  Namespace-aliasing was applied on the @effectiveNs.
        */
        xsltEffectiveNsPtr effectiveNs;

    };
    struct _xsltCompilerNodeInfo {
        xsltCompilerNodeInfoPtr next;
        xsltCompilerNodeInfoPtr prev;
        xmlNodePtr node;
        int depth;
        xsltTemplatePtr templ;   /* The owning template */
        int category;	     /* XSLT element, LR-element or
                                    extension element */
        xsltStyleType type;
        xsltElemPreCompPtr item; /* The compiled information */
        /* The current in-scope namespaces */
        xsltNsListContainerPtr inScopeNs;
        /* The current excluded result namespaces */
        xsltPointerListPtr exclResultNs;
        /* The current extension instruction namespaces */
        xsltPointerListPtr extElemNs;

        /* The current info for literal result elements. */
        xsltStyleItemLRElementInfoPtr litResElemInfo;
        /*
        * Set to 1 if in-scope namespaces changed,
        *  or excluded result namespaces changed,
        *  or extension element namespaces changed.
        * This will trigger creation of new infos
        *  for literal result elements.
        */
        int nsChanged;
        int preserveWhitespace;
        int stripWhitespace;
        int isRoot; /* whether this is the stylesheet's root node */
        int forwardsCompat; /* whether forwards-compatible mode is enabled */
        /* whether the content of an extension element was processed */
        int extContentHandled;
        /* the type of the current child */
        xsltStyleType curChildType;
    };
    typedef struct _xsltPrincipalStylesheetData xsltPrincipalStylesheetData;
    typedef xsltPrincipalStylesheetData *xsltPrincipalStylesheetDataPtr; 
    typedef struct _xsltStyleItemUknown xsltStyleItemUknown;
    typedef xsltStyleItemUknown *xsltStyleItemUknownPtr;
    struct _xsltStyleItemUknown {
        xsltNsListContainerPtr inScopeNs;
    };


    typedef struct _xsltNsAlias xsltNsAlias;
    typedef xsltNsAlias *xsltNsAliasPtr;
    struct _xsltNsAlias {
        xsltNsAliasPtr next; /* next in the list */
        xmlNsPtr literalNs;
        xmlNsPtr targetNs;
        xmlDocPtr docOfTargetNs;
    };

    typedef struct _xsltVarInfo xsltVarInfo;
    typedef xsltVarInfo *xsltVarInfoPtr;
    struct _xsltVarInfo {
        xsltVarInfoPtr next; /* next in the list */
        xsltVarInfoPtr prev;
        int depth; /* the depth in the tree */
        const xmlChar *name;
        const xmlChar *nsName;
    };
    typedef struct _xsltCompilerCtxt xsltCompilerCtxt;
    typedef xsltCompilerCtxt *xsltCompilerCtxtPtr;
    struct _xsltCompilerCtxt {
        void *errorCtxt;            /* user specific error context */
        /*
        * used for error/warning reports; e.g. XSLT_ERROR_SEVERITY_WARNING */
        xsltErrorSeverityType errSeverity;
        int warnings;		/* TODO: number of warnings found at
                                    compilation */
        int errors;			/* TODO: number of errors found at
                                    compilation */
        xmlDictPtr dict;
        xsltStylesheetPtr style;
        int simplified; /* whether this is a simplified stylesheet */
        /* TODO: structured/unstructured error contexts. */
        int depth; /* Current depth of processing */

        xsltCompilerNodeInfoPtr inode;
        xsltCompilerNodeInfoPtr inodeList;
        xsltCompilerNodeInfoPtr inodeLast;
        xsltPointerListPtr tmpList; /* Used for various purposes */
        /*
        * The XSLT version as specified by the stylesheet's root element.
        */
        int isInclude;
        int hasForwardsCompat; /* whether forwards-compatible mode was used
                    in a parsing episode */
        int maxNodeInfos; /* TEMP TODO: just for the interest */
        int maxLREs;  /* TEMP TODO: just for the interest */
        /*
        * In order to keep the old behaviour, applying strict rules of
        * the spec can be turned off. This has effect only on special
        * mechanisms like whitespace-stripping in the stylesheet.
        */
        int strict;
        xsltPrincipalStylesheetDataPtr psData;
        xsltStyleItemUknownPtr unknownItem;
        int hasNsAliases; /* Indicator if there was an xsl:namespace-alias. */
        xsltNsAliasPtr nsAliases;
        xsltVarInfoPtr ivars; /* Storage of local in-scope variables/params. */
        xsltVarInfoPtr ivar; /* topmost local variable/param. */
    };

    typedef struct _xsltStylesheet {
        /*
         * The stylesheet import relation is kept as a tree.
         */
        struct _xsltStylesheet *parent;
        struct _xsltStylesheet *next;
        struct _xsltStylesheet *imports;
    
        xsltDocumentPtr docList;		/* the include document list */
    
        /*
         * General data on the style sheet document.
         */
        xmlDocPtr doc;		/* the parsed XML stylesheet */
        xmlHashTablePtr stripSpaces;/* the hash table of the strip-space and
                       preserve space elements */
        int             stripAll;	/* strip-space * (1) preserve-space * (-1) */
        xmlHashTablePtr cdataSection;/* the hash table of the cdata-section */
    
        /*
         * Global variable or parameters.
         */
        xsltStackElemPtr variables; /* linked list of param and variables */
    
        /*
         * Template descriptions.
         */
        xsltTemplatePtr templates;           /* the ordered list of templates */
        xmlHashTablePtr templatesHash;       /* hash table or wherever compiled
                                                templates information is stored */
        struct _xsltCompMatch *rootMatch;    /* template based on / */
        struct _xsltCompMatch *keyMatch;     /* template based on key() */
        struct _xsltCompMatch *elemMatch;    /* template based on * */
        struct _xsltCompMatch *attrMatch;    /* template based on @* */
        struct _xsltCompMatch *parentMatch;  /* template based on .. */
        struct _xsltCompMatch *textMatch;    /* template based on text() */
        struct _xsltCompMatch *piMatch;      /* template based on
                                                processing-instruction() */
        struct _xsltCompMatch *commentMatch; /* template based on comment() */
    
        /*
         * Namespace aliases.
         * NOTE: Not used in the refactored code.
         */
        xmlHashTablePtr nsAliases;	/* the namespace alias hash tables */
    
        /*
         * Attribute sets.
         */
        xmlHashTablePtr attributeSets;/* the attribute sets hash tables */
    
        /*
         * Namespaces.
         * TODO: Eliminate this.
         */
        xmlHashTablePtr nsHash;     /* the set of namespaces in use:
                                       ATTENTION: This is used for
                                       execution of XPath expressions; unfortunately
                                       it restricts the stylesheet to have distinct
                                       prefixes.
                       TODO: We need to get rid of this.
                     */
        void           *nsDefs;     /* ATTENTION TODO: This is currently used to store
                       xsltExtDefPtr (in extensions.c) and
                                       *not* xmlNsPtr.
                     */
    
        /*
         * Key definitions.
         */
        void *keys;			/* key definitions */
    
        /*
         * Output related stuff.
         */
        xmlChar *method;		/* the output method */
        xmlChar *methodURI;		/* associated namespace if any */
        xmlChar *version;		/* version string */
        xmlChar *encoding;		/* encoding string */
        int omitXmlDeclaration;     /* omit-xml-declaration = "yes" | "no" */
    
        /*
         * Number formatting.
         */
        xsltDecimalFormatPtr decimalFormat;
        int standalone;             /* standalone = "yes" | "no" */
        xmlChar *doctypePublic;     /* doctype-public string */
        xmlChar *doctypeSystem;     /* doctype-system string */
        int indent;			/* should output being indented */
        xmlChar *mediaType;		/* media-type string */
    
        /*
         * Precomputed blocks.
         */
        xsltElemPreCompPtr preComps;/* list of precomputed blocks */
        int warnings;		/* number of warnings found at compilation */
        int errors;			/* number of errors found at compilation */
    
        xmlChar  *exclPrefix;	/* last excluded prefixes */
        xmlChar **exclPrefixTab;	/* array of excluded prefixes */
        int       exclPrefixNr;	/* number of excluded prefixes in scope */
        int       exclPrefixMax;	/* size of the array */
    
        void     *_private;		/* user defined data */
    
        /*
         * Extensions.
         */
        xmlHashTablePtr extInfos;	/* the extension data */
        int		    extrasNr;	/* the number of extras required */
    
        /*
         * For keeping track of nested includes
         */
        xsltDocumentPtr includes;	/* points to last nested include */
    
        /*
         * dictionary: shared between stylesheet, context and documents.
         */
        xmlDictPtr dict;
        /*
         * precompiled attribute value templates.
         */
        void *attVTs;
        /*
         * if namespace-alias has an alias for the default stylesheet prefix
         * NOTE: Not used in the refactored code.
         */
        const xmlChar *defaultAlias;
        /*
         * bypass pre-processing (already done) (used in imports)
         */
        int nopreproc;
        /*
         * all document text strings were internalized
         */
        int internalized;
        /*
         * Literal Result Element as Stylesheet c.f. section 2.3
         */
        int literal_result;
        /*
        * The principal stylesheet
        */
        xsltStylesheetPtr principal;

        /*
        * Compilation context used during compile-time.
        */
        xsltCompilerCtxtPtr compCtxt; /* TODO: Change this to (void *). */
    
        xsltPrincipalStylesheetDataPtr principalData;

        /*
         * Forwards-compatible processing
         */
        int forwards_compatible;
    
        xmlHashTablePtr namedTemplates; /* hash table of named templates */
    
        xmlXPathContextPtr xpathCtxt;
    } xsltStylesheet;
    
    typedef xsltStylesheet *xsltStylesheetPtr;

    xsltStylesheetPtr xsltParseStylesheetDoc	(xmlDocPtr doc);
    xmlDocPtr	xsltApplyStylesheet	(xsltStylesheetPtr style, 
					 xmlDocPtr doc, 
					 const char ** params);
    xmlDocPtr xsltApplyStylesheetUser(xsltStylesheetPtr stylesheet,
                     xmlDocPtr doc,
                     const char** params,
                     const char* output,
                     void* profile,
                     xsltTransformContextPtr userCtxt);
    xsltTransformContextPtr xsltNewTransformContext(xsltStylesheetPtr stylesheet,
                     xmlDocPtr doc);
    void xsltFreeTransformContext(xsltTransformContextPtr ctxt);
    void xsltSetGenericErrorFunc (void * ctx, xmlGenericErrorFunc handler);

]]
