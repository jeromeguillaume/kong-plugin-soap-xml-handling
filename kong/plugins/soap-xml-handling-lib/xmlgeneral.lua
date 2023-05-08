local xmlgeneral = {}

xmlgeneral.HTTPCodeSOAPFault = 500

xmlgeneral.RequestTextError   = "Request"
xmlgeneral.ResponseTextError  = "Response"
xmlgeneral.SepTextError       = " - "
xmlgeneral.XSLTError          = "XSLT transformation failed"
xmlgeneral.XSDError           = "XSD validation failed"
xmlgeneral.BeforeXSD          = " (before XSD validation)"
xmlgeneral.AfterXSD           = " (after XSD validation)"

---------------------------------
-- Format the SOAP Fault message
---------------------------------
function xmlgeneral.formatSoapFault(VerboseResponse, ErrMsg, ErrEx)
  local detailErrMsg
  
  -- If verbose mode is enabled we display the detailed Error Message
  if VerboseResponse then
    detailErrMsg = ErrMsg .. ": " .. ErrEx
  else
    detailErrMsg = ErrMsg
  end

  local soapErrMsg = "\
<?xml version=\"1.0\" encoding=\"utf-8\"?> \
<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"> \
  <soap:Body> \
    <soap:Fault>\
      <faultcode>soap:Client</faultcode>\
      <faultstring>" .. detailErrMsg .. "</faultstring>\
      <detail/>\
    </soap:Fault>\
  </soap:Body>\
</soap:Envelope>\
"
  kong.log.err ("formatSoapFault, soapErrMsg:" .. soapErrMsg)
  return soapErrMsg
end

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function xmlgeneral.returnSoapFault(plugin_conf, HTTPcode, soapErrMsg)  
  -- Sends a Fault code to client
  return kong.response.exit(HTTPcode, soapErrMsg, {["Content-Type"] = "text/xml; charset=utf-8"})
end

----------------------------------------------------------------------------------------
-- Prepare a XML declaration (which starts by '<?')
-- The XLST removes it; so if the user defines its xslt file with 
-- omit-xml-declaration="no" we format it and append it to SOAP/XML content (after XSLT)
--
-- Example: <?xml version="1.0" encoding="utf-8"?>
----------------------------------------------------------------------------------------
function xmlgeneral.XSLT_Format_XMLDeclaration(plugin_conf, version, encoding, omitXmlDeclaration, standalone, indent)
  local xmlDeclaration = ""
  local ffi = require("ffi")
  
  -- If we have to Format and Add (to SOAP/XML content) the XML declaration
  if omitXmlDeclaration == 0 then
    xmlDeclaration = "<?xml version=\""
    if version == ffi.NULL then
      xmlDeclaration = xmlDeclaration .. "1.0\""
    else
      xmlDeclaration = xmlDeclaration .. ffi.string(version) .. "\""
    end
    xmlDeclaration = xmlDeclaration .. " encoding=\""
    if encoding == ffi.NULL then
      xmlDeclaration = xmlDeclaration .. "utf-8\""
    else
      xmlDeclaration = xmlDeclaration .. ffi.string(encoding) .. "\""
    end
    if standalone == 1 then
      xmlDeclaration = xmlDeclaration .. " standalone=\"yes\""
    end
    xmlDeclaration = xmlDeclaration .. "?>"
    if indent == 1 then
      xmlDeclaration = xmlDeclaration .. "\n"
    end
  end
  
  return xmlDeclaration
end

