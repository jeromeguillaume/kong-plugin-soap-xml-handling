local xmlgeneral = {}

local ffi               = require("ffi")
local libxml2           = require("xmlua.libxml2")
local libxml2ex         = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
local libxslt           = require("kong.plugins.soap-xml-handling-lib.libxslt")

local loaded, xml2 = pcall(ffi.load, "xml2")

xmlgeneral.HTTPCodeSOAPFault = 500

xmlgeneral.RequestTextError   = "Request"
xmlgeneral.ResponseTextError  = "Response"
xmlgeneral.SepTextError       = " - "
xmlgeneral.XSLTError          = "XSLT transformation failed"
xmlgeneral.XSDError           = "XSD validation failed"
xmlgeneral.BeforeXSD          = " (before XSD validation)"
xmlgeneral.AfterXSD           = " (after XSD validation)"

local HTTP_ERROR_MESSAGES = {
    [400] = "Bad request",
    [401] = "Unauthorized",
    [402] = "Payment required",
    [403] = "Forbidden",
    [404] = "Not found",
    [405] = "Method not allowed",
    [406] = "Not acceptable",
    [407] = "Proxy authentication required",
    [408] = "Request timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length required",
    [412] = "Precondition failed",
    [413] = "Payload too large",
    [414] = "URI too long",
    [415] = "Unsupported media type",
    [416] = "Range not satisfiable",
    [417] = "Expectation failed",
    [418] = "I'm a teapot",
    [421] = "Misdirected request",
    [422] = "Unprocessable entity",
    [423] = "Locked",
    [424] = "Failed dependency",
    [425] = "Too early",
    [426] = "Upgrade required",
    [428] = "Precondition required",
    [429] = "Too many requests",
    [431] = "Request header fields too large",
    [451] = "Unavailable for legal reasons",
    [494] = "Request header or cookie too large",
    [500] = "An unexpected error occurred",
    [501] = "Not implemented",
    [502] = "An invalid response was received from the upstream server",
    [503] = "The upstream server is currently unavailable",
    [504] = "The upstream server is timing out",
    [505] = "HTTP version not supported",
    [506] = "Variant also negotiates",
    [507] = "Insufficient storage",
    [508] = "Loop detected",
    [510] = "Not extended",
    [511] = "Network authentication required",
}

---------------------------------
-- Format the SOAP Fault message
---------------------------------
function xmlgeneral.formatSoapFault(VerboseResponse, ErrMsg, ErrEx)
  local detailErrMsg
  
  -- If verbose mode is enabled we display the detailed Error Message
  if VerboseResponse then
    detailErrMsg = ErrEx
    
    -- Add the Http status code of the SOAP/XML Web Service only during 'Response' phases (response, header_filter, body_filter)
    local ngx_get_phase = ngx.get_phase
    if  ngx_get_phase() == "response"      or 
        ngx_get_phase() == "header_filter" or 
        ngx_get_phase() == "body_filter"   then
      local status = kong.service.response.get_status()
      if status ~= nil then
        local additionalErrMsg = ''
        additionalErrMsg = ". SOAP/XML Web Service - HTTP code: " .. tostring(status)
        detailErrMsg = detailErrMsg .. additionalErrMsg
      end
    end
    detailErrMsg ="<detail>" .. detailErrMsg .. "<detail/>"
  else
    detailErrMsg = ""
  end

  local soapErrMsg = "<?xml version=\"1.0\" encoding=\"utf-8\"?> \
<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"> \
  <soap:Body> \
    <soap:Fault>\
      <faultcode>soap:Client</faultcode>\
      <faultstring>" .. ErrMsg .. "</faultstring>\
      " .. detailErrMsg .. "\
    </soap:Fault>\
  </soap:Body>\
</soap:Envelope>\
"
  kong.log.err ("formatSoapFault, soapErrMsg:" .. soapErrMsg)
  return soapErrMsg
end

