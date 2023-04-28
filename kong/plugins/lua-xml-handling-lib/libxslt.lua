local libxslt = {}

require("kong.plugins.lua-xml-handling-lib.libxslt.internals")

local ffi = require("ffi")
local loaded, xslt = pcall(ffi.load, "xslt")

-- Parse an XSLT stylesheet, building the associated structures. doc is kept as a reference within the returned stylesheet, so changes to doc after the parsing will be reflected when the stylesheet is applied, and the doc is automatically freed when the stylesheet is closed.
-- Doc:	and xmlDoc parsed XML
-- Returns:	a new XSLT stylesheet structure.
function libxslt.xsltParseStylesheetDoc (styledoc)
    local style = xslt.xsltParseStylesheetDoc(styledoc)
    
    if style == ffi.NULL then
        ngx.log(ngx.ERR, "xsltParseStylesheetDoc returns null")
    end
    -- No need to free memory, it's already done (and it avoids the msg 'free(): double free detected in tcache 2')
    -- return ffi.gc(style, xslt.xsltFreeStylesheet)
    return style
end

-- Apply the stylesheet to the document NOTE: This may lead to a non-wellformed output XML wise!
-- style:	a parsed XSLT stylesheet
-- doc:	a parsed XML document
-- params:	a NULL terminated arry of parameters names/values tuples
-- Returns:	the result document or NULL in case of error
function libxslt.xsltApplyStylesheet (style, doc)
    local doc_transformed = xslt.xsltApplyStylesheet (style, doc, nil)

    if doc_transformed == ffi.NULL then
        ngx.log(ngx.ERR, "xsltApplyStylesheet returns null")
    end
    local libxml2     = require("xmlua.libxml2")
    
    return ffi.gc(doc_transformed, libxml2.xmlFreeDoc)
end

return libxslt