------------------------------------------
-- Transform XML with XSLT Transformation
------------------------------------------
function xmlgeneral.XSLTransform(plugin_conf, XMLtoTransform, XSLT)
  local libxml2ex   = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
  local libxslt     = require("kong.plugins.soap-xml-handling-lib.libxslt")
  local libxml2     = require("xmlua.libxml2")
  local ffi         = require("ffi")
  local errMessage  = ""
  local err         = nil
  local style       = nil
  local xml_doc     = nil
  local errDump     = 0
  local xml_transformed_dump  = ""
  local xmlNodePtrRoot        = nil
  
  kong.log. debug("XSLT transformation, BEGIN: " .. XMLtoTransform)
  
  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING,
                                        ffi.C.XML_PARSE_NONET)
                                        
  -- Load the XSLT document
  local xslt_doc, errMessage = libxml2ex.xmlReadMemory(XSLT, nil, nil, default_parse_options)
  
  if errMessage == nil then
    -- Parse XSLT document
    style = libxslt.xsltParseStylesheetDoc (xslt_doc)
    if style ~= nil then
      -- Load the complete XML document (with <soap:Envelope>)
      xml_doc, errMessage = libxml2ex.xmlReadMemory(XMLtoTransform, nil, nil, default_parse_options)
    else
      errMessage = "error calling 'xsltParseStylesheetDoc'"
    end
  end

  -- If the XSLT and the XML are correctly loaded and parsed
  if errMessage == nil then
    -- Transform the XML doc with XSLT transformation
    local xml_transformed = libxslt.xsltApplyStylesheet (style, xml_doc)
    
    if xml_transformed ~= nil then
      -- Dump into a String the canonized image of the XML transformed by XSLT
      xml_transformed_dump, errDump = libxml2ex.xmlC14NDocSaveTo (xml_transformed, nil)
      if errDump == 0 then
        -- If needed we wppend the xml declaration
        -- Example: <?xml version="1.0" encoding="utf-8"?>
        xml_transformed_dump = xmlgeneral.XSLT_Format_XMLDeclaration (
                                            plugin_conf, 
                                            style.version, 
                                            style.encoding,
                                            style.omitXmlDeclaration, 
                                            style.standalone, 
                                            style.indent) .. xml_transformed_dump

        -- Remove empty Namespace (example: xmlns="") added by XSLT library or transformation 
        xml_transformed_dump = xml_transformed_dump:gsub(' xmlns=""', '')
        kong.log. debug ("XSLT transformation, END: " .. xml_transformed_dump)
      else
        errMessage = "error calling 'xmlC14NDocSaveTo'"
      end
    else
      errMessage = "error calling 'xsltApplyStylesheet'"
    end
  end
  
  if errMessage ~= nil then
    kong.log.err ("XSLT transformation, errMessage: " .. errMessage)
  end

  -- xmlCleanupParser()
  -- xmlMemoryDump()
  
  return xml_transformed_dump, errMessage
  
end

--------------------------------------
-- Validate a XML with its XSD schema
--------------------------------------
function xmlgeneral.XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, XSDSchema)
  local ffi           = require("ffi")
  local libxml2ex     = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
  local libxml2       = require("xmlua.libxml2")
  local errMessage    = nil
  local err           = nil
  local is_valid      = 0
  
  -- Create Parser Context
  local xsd_context = libxml2ex.xmlSchemaNewMemParserCtxt(XSDSchema)
  
  -- Create XSD schema
  local xsd_schema_doc, errMessage = libxml2ex.xmlSchemaParse(xsd_context)
  
  -- If there is no error loading the XSD schema
  if not errMessage then
    
    -- Create Validation context of XSD Schema
    local validation_context = libxml2ex.xmlSchemaNewValidCtxt(xsd_schema_doc)
    
    local default_parse_options = bit.bor(ffi.C.XML_PARSE_RECOVER)
    local xml_doc = libxml2ex.xmlReadMemory(XMLtoValidate, nil, nil, default_parse_options )
    
    -- if we have to find the 1st Child of API which is this example <Add ... /"> (and not the <soap> root)
    if child ~=0 then
      -- Example:
      -- <soap:Envelope xmlns:xsi=....">
      --    <soap:Body>
      --      <Add xmlns="http://tempuri.org/">
      --        <a>5</a>
      --        <b>7</b>
      --      </Add>
      --    </soap:Body>
      --  </soap:Envelope>
      
      -- Get Root Element, which is <soap:Envelope>
      local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_doc);
      -- Get Child Element, which is <soap:Body>
      local xmlNodePtrChild  = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
      -- Get WebService Child Element, which is, for instance, <Add xmlns="http://tempuri.org/">
      local xmlNodePtrChildWS = libxml2.xmlFirstElementChild(xmlNodePtrChild)

      -- Dump in a String the WebService part
      kong.log. debug ("XSD validation API part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrChildWS, 1, 1))

      -- Check validity of One element with its XSD schema
      is_valid, errMessage = libxml2ex.xmlSchemaValidateOneElement (validation_context, xmlNodePtrChildWS)
    else
      -- Get Root Element, which is <soap:Envelope>
      local xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xml_doc);
      kong.log. debug ("XSD validation SOAP part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrRoot, 1, 1))

      -- Check validity of XML with its XSD schema
      is_valid, errMessage = libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc)
      kong.log. debug ("is_valid: " .. is_valid)
    end
  end
  
  if not errMessage and is_valid == 0 then
    kong.log. debug ("XSD validation of SOAP schema: Ok")
  elseif errMessage then
    kong.log.err ("XSD validation of SOAP schema: Ko, " .. errMessage)
  else
    errMessage = "Ko"
    kong.log.err ("XSD validation of SOAP schema: ")
  end
  return errMessage