----------------------------------------------------
-- Re-Format a JSON message to a SOAP Fault message
----------------------------------------------------
function xmlgeneral.reformatJsonToSoapFault(VerboseResponse)
  local soapFaultBody
  
  local msg = HTTP_ERROR_MESSAGES[kong.response.get_status()]
  
  if not msg then
    msg = "Error"
  end

  soapFaultBody = xmlgeneral.formatSoapFault(VerboseResponse, msg, "HTTP Error code is " .. tostring(kong.response.get_status()))
  
  return soapFaultBody
end

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function xmlgeneral.returnSoapFault(plugin_conf, HTTPcode, soapErrMsg)  
  -- Sends a Fault code to client
  return kong.response.exit(HTTPcode, soapErrMsg, {["Content-Type"] = "text/xml; charset=utf-8"})
end

---------------------------------------------------------------------
-- Initialize the 'libxml2' Error handler and External Entity Loader
---------------------------------------------------------------------
function xmlgeneral.initializeHandlerLoader ()
  -- We initialize the Error Handler only one time for the Nginx process and for the Plugin
  -- The error message will be set contextually to the Request by using the 'kong.ctx'
  -- Conversely if we initialize the Error Handler on each Request (like 'access' phase)
  -- the 'libxml2' library complains with an error message: 'too many calls' (after ~100 calls)
  if not kong.xmlSoapErrorHandler then
    kong.log.debug ("initializeErrorHandler: it's the 1st time the function is called => initialize the 'libxml2' Error Handler")
    kong.xmlSoapErrorHandler = ffi.cast("xmlStructuredErrorFunc", function(userdata, xmlError)
      -- The callback function can be called two times in a row
      -- 1st time: initial message (like: "Start tag expected, '<' not found")
      if kong.ctx.shared.xmlSoapErrMessage == nil then
        kong.ctx.shared.xmlSoapErrMessage = libxml2ex.formatErrMsg(xmlError)
      -- 2nd time: cascading error message (like: "Failed to parse the XML resource", because the '<' not found in XSD")
      else
        kong.ctx.shared.xmlSoapErrMessage = kong.ctx.shared.xmlSoapErrMessage .. '. ' .. libxml2ex.formatErrMsg(xmlError)
      end
    end)
  else
    kong.log.debug ("initializeErrorHandler: 'libxml2' Error Handler is already initialized => nothing to do")
  end

  -- Initialize the External Entity Loader for downloading XSD that are imported on 'http(s)://'
  -- Example: <xsd:import namespace="http://tempuri.org/" schemaLocation="https://mytempui.com/tempui.org.xsd"/>
  if not kong.xmlSoapInitializeExternalEntityLoader then
    libxml2ex.initializeExternalEntityLoader()
    kong.xmlSoapInitializeExternalEntityLoader = true
  else
    kong.log.debug ("initializeExternalEntityLoader: 'libxml2' External Load is already initialized => nothing to do")
  end
end

-------------------------------------------------------------------
-- Initialize the Contextual Data related to the External Entities
-------------------------------------------------------------------
function xmlgeneral.initializeContextualDataExternalEntities (plugin_conf)
  if kong.ctx.shared.xmlSoapExternalEntity == nil then
    kong.ctx.shared.xmlSoapExternalEntity = {}
  end
  kong.ctx.shared.xmlSoapExternalEntity.timeout  = plugin_conf.ExternalEntityLoader_Timeout
  kong.ctx.shared.xmlSoapExternalEntity.cacheTTL = plugin_conf.ExternalEntityLoader_CacheTTL
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
function xmlgeneral.XSLTransform(plugin_conf, XMLtoTransform, XSLT, verbose)
  local errMessage  = ""
  local err         = nil
  local style       = nil
  local xml_doc     = nil
  local errDump     = 0
  local xml_transformed_dump  = ""
  local xmlNodePtrRoot        = nil
  
  kong.log.debug("XSLT transformation, BEGIN: " .. XMLtoTransform)

  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                      ffi.C.XML_PARSE_NOWARNING)

  -- Load the XSLT document
  local xslt_doc, errMessage = libxml2ex.xmlReadMemory(XSLT, nil, nil, default_parse_options, verbose)
  
  if errMessage == nil then
    -- Parse XSLT document
    style = libxslt.xsltParseStylesheetDoc (xslt_doc)
    if style ~= nil then
      -- Load the complete XML document (with <soap:Envelope>)
      xml_doc, errMessage = libxml2ex.xmlReadMemory(XMLtoTransform, nil, nil, default_parse_options, verbose)
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
        -- If needed we append the xml declaration
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
        kong.log.debug ("XSLT transformation, END: " .. xml_transformed_dump)
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

