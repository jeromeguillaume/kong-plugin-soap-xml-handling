local xmlgeneral = {}

local ffi               = require("ffi")
local libxml2           = require("xmlua.libxml2")
local libxml2ex         = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
local libxslt           = require("kong.plugins.soap-xml-handling-lib.libxslt")
local libsaxon4kong     = require("kong.plugins.soap-xml-handling-lib.libsaxon4kong")

local loaded, xml2 = pcall(ffi.load, "xml2")
local loaded, xslt = pcall(ffi.load, "xslt")

xmlgeneral.HTTPCodeSOAPFault = 500

xmlgeneral.RequestTextError   = "Request"
xmlgeneral.ResponseTextError  = "Response"
xmlgeneral.GeneralError       = "General process failed"
xmlgeneral.SepTextError       = " - "
xmlgeneral.XSLTError          = "XSLT transformation failed"
xmlgeneral.XSDError           = "XSD validation failed"
xmlgeneral.BeforeXSD          = " (before XSD validation)"
xmlgeneral.AfterXSD           = " (after XSD validation)"
xmlgeneral.xmlnsXsdHref       = "http://www.w3.org/2001/XMLSchema"
xmlgeneral.xsdSchema          = "schema"
xmlgeneral.XMLContentType     = "text/xml; charset=utf-8"
xmlgeneral.JSONContentType    = "application/json"
xmlgeneral.XMLContentTypeBody     = 1
xmlgeneral.JSONContentTypeBody    = 2
xmlgeneral.unknownContentTypeBody = 3

xmlgeneral.timerXmlSoapSleep      = 0.250  -- it's the sleep (in second) of the timer to download XSD content
xmlgeneral.prefetchStatusOk       = "Ok"
xmlgeneral.prefetchStatusRunning  = "Running"
xmlgeneral.prefetchStatusKo       = "Ko"

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
function xmlgeneral.formatSoapFault(VerboseResponse, ErrMsg, ErrEx, contentTypeJSON)
  local soapErrMsg
  local detailErrMsg
  
  detailErrMsg = ErrEx

  -- if the last character is '\n' => we remove it
  if detailErrMsg:sub(-1) == '\n' then
    detailErrMsg = string.sub(detailErrMsg, 1, -2)
  end

  -- Add the Http status code of the SOAP/XML Web Service only during 'Response' phases (response, header_filter, body_filter)
  local ngx_get_phase = ngx.get_phase
  if  ngx_get_phase() == "response"      or 
      ngx_get_phase() == "header_filter" or 
      ngx_get_phase() == "body_filter"   then
    local status = kong.service.response.get_status()
    if status ~= nil then
      -- if the last character is not '.' => we add it
      if detailErrMsg:sub(-1) ~= '.' then
        detailErrMsg = detailErrMsg .. '.'
      end
      local additionalErrMsg = "SOAP/XML Web Service - HTTP code: " .. tostring(status)      
      detailErrMsg = detailErrMsg .. " " .. additionalErrMsg
    end
  end
  
  -- If it's a SOAP/XML Request then the Fault Message is SOAP/XML text
  if contentTypeJSON == false then
    kong.log.err ("<faultstring>" .. ErrMsg .. "</faultstring><detail>".. detailErrMsg .. "</detail>")
    if VerboseResponse then
      detailErrMsg = "\n      <detail>" .. detailErrMsg .. "</detail>"
    else
      detailErrMsg = ''
    end
    soapErrMsg = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\
<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\
  <soap:Body>\
    <soap:Fault>\
      <faultcode>soap:Client</faultcode>\
      <faultstring>" .. ErrMsg .. "</faultstring>" .. detailErrMsg .. "\
    </soap:Fault>\
  </soap:Body>\