end

---------------------------------------------
-- Search a XPath and Compares it to a value
---------------------------------------------
function xmlgeneral.RouteByXPath (kong, XMLtoSearch, XPath, XPathCondition, XPathRegisterNs)
  local ffi         = require("ffi")
  local libxml2ex   = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
  local libxml2     = require("xmlua.libxml2")
  local rcXpath     = false
  
  kong.log. debug("RouteByXPath, XMLtoSearch: " .. XMLtoSearch)

  local context = libxml2.xmlNewParserCtxt()
  local document = libxml2.xmlCtxtReadMemory(context, XMLtoSearch)
  
  if not document then
    kong.log.err ("RouteByXPath, xmlCtxtReadMemory error, no document")
  end
  
  local context = libxml2.xmlXPathNewContext(document)
  
  -- Register NameSpace(s)
  kong.log. debug("XPathRegisterNs length: " .. #XPathRegisterNs)
  
  -- Go on each NameSpace definition
  for i = 1, #XPathRegisterNs do
    local prefix, uri
    local j = XPathRegisterNs[i]:find(',', 1)
    if j then
      prefix  = string.sub(XPathRegisterNs[i], 1, j - 1)
      uri     = string.sub(XPathRegisterNs[i], j + 1, #XPathRegisterNs[i])
    end
    local rc = false
    if prefix and uri then
      -- Register NameSpace
      rc = libxml2.xmlXPathRegisterNs(context, prefix, uri)
    end
    if rc then
      kong.log. debug("RouteByXPath, successful registering NameSpace for '" .. XPathRegisterNs[i] .. "'")
    else
      kong.log.err("RouteByXPath, failure registering NameSpace for '" .. XPathRegisterNs[i] .. "'")
    end
  end

  local object = libxml2.xmlXPathEvalExpression(XPath, context)
  if object ~= ffi.NULL then
    
    -- If we found the XPath element
    if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then        
        local nodeContent = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
        kong.log. debug("libxml2.xmlNodeGetContent: " .. nodeContent)
        if nodeContent == XPathCondition then
          rcXpath = true
        end
    else
      kong.log.err ("RouteByXPath, object.nodesetval is null")  
    end
  else
    kong.log.err ("RouteByXPath, object is null")
  end
  local msg = "with XPath=\"" .. XPath .. "\" and XPathCondition=\"" .. XPathCondition .. "\""
  
  if rcXpath then
    kong.log. debug ("RouteByXPath: Ok " .. msg)
  else
    kong.log. debug ("RouteByXPath: Ko " .. msg)
  end
  return rcXpath
end

return xmlgeneral