------------------------------
-- Validate a XML with a WSDL
------------------------------
function xmlgeneral.XMLValidateWithWSDL (plugin_conf, child, XMLtoValidate, WSDL, verbose)
  local xml_doc           = nil
  local errMessage        = nil
  local xsdSchema         = nil
  local currentNode       = nil
  local wsdlNodeFound     = false
  local typesNodeFound    = false
  local validSchemaFound  = false
  local nodeName          = ""
  local index             = 0
  
  -- If we have a WDSL file, we retrieve the '<wsdl:types>' Node AND the '<xs:schema>' child nodes 
  --   OR
  -- In we have a raw XSD schema '<xs:schema>'
  --   THEN
  -- We do a loop for validating the 'XMLtoValidate' XML with each '<xs:schema>' until one works
  --
  -- Example of WSDL:
  --  <wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tns="http://tempuri.org/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:http="http://schemas.microsoft.com/ws/06/2004/policy/http" xmlns:msc="http://schemas.microsoft.com/ws/2005/12/wsdl/contract" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsam="http://www.w3.org/2007/05/addressing/metadata" targetNamespace="http://tempuri.org/" name="INonCacheService" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">
  --    <wsdl:types>
  --      <xs:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ser="http://schemas.microsoft.com/2003/10/Serialization/">
  --        <xs:import namespace="http://schemas.datacontract.org/2004/07/APIM_Dummy.Common.Models.Responses" />
  --        <xs:element name="DeleteDummyPayload">
  --        ....
  --      </xs:schema>
  --      <xs:schema attributeFormDefault="qualified" elementFormDefault="qualified" targetNamespace="http://schemas.microsoft.com/2003/10/Serialization/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tns="http://schemas.microsoft.com/2003/10/Serialization/">
  --        ....
  --      </xs:schema>
  --  </wsdl:types>
  --  <wsdl:message name="INonCacheService_DeleteDummyPayload_InputMessage">
  --    <wsdl:part name="parameters" element="tns:DeleteDummyPayload" />
  --  </wsdl:message>

  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                      ffi.C.XML_PARSE_NOWARNING)

  -- Parse an XML in-memory document and build a tree
  xml_doc, errMessage = libxml2ex.xmlReadMemory(WSDL, nil, nil, default_parse_options, verbose)
  if errMessage then
    errMessage = "WSDL validation, errMessage " .. errMessage
    kong.log.err (errMessage)
    return errMessage
  end
  kong.log.debug("XMLValidateWithWSDL, xmlReadMemory - Ok")
  
  -- Retrieve the <wsdl:definitions>
  local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_doc)
  if xmlNodePtrRoot then
    if tonumber(xmlNodePtrRoot.type) == ffi.C.XML_ELEMENT_NODE then
      nodeName = ffi.string(xmlNodePtrRoot.name)
      if nodeName == "definitions" then
        wsdlNodeFound = true
      end
    end
  end

  -- If we found the <wsdl:definitions>
  if wsdlNodeFound then
    currentNode  = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
    -- Retrieve '<wsdl:types>' Node in the WSDL
    while currentNode ~= ffi.NULL and not typesNodeFound do
      if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE then
        kong.log.debug ("currentNode.name: " .. ffi.string(currentNode.name))
        nodeName = ffi.string(currentNode.name)
        if nodeName == "types" then
          typesNodeFound = true
        end
      end
      if not typesNodeFound then
        currentNode = ffi.cast("xmlNode *", currentNode.next)
      end
    end
    -- If we don't find <wsdl:types>
    if not typesNodeFound then
      errMessage = "Unable to find the 'wsdl:types'"
      kong.log.err (errMessage)
      return errMessage
    end
  else
    kong.log.debug("Unable to find the '<wsdl:definitions>', so we consider the XSD as a raw '<xs:schema>'")
  end
  -- If we found the '<wsdl:types>' Node we select the first child Node which is '<xs:schema>'
  if typesNodeFound then
    kong.log.debug("XMLValidateWithWSDL, Found the '<wsdl:types>' Node")
    currentNode  = libxml2.xmlFirstElementChild(currentNode)
  -- Else it's a not a WSDL it's a raw <xs:schema>
  else
    currentNode = xmlNodePtrRoot
  end
  -- Retrieve all '<xs:schema>' Nodes until we found a valid Schema validating the XML
  while currentNode ~= ffi.NULL and not validSchemaFound do
    
    if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE then
      -- Get the node Name
      nodeName = ffi.string(currentNode.name)
      if nodeName == "schema" then
        index = index + 1
        xsdSchema = libxml2ex.xmlNodeDump	(xml_doc, currentNode, 1, 1)
        kong.log.debug ("schema #" .. index .. ", lentgh: " .. #xsdSchema .. ", dump: " .. xsdSchema)
        errMessage = nil
        -- Validate the XML with the <xs:schema>'
        errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, xsdSchema, verbose)
        -- If there is no error it means that we found the right Schema validating the SOAP/XML
        if not errMessage then
          kong.log.debug ("We found the right XSD Schema validating the SOAP/XML")
          validSchemaFound = true
          errMessage = nil
          break
        end
      end
    end
    -- Go to the next '<xs:schema' Node
    currentNode = ffi.cast("xmlNode *", currentNode.next)
  end

  -- If there is no Error and we don't retrieve a valid Schema for the XML
  if not errMessage and not validSchemaFound then
    errMessage = "Unable to find a suitable Schema to validate the SOAP/XML"
  end

  return errMessage
