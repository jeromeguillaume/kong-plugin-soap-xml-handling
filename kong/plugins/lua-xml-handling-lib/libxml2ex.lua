local libxml2ex = {}

require("kong.plugins.lua-xml-handling-lib.libxml2ex.xmlschemas")
require("kong.plugins.lua-xml-handling-lib.libxml2ex.tree")
require("kong.plugins.lua-xml-handling-lib.libxml2ex.xmlerror")
require("xmlua.libxml2.xmlerror")

local ffi = require("ffi")
local loaded, xml2 = pcall(ffi.load, "xml2")
if not loaded then
  if _G.jit.os == "Windows" then
    xml2 = ffi.load("libxml2-2.dll")
  else
    xml2 = ffi.load("libxml2.so.2")
  end
end

-- Create an XML Schemas parse context for that memory buffer expected to contain an XML Schemas file.
-- buffer:	a pointer to a char array containing the schemas
-- size:	the size of the array
-- Returns:	the parser context or NULL in case of error
function libxml2ex.xmlSchemaNewMemParserCtxt (xsd_schema)
    
    local xsd_context = xml2.xmlSchemaNewMemParserCtxt(xsd_schema, #xsd_schema)
    
    if xsd_context == ffi.NULL then
        ngx.log(ngx.ERR, "xmlSchemaNewMemParserCtxt returns null")
        return nil
    end
    
    return ffi.gc(xsd_context, xml2.xmlSchemaFreeParserCtxt)
end

-- Parse a schema definition resource and build an internal XML Schema structure which can be used to validate instances.
-- ctxt:	a schema validation context
-- Returns:	the internal XML Schema structure built from the resource or NULL in case of error
function libxml2ex.xmlSchemaParse (xsd_context)
    local errMessage
    local error_handler = ffi.cast("xmlStructuredErrorFunc", function(userdata, xmlError)
      -- The callback function can be called two times in a row
      -- 1st time: initial message (like: "Start tag expected, '<' not found")
      if errMessage == nil then
        errMessage = libxml2ex.formatErrMsg(xmlError)
      -- 2nd time: cascading error message (like: "Failed to parse the XML resource", because the '<' not found in XSD")
      else
        errMessage = errMessage .. '. ' .. libxml2ex.formatErrMsg(xmlError)
      end
    end)

    xml2.xmlSetStructuredErrorFunc(xsd_context, error_handler)
    ffi.gc(error_handler, error_handler.free)
    
    local xsd_schema_doc = xml2.xmlSchemaParse(xsd_context)

    if xsd_schema_doc == ffi.NULL then
        ngx.log(ngx.ERR, "xmlSchemaParse returns null")
    end
    
    return xsd_schema_doc,  errMessage
end

-- Create an XML Schemas validation context based on the given schema.
-- schema:	a precompiled XML Schemas
-- Returns:	the validation context or NULL in case of error
function libxml2ex.xmlSchemaNewValidCtxt (xsd_schema_doc)
    local libxml2 = require("xmlua.libxml2")  
    local validation_context = xml2.xmlSchemaNewValidCtxt(xsd_schema_doc)
    
    if validation_context == ffi.NULL then
        ngx.log(ngx.ERR, "xmlSchemaNewValidCtxt returns null")
        return nil
    end

    return ffi.gc(validation_context, libxml2.xmlSchemaFreeValidCtxt)
end

-- Parse an XML in-memory document and build a tree.
-- buffer:	a pointer to a char array
-- size:	the size of the array
-- URL:	the base URL to use for the document
-- encoding:	the document encoding, or NULL
-- options:	a combination of xmlParserOption
-- Returns:	the resulting document tree
function libxml2ex.xmlReadMemory (xml_document, base_url_document, document_encoding, options)
  local libxml2 = require("xmlua.libxml2")
  local errMessage
  
  local error_handler = ffi.cast("xmlStructuredErrorFunc", function(userdata, xmlError)
      errMessage = libxml2ex.formatErrMsg(xmlError)
    end)
  xml2.xmlSetStructuredErrorFunc(nil, error_handler)
  ffi.gc(error_handler, error_handler.free)

  local xml_doc = xml2.xmlReadMemory (xml_document, #xml_document, base_url_document, document_encoding, options)
    
  if xml_doc == ffi.NULL then
    ngx.log(ngx.ERR, "xmlReadMemory returns null")
  end

  return ffi.gc(xml_doc, libxml2.xmlFreeDoc), errMessage
end

-- Validate a document tree in memory.
-- ctxt:	a schema validation context
-- doc:	a parsed document tree
-- Returns:	0 if the document is schemas valid, a positive error code number otherwise and -1 in case of internal or API error.
function libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc)
  local errMessage
  local error_handler = ffi.cast("xmlStructuredErrorFunc", function(userdata, xmlError)
      errMessage = libxml2ex.formatErrMsg(xmlError)
    end)
  xml2.xmlSchemaSetValidStructuredErrors(validation_context, error_handler, nil)
  
  ffi.gc(error_handler, error_handler.free)

  local is_valid = xml2.xmlSchemaValidateDoc (validation_context, xml_doc)

  return tonumber(is_valid), errMessage
end

-- Validate a branch of a tree, starting with the given @elem.
-- ctxt:	a schema validation context
-- elem:	an element node
-- Returns:	0 if the element and its subtree is valid, a positive error code number otherwise and -1 in case of an internal or API error.
function libxml2ex.xmlSchemaValidateOneElement	(validation_context, xmlNodePtr)
  local errMessage
  local error_handler = ffi.cast("xmlStructuredErrorFunc", function(userdata, xmlError)
      errMessage = libxml2ex.formatErrMsg(xmlError)
    end)
  xml2.xmlSchemaSetValidStructuredErrors(validation_context, error_handler, nil)
  
  ffi.gc(error_handler, error_handler.free)

  local is_valid = xml2.xmlSchemaValidateOneElement (validation_context, xmlNodePtr)
  return tonumber(is_valid), errMessage
end

-- Format the Error Message
function libxml2ex.formatErrMsg(xmlError)

  local xmlErrorMsg = ffi.string(xmlError.message)
  -- If the last character is Return Line
  if xmlErrorMsg:sub(-1) == '\n' then
    -- Remove the Return Line
    xmlErrorMsg = xmlErrorMsg:sub(1, -2)
  end
  
  local errMessage =  "Error code: "  .. tonumber(xmlError.code) ..
                      ", Line: "      .. tonumber(xmlError.line) ..
                      ", Message: "   .. xmlErrorMsg
  return errMessage
end

-- Get the last parsing error registered
-- ctx:	an XML parser context
-- Returns:	NULL if no error occurred or a pointer to the error
-- **** DON'T USE THIS FUNCTION: it returns a global variable Error and it's for the nginx multi-treaded processing 
function libxml2ex.xmlGetLastError ()
  local errMessage = ""
  local xmlError = xml2.xmlGetLastError()
  if xmlError ~= ffi.NULL then
    errMessage = libxml2ex.formatErrMsg(xmlError)
    xml2.xmlResetLastError()
  else
    xmlError = nil
  end
  return errMessage, xmlError
end

-- Dump an XML node, recursive behaviour,children are printed too. 
-- Note that @format = 1 provide node indenting only if xmlIndentTreeOutput = 1 or xmlKeepBlanksDefault(0) was called.
-- Since this is using xmlBuffer structures it is limited to 2GB and somehow deprecated, use xmlNodeDumpOutput() instead.
-- buf:	the XML buffer output
-- doc:	the document
-- cur:	the current node
-- level:	the imbrication level for indenting
-- format:	is formatting allowed
-- Returns:	the number of bytes written to the buffer or -1 in case of error
function libxml2ex.xmlNodeDump	(xmlDocPtr, xmlNodePtr, level, format)
  local xmlBuffer = xml2.xmlBufferCreate();
  local errDump = -1
  local xmlDump = ""

  if xmlBuffer ~= ffi.NULL then
    local rc = xml2.xmlNodeDump(xmlBuffer, xmlDocPtr, xmlNodePtr, level, format)
    -- if we succeeded dumping XML
    if tonumber(rc) ~= -1 then
      xmlDump = ffi.string(xmlBuffer.content)
      -- No error
      errDump = 0
    else
      ngx.log(ngx.ERR, "Error calling 'xmlNodeDump'")
    end
    -- free Buffer
    xml2.xmlBufferFree(xmlBuffer)
  else
    ngx.log(ngx.ERR, "Error calling 'xmlBufferCreate'")
  end
  return xmlDump, errDump
end

function libxml2ex.xmlSchemaValidCtxtGetParserCtxt (xmlSchemaValidCtxtPtr)
  return xml2.xmlSchemaValidCtxtGetParserCtxt(xmlSchemaValidCtxtPtr)
end

-- Search and get the value of an attribute associated to a node This does the entity substitution. This function looks in DTD attribute declaration for #FIXED or default declaration values unless DTD use has been turned off. This function is similar to xmlGetProp except it will accept only an attribute in no namespace.
-- node:	the node
-- name:	the attribute name
-- Returns:	the attribute value or NULL if not found. It's up to the caller to free the memory with xmlFree().
function libxml2ex.xmlGetNoNsProp	(node, name)
  local attribute = xml2.xmlGetNoNsProp (node, name)

  return attribute
end

return libxml2ex