</soap:Envelope>\
"
  -- Else the Fault Message is a JSON text
  else
    -- Replace " by '
    detailErrMsg = string.gsub(detailErrMsg, "\"", "'")
    kong.log.err ("message: '" .. ErrMsg .. "' message_verbose: '".. detailErrMsg .. "'")
    soapErrMsg = "{\n    \"message\": \"" .. ErrMsg .. "\""
    if VerboseResponse then
      soapErrMsg = soapErrMsg .. ",\n    \"message_verbose\": \"" .. detailErrMsg .. "\""
    else
      soapErrMsg = soapErrMsg .. "\n"
    end
    soapErrMsg = soapErrMsg .. "\n}"
  end

  return soapErrMsg
end

-----------------------------------------------------
-- Add the HTTP Error code to the SOAP Fault message
-----------------------------------------------------
function xmlgeneral.addHttpErorCodeToSoapFault(VerboseResponse, contentTypeJSON)
  local soapFaultBody
  
  local msg = HTTP_ERROR_MESSAGES[kong.response.get_status()]
  if not msg then
    msg = "Error"
  end
  soapFaultBody = xmlgeneral.formatSoapFault(VerboseResponse, msg, "HTTP Error code is " .. tostring(kong.response.get_status()), contentTypeJSON)
  
  return soapFaultBody
end

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function xmlgeneral.returnSoapFault(plugin_conf, HTTPcode, soapErrMsg, contentTypeJSON) 
  local contentType
  if contentTypeJSON == false then
    contentType = xmlgeneral.XMLContentType
  else
    contentType = xmlgeneral.JSONContentType
  end
  -- Send a Fault code to client
  return kong.response.exit(HTTPcode, soapErrMsg, {["Content-Type"] = contentType})
end

--------------------------------------------------------------------------------------
-- Initialize the ContentTypeJSON table for keeping the 'Content-Type' of the Request
--------------------------------------------------------------------------------------
function xmlgeneral.initializeContentTypeJSON ()
  -- If the 'kong.ctx.shared.contentTypeJSON' is not already created (by the Request plugin)
  if not kong.ctx.shared.contentTypeJSON then
    kong.ctx.shared.contentTypeJSON = {}
    -- Get the 'Content-Type' to define the type of a potential Error message (sent by the plugin): SOAP/XML or JSON
    local contentType = kong.request.get_header("Content-Type")
    kong.ctx.shared.contentTypeJSON.request = xmlgeneral.compareToJSONType(contentType)
  end
end

----------------------------------------------------------------
-- Return true if the contentType is JSON type, false otherwise
----------------------------------------------------------------
function xmlgeneral.compareToJSONType (contentType)
  return contentType == 'application/json' or contentType == 'application/vnd.api+json'
end