end

--------------------------------------
-- Validate a XML with its XSD schema
--------------------------------------
function xmlgeneral.XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, XSDSchema, verbose)
  local xml_doc       = nil
  local errMessage    = nil
  local err           = nil
  local is_valid      = 0
  local schemaType    = ""
  local bodyNodeFound = nil
  local currentNode   = nil
  local nodeName      = ""
  local libxml2           = require("xmlua.libxml2")

  -- Prepare the error Message
  if child == 0 then
    schemaType = "SOAP"
  else
    schemaType = "API"
  end

  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                      ffi.C.XML_PARSE_NOWARNING)

  -- Create Parser Context
  local xsd_context = libxml2ex.xmlSchemaNewMemParserCtxt(XSDSchema)
  
  -- Create XSD schema  
  local xsd_schema_doc, errMessage = libxml2ex.xmlSchemaParse(xsd_context, verbose)
  
  -- If there is no error loading the XSD schema
  if not errMessage then
    
    -- Create Validation context of XSD Schema
    local validation_context = libxml2ex.xmlSchemaNewValidCtxt(xsd_schema_doc)

    xml_doc, errMessage = libxml2ex.xmlReadMemory(XMLtoValidate, nil, nil, default_parse_options, verbose)
    
    -- If there is an error on 'xmlReadMemory' call
    if errMessage then
      -- The Error processing is done at the End of the function, so we do nothing...

    -- if we have to find the 1st Child of API which is this example <Add ... /"> (and not the <soap> root)
    elseif child ~=0 then
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

      currentNode  = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
       -- Retrieve '<soap:Body>' Node in the XML
      while currentNode ~= ffi.NULL and not bodyNodeFound do
        if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE then
          kong.log.debug ("currentNode.name: " .. ffi.string(currentNode.name))
          nodeName = ffi.string(currentNode.name)
          if nodeName == "Body" then
            bodyNodeFound = true
            break
          end
        end
        if not bodyNodeFound then
          currentNode = ffi.cast("xmlNode *", currentNode.next)
        end
      end
      -- If we don't find <wsdl:types>
      if not bodyNodeFound then
        errMessage = "Unable to find the 'soap:Body'"
        kong.log.err (errMessage)
        return errMessage
      end

      -- Get WebService Child Element, which is, for instance, <Add xmlns="http://tempuri.org/">
      local xmlNodePtrChildWS = libxml2.xmlFirstElementChild(currentNode)

      -- Dump in a String the WebService part
      kong.log.debug ("XSD validation ".. schemaType .." part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrChildWS, 1, 1))

      -- Check validity of One element with its XSD schema
      is_valid, errMessage = libxml2ex.xmlSchemaValidateOneElement (validation_context, xmlNodePtrChildWS, verbose)
    else
      -- Get Root Element, which is <soap:Envelope>
      local xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xml_doc);
      kong.log.debug ("XSD validation ".. schemaType .." part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrRoot, 1, 1))
      
      -- Check validity of XML with its XSD schema
      is_valid, errMessage = libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc, verbose)
      kong.log.debug ("is_valid: " .. is_valid)
    end
  end
  
  if not errMessage and is_valid == 0 then
    kong.log.debug ("XSD validation of ".. schemaType .." schema: Ok")
  elseif errMessage then
    kong.log.debug ("XSD validation of "..  schemaType .." schema: Ko, " .. errMessage)
  else
    errMessage = "Ko"
    kong.log.debug ("XSD validation of ".. schemaType .." schema: " .. errMessage)
  end

  if errMessage then
    kong.log.debug ("XSD validation, errMessage: " .. errMessage)
  end

  return errMessage
