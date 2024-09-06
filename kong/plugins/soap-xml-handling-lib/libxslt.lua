local libxslt = {}

require("kong.plugins.soap-xml-handling-lib.libxslt.internals")

local libxml2   = require("xmlua.libxml2")
local ffi       = require("ffi")

local loaded, xslt = pcall(ffi.load, "xslt")

-- Parse an XSLT stylesheet, building the associated structures. doc is kept as a reference within the returned stylesheet, so changes to doc after the parsing will be reflected when the stylesheet is applied, and the doc is automatically freed when the stylesheet is closed.
-- Doc:	and xmlDoc parsed XML
-- Returns:	a new XSLT stylesheet structure.
function libxslt.xsltParseStylesheetDoc (styledoc)
  local errMessage
  local style
  kong.ctx.shared.xmlSoapErrMessage = nil
  style = xslt.xsltParseStylesheetDoc(styledoc)
  
  if style == ffi.NULL then
    kong.log.err("xsltParseStylesheetDoc returns null")
  elseif kong.ctx.shared.xmlSoapErrMessage then
    errMessage = kong.ctx.shared.xmlSoapErrMessage
  end
    
  -- No need to free memory, it's already done (and it avoids the msg 'free(): double free detected in tcache 2')
  -- return ffi.gc(style, xslt.xsltFreeStylesheet)
  return style, errMessage
end

-- Apply the stylesheet to the document NOTE: This may lead to a non-wellformed output XML wise!
-- style:	a parsed XSLT stylesheet
-- doc:	a parsed XML document
-- params:	a NULL terminated arry of parameters names/values tuples
-- Returns:	the result document or NULL in case of error
function libxslt.xsltApplyStylesheet (style, doc)
    local doc_transformed = xslt.xsltApplyStylesheet (style, doc, nil)

    if doc_transformed == ffi.NULL then
      kong.log.err("xsltApplyStylesheet returns null")
    end
    
    return ffi.gc(doc_transformed, libxml2.xmlFreeDoc)
end

function libxslt.make_parameter_table()
    return setmetatable({}, {
        __newindex = function (t, key, value)
          if type(value) == "string" then
            if string.find(value, "'") then
              error("cannot use apostrophe in string value passed to xslt")
            end
            rawset(t, key, "'" .. value .. "'")
          elseif type(value) == "number" then
            rawset(t, key, value)
          else
            error("cannot pass value of type " .. type(value) .. " as parameter to xslt")
          end
        end,
    })
  end
  
-- Apply the stylesheet to the document and allow the user to provide its own transformation context.
-- style:	a parsed XSLT stylesheet
-- doc:	a parsed XML document
-- params:	a NULL terminated array of parameters names/values tuples
-- output:	the targetted output
-- profile:	profile FILE * output or NULL
-- userCtxt:	user provided transform context
-- Returns:	the result document or NULL in case of error
function libxslt.xsltApplyStylesheetUser(stylesheet, doc, params)

    local context = xslt.xsltNewTransformContext(stylesheet, doc)
    local xml2 = ffi.load "xml2"
    ffi.gc(context, xslt.xsltFreeTransformContext)

    local param_pairs = {}
    for k, v in pairs(params) do
      param_pairs[#param_pairs + 1] = k
      param_pairs[#param_pairs + 1] = v
    end

    local params_array = ffi.new("const char*[?]", #param_pairs + 1, param_pairs)
    params_array[#param_pairs] = nil

    local result = xslt.xsltApplyStylesheetUser(stylesheet, doc, params_array, ffi.NULL, ffi.NULL, context)
    if result == nil then
        return nil
    end
    ffi.gc(result, xml2.xmlFreeDoc)

end

return libxslt