---------------------------------------------------------------------------------------------
-- Get the Content-Type of the body by getting the first character:
--    <      =>  XML 
--    { or [ =>  JSON
-- It's used when an XSLT transformation is done:
--    XML transformed to JSON or 
--    JSON transformed to XML
---------------------------------------------------------------------------------------------
function xmlgeneral.getBodyContentType(plugin_conf, body)
  local rc = xmlgeneral.unknownContentTypeBody  
  
  if body then
    -- check if the 1st character is a '<', which stands for a SOAP/XML body Content Type
    -- we ignore space (\s) and tabulation (\t) characters
    local i, _ = string.find(body, "^%s*<")
    if i == 1 then
      rc = xmlgeneral.XMLContentTypeBody
    else
      -- check if the 1st character is a '{' or '[', which stands for a JSON body Content Type
      i, _ = string.find(body, "^%s*[{%[]")
      if i == 1 then
        rc = xmlgeneral.JSONContentTypeBody
      end
    end
  end
kong.log.notice("** jerome: getBodyContentType | rc: " .. rc)  
  return rc
end

-------------------------------------------------------------------
-- Initialize the Contextual Data related to the External Entities
-------------------------------------------------------------------
function xmlgeneral.initializeContextualDataExternalEntities (plugin_conf)
  if kong.ctx.shared.xmlSoapExternalEntity == nil then
    kong.ctx.shared.xmlSoapExternalEntity = {}
  end
  kong.ctx.shared.xmlSoapExternalEntity.async               = plugin_conf.ExternalEntityLoader_Async
  kong.ctx.shared.xmlSoapExternalEntity.cacheTTL            = plugin_conf.ExternalEntityLoader_CacheTTL
  kong.ctx.shared.xmlSoapExternalEntity.timeout             = plugin_conf.ExternalEntityLoader_Timeout
  kong.ctx.shared.xmlSoapExternalEntity.xsdApiSchemaInclude = plugin_conf.xsdApiSchemaInclude
  
  if not kong.ctx.shared.xmlSoapExternalEntity.cacheTTL then
    kong.ctx.shared.xmlSoapExternalEntity.cacheTTL = 1
  end
  if not kong.ctx.shared.xmlSoapExternalEntity.timeout then
    kong.ctx.shared.xmlSoapExternalEntity.timeout = 3600
  end
end

-------------------------------------------------------------------------------
-- Initialize the SOAP/XML plugin
-- Setup a 'libxml2' Error handler
-- Setup a 'libxslt' Error handler
-- Setup the SOAP/XML Timer context in charge of downloading the XSD in the background
-- Setup an External Entity Loader
-------------------------------------------------------------------------------
function xmlgeneral.initializeXmlSoapPlugin ()
  -- We initialize the Error Handlers only one time for the Nginx process and for the Plugin
  -- The error message will be set contextually to the Request by using the 'kong.ctx'
  -- Conversely if we initialize the Error Handler on each Request (like 'access' phase)
  -- the 'libxml2' library complains with an error message: 'too many calls' (after ~100 calls)
  -- LIBXML Error Handler
  if not kong.xmlSoapLibxmlErrorHandler then
    kong.log.debug ("initializeXmlSoapPlugin: it's the 1st time the function is called => initialize the 'libxml2' Error Handler")
    kong.xmlSoapLibxmlErrorHandler = ffi.cast("xmlStructuredErrorFunc", function(userdata, xmlError)
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
    kong.log.debug ("initializeXmlSoapPlugin: 'libxml2' Error Handler is already initialized => nothing to do")
  end

  -- LIBXSLT Error Handler
  if not kong.xmlSoapLibxsltErrorHandler then
    kong.log.debug ("initializeXmlSoapPlugin: it's the 1st time the function is called => initialize the 'libxslt' Error Handler")
    -- LuaJit's FFI cannot manage a variable number of arguments of C function and
    -- there is up to 6 variables in the callback function(ctx, msg, type, file, line, name)
    -- Only 'ctx', 'msg', 'type' are set on each call; so we remove the others ('file', 'line', 'name')
    -- See: https://android.googlesource.com/platform/external/libxslt/+/7d1dabff1598661db0018d89d16cca02f7c31ae2/libxslt/xsltutils.c#650
    --      https://luajit.org/ext_ffi_semantics.html#callback
    xslt.xsltSetGenericErrorFunc (nil, function(ctx, msg, type)
      -- The callback function can be called two times in a row
      if kong.ctx.shared.xmlSoapErrMessage == nil then
        kong.ctx.shared.xmlSoapErrMessage = ffi.string(type)
      else
        kong.ctx.shared.xmlSoapErrMessage = kong.ctx.shared.xmlSoapErrMessage .. '. ' .. ffi.string(type)
      end
    end)
    kong.xmlSoapLibxsltErrorHandler = true
  else
    kong.log.debug ("initializeXmlSoapPlugin: 'libxslt' Error Handler is already initialized => nothing to do")
  end
  
  -- Initialize the SOAP/XML context in charge of downloading Asynchronously the XSD content
  if not kong.xmlSoapTimer then
    kong.xmlSoapTimer = {entityLoader = {hashKeys = {}, urls = {} } }
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

----------------------------
-- libsaxon: Initialization
----------------------------
function xmlgeneral.initializeSaxon()
  local errMessage

  if not kong.xmlSoapSaxon then
    kong.log.debug ("initializeSaxon: it's the 1st time the function is called => initialize the 'saxon' library")
    kong.xmlSoapSaxon = {}
    kong.xmlSoapSaxon.saxonProcessor    = ffi.NULL
    kong.xmlSoapSaxon.xslt30Processor   = ffi.NULL
    
    -- Load the Saxon for kong Shared Object
    kong.log.debug ("initializeSaxon: loadSaxonforKongLibrary")
    errMessage = libsaxon4kong.loadSaxonforKongLibrary ()

    if not errMessage then
      -- Create Saxon Processor
      kong.log.debug ("initializeSaxon: createSaxonProcessorKong")
      kong.xmlSoapSaxon.saxonProcessor, errMessage = libsaxon4kong.createSaxonProcessorKong ()
      
      if not errMessage then
        -- Create XSLT 3.0 processor
        kong.log.debug ("initializeSaxon: createXslt30ProcessorKong")
        kong.xmlSoapSaxon.xslt30Processor, errMessage = libsaxon4kong.createXslt30ProcessorKong (kong.xmlSoapSaxon.saxonProcessor)
        if not errMessage then
          kong.log.debug ("initializeSaxon: the 'saxon' library is successfully initialized")
        end
      end

      if errMessage then
        kong.log.err ("initializeSaxon: errMessage: " .. errMessage)
      end

    else
      kong.log.debug ("initializeSaxon: errMessage: " .. errMessage)
    end
  else
    kong.log.debug ("initializeSaxon: 'saxon' is already initialized => nothing to do")
  end
end

---------------------------------------------------
-- libsaxon: Transform XML with XSLT Transformation
---------------------------------------------------
function xmlgeneral.XSLTransform_libsaxon(plugin_conf, XMLtoTransform, XSLT, verbose)
  local errMessage
  local xml_transformed_dump
  local context
  
  kong.log.debug ("XSLT transformation, BEGIN: " .. XMLtoTransform)

  -- Check if Saxon for Kong library is correctly loaded
  errMessage = libsaxon4kong.isSaxonforKongLoaded()
  
  if not errMessage then
    -- Compile the XSLT document
    context, errMessage = libsaxon4kong.compileStylesheet (kong.xmlSoapSaxon.saxonProcessor, 
                                                          kong.xmlSoapSaxon.xslt30Processor, 
                                                          XSLT)
  end

  if not errMessage then
    -- If the XSLT Transformation is configured with a Template (example: <xsl:template name="main">)
    if plugin_conf.xsltSaxonTemplate and plugin_conf.xsltSaxonTemplateParam then
      -- Transform the XML doc with XSLT transformation by invoking a template
      xml_transformed_dump, errMessage = libsaxon4kong.stylesheetInvokeTemplate ( 
                                            kong.xmlSoapSaxon.saxonProcessor,
                                            context,
                                            plugin_conf.xsltSaxonTemplate, 
                                            plugin_conf.xsltSaxonTemplateParam,
                                            XMLtoTransform
                                          )
    else
      -- Transform the XML doc with XSLT transformation
      xml_transformed_dump, errMessage = libsaxon4kong.stylesheetTransformXml ( 
                                            kong.xmlSoapSaxon.saxonProcessor,
                                            context,
                                            XMLtoTransform
                                          )
    end
  end
  
  -- Free memory
  if context then
    -- Delete the Saxon Context and the compiled XSLT
    libsaxon4kong.deleteContext(context)
  end

  if errMessage == nil then
    kong.log.debug ("XSLT transformation, END: " .. xml_transformed_dump)
  else
    kong.log.debug ("XSLT transformation, END with error: " .. errMessage)
  end
  
  return xml_transformed_dump, errMessage
end

---------------------------------------------------
-- libxslt: Transform XML with XSLT Transformation
---------------------------------------------------
function xmlgeneral.XSLTransform_libxlt(plugin_conf, XMLtoTransform, XSLT, verbose)
  local errMessage  = nil
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
    style, errMessage = libxslt.xsltParseStylesheetDoc (xslt_doc)
    
    if style == ffi.NULL then
      errMessage = "error calling 'xsltParseStylesheetDoc'"
    elseif errMessage == nil then
      -- Load the complete XML document (with <soap:Envelope>)
      xml_doc, errMessage = libxml2ex.xmlReadMemory(XMLtoTransform, nil, nil, default_parse_options, verbose)
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
    kong.log.debug ("XSLT transformation, END with error: " .. errMessage)
  end

  -- xmlCleanupParser()
  
  return xml_transformed_dump, errMessage
  
end

---------------------------------------------------
-- Transform XML with XSLT Transformation
---------------------------------------------------
function xmlgeneral.XSLTransform(plugin_conf, XMLtoTransform, XSLT, verbose)
  local errMessage
  local xml_transformed_dump
  
  if plugin_conf.xsltLibrary == 'libxslt' then
    xml_transformed_dump, errMessage = xmlgeneral.XSLTransform_libxlt(plugin_conf, XMLtoTransform, XSLT, verbose)
  elseif plugin_conf.xsltLibrary == 'saxon' then
    -- If XMLtoTransform is a JSON type we add a faked <InternalkongRoot> tag to be ingested as an XML
    if xmlgeneral.getBodyContentType(plugin_conf, XMLtoTransform) == xmlgeneral.JSONContentTypeBody then
      XMLtoTransform = "<InternalkongRoot>" .. XMLtoTransform .. "</InternalkongRoot>"
    end
    xml_transformed_dump, errMessage = xmlgeneral.XSLTransform_libsaxon(plugin_conf, XMLtoTransform, XSLT, verbose)
  else
    kong.log.err("XSLTransform: unknown library " .. plugin_conf.xsltLibrary)
  end
  return xml_transformed_dump, errMessage
end

----------------------------------------------------------------------------------------------------
-- Prefetch External Entities (i.e. Download Asynchronously XSD content) specified in WSDL
-- Executed one time during 1st call for each 'xsdApiSchema' plugin configuration
-- When the plugin configuration ('xsdApiSchema') has changed the prefetch is executed another time
----------------------------------------------------------------------------------------------------
function xmlgeneral.prefetchExternalEntities (plugin_conf, child, WSDL, verbose)
  local errMessage
  local i   = 1
  local nowTime = ngx.now()

  -- If Asynchronous is not enabled OR
  -- If there is no XSD we don't do a Prefetch
  if not plugin_conf.ExternalEntityLoader_Async or not plugin_conf.xsdApiSchema then
    return
  end

  local xsdHashKey = libxml2ex.hash_key(plugin_conf.xsdApiSchema)
  -- If it's the 1st time we call the Prefetch
  if kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey] == nil then
    kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey] = {
      prefetchStus = xmlgeneral.prefetchStatusRunning
    }
    kong.log.debug("prefetchExternalEntities - First execution")
  -- Else if the Prefetch has been already called: we don't call it anymore
  elseif kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey].prefetchStus ~= xmlgeneral.prefetchStatusRunning then
    kong.log.debug("prefetchExternalEntities - Prefetch was already executed, prefetchSatus: " .. kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey].prefetchStus)
    return  
  end

  -- Loop during a maximum of 'timeout' second to retrieve the complete list of the URL of XSD
  while (nowTime + kong.ctx.shared.xmlSoapExternalEntity.timeout) > ngx.now() do
    -- Prefetch External Entities: just retrieve the URL of XSD External entities (not the XSD content)
    -- The 'asyncDownloadEntities' function is in charge of downloading the XSD content
    errMessage = xmlgeneral.XMLValidateWithWSDL (plugin_conf, child, nil, WSDL, verbose, true)
    
    -- If the prefetch succeeded we stop it
    if not errMessage then
      kong.log.debug("prefetchExternalEntities: #" .. i .. " **Success**")
      kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey].prefetchStus = xmlgeneral.prefetchStatusOk
      break
    else
      kong.log.debug("prefetchExternalEntities: #" .. i .. " err: " .. errMessage)
      local j, _ = string.find(errMessage, "failed.to.load.external.entity")
      local k, _ = string.find(errMessage, "Failed.to.parse.the.XML.resource")
      -- If there is an error not related to a failure to 'load external entity' (for instance: a WSDL/XSD syntax eror)
      --    => Stop the loop
      -- Else continue the loop
      if j == nil and k == nil then
        break
      end
    end
    i = i + 1
    -- Do a sleep and expect that, meanwhile, the 'timerXmlSoap' function downloads the XSD content
    ngx.sleep (xmlgeneral.timerXmlSoapSleep / 2)
    
  end
  -- If the Prefetch status is still 'Running' it means that the Prefetch failed. 
  -- So we set a Ko status and next time it won't be executed (the Prefetch is executed 1 time)
  if kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey].prefetchStus == xmlgeneral.prefetchStatusRunning then
    kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey].prefetchStus = xmlgeneral.prefetchStatusKo
  end
  kong.log.debug("prefetchExternalEntities - Last status: " .. kong.xmlSoapTimer.entityLoader.hashKeys[xsdHashKey].prefetchStus)