end

---------------------------------------------
-- Search a XPath and Compares it to a value
---------------------------------------------
function xmlgeneral.RouteByXPath (kong, XMLtoSearch, XPath, XPathCondition, XPathRegisterNs)
  local rcXpath     = false
  
  kong.log.debug("RouteByXPath, XMLtoSearch: " .. XMLtoSearch)

  local context = libxml2.xmlNewParserCtxt()
  local document = libxml2.xmlCtxtReadMemory(context, XMLtoSearch)
  
  if not document then
    kong.log.err ("RouteByXPath, xmlCtxtReadMemory error, no document")
  end
  
  local context = libxml2.xmlXPathNewContext(document)
  
  -- Register NameSpace(s)
  kong.log.debug("XPathRegisterNs length: " .. #XPathRegisterNs)
  
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
      kong.log.debug("RouteByXPath, successful registering NameSpace for '" .. XPathRegisterNs[i] .. "'")
    else
      kong.log.err("RouteByXPath, failure registering NameSpace for '" .. XPathRegisterNs[i] .. "'")
    end
  end

  local object = libxml2.xmlXPathEvalExpression(XPath, context)
  if object ~= ffi.NULL then
    
    -- If we found the XPath element
    if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then        
        local nodeContent = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
        kong.log.debug("libxml2.xmlNodeGetContent: " .. nodeContent)
        if nodeContent == XPathCondition then
          rcXpath = true
        end
    else
      kong.log.debug ("RouteByXPath, object.nodesetval is null")  
    end
  else
    kong.log.debug ("RouteByXPath, object is null")
  end
  local msg = "with XPath=\"" .. XPath .. "\" and XPathCondition=\"" .. XPathCondition .. "\""
  
  if rcXpath then
    kong.log.debug ("RouteByXPath: Ok " .. msg)
  else
    kong.log.debug ("RouteByXPath: Ko " .. msg)
  end
  return rcXpath
end

return xmlgeneral