end


--------------------------
-- Dump a document to XML
--------------------------
function xmlgeneral.to_xml(document)
  local buffer = libxml2.xmlBufferCreate()
  local context = libxml2.xmlSaveToBuffer(buffer,
                                          "UTF-8",
                                          bit.bor(ffi.C.XML_SAVE_FORMAT,
                                                  ffi.C.XML_SAVE_NO_DECL,
                                                  ffi.C.XML_SAVE_AS_XML))
  libxml2.xmlSaveDoc(context, document)
  libxml2.xmlSaveClose(context)
  return libxml2.xmlBufferGetContent(buffer)
end

------------------------------------------------------------------------
-- Add Global NameSpaces (defined at <wsdl:definition>) to <xsd:schema>
------------------------------------------------------------------------
function xmlgeneral.addNamespaces(xsdSchema, document, node)

  local xsdSchemaTag
  local xmlNsXsdPrefix
  local raw_namespaces
  local beginSchema
  local endSchema

  -- Retrieve the Schema NameSpace prefix of 'xmlns:prefix' regarding hRef: 'http://www.w3.org/2001/XMLSchema'
  -- Example of prefix: xsd (xmlns:xsd), xs (xmlns:xs), myxsd (xmlns:myxsd), etc.
  local xmlNsPtr = libxml2.xmlSearchNsByHref(document, node, xmlgeneral.xmlnsXsdHref)
  if xmlNsPtr ~= ffi.NULL then
    xmlNsXsdPrefix = ffi.string(xmlNsPtr.prefix)
  end
  
  -- Get the List of all NameSpaces
  raw_namespaces = libxml2.xmlGetNsList(document, node)

  -- Search the begin and end of '<xsd:schema'
  if xmlNsXsdPrefix then
    xsdSchemaTag = "<" .. xmlNsXsdPrefix .. ":" .. xmlgeneral.xsdSchema
    beginSchema = xsdSchema:find (xsdSchemaTag, 1)
    endSchema   = xsdSchema:find (">", 2)
  end

  if not xmlNsXsdPrefix or not raw_namespaces or not beginSchema or not endSchema then
    kong.log.err("WSDL validation - Unable to add Namespaces from <wsdl:definition>")
    return xsdSchema
  end

  local xsdSchemaTmp = xsdSchema:sub(beginSchema, endSchema)

  local i = 0
  local xmlns = ''
  -- Add each Namespace definition defined at <wsdl> level in <xsd:schema>
  while raw_namespaces[i] ~= ffi.NULL do
    if not xsdSchemaTmp:find("xmlns:" .. ffi.string(raw_namespaces[i].prefix) .. "=\"") then
      xmlns = "xmlns:" .. ffi.string(raw_namespaces[i].prefix) .. "=\"" .. ffi.string(raw_namespaces[i].href) .. "\" " .. xmlns
    end
    i = i + 1
  end
  
  if #xmlns > 1 then
    xsdSchema = xsdSchemaTag .. " " .. xmlns .. xsdSchema:sub(beginSchema + #xsdSchemaTag, -1)
  end
  
  return xsdSchema
end


------------------------------
-- Validate a XML with a WSDL
------------------------------
function xmlgeneral.XMLValidateWithWSDL (plugin_conf, child, XMLtoValidate, WSDL, verbose, prefetch)
  local xml_doc          = nil
  local errMessage       = nil
  local firstErrMessage  = nil
  local xsdSchema        = nil
  local currentNode      = nil
  local xmlNsXsdPrefix   = nil
  local wsdlNodeFound    = false
  local typesNodeFound   = false
  local validSchemaFound = false
  local nodeName         = ""
  local index            = 0
  
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
    errMessage = "WSDL validation - errMessage " .. errMessage
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
      kong.log.debug (errMessage)
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
  -- Retrieve all '<xs:schema>' Nodes until 
  --   We found a valid Schema validating the XML 
  --     OR
  --   If prefetch is enabled
  while currentNode ~= ffi.NULL and (not validSchemaFound or prefetch) do
    
    if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE then
      -- Get the node Name
      nodeName = ffi.string(currentNode.name)
      if nodeName == "schema" then
        index = index + 1
        xsdSchema = libxml2ex.xmlNodeDump	(xml_doc, currentNode, 1, 1)
        kong.log.debug ("schema #" .. index .. ", length: " .. #xsdSchema .. ", dump: " .. xsdSchema)
        
        -- Add Global NameSpaces (defined at <wsdl:definition>) to <xsd:schema>
        xsdSchema = xmlgeneral.addNamespaces(xsdSchema, xml_doc, currentNode)

        errMessage = nil
        -- Validate the XML with the <xs:schema>'
        errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, xsdSchema, verbose, prefetch)
        
        local msgDebug = errMessage or "Ok"
        kong.log.debug ("Validation for schema #" .. index .. " Message: '" .. msgDebug .. "'")
        
        -- If prefetch is enabled
        if prefetch then
          -- If there is an error, Keep only the 1st Error message and 
          -- avoid, for instance, that the correct validation of schema#2 overwrites the error of schema#1
          if errMessage and not firstErrMessage then
            firstErrMessage = errMessage
          end
          -- Go on next schema
          kong.log.debug ("Prefetch is enabled: go on next XSD Schema")
          
        -- If there is no error it means that we found the right Schema validating the SOAP/XML
        elseif not errMessage then
          kong.log.debug ("Found the right XSD Schema validating the SOAP/XML")
          validSchemaFound = true
          errMessage = nil
          break
        end
      end
    end
    -- Go to the next '<xs:schema' Node
    currentNode = ffi.cast("xmlNode *", currentNode.next)
  end

  -- If prefetch is enabled 
  if prefetch then
    -- Get the 1st Error message
    errMessage = firstErrMessage
  -- Else If there is no Error and we don't retrieve a valid Schema for the XML
  elseif not errMessage and not validSchemaFound then
    errMessage = "Unable to find a suitable Schema to validate the SOAP/XML"
  end

  return errMessage
end

--------------------------------------
-- Validate a XML with its XSD schema
--------------------------------------
function xmlgeneral.XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, XSDSchema, verbose, prefech)
  local xml_doc       = nil
  local errMessage    = nil
  local err           = nil
  local is_valid      = 0
  local schemaType    = ""
  local bodyNodeFound = nil
  local currentNode   = nil
  local nodeName      = ""
  local libxml2       = require("xmlua.libxml2")

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
  -- If it's a Prefetch we just have to parse the XSD which downloads XSD in cascade 
  if prefech then
    return errMessage
  end

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
          kong.log.debug ("XSD validation - CurrentNode.name: " .. ffi.string(currentNode.name))
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
        errMessage = "XSD validation - Unable to find the 'soap:Body'"
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
      kong.log.debug ("XSD validation - is_valid: " .. is_valid)
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
    kong.log.debug ("RouteByXPath, xmlCtxtReadMemory error, no document")
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