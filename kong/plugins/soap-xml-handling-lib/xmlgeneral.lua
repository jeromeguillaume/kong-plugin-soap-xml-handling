local xmlgeneral = {}

local ffi               = require("ffi")
local libxml2           = require("xmlua.libxml2")
local libxml2ex         = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
local libxslt           = require("kong.plugins.soap-xml-handling-lib.libxslt")
local libsaxon4kong     = require("kong.plugins.soap-xml-handling-lib.libsaxon4kong")

local loaded, xml2 = pcall(ffi.load, "xml2")
local loaded, xslt = pcall(ffi.load, "xslt")

xmlgeneral.HTTPClientCodeSOAPFault  = 400
xmlgeneral.HTTPServerCodeSOAPFault  = 500

xmlgeneral.RequestTypePlugin  = 1
xmlgeneral.ResponseTypePlugin = 2

xmlgeneral.RequestTextError   = "Request"
xmlgeneral.ResponseTextError  = "Response"
xmlgeneral.GeneralError       = "General process failed"
xmlgeneral.GenericError       = "SOAP/XML process failure"
xmlgeneral.SepTextError       = " - "
xmlgeneral.XSLTError          = "XSLT transformation failed"
xmlgeneral.XSDError           = "XSD validation failed"
xmlgeneral.BeforeXSD          = " (before XSD validation)"
xmlgeneral.AfterXSD           = " (after XSD validation)"
xmlgeneral.invalidXML         = "Invalid XML input"
xmlgeneral.invalidXSLT        = "Invalid XSLT definition"
xmlgeneral.invalidXSD         = "Invalid XSD schema"
xmlgeneral.invalidWSDL_XSD    = "Invalid WSDL/XSD schema"

xmlgeneral.soapFaultCodeNone    = 0   -- Fault Code type is 'None'
xmlgeneral.soapFaultCodeServer  = 1   -- Fault Code type is 'Server' (The Kong GW and Upstream)
xmlgeneral.soapFaultCodeClient  = 2   -- Fault Code type is 'Client' (The Consumer)

xmlgeneral.schemaWSDL1_1              = "http://schemas.xmlsoap.org/wsdl/"
xmlgeneral.schemaWSDL2_0              = "http://www.w3.org/ns/wsdl"
xmlgeneral.schemaHttpTransport        = "http://schemas.xmlsoap.org/soap/http"
xmlgeneral.schemaSOAP1_1              = "http://schemas.xmlsoap.org/soap/envelope/"
xmlgeneral.schemaSOAP1_2              = "http://www.w3.org/2003/05/soap-envelope"
xmlgeneral.schemaWSDL1_1_SOAP1_1      = "http://schemas.xmlsoap.org/wsdl/soap/"
xmlgeneral.schemaWSDL1_1_SOAP1_2      = "http://schemas.xmlsoap.org/wsdl/soap12/"

xmlgeneral.schemaWSDL_WSAM_in_out     = "http://www.w3.org/ns/wsdl/in-out"      -- Web Services Addressing 1.0 - Metadata
xmlgeneral.schemaWSDL_WSAM_in_out_opt = "http://www.w3.org/ns/wsdl/in-opt-out"  -- Web Services Addressing 1.0 - Metadata

xmlgeneral.schemaWSAM                 = "http://www.w3.org/2007/05/addressing/metadata"
xmlgeneral.xmlnsXsdHref               = "http://www.w3.org/2001/XMLSchema"
xmlgeneral.xsdSchema                  = "schema"
xmlgeneral.schemaTypeSOAP             = 1
xmlgeneral.schemaTypeAPI              = 2
xmlgeneral.xsltBeforeXSD              = 3
xmlgeneral.xsltAfterXSD               = 4
xmlgeneral.SOAP1_1ContentType         = "text/xml; charset=utf-8"
xmlgeneral.SOAP1_2ContentType         = "application/soap+xml; charset=utf-8"
xmlgeneral.JSONContentType            = "application/json"
xmlgeneral.Unknown_WSDL               = 0             -- Unknown WSDL
xmlgeneral.WSDL1_1                    = 11            -- WSDL 1.1
xmlgeneral.WSDL2_0                    = 20            -- WSDL 2.0
xmlgeneral.SOAP1_1                    = 11            -- SOAP 1.1
xmlgeneral.SOAP1_2                    = 12            -- SOAP 1.2
xmlgeneral.JSON                       = 30            -- JSON content type
xmlgeneral.SOAPAction                 = "SOAPAction"  -- SOAP 1.1
xmlgeneral.action                     = "action"      -- SOAP 1.2
xmlgeneral.SOAPAction_Header_No       = "no"
xmlgeneral.SOAPAction_Header_Yes_Null = "yes_null_allowed"
xmlgeneral.SOAPAction_Header_Yes      = "yes"

xmlgeneral.startInternalkongRoot      = "<InternalkongRoot>"
xmlgeneral.endInternalkongRoot        = "</InternalkongRoot>"

xmlgeneral.XMLContentTypeBody     = 1
xmlgeneral.JSONContentTypeBody    = 2
xmlgeneral.unknownContentTypeBody = 3

xmlgeneral.prefetchStatusInit     = 0
xmlgeneral.prefetchStatusOk       = 1
xmlgeneral.prefetchStatusRunning  = 2
xmlgeneral.prefetchStatusKo       = 3
xmlgeneral.prefetchQueueTimeout   = libxml2ex.externalEntityTimeout + 1  -- Queue Timeout to Asynchronously do an XSD Validation Prefetch
xmlgeneral.prefetchReqQueueName   = "-prefetch-request-schema"
xmlgeneral.prefetchResQueueName   = "-prefetch-response-schema"

xmlgeneral.libxmlNoMatchGlobalDecl  = 1845  -- libxml Error code for 'No matching global declaration available for the validation root'.
                                            -- It means that the operation Name (example: Add/Subtract/Divide, etc.)
                                            -- that is 1st child of '<soap:Body>' can't be found in the XSD

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
function xmlgeneral.formatSoapFault(VerboseResponse, ErrMsg, ErrEx, contentType, soapFaultCode)
  local soapErrMsg
  local errorMessage
  local backendHttpCode
  local soapFaultCodeStr
  
  errorMessage = ErrEx

  -- if the last character is '\n' => we remove it
  if errorMessage:sub(-1) == '\n' then
    errorMessage = string.sub(errorMessage, 1, -2)
  end

  -- Get the Http status code of the Backend Service only during 'Response' phases (response, header_filter, body_filter)
  local ngx_get_phase = ngx.get_phase
  if  ngx_get_phase() == "response"      or 
      ngx_get_phase() == "header_filter" or 
      ngx_get_phase() == "body_filter"   then
    local status = kong.service.response.get_status()
    if status ~= nil then      
      backendHttpCode = status
    end
  end
  -- Replace " by '
  errorMessage = string.gsub(errorMessage, "\"", "'")

  -- If it's a SOAP 1.1 or SOAP 1.2 request
  if contentType == xmlgeneral.SOAP1_1 or contentType == xmlgeneral.SOAP1_2 then
    -- Replace '<' and '>' symbols by a full-text representation, thus avoiding incorrect XML parsing later
    errorMessage = string.gsub(errorMessage, "<", "Less Than")
    errorMessage = string.gsub(errorMessage, ">", "Greater Than")
    kong.log.err ("<faultstring>" .. ErrMsg .. "</faultstring><detail>".. errorMessage .. "</detail>")    
  end

  -- If it's a SOAP 1.1 request, send a SOAP 1.1 fault message
  if contentType == xmlgeneral.SOAP1_1 then
    -- If verbose is enable, send all the details
    if VerboseResponse then
      errorMessage = ""..
     "<detail>\
        <errorMessage>" .. errorMessage .."</errorMessage>"
      if backendHttpCode then
        errorMessage = errorMessage .. "\
        <backendHttpCode>"..backendHttpCode.."</backendHttpCode>"
      end
      errorMessage = errorMessage .. "\
      </detail>"
    -- If verbose is not enable, put in <Detail> a Generic message (as <detail> is required by the RFC)
    else
      errorMessage = ""..
     "<detail>\
        <errorMessage>" .. xmlgeneral.GenericError .."</errorMessage>\
      </detail>"
    end
    if soapFaultCode == xmlgeneral.soapFaultCodeClient then
      soapFaultCodeStr = 'Client'
    else
      soapFaultCodeStr = 'Server'
    end
    soapErrMsg = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\
<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\
  <soap:Body>\
    <soap:Fault>\
      <faultcode>soap:" .. soapFaultCodeStr .. "</faultcode>\
      <faultstring>" .. ErrMsg .. "</faultstring>\
      " .. errorMessage .. "\
    </soap:Fault>\
  </soap:Body>\
</soap:Envelope>"

  -- If it's a SOAP 1.2 request, send a SOAP 1.2 fault message
  elseif contentType == xmlgeneral.SOAP1_2 then
    if VerboseResponse then
      errorMessage = ""..
     "<env:Detail>\
        <f:errorDetails>\
          <f:errorMessage>".. errorMessage .."</f:errorMessage>"
      if backendHttpCode then
        errorMessage = errorMessage .. "\
          <f:backendHttpCode>"..backendHttpCode.."</f:backendHttpCode>"
      end
      errorMessage = errorMessage .. "\
        </f:errorDetails>\
      </env:Detail>"
    -- If verbose is not enabled, put in <Detail> a Generic message for SOAP 1.1 "parity" (as the SOAP 1.2 RFC doesn't explicitly requires it)
    else
      errorMessage = ""..
     "<env:Detail>\
        <f:errorDetails>\
          <f:errorMessage>".. xmlgeneral.GenericError .."</f:errorMessage>\
        </f:errorDetails>\
      </env:Detail>"
    end
    if soapFaultCode == xmlgeneral.soapFaultCodeClient then
      soapFaultCodeStr = 'Sender'
    else
      soapFaultCodeStr = 'Receiver'
    end
    soapErrMsg = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\
<env:Envelope xmlns:env=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:f=\"http://www.example.org/faults\" xmlns:xml=\"http://www.w3.org/XML/1998/namespace\">\
  <env:Body>\
    <env:Fault>\
      <env:Code>\
        <env:Value>env:" ..soapFaultCodeStr.. "</env:Value>\
      </env:Code>\
      <env:Reason>\
        <env:Text xml:lang=\"en\">" ..ErrMsg.. "</env:Text>\
      </env:Reason>\
      " .. errorMessage .. "\
    </env:Fault>\
  </env:Body>\
</env:Envelope>"

  -- Else the Fault Message is a JSON text
  else
    kong.log.err ("message: '" .. ErrMsg .. "' message_verbose: '".. errorMessage .. "'")
    soapErrMsg = "{\n    \"message\": \"" .. ErrMsg .. "\""
    if VerboseResponse then
      soapErrMsg = soapErrMsg .. ",\n    \"message_verbose\": \"" .. errorMessage .. "\""
      if backendHttpCode then
        soapErrMsg = soapErrMsg .. ",\n    \"backend_http_code\": " .. tonumber(backendHttpCode) .. ""
      end
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
function xmlgeneral.addHttpErorCodeToSoapFault(VerboseResponse, contentType)
  local soapFaultBody
  local status = kong.response.get_status()
  local msg = HTTP_ERROR_MESSAGES[status]
  local soapFaultCode
  
  if not msg then
    msg = "Error"
  end
  if status < 500 then
    soapFaultCode = xmlgeneral.soapFaultCodeClient
  else
    soapFaultCode = xmlgeneral.soapFaultCodeServer
  end
  soapFaultBody = xmlgeneral.formatSoapFault(VerboseResponse, msg, "HTTP Error code is " .. status, contentType, soapFaultCode)
  
  return soapFaultBody
end

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function xmlgeneral.getContentType (contentType)
  local contentTypeRC = xmlgeneral.SOAP1_1ContentType -- Default Content-Type
  
  if contentType == xmlgeneral.SOAP1_1 then
    contentTypeRC = xmlgeneral.SOAP1_1ContentType
  elseif contentType == xmlgeneral.SOAP1_2 then
    contentTypeRC = xmlgeneral.SOAP1_2ContentType
  elseif contentType == xmlgeneral.JSON then
    contentTypeRC = xmlgeneral.JSONContentType
  end
  
  return contentTypeRC
end

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function xmlgeneral.returnSoapFault(soapFaultCode, soapErrMsg, contentType)
  local HTTPcode = xmlgeneral.HTTPServerCodeSOAPFault

  -- If it's a JSON request and the Fault comes from the Client
  if contentType == xmlgeneral.JSON and soapFaultCode == xmlgeneral.soapFaultCodeClient then
    HTTPcode = xmlgeneral.HTTPClientCodeSOAPFault
  end
  -- Send a Fault code to client
  return kong.response.exit(HTTPcode, soapErrMsg, {["Content-Type"] = xmlgeneral.getContentType(contentType)})
end

--------------------------------------------------------------------------------------
-- Initialize the ContentType table for keeping the 'Content-Type' of the Request
--------------------------------------------------------------------------------------
function xmlgeneral.initializeContentType ()
  -- If the 'kong.ctx.shared.contentType' is not already created (by the Request plugin)
  if not kong.ctx.shared.contentType then
    kong.ctx.shared.contentType = {}
    -- Get the 'Content-Type' to define the type of a potential Error message (sent by the plugin): SOAP/XML or JSON
    local contentType = kong.request.get_header("Content-Type")
    kong.ctx.shared.contentType.request = xmlgeneral.detectContentType(contentType)
  end
end

--------------------------------------------------
-- Detect content type SOAP 1.1 / SOAP 1.2 / JSON
--------------------------------------------------
function xmlgeneral.detectContentType (contentType)
  local rc = xmlgeneral.SOAP1_1
  
  -- Ignore space and tabulation characters by using: %s
  
  -- If there is no 'Content-Type' header
  if not contentType then
    -- Apply default SOAP 1.1
    rc = xmlgeneral.SOAP1_1
  -- SOAP 1.1
  elseif string.find(contentType, "^%s*text/xml")   then
    rc = xmlgeneral.SOAP1_1
  -- SOAP 1.2
  elseif string.find(contentType, "^%s*application/soap%+xml") then
    rc = xmlgeneral.SOAP1_2
  -- JSON
  elseif string.match(contentType, "^%s*application/json") or string.match(contentType, "^%s*application/vnd.api%+json") then
    rc = xmlgeneral.JSON
  end
  
  return rc
end

---------------------------------------------------------------------------------------------
-- Get the content type of the body by getting the first character:
--    <      =>  XML 
--    { or [ =>  JSON
-- It's used when an XSLT transformation is done:
--    XML  transformed to JSON or 
--    JSON transformed to XML
---------------------------------------------------------------------------------------------
function xmlgeneral.getBodyContentType(body)
  local rc = xmlgeneral.unknownContentTypeBody  
  
  if body then
    -- check if the 1st character is a '<', which stands for a SOAP/XML body Content Type
    -- we ignore space and tabulation (%s) characters
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
  return rc
end

-------------------------------------------------------------------
-- Initialize the Contextual Data related to the External Entities
-------------------------------------------------------------------
function xmlgeneral.initializeContextualDataExternalEntities (plugin_conf)
  if kong.ctx.shared.xmlSoapExternalEntity == nil then
    kong.ctx.shared.xmlSoapExternalEntity = {}
  end
  kong.ctx.shared.xmlSoapExternalEntity.async                = plugin_conf.ExternalEntityLoader_Async
  kong.ctx.shared.xmlSoapExternalEntity.cacheTTL             = plugin_conf.ExternalEntityLoader_CacheTTL
  kong.ctx.shared.xmlSoapExternalEntity.timeout              = plugin_conf.ExternalEntityLoader_Timeout
  kong.ctx.shared.xmlSoapExternalEntity.xsdApiSchemaInclude  = plugin_conf.xsdApiSchemaInclude
  kong.ctx.shared.xmlSoapExternalEntity.xsdSoapSchemaInclude = plugin_conf.xsdSoapSchemaInclude
  
  if not kong.ctx.shared.xmlSoapExternalEntity.cacheTTL then
    kong.ctx.shared.xmlSoapExternalEntity.cacheTTL = libxml2ex.externalEntityCacheTTL
  end
  if not kong.ctx.shared.xmlSoapExternalEntity.timeout then
    kong.ctx.shared.xmlSoapExternalEntity.timeout = libxml2ex.externalEntityTimeout
  end
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
    
    -- Load the 'Saxon for kong' Shared Object
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
      kong.log.err ("initializeSaxon: errMessage: " .. errMessage)
    end
  else
    kong.log.debug ("initializeSaxon: 'saxon' is already initialized => nothing to do")
  end
end

-----------------------------------------------------------------------------------------------
-- Callback function called by 'kong.tools.queue' to Asynchronously Prefetch Schema Validation
-----------------------------------------------------------------------------------------------
local asyncPrefetch_Schema_Validation_callback = function(conf, prefetchConf_entries)
  local errMessage
  local soapFaultCode
  local child
  local WSDL
  local verbose
  local xsdHashKey
  local rc = true  
  kong.log.debug("asyncPrefetch_Schema_Validation_callback - Begin - PluginType:"..conf.typePlugin)
    
  local count = 0  

  -- Loop over all WSDL/XSDs
  for k, prefetchConf_entry in pairs (prefetchConf_entries) do
    
    count = count + 1
    kong.log.debug("asyncPrefetch_Schema_Validation_callback : #prefetch: " .. count .. "/" .. #prefetchConf_entries)
    xsdHashKey = kong.xmlSoapAsync.entityLoader.hashKeys[prefetchConf_entry.xsdHashKey]
    
    -- If the XSD 'hashKey' is found in the 'entityLoader.hashKeys'
    if xsdHashKey then
      WSDL       = prefetchConf_entry.xsdSchemaInclude
      verbose    = prefetchConf_entry.VerboseRequest
      child      = prefetchConf_entry.child

      -- If the prefetch has been successfully done 
      if  xsdHashKey.prefetchStatus == xmlgeneral.prefetchStatusOk then
        kong.log.debug("asyncPrefetch_Schema_Validation_callback - prefetchStatus='Ok' - Nothing to do")
        -- Go on the next Entry
        goto continue
      elseif xsdHashKey.prefetchStatus == xmlgeneral.prefetchStatusInit then
        kong.log.debug("asyncPrefetch_Schema_Validation_callback - First execution")
      end
      xsdHashKey.prefetchStatus = xmlgeneral.prefetchStatusRunning

      -- Prefetch External Entities: just retrieve the URL of XSD External entities (not the XSD content)
      -- The 'asyncDownloadEntities' function is in charge of downloading the XSD content
      errMessage, soapFaultCode = xmlgeneral.XMLValidateWithWSDL (conf.typePlugin, nil, child, nil, WSDL, verbose, true, true)

      -- If the prefetch succeeded
      if not errMessage then
        xsdHashKey.prefetchStatus = xmlgeneral.prefetchStatusOk
        xsdHashKey.duration = ngx.now() - xsdHashKey.started
        kong.log.debug("asyncPrefetch_Schema_Validation_callback: **Success** | PluginType:"..conf.typePlugin.."| count: "..count.."| duration=" .. xsdHashKey.duration)
      else
        kong.log.debug("asyncPrefetch_Schema_Validation_callback: PluginType:"..conf.typePlugin.." err: " .. errMessage)
        local j, _ = string.find(errMessage, "failed.to.load.external.entity")
        local k, _ = string.find(errMessage, "Failed.to.parse.the.XML.resource")
        -- If there is an error not related to a failure to 'load external entity' (for instance: a WSDL/XSD syntax eror)
        if j == nil and k == nil then
          xsdHashKey.prefetchStatus = xmlgeneral.prefetchStatusKo
        end
      end

      -- If the Prefetch status is still 'Running' it means that there is no syntax Error 
      -- but not all external entities are downloaded
      if xsdHashKey.prefetchStatus == xmlgeneral.prefetchStatusRunning then
        xsdHashKey.prefetchStatus = xmlgeneral.prefetchStatusKo
        rc = false
        errMessage = "Not all external entities are downloaded. This process must be performed (at least) once more"
      else
        -- At this stage the status could be 'prefetchStatusKo' related to a WSDL/XSD syntax error, in this case
        -- no need to return 'false' because at the next execution there will have the same result (i.e. a syntax error)
        rc = true
        errMessage = nil
      end
      kong.log.debug("asyncPrefetch_Schema_Validation_callback - PluginType:"..conf.typePlugin.." Last status: " .. tostring(xsdHashKey.prefetchStatus) .. " Last message: " .. (errMessage or "'N/A'"))
    
    -- Else the XSD 'hashKey' is not found in the 'entityLoader.hashKeys'
    else
      rc = false
      errMessage = "PluginType:"..conf.typePlugin.." Unable to find XSD HashKey '" .. (prefetchConf_entry.xsdHashKey or "nil") .. "' in the 'entityLoader.hashKeys'"
      kong.log.debug("asyncPrefetch_Schema_Validation_callback: " .. errMessage)
    end
    ::continue::
  end
  return rc, errMessage
end

---------------------------------------------------------------------------------------
-- Process linked with the 'configure' phase
--  libxml -> Enable the prefetch Validation of SOAP Schema and WSDL/XSD Api Schemas
--            It concerns the new ones and the existing schemas that previously failed
---------------------------------------------------------------------------------------
function xmlgeneral.pluginConfigure_XSD_Validation_Prefetch (config, typePlugin, xsdSchemaInclude, child, queueName, queue_conf)

  local xsdHashKey = libxml2ex.hash_key(xsdSchemaInclude)
  -- If it's the 1st time the XSD Schema is seen
  if kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey] == nil then
    kong.log.debug("XSD_Validation_Prefetch: it's the 1st time the XSD Schema is seen, hashKey=" .. xsdHashKey)
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey] = {
      prefetchStatus = xmlgeneral.prefetchStatusInit,
      started  = ngx.now(),
      duration =  0

    }
  -- Else If the XSD Schema is already known and the Prefetch status is Ko
  elseif kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].prefetchStatus == xmlgeneral.prefetchStatusKo then
    kong.log.debug("XSD_Validation_Prefetch: the XSD Schema is known but the Prefetch status is Ko. Let's try another Prefetch, hashKey=" .. xsdHashKey)
    -- So let's try another Prefetch
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].prefetchStatus = xmlgeneral.prefetchStatusInit
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].started  = ngx.now()
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].duration =  0

  else
    -- Else If the XSD Schema is already known and the Prefetch status is Init/Running/Ok
    --   => Don't change anything
    kong.log.debug("XSD_Validation_Prefetch: the XSD Schema is already known and the Prefetch status is Init/Running/Ok")
  end

  -- Set the information of the plugin using the Schema
  if typePlugin == xmlgeneral.RequestTypePlugin then
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].ReqPluginRemove = false
  else
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].ResPluginRemove = false
  end

  -- If the Prefetch has the 'Init' status
  if kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].prefetchStatus == xmlgeneral.prefetchStatusInit then
    local prefetchConf = {
      xsdSchemaInclude = xsdSchemaInclude,
      VerboseRequest = config.VerboseRequest,
      ExternalEntityLoader_Timeout = config.ExternalEntityLoader_Timeout,
      xsdHashKey = xsdHashKey,
      child = child,
    }
    local conf = {}
    conf.typePlugin = typePlugin

    -- Asynchronously execute the Prefetch of External Entities
    local rc, err = kong.xmlSoapAsync.entityLoader.prefetchQueue.enqueue(queue_conf, asyncPrefetch_Schema_Validation_callback, conf , prefetchConf)
    if err then
      kong.log.err("XSD_Validation_Prefetch, prefetchQueue: " .. err)
    end
  end
end

----------------------------------------------------------------------------------------------
-- Process linked with the 'configure' phase
--  libxml -> Enable the prefetch Validation
--  saxon  -> If required load the 'saxon' library
--  libxml+libxslt+saxon => Initialize a Cache Table for Compiling and Parsing WSDL/XSD, XSLT
--
-- If there is a change in Request  Plugins, 'pluginConfigure' is called
-- If there is a change in Response Plugins, 'pluginConfigure' is called another time
---------------------------------------------------------------------------------------------
function xmlgeneral.pluginConfigure (configs, typePlugin)
  local saxon = false
  local iCount = 0

  if configs then
    local queueName
    
    if typePlugin == xmlgeneral.RequestTypePlugin then
      queueName = libxml2ex.queueNamePrefix .. xmlgeneral.prefetchReqQueueName
    else
      queueName = libxml2ex.queueNamePrefix .. xmlgeneral.prefetchResQueueName
    end

    local queue_conf  =
    {
      name = queueName,                   -- name of the queue (required)
      log_tag = libxml2ex.queueNamePrefix,-- tag string to identify plugin or application area in logs
      max_batch_size = 100,               -- maximum number of entries in one batch (default 1)
      max_coalescing_delay = 1,           -- maximum number of seconds after first entry before a batch is sent
      max_entries = 10000,                -- maximum number of entries on the queue (default 10000)
      max_bytes = nil,                                    -- maximum number of bytes on the queue (default nil)
      initial_retry_delay = libxml2ex.xmlSoapSleepAsync,  -- initial delay when retrying a failed batch, doubled for each subsequent retry
      max_retry_time = xmlgeneral.prefetchQueueTimeout,   -- maximum number of seconds before a failed batch is dropped
      max_retry_delay = libxml2ex.xmlSoapSleepAsync * 4,  -- maximum delay between send attempts, caps exponential retry
      concurrency_limit = 1             -- specify the number of delivery timers (`-1` means no limit at all, and each entry would create an individual timer for sending)
    }

    -- Prepare the purge of 'entityLoader.hashKeys' that are no longer useful
    -- Firstly, consider that all entries have to be deleted
    for k, entityHashKey in next, kong.xmlSoapAsync.entityLoader.hashKeys do
      if typePlugin == xmlgeneral.RequestTypePlugin then
        entityHashKey.ReqPluginRemove = true
      else
        entityHashKey.ResPluginRemove = true
      end
      iCount = iCount + 1
    end
    
    kong.log.debug("pluginConfigure, BEGIN #entityLoader.hashKeys=" .. tostring(iCount))
    
    -- Only for 'Saxon' library => Delete the current Saxon contexts
    for keyPluginId, cachePlugin in pairs (kong.xmlSoapPtrCache.plugins) do
      if cachePlugin.XSLTs then
        -- If 'XSLT before XSD' is defined for Saxon libary
        --    and
        -- If there is a current Contex
        --    and
        -- If the plugin Type of Cache is concerned by the 'configure' phase (Request or Response plugin)
        if cachePlugin.XSLTs[xmlgeneral.xsltBeforeXSD] and
           cachePlugin.xsltLibrary == 'saxon' and
           cachePlugin.XSLTs[xmlgeneral.xsltBeforeXSD].xsltPtr ~= ffi.NULL and
           cachePlugin.typePlugin == typePlugin then
          libsaxon4kong.deleteContext (cachePlugin.XSLTs[xmlgeneral.xsltBeforeXSD].xsltPtr)
          cachePlugin.XSLTs[xmlgeneral.xsltBeforeXSD].xsltPtr = ffi.NULL
        end

        -- If 'XSLT after XSD' is defined for Saxon libary
        --    and
        -- If there is a current Contex
        --    and
        -- If the plugin Type of Cache is concerned by the 'configure' phase (Request or Response plugin)
        if cachePlugin.XSLTs[xmlgeneral.xsltAfterXSD] and 
           cachePlugin.xsltLibrary == 'saxon' and
           cachePlugin.XSLTs[xmlgeneral.xsltAfterXSD].xsltPtr ~= ffi.NULL and
           cachePlugin.typePlugin == typePlugin then
          libsaxon4kong.deleteContext (cachePlugin.XSLTs[xmlgeneral.xsltAfterXSD].xsltPtr)
          cachePlugin.XSLTs[xmlgeneral.xsltAfterXSD].xsltPtr = ffi.NULL
        end
        
        -- If the Plugin Cache is concerned by the 'configure' phase (Request or Response plugin)
        if cachePlugin.typePlugin == typePlugin then
          -- Remove the Cache Entry in case the plugin is no longer used
          -- For plugins still alive, the Cache Entities will be re-created in the loop below
          kong.xmlSoapPtrCache.plugins[keyPluginId] = nil
        end

      end
    end
    
    -- Parse all instances of the plugin
    for keyConfig, config in ipairs(configs) do
      local plugin_id = config.__plugin_id

      -- Initialize the Pointers cache of the plugin for Loading and Parsing the WSDL/XSD and XSLT schemas
      kong.xmlSoapPtrCache.plugins[plugin_id] = {}
      local pluginConf = kong.xmlSoapPtrCache.plugins[plugin_id]
      pluginConf.typePlugin = typePlugin      
      pluginConf.WSDLs = {}
      pluginConf.WSDLs[xmlgeneral.schemaTypeSOAP] = {}
      pluginConf.WSDLs[xmlgeneral.schemaTypeAPI ] = {}
      pluginConf.WSDLs[xmlgeneral.schemaTypeSOAP].TTL = config.ExternalEntityLoader_CacheTTL
      pluginConf.WSDLs[xmlgeneral.schemaTypeAPI ].TTL = config.ExternalEntityLoader_CacheTTL
      pluginConf.WSDLs[xmlgeneral.schemaTypeSOAP].XSDs = {}
      pluginConf.WSDLs[xmlgeneral.schemaTypeAPI ].XSDs = {}
      
      pluginConf.xsltLibrary = config.xsltLibrary
      pluginConf.XSLTs = {}
      pluginConf.XSLTs[xmlgeneral.xsltBeforeXSD ] = {}
      pluginConf.XSLTs[xmlgeneral.xsltAfterXSD  ] = {}
      pluginConf.soapAction = {}
      pluginConf.routeByXPath = {}
      
      -- If saxon library is enabled
      if config.xsltLibrary == 'saxon' then
        saxon = true
      end

      -- Check if there is 'xsdSoapSchemaInclude' for SOAP Envelope
      local xsdSoapSchemaInclude = false
      if config.xsdSoapSchemaInclude then
        for k,v in pairs(config.xsdSoapSchemaInclude) do            
          xsdSoapSchemaInclude = true
          break
        end
      end

      -- Check if there is 'xsdApiSchemaInclude' for API Envelope
      local xsdApiSchemaInclude = false
      if config.xsdApiSchemaInclude then
        for k,v in pairs(config.xsdApiSchemaInclude) do            
          xsdApiSchemaInclude = true
          break
        end
      end
      
      -- If Kong 'stream_listen' is enabled the 'kong.ctx.shared' is not properly set
      -- so the Schema included in the plugin conf or the Asynchronous download can't work
      if #kong.configuration.stream_listeners > 0 and 
        (xsdSoapSchemaInclude or xsdApiSchemaInclude or config.ExternalEntityLoader_Async) then
        kong.log.err(libxml2ex.stream_listen_err)
      -- If Asynchronous is enabled
      elseif config.ExternalEntityLoader_Async then
        kong.log.debug("pluginConfigure, Async")

        -- If a SOAP XSD Schema is defined and
        -- If the XSD content is NOT included in the plugin configuration
        if      config.xsdSoapSchema and
            not xsdSoapSchemaInclude then
          kong.log.debug("pluginConfigure, Validation Prefetch of SOAP Schema")
          xmlgeneral.pluginConfigure_XSD_Validation_Prefetch (config, typePlugin, config.xsdSoapSchema, xmlgeneral.schemaTypeSOAP, queueName, queue_conf)
        end

        -- If an API XSD Schema is defined and
        -- If the XSD content is NOT included in the plugin configuration
        if      config.xsdApiSchema  and
            not xsdApiSchemaInclude then
          kong.log.debug("pluginConfigure, Validation Prefetch of API Schema")
          xmlgeneral.pluginConfigure_XSD_Validation_Prefetch (config, typePlugin, config.xsdApiSchema, xmlgeneral.schemaTypeAPI, queueName, queue_conf)
        end          
      end
    end

    -- Lastly, purge the 'entityLoader.hashKeys'
    --    => Free memory of XSD entries that are no longer used due to a plugin change/deletion
    --    For an effective deletion of a XSD shared by the Request AND Response plugin, we have to 'wait' 
    --    the 'configure' phase of both plugins: 'Request' AND 'Response' plugins
    for k, entityHashKey in next, kong.xmlSoapAsync.entityLoader.hashKeys do
      if  (entityHashKey.ReqPluginRemove == nil or entityHashKey.ReqPluginRemove == true ) and
          (entityHashKey.ResPluginRemove == nil or entityHashKey.ResPluginRemove == true ) and
          entityHashKey.prefetchStatus ~= xmlgeneral.prefetchStatusRunning then
        kong.log.debug("pluginConfigure: remove XSD Api Schema in 'entityLoader.hashKeys' hashKey=" .. k)
        kong.xmlSoapAsync.entityLoader.hashKeys [k] = nil
      end
    end
    
    -- If the 'saxon' is not already Initialized 
    --    and
    -- If the 'saxon' library is enabled at least by 1 plugin
    if kong.xmlSoapSaxon == nil and saxon then
      -- Initialize Saxon
      xmlgeneral.initializeSaxon()
    end

    iCount = 0
    for k, v in next, kong.xmlSoapAsync.entityLoader.hashKeys do
      iCount = iCount + 1
    end
    kong.log.debug("pluginConfigure: END #entityLoader.hashKeys=" .. tostring(iCount))
  end
end

----------------------------------------------
-- Do a sleep for waiting the end of Prefetch
----------------------------------------------
function xmlgeneral.sleepForPrefetchEnd (ExternalEntityLoader_Async, xsdApiSchemaInclude, queuename)
  local rc = false
  local xsdApiSchemaIncluded = false

  -- If Asynchronous is enabled
  if ExternalEntityLoader_Async then
    
    -- Check if there is XSD content in the plugin configuration
    if xsdApiSchemaInclude and next(xsdApiSchemaInclude) then
      xsdApiSchemaIncluded = true
    end
    
    -- If there is NO XSD content included in the plugin configuration
    if not xsdApiSchemaIncluded then
      local nowTime = ngx.now()
      -- Wait for:
      --     The end of Prefetch Validation of the XSD schema and
      --     The timeout Prefetch (avoiding infinite loop)
      while kong.xmlSoapAsync.entityLoader.prefetchQueue.exists(queuename) and
            (nowTime + xmlgeneral.prefetchQueueTimeout > ngx.now()) do
              -- This 'sleep' happens only one time per Plugin configuration update
        ngx.sleep(libxml2ex.xmlSoapSleepAsync)
        rc = true
      end
    else
      -- As the XSD content is included in the plugin, don't wait the asynchronous download of XSD content
    end
  end
  
  return rc
end

---------------------------------------------------------------------------------
-- Initialize the SOAP/XML plugin
-- Setup a 'libxml2' Error handler
-- Setup a 'libxslt' Error handler
-- Setup the SOAP/XML context in charge of downloading the XSD in the background
-- Setup an External Entity Loader
---------------------------------------------------------------------------------
function xmlgeneral.initializeXmlSoapPlugin ()
  
  -- Performance capability: Initialize the cache of Pointers for Loading and Parsing the WSDL/XSD and XSLT schemas
  if not kong.xmlSoapPtrCache then
    kong.xmlSoapPtrCache = {}
    kong.xmlSoapPtrCache.plugins = {}
  end
  
  -- Initialize the Error Handlers only one time for the Nginx process and for the Plugin
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
      if kong.ctx.shared.xmlSoapErrMessage == nil and type ~= ffi.NULL then
        kong.ctx.shared.xmlSoapErrMessage = ffi.string(type)
      elseif type ~= ffi.NULL then
        kong.ctx.shared.xmlSoapErrMessage = kong.ctx.shared.xmlSoapErrMessage .. '. ' .. ffi.string(type)
      end
    end)
    kong.xmlSoapLibxsltErrorHandler = true
  else
    kong.log.debug ("initializeXmlSoapPlugin: 'libxslt' Error Handler is already initialized => nothing to do")
  end
  
  -- LIBXML: Initialize the External Entity Loader for downloading XSD that are imported on 'http(s)://'
  -- Example: <xsd:import namespace="http://tempuri.org/" schemaLocation="https://mytempuri.com/tempuri.org.xsd"/>
  if not kong.xmlSoapAsync then
    kong.log.debug ("initializeExternalEntityLoader: it's the 1st time the function is called => initialize the 'libxml2' External Loader")
    kong.xmlSoapAsync = {
      entityLoader = {
        hashKeys = {},
        prefetchQueue = require "kong.tools.queue", -- Queue to prefetch the validation of all WSDL/XSD schemas and bring on the download of External Entities (XSD)
        downloadExtEntitiesQueue = require "kong.tools.queue",  -- Queue to download the External Entities (XSD)
      }
    }
    libxml2ex.initializeExternalEntityLoader()  
  else
    kong.log.debug ("initializeExternalEntityLoader: 'libxml2' External Loader is already initialized => nothing to do")
  end
end

----------------------------------------------------------------------------------------
-- Prepare a XML declaration (which starts by '<?')
-- The XLST removes it; so if the user defines its xslt file with 
-- omit-xml-declaration="no" we format it and append it to SOAP/XML content (after XSLT)
--
-- Example: <?xml version="1.0" encoding="utf-8"?>
----------------------------------------------------------------------------------------
function xmlgeneral.XSLT_Format_XMLDeclaration(version, encoding, omitXmlDeclaration, standalone, indent)
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

---------------------------------------------------
-- libsaxon: Transform XML with XSLT Transformation
---------------------------------------------------
function xmlgeneral.XSLTransform_libsaxon(pluginType, pluginId, xsltBeforeAfterXSD, xsltParams, XMLtoTransform, XSLT, verbose)
  local errMessage
  local xml_transformed_dump
  local context
  local errFaultCode
  local soapFaultCode = xmlgeneral.soapFaultCodeServer
  
  kong.log.debug ("XSLT transformation, BEGIN: " .. XMLtoTransform)

  -- Get the XSLT Cache table  
  local cacheXslt = kong.xmlSoapPtrCache.plugins[pluginId].XSLTs[xsltBeforeAfterXSD]
  
  -- Check if Saxon for Kong library is correctly loaded
  errMessage = libsaxon4kong.isSaxonforKongLoaded()
  
  if not errMessage then

    -- If the compiled XSLT is not in the cache and If there is no Error from Cache
    if not cacheXslt.xsltPtr and not cacheXslt.xsltErrMsg then
      kong.log.debug ("XSLT transformation, caching: Compile the XSLT and Put it in the cache")
      
      -- Compile the XSLT document
      context, errMessage = libsaxon4kong.compileStylesheet (kong.xmlSoapSaxon.saxonProcessor,
                                                             kong.xmlSoapSaxon.xslt30Processor,
                                                             XSLT)
      if errMessage then
        errMessage = xmlgeneral.invalidXSLT .. ". " .. errMessage    
      end
      cacheXslt.xsltPtr     = context
      cacheXslt.xsltErrMsg  = errMessage
    else
      kong.log.debug ("XSLT transformation, caching: Get the compiled XSLT from cache")
      context     = cacheXslt.xsltPtr
      errMessage  = cacheXslt.xsltErrMsg
    end

  end

  if not errMessage then
    -- If the XSLT Transformation is configured with a Template (example: <xsl:template name="main">)
    -- see example in the repo: _tmp.xslt.transformation/xslt-v3-tester_kong_json-to-xml_with_template.xslt
    -- xsltSaxonTemplate='main' and xsltSaxonTemplateParam='request-body'
    --if plugin_conf.xsltSaxonTemplate and plugin_conf.xsltSaxonTemplateParam then
      -- Transform the XML doc with XSLT transformation by invoking a template
    --  xml_transformed_dump, errMessage = libsaxon4kong.stylesheetInvokeTemplate ( 
    --                                        kong.xmlSoapSaxon.saxonProcessor,
    --                                        context,
    --                                        plugin_conf.xsltSaxonTemplate, 
    --                                        plugin_conf.xsltSaxonTemplateParam,
    --                                        XMLtoTransform
    --                                      )
    --else

    -- Transform the XML doc with XSLT transformation
    xml_transformed_dump, errMessage = libsaxon4kong.stylesheetTransformXml ( 
                                          kong.xmlSoapSaxon.saxonProcessor,
                                          context,
                                          XMLtoTransform,
                                          xsltParams
                                        )

    if not errMessage then 
      -- Remove empty Namespace (example: xmlns="") added by XSLT library or transformation 
      xml_transformed_dump = xml_transformed_dump:gsub(' xmlns=""', '')
    else
      -- If it's the Request Plugin we consider that the error comes from the Client
      if pluginType == xmlgeneral.RequestTypePlugin then
        soapFaultCode = xmlgeneral.soapFaultCodeClient
      end
    end
  end
  
  -- Here don't free Context memory:
  --  'xmlgeneral.pluginConfigure' is in charge for freeing memory (by calling 'deleteContext(context)')

  if errMessage == nil then
    kong.log.debug ("XSLT transformation, END: " .. xml_transformed_dump)
  else
    kong.log.debug ("XSLT transformation, END with error: " .. errMessage)
  end
  
  return xml_transformed_dump, errMessage, soapFaultCode
end

---------------------------------------------------
-- libxslt: Transform XML with XSLT Transformation
---------------------------------------------------
function xmlgeneral.XSLTransform_libxlt(pluginType, pluginId, xsltBeforeAfterXSD, xsltParams, XMLtoTransform, XSLT, verbose)
  local errMessage  = nil
  local err         = nil
  local style       = nil
  local xslt_doc    = nil
  local xml_doc     = nil
  local errDump     = 0
  local xml_transformed_dump  = ""
  local xmlNodePtrRoot        = nil
  local soapFaultCode         = xmlgeneral.soapFaultCodeServer
  
  kong.log.debug("XSLT transformation, BEGIN: " .. XMLtoTransform)
  
  -- If it's the Request Plugin
  if pluginType == xmlgeneral.RequestTypePlugin then
    -- By default the error is related to the 'Client' (exception: in case of wrong XSLT definition, the errror is related to 'Server')
    soapFaultCode = xmlgeneral.soapFaultCodeClient
  -- Else it's the Response Plugin
  else
    -- The error is related to the 'Server'
    soapFaultCode = xmlgeneral.soapFaultCodeServer
  end

  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                      ffi.C.XML_PARSE_NOWARNING)

  -- Get the XSLT Cache table  
  local cacheXslt = kong.xmlSoapPtrCache.plugins[pluginId].XSLTs[xsltBeforeAfterXSD]
  
  -- If the XML Tree document of XSLT is not in the cache and If there is no Error from Cache
  if not cacheXslt.xmlXsltPtr and not cacheXslt.xmlXsltErrMsg then
    kong.log.debug ("XSLT transformation, caching: Compile the XSLT and Put it in the cache")
    -- Load the XSLT document
    xslt_doc, errMessage = libxml2ex.xmlReadMemory(XSLT, nil, nil, default_parse_options, verbose, true)
    cacheXslt.xmlXsltPtr    = xslt_doc
    cacheXslt.xmlXsltErrMsg = errMessage
  -- Get from cache the XML Tree document of XSLT
  else
    kong.log.debug ("XSLT transformation, caching: Get the compiled XSLT from cache")
    xslt_doc   = cacheXslt.xmlXsltPtr
    errMessage = cacheXslt.xmlXsltErrMsg
  end

  if errMessage == nil then
    -- If XSLT document parser is not in the cache and If there is no Error from Cache
    if not cacheXslt.xsltParsePtr and not cacheXslt.xsltParseErrMsg then
      -- Parse XSLT document
      style, errMessage = libxslt.xsltParseStylesheetDoc (xslt_doc)
      cacheXslt.xsltParsePtr    = style
      cacheXslt.xsltParseErrMsg = errMessage
    -- Get from cache the XSLT Parser
    else
      style      = cacheXslt.xsltParsePtr
      errMessage = cacheXslt.xsltParseErrMsg
    end

    if errMessage then
      errMessage = xmlgeneral.invalidXSLT .. ". " .. errMessage
      soapFaultCode = xmlgeneral.soapFaultCodeServer
    elseif style == ffi.NULL then
      errMessage = xmlgeneral.invalidXSLT .. ". Error calling 'xsltParseStylesheetDoc'"
      soapFaultCode = xmlgeneral.soapFaultCodeServer
    else
      -- Load the complete XML document (with <soap:Envelope>)
      xml_doc, errMessage = libxml2ex.xmlReadMemory(XMLtoTransform, nil, nil, default_parse_options, verbose, false)
      if errMessage ~= nil then
        errMessage = xmlgeneral.invalidXML .. ". " .. errMessage
      end
    end
  else
    errMessage = xmlgeneral.invalidXSLT .. ". " .. errMessage
    soapFaultCode = xmlgeneral.soapFaultCodeServer
  end

  -- If the XSLT and the XML are correctly loaded and parsed
  if errMessage == nil then
    -- Transform the XML doc with XSLT transformation
    local xml_transformed = libxslt.xsltApplyStylesheet(style, xml_doc, xsltParams)

    if xml_transformed ~= nil then
      -- Dump into a String the canonized image of the XML transformed by XSLT
      xml_transformed_dump, errDump = libxml2ex.xmlC14NDocSaveTo (xml_transformed, nil)
      
      if errDump == 0 then
        -- If needed we append the xml declaration
        -- Example: <?xml version="1.0" encoding="utf-8"?>
        xml_transformed_dump = xmlgeneral.XSLT_Format_XMLDeclaration (
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
  
  return xml_transformed_dump, errMessage, soapFaultCode
  
end

---------------------------------------------------
-- Transform XML with XSLT Transformation
---------------------------------------------------
function xmlgeneral.XSLTransform(pluginType, pluginId, xsltBeforeAfterXSD, xsltLibrary, xsltParams, XMLtoTransform, XSLT, verbose)
  local errMessage
  local xml_transformed_dump
  local soapFaultCode = xmlgeneral.soapFaultCodeServer
  
  if xsltLibrary == 'libxslt' then
    xml_transformed_dump, errMessage, soapFaultCode = xmlgeneral.XSLTransform_libxlt(pluginType,
                                                                                     pluginId,
                                                                                     xsltBeforeAfterXSD,
                                                                                     xsltParams,
                                                                                     XMLtoTransform,
                                                                                     XSLT,
                                                                                     verbose)
  elseif xsltLibrary == 'saxon' then
    -- If XMLtoTransform is a JSON type, we add a fake <InternalkongRoot> tag to be ingested as an XML
    if xmlgeneral.getBodyContentType(XMLtoTransform) == xmlgeneral.JSONContentTypeBody then
      XMLtoTransform = xmlgeneral.startInternalkongRoot .. XMLtoTransform .. xmlgeneral.endInternalkongRoot
    end
    xml_transformed_dump, errMessage, soapFaultCode = xmlgeneral.XSLTransform_libsaxon(pluginType,
                                                                                       pluginId,
                                                                                       xsltBeforeAfterXSD,
                                                                                       xsltParams,
                                                                                       XMLtoTransform,
                                                                                       XSLT,
                                                                                       verbose)
  else
    kong.log.err("XSLTransform: unknown library " .. xsltLibrary)
  end
  return xml_transformed_dump, errMessage, soapFaultCode
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
  
  -- Retrieve the NameSpace prefix of 'XML Schema': 'xmlns:prefix' associated to hRef: 'http://www.w3.org/2001/XMLSchema'
  --    Example of 'prefix': xsd (xmlns:xsd), xs (xmlns:xs), myxsd (xmlns:myxsd), etc.
  -- The prefix can be null:
  --    Example of a NULL 'prefix': xmlns="http://www.w3.org/2001/XMLSchema"
  local xmlNsPtr = libxml2.xmlSearchNsByHref(document, node, xmlgeneral.xmlnsXsdHref)
  -- If the Namespace of 'XML Schema' is found
  if xmlNsPtr ~= ffi.NULL and xmlNsPtr.type == ffi.C.XML_NAMESPACE_DECL then
    -- The prefix is defined
    if xmlNsPtr.prefix ~= ffi.NULL then
      xmlNsXsdPrefix = ffi.string(xmlNsPtr.prefix) .. ':'
    -- Else the prefix is NULL
    else
      xmlNsXsdPrefix = ''
    end    
  end
  
  -- Search the begin and end of '<xsd:schema' ... '>'
  if xmlNsXsdPrefix then
    xsdSchemaTag = "<" .. xmlNsXsdPrefix .. xmlgeneral.xsdSchema
    beginSchema = xsdSchema:find (xsdSchemaTag, 1)
    endSchema   = xsdSchema:find (">", 2)
  end

  -- Get the List of all NameSpaces
  raw_namespaces = libxml2.xmlGetNsList(document, node)
  
  if not xmlNsXsdPrefix or not raw_namespaces or not beginSchema or not endSchema then
    kong.log.err("WSDL validation - Unable to add Namespaces from <wsdl:definition>")
    return xsdSchema
  end

  local xsdSchemaTmp = xsdSchema:sub(beginSchema, endSchema)
  local i = 0
  local xmlns = ''
  -- Add each Namespace definition defined at <wsdl> level in <xsd:schema>
  while raw_namespaces[i] ~= ffi.NULL do
    
    -- If it's a NAMESPACE DECLaration
    if raw_namespaces[i].type == ffi.C.XML_NAMESPACE_DECL then      
      
      -- If the prefix and href are both defined (example: xmlns:xs="http://www.w3.org/2001/XMLSchema" | here prefix='xs' and href="http://www.w3.org/2001/XMLSchema")
      --   AND
      -- If the prefix (xmlns:xs) is not already defined in the current <xsd:schema>
      if     raw_namespaces[i].prefix ~= ffi.NULL and raw_namespaces[i].href ~= ffi.NULL and
         not xsdSchemaTmp:find("xmlns:" .. ffi.string(raw_namespaces[i].prefix) .. "=\"") then
        xmlns = "xmlns:" .. ffi.string(raw_namespaces[i].prefix) .. "=\"" .. ffi.string(raw_namespaces[i].href) .. "\" " .. xmlns
      
      -- If the prefix is not defined and href is defined (example: xmlns="http://www.w3.org/2001/XMLSchema" | here prefix=NULL and href="http://www.w3.org/2001/XMLSchema")
      --   AND
      -- If the 'xmlns' is not already defined in the current <xsd:schema>
      elseif raw_namespaces[i].prefix == ffi.NULL and raw_namespaces[i].href ~= ffi.NULL and
         not xsdSchemaTmp:find("xmlns=\"") then
          xmlns = "xmlns=\"" .. ffi.string(raw_namespaces[i].href) .. "\" " .. xmlns
      else
        -- Do nothing because the Namespace is already defined
      end

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
function xmlgeneral.XMLValidateWithWSDL (pluginType, pluginId, child, XMLtoValidate, WSDL, verbose, prefetch, async)
  local xml_doc          = nil
  local errMessage       = nil
  local firstErrMessage  = nil
  local firstCall        = false
  local xsdSchema        = nil
  local currentNode      = nil
  local xmlNsXsdPrefix   = nil
  local cacheWSDL        = nil
  local wsdlNodeFound    = false
  local typesNodeFound   = false
  local validSchemaFound = false
  local XMLXSDMatching   = false
  local nodeName         = ""
  local index            = 0
  local soapFaultCode    = xmlgeneral.soapFaultCodeServer

  kong.log.debug("WSDL Validation, BEGIN PluginType:"..pluginType.." child:"..child .. " prefetch:"..tostring(prefetch) .. " async:"..tostring(async))

  -- If we have a WDSL file, we retrieve the '<wsdl:types>' Node AND the '<xs:schema>' child nodes 
  --   OR
  -- In we have a raw XSD schema '<xs:schema>'
  --   THEN
  -- We do a loop for validating the 'XMLtoValidate' XML with each '<xs:schema>' until one works
  --
  -- Example of WSDL 2.0:
  --  <description xmlns="http://www.w3.org/ns/wsdl" targetNamespace="http://tempuri.org/" xmlns:tns="http://tempuri.org/" xmlns:stns="http://tempuri.org/" xmlns:wsoap="http://www.w3.org/ns/wsdl/soap" xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:wsdlx="http://www.w3.org/ns/wsdl-extensions" >
  -- Example of WSDL 1.1:
  --  <wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tns="http://tempuri.org/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:http="http://schemas.microsoft.com/ws/06/2004/policy/http" xmlns:msc="http://schemas.microsoft.com/ws/2005/12/wsdl/contract" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsam="http://www.w3.org/2007/05/addressing/metadata" targetNamespace="http://tempuri.org/" name="INonCacheService" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">
  --  <!-- ********************************* --> 
  --  <!-- Ccommon part for WSDL 1.1 and 2.0 -->
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

  -- If it's the Request Plugin
  if pluginType == xmlgeneral.RequestTypePlugin then
    -- By default the error is related to the 'Client' (exception: in case of wrong WSDL definition, the errror is related to 'Server')
    soapFaultCode = xmlgeneral.soapFaultCodeClient
  -- Else it's the Response Plugin
  else
    -- The error is related to the 'Server'
    soapFaultCode = xmlgeneral.soapFaultCodeServer
  end

  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING)

  -- Get the WSDL Cache table
  if prefetch or async then
    -- If prefetch is enabled
    --    Don't try to cache the compiled WSDL because many plugins could share the same WSDL definition (hash).
    --    The prefetch is done for each distinct (hash) WSDL and not for each plugin and the goal is to asynchronously download external entities
    --    Here we have:
    --        prefetch=true
    --        pluginId=nil <- unable to call kong.xmlSoapPtrCache.plugins[pluginId]
    --  OR 
    -- If asnchronous download is enabled
    --    Don't try to cache the compiled WSDL because there is no guarantee for getting all new External Entities at time 
    --    related to their TTL (refreshing their content)
    cacheWSDL = {}
  else    
    cacheWSDL = kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child]
    local cacheOk = true
    
    -- If it's the first time the WSDL is called
    if not cacheWSDL.started then
      cacheWSDL.started = ngx.now()
    -- Else If the WSDL is too old, remove it from the cache      
    elseif cacheWSDL.started + cacheWSDL.TTL < ngx.now() then
      kong.log.debug ("WSDL Validation, caching: TTL ("..(cacheWSDL.TTL or 'nil').." s) is reached, so re-compile the WSDL")
      cacheOk = false
    -- Else check that all XSD pointers are correctly compiled in the cache
    else
      for k, cacheXSD in pairs (cacheWSDL.XSDs) do
        if cacheXSD and (not cacheXSD.xmlSchemaParserCtxtPtr or not cacheXSD.xmlSchemaPtr or not cacheXSD.xmlSchemaValidCtxtPtr) then
          kong.log.debug ("WSDL Validation, caching: Not all XSDs are correctly compiled, so re-compile the WSDL")
          cacheOk = false
          break
        end
      end
    end
    
    -- If we have to refresh the WSDL cache or if the XSDs attached to the WSDL are not correctly compiled
    if not cacheOk then
      local cacheTTL = cacheWSDL.TTL
      kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child] = {}
      cacheWSDL = kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child]
      cacheWSDL.started = ngx.now()
      cacheWSDL.TTL = cacheTTL
      cacheWSDL.XSDs = {}      
    end
  end
  
  -- If the XML Tree document of WSDL is not in the cache
  if cacheWSDL.xmlWsdlPtr == nil or cacheWSDL.xmlWsdlPtr == ffi.NULL then
    
    firstCall = true
    if async then
      kong.log.debug ("WSDL Validation, no WSDL caching due to Asynchronous external entities")
    else
      kong.log.debug ("WSDL Validation, caching: Compile the WSDL and Put it in the cache")
    end

    -- Parse an XML in-memory document of the WSDL and build a tree
    xml_doc, errMessage = libxml2ex.xmlReadMemory(WSDL, nil, nil, default_parse_options, verbose, false)
    cacheWSDL.xmlWsdlPtr = xml_doc
    kong.log.debug("XMLValidateWithWSDL, xmlReadMemory - Ok")
  -- Get from cache the XML Tree document of WSDL
  else
    kong.log.debug ("WSDL Validation, caching: Get the compiled WSDL from cache")
    xml_doc    = cacheWSDL.xmlWsdlPtr
  end
  
  if errMessage then
    -- Force the cache to nil. So for the next call there will have a new compilation/caching try
    cacheWSDL.xmlWsdlPtr = nil
    errMessage = xmlgeneral.invalidWSDL_XSD .. ". " .. errMessage      
    soapFaultCode = xmlgeneral.soapFaultCodeServer
    kong.log.err (errMessage)
    return errMessage, soapFaultCode
  end
  
  -------------------------------------------------------------------------------------------------
  -- If it's the first call due to:
  --   -> Prefetch OR
  --   -> Synchronous (with no former successful WSDL validation or with TTL exceeded) OR
  --   -> Asynchronous
  --   => Get all XSDs and compile/parse them for caching
  -------------------------------------------------------------------------------------------------
  if firstCall then

    if prefetch then
      kong.log.debug("XMLValidateWithWSDL, prefetch: so get all XSDs and raise the download of External Entities") 
    elseif async then
      kong.log.debug("XMLValidateWithWSDL, asynchronous: validate the XML with the WSDL") 
    else
      kong.log.debug("XMLValidateWithWSDL, caching: it's the first call for this WSDL: so get all XSDs and compile/parse them for caching") 
    end
    -- Retrieve the <wsdl:definitions>
    local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_doc)
    if xmlNodePtrRoot then
      if tonumber(xmlNodePtrRoot.type) == ffi.C.XML_ELEMENT_NODE and 
        xmlNodePtrRoot.name ~= ffi.NULL then
        nodeName = ffi.string(xmlNodePtrRoot.name)
        -- WSDL 1.1
        if     nodeName == "definitions" then
          wsdlNodeFound = true
        -- WSDL 2.0
        elseif nodeName == "description" then
          wsdlNodeFound = true
        end
      end
    end

    -- If we found the <wsdl:definitions>
    if wsdlNodeFound then
      currentNode  = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
      -- Retrieve '<wsdl:types>' Node in the WSDL
      while currentNode ~= ffi.NULL and not typesNodeFound do
        if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE and 
          currentNode.name ~= ffi.NULL then
          kong.log.debug ("currentNode.name: '" .. ffi.string(currentNode.name) .. "'")
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
        errMessage = "Unable to find the '<wsdl:types>'"
        kong.log.debug (errMessage)
        soapFaultCode = xmlgeneral.soapFaultCodeServer
        return errMessage, soapFaultCode
      end
    else
      kong.log.debug("Unable to find the '<wsdl:definitions>', so considering the XSD as a raw '<xs:schema>'")
    end

    -- If we found the '<wsdl:types>' Node we select the first child Node which is '<xs:schema>'
    if typesNodeFound then
      kong.log.debug("XMLValidateWithWSDL, Found the '<wsdl:types>' Node")
      currentNode  = libxml2.xmlFirstElementChild(currentNode)
    -- Else it's a not a WSDL it's a raw <xs:schema>
    else
      currentNode = xmlNodePtrRoot
    end

    -- Retrieve all '<xs:schema>' Nodes and 
    -- Continue the loop until & stop depending on Prefetch/Async/Sync
    --   -> Prefetch: get all XSDs (without checking the validity of 'XMLtoValidate')
    --   -> Async   : get the right XSD for validating the XML
    --   -> Sync    : get all XSDs and compile/parse them for caching (done only once except if there is error or TTL cache expired)
    while currentNode ~= ffi.NULL and not (async and (validSchemaFound or XMLXSDMatching)) do
      
      if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE and 
        currentNode.name ~= ffi.NULL then
        -- Get the node Name
        nodeName = ffi.string(currentNode.name)
        if nodeName == "schema" then        
          index = index + 1
          xsdSchema = libxml2ex.xmlNodeDump	(xml_doc, currentNode, 1, 1)
          kong.log.debug ("Cache/Prefetch - schema #" .. index .. ", length: " .. #xsdSchema .. ", dump: " .. xsdSchema)
          
          -- Add Global NameSpaces (defined at <wsdl:definition>) to <xsd:schema>
          xsdSchema = xmlgeneral.addNamespaces(xsdSchema, xml_doc, currentNode)
          
          errMessage = nil
          -- Validate the XML with the <xs:schema>'
          errMessage, XMLXSDMatching, soapFaultCode = xmlgeneral.XMLValidateWithXSD (pluginType, pluginId, child, index, XMLtoValidate, xsdSchema, verbose, prefetch, async)
                    
          -- If prefetch is enabled
          if prefetch then
            -- If there is an error, Keep only the 1st Error message and 
            -- avoid, for instance, that the correct validation of schema#2 overwrites the error of schema#1
            if errMessage and not firstErrMessage then
              firstErrMessage = errMessage
            end
            -- Go on next schema
            kong.log.debug ("Prefetch is enabled: go on next XSD Schema")

          -- Else If there is no error it means that we found the right Schema validating the SOAP/XML
          elseif not errMessage then
            kong.log.debug ("Found the right XSD Schema validating the SOAP/XML")
            validSchemaFound = true
          -- Else if there is an Error and it's a synchronous download and the First Message is not caught yet
          elseif errMessage and not async and not firstErrMessage then
            local j, _ = string.find(errMessage, "failed.to.load.external.entity")
            local k, _ = string.find(errMessage, "Failed.to.parse.the.XML.resource")
            -- If there is an error related to a failure to 'load external entity'
            if j or k then
              firstErrMessage = errMessage
            end
          end
         
        end
      end
      -- Go to the next '<xs:schema>' Node
      currentNode = ffi.cast("xmlNode *", currentNode.next)
    end
  end
  
  ----------------------------------------------------------------------------------
  -- Else if there is no prefetch, no asynchronous
  ----------------------------------------------------------------------------------
  if not prefetch and not async then
    
    -- If not all XSDs were not successfully compiled for the cache
    if firstErrMessage then 
      kong.log.debug("XMLValidateWithWSDL, synchronous: not all XSDs were successfully compiled for the cache") 
      errMessage = firstErrMessage
      soapFaultCode = xmlgeneral.soapFaultCodeServer
    else
      kong.log.debug("XMLValidateWithWSDL, synchronous: validate the XML with the compiled WSDL/XSDs in the cache") 
      validSchemaFound = false

      -- Find the right XSD (in the WSDL) for validating the XML
      for index,value in pairs(cacheWSDL.XSDs) do
        
        kong.log.debug ("Validation for schema #" .. index)

        errMessage, XMLXSDMatching, soapFaultCode = xmlgeneral.XMLValidateWithXSD (pluginType, pluginId, child, index, XMLtoValidate, xsdSchema, verbose, prefetch, async)
        
        local msgDebug = errMessage or "Ok"
        kong.log.debug ("Validation for schema #" .. index .. " RC_Message: '" .. msgDebug .. "'")

        -- If there is a Match between the Operation Name (of XML) and the XSD
        --   or
        -- If there is no Error
        if XMLXSDMatching or not errMessage then
          kong.log.debug ("Found the right XSD Schema validating the SOAP/XML")
          validSchemaFound = true
          break
        end      
      end
    end
  end
  
  -- If prefetch is enabled 
  if prefetch then
    -- Get the 1st Error message
    errMessage = firstErrMessage
  -- Else If there is no Error and we don't retrieve a valid Schema for the XML
  elseif not errMessage and not validSchemaFound then
    errMessage = "Unable to find a suitable Schema to validate the SOAP/XML"
  end

  kong.log.debug("WSDL Validation, END")

  return errMessage, soapFaultCode
end

--------------------------------------
-- Validate a XML with its XSD schema
--------------------------------------
function xmlgeneral.XMLValidateWithXSD (pluginType, pluginId, child, indexXSD, XMLtoValidate, XSDSchema, verbose, prefetch, async)
  local xml_doc            = nil
  local errMessage         = nil
  local err                = nil
  local is_valid           = 0
  local schemaType         = ""
  local bodyNodeFound      = nil
  local currentNode        = nil
  local XMLXSDMatching     = false
  local nodeName           = ""
  local libxml2            = require("xmlua.libxml2")
  local soapFaultCode      = xmlgeneral.soapFaultCodeServer
  local cacheXSD           = nil
  local xsd_context        = nil
  local xsd_schema_doc     = nil  
  local validation_context = nil

  -- Prepare the error Message
  if child == xmlgeneral.schemaTypeSOAP then
    schemaType = "SOAP"
  else
    schemaType = "API"
  end
  
  kong.log.debug("XSD Validation for '".. schemaType.. "', BEGIN PluginType: "..pluginType .." prefetch:"..tostring(prefetch).." async:"..tostring(async))

  -- If it's the Request Plugin
  if pluginType == xmlgeneral.RequestTypePlugin then
    -- By default the error is related to the 'Client' (exception: in case of wrong XSD definition, the errror is related to 'Server')
    soapFaultCode = xmlgeneral.soapFaultCodeClient
  -- Else it's the Response Plugin
  else
    -- The error is related to the 'Server'
    soapFaultCode = xmlgeneral.soapFaultCodeServer
  end
  
  -- Get the XSD Cache table
  if prefetch or async then
    -- If prefetch is enabled
    --    Don't try to cache the compiled XSD because many plugins could share the same XSD definition (hash).
    --    The prefetch is done for each distinct (hash) XSD and not for each plugin and the goal is to asynchronously download external entities
    --    Here we have:
    --        prefetch=true
    --        pluginId=nil <- unable to call kong.xmlSoapPtrCache.plugins[pluginId]
    --  OR 
    -- If asnchronous download is enabled
    --    Don't try to cache the compiled XSD because there is no guarantee for getting all new External Entities at time 
    --    related to their TTL (refreshing their content)
    cacheXSD = {}
  else
    -- If it's the first call => let's create the XSD cache table
    if not kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].XSDs[indexXSD] then    
      kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].XSDs[indexXSD] = {}
      kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].XSDs[indexXSD].started = ngx.now()
    else
      -- Get XSD pointers from the cache table
      cacheXSD = kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].XSDs[indexXSD]
      -- Else If the XSD is too old, remove it from the cache
      if cacheXSD.started + kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].TTL < ngx.now() then
        kong.log.debug ("XSD Validation, caching: TTL ("..(kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].TTL or 'nil').." s) is reached, so re-compile the XSD")
        kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].XSDs[indexXSD] = {}
      -- If not all pointers aren't in the cache table
      elseif not cacheXSD.xmlSchemaParserCtxtPtr or not cacheXSD.xmlSchemaPtr or not cacheXSD.xmlSchemaValidCtxtPtr then
        kong.log.debug("XSD Validation, caching: All the pointers need to recreated for consistency")
        kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].XSDs[indexXSD] = {}
      end
    end
    
    cacheXSD = kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[child].XSDs[indexXSD]
    
  end

  -- If the Parser Context is not in the cache 
  if not cacheXSD.xmlSchemaParserCtxtPtr then

    if prefetch then
      kong.log.debug("XSD Validation, prefetch: Compile XSD and Raise the download of External Entities")
    elseif async then
      kong.log.debug("XSD Validation, no XSD caching due to Asynchronous external entities") 
    else
      kong.log.debug("XSD Validation, caching: Compile the XSD and Put it in the cache") 
    end

    -- Create the Parser Context
    xsd_context, errMessage = libxml2ex.xmlSchemaNewMemParserCtxt(XSDSchema)
    cacheXSD.xmlSchemaParserCtxtPtr = xsd_context
  -- Get the Parser Context from cache
  else
    kong.log.debug ("XSD Validation, caching: Get the compiled XSD from cache")
    xsd_context = cacheXSD.xmlSchemaParserCtxtPtr
  end
  
  if not errMessage then
    -- If the Schema Parser is not in the cache
    if not cacheXSD.xmlSchemaPtr then
      -- Parse XSD schema
      xsd_schema_doc, errMessage = libxml2ex.xmlSchemaParse(xsd_context, verbose)
      cacheXSD.xmlSchemaPtr = xsd_schema_doc
    -- Get the Schema Parser from cache
    else
      xsd_schema_doc = cacheXSD.xmlSchemaPtr
    end
  end
  
  -- If it's a Prefetch we just have to parse the XSD, which downloads XSD in cascade 
  --   => there is no XML to validate with its schema
  if prefetch then
    return errMessage, XMLXSDMatching, soapFaultCode
  end

  if not errMessage then
    -- If the Validation Context pointer is not in the cache
    if not cacheXSD.xmlSchemaValidCtxtPtr then
      -- Create Validation context of XSD Schema
      validation_context, errMessage = libxml2ex.xmlSchemaNewValidCtxt(xsd_schema_doc)
      cacheXSD.xmlSchemaValidCtxtPtr = validation_context
    else
      validation_context = cacheXSD.xmlSchemaValidCtxtPtr
    end
  end

  if not errMessage then
    local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING)

    -- Load the XML to be validated against the schema
    xml_doc, errMessage = libxml2ex.xmlReadMemory(XMLtoValidate, nil, nil, default_parse_options, verbose, false)

    -- If there is an error on 'xmlReadMemory' call
    if errMessage then
      errMessage = xmlgeneral.invalidXML .. ". " .. errMessage      
    -- Else if we have to find the 1st Child of API, which is in this example <Add ... /"> (and not the <soap> root)
    elseif child ~= xmlgeneral.schemaTypeSOAP then
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
      local xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xml_doc);

      currentNode  = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
       -- Retrieve '<soap:Body>' Node in the XML
      while currentNode ~= ffi.NULL and not bodyNodeFound do
        if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE and
           currentNode.name ~= ffi.NULL then
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
      -- If we don't find <soap:Body>
      if not bodyNodeFound then
        errMessage = xmlgeneral.invalidXML .. ". Unable to find the 'soap:Body'"
        kong.log.err (errMessage)
        return errMessage, XMLXSDMatching, soapFaultCode
      end

      -- Get WebService Child Element, which is, for instance, <Add xmlns="http://tempuri.org/">
      local xmlNodePtrChildWS = libxml2.xmlFirstElementChild(currentNode)
      
      if xmlNodePtrChildWS ~= ffi.NULL and tonumber(xmlNodePtrChildWS.type) == ffi.C.XML_ELEMENT_NODE then
        -- Dump in a String the WebService part
        kong.log.debug ("XSD validation ".. schemaType .." part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrChildWS, 1, 1))
        -- Check validity of One element with its XSD schema
        is_valid, errMessage = libxml2ex.xmlSchemaValidateOneElement (validation_context, xmlNodePtrChildWS, verbose)        
      else
        errMessage = xmlgeneral.invalidXML .. ". Unable to find the Operation tag in the 'soap:Body'"
      end      
    else      
      -- Get Root Element, which is <soap:Envelope>
      local xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xml_doc);
      if xmlNodePtrRoot ~= ffi.NULL then
        kong.log.debug ("XSD validation ".. schemaType .." part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrRoot, 1, 1))
        
        -- Check validity of XML with its XSD schema
        is_valid, errMessage = libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc, verbose)        

      else
        errMessage = xmlgeneral.invalidXML .. ". Unable to find the 'soap:Envelope'"
      end
    end
  else
    -- If it's the Request Plugin
    if pluginType == xmlgeneral.RequestTypePlugin then
      -- The error is related to the 'Server'
      soapFaultCode = xmlgeneral.soapFaultCodeServer
    end
    errMessage = xmlgeneral.invalidXSD .. ". " .. errMessage
  end
    
  if not errMessage and is_valid == 0 then
    kong.log.debug ("XSD validation of " ..schemaType.. " schema: Ok, END")
  elseif errMessage then
    -- If 'is_valid' returns a 'No matching global declaration available for the validation root' => returns false (wrong schema)
    -- Else => returns true that indicates that the right schema has been found
    if  is_valid == xmlgeneral.libxmlNoMatchGlobalDecl then
      XMLXSDMatching = false 
    else 
      XMLXSDMatching = true
    end
    kong.log.debug ("XSD validation of " ..schemaType.. " RC: " ..is_valid..
                    " matching of XML and XSD: " .. tostring (XMLXSDMatching) .. ", schema: Ko, " .. errMessage .. ", END")
  else
    errMessage = "Ko"
    kong.log.debug ("XSD validation of " .. schemaType .. " schema: " .. errMessage .. ", END")
  end

  return errMessage, XMLXSDMatching, soapFaultCode
end

--------------------------------------------------------------------------------------------------------
-- Get the 'SOAPAction' value from WSDL related to the Operation Name (retrieved from the SOAP Request)
--------------------------------------------------------------------------------------------------------
function xmlgeneral.getSOAPActionFromWSDL (pluginId, WSDL, request_OperationName, xmlnsSOAPEnvelope_hRef, verbose, async)

  local wsdlDefinitions_type  = xmlgeneral.Unknown_WSDL
  local context               = nil
  local object                = nil
  local errMessage            = nil
  local errXPathSoapAction    = nil
  local xmlWSDL_doc           = nil
  local xmlWSDLNodePtrRoot    = nil
  local nodeName              = nil
  local parserCtx             = nil
  local document              = nil
  local xpathReqRoot          = nil
  local xpathReqSoapAction    = nil
  local xpathReqRequired      = nil
  local wsdlRaw_namespaces    = nil
  local wsdlNS1_1             = nil
  local wsdlNS2_0             = nil
  local wsamNS                = nil
  local wsdlNS_SOAP           = nil
  local wsdlNS_SOAP1_1        = nil
  local wsdlNS_SOAP1_2        = nil
  local wsdlSoapAction_Value  = nil
  local targetNamespace       = nil
  local interfaceName         = nil
  local pattern               = nil
  local wsdlRequired_Value    = false
  local wsdl2_0_ActionFound   = false
  local rc                    = false
  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING)
  
  -- If asnchronous download is enabled (the WSDL is not cached)
  if async then
    -- Parse an XML in-memory document of the WSDL and build a tree
    kong.log.debug ("getSOAPActionFromWSDL: no WSDL caching due to Asynchronous external entities")
    xmlWSDL_doc, errMessage = libxml2ex.xmlReadMemory(WSDL, nil, nil, default_parse_options, verbose, false)  
  else 
    -- Get the WSDL Cache table
    kong.log.debug ("getSOAPActionFromWSDL: caching: Get the compiled WSDL from cache")
    xmlWSDL_doc = kong.xmlSoapPtrCache.plugins[pluginId].WSDLs[xmlgeneral.schemaTypeAPI].xmlWsdlPtr
  end
  
  -- If the XML Tree document of WSDL is not in the cache
  if xmlWSDL_doc == nil or xmlWSDL_doc == ffi.NULL then
    -- This code should never happen because if the pointer is null it will be raised before by 'xmlgeneral.XMLValidateWithWSDL'
    return wsdlSoapAction_Value, wsdlRequired_Value, (errMessage or "Unable to get the XML Tree document of WSDL is not in the cache")
  end

  -- Get the SOAP Action Cache table  
  local cacheSoapAction = kong.xmlSoapPtrCache.plugins[pluginId].soapAction
  
  -- If wsdlDefinitions_type is not in the cache and If there is no Error from Cache
  if not cacheSoapAction.wsdlDefinitions_type and not cacheSoapAction.wsdlDefinitions_typeError then
    -- Retrieve:
    --  For WSDL 1.1 <wsdl:definitions> node
    --  For WSDL 2.0 <wsdl:description> node
    kong.log.debug ("getSOAPActionFromWSDL: caching: Retrieve 'wsdlDefinitions_type' from WSDL and Put it in the cache")
    xmlWSDLNodePtrRoot = libxml2.xmlDocGetRootElement(xmlWSDL_doc)
    if xmlWSDLNodePtrRoot then
      if tonumber(xmlWSDLNodePtrRoot.type) == ffi.C.XML_ELEMENT_NODE then
        nodeName = ffi.string(xmlWSDLNodePtrRoot.name)
        if     nodeName == "definitions" then
          kong.log.debug("getSOAPActionFromWSDL: <definitions> for WSDL 1.1 found")
          wsdlDefinitions_type = xmlgeneral.WSDL1_1
        elseif nodeName == "description" then
          kong.log.debug("getSOAPActionFromWSDL: <description> for WSDL 2.0 found")
          wsdlDefinitions_type = xmlgeneral.WSDL2_0
        end
      end
    end

    if wsdlDefinitions_type ~= xmlgeneral.Unknown_WSDL then
      -- Get the List of all NameSpaces of the WSDL and find the NameSpace related to WSDL and SOAP 1.1 and SOAP 1.2
      wsdlRaw_namespaces = libxml2.xmlGetNsList(xmlWSDL_doc, xmlWSDLNodePtrRoot)
      local i = 0
      while wsdlRaw_namespaces and wsdlRaw_namespaces[i] ~= ffi.NULL and wsdlRaw_namespaces[i].href ~= ffi.NULL do
        -- WSDL 1.1 namespace (example: wsdl)
        if     ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSDL1_1 then
          if wsdlRaw_namespaces[i].prefix ~= ffi.NULL then
            wsdlNS1_1 = ffi.string(wsdlRaw_namespaces[i].prefix)
          else
            -- There is no prefix for the 'wsdl' Namespace: we put an arbitrary value for 'xmlXPathRegisterNs'
            wsdlNS1_1 = "wsdl11_kong"
          end
        -- WSDL 2.0 namespace (example: wsdl2)
        elseif ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSDL2_0 then
          if wsdlRaw_namespaces[i].prefix ~= ffi.NULL then
            wsdlNS2_0 = ffi.string(wsdlRaw_namespaces[i].prefix)
          else
            -- There is no prefix for the 'wsdl' Namespace: we put an arbitrary value for 'xmlXPathRegisterNs'
            wsdlNS2_0 = "wsdl20_kong"
          end
        -- WSAM: WS-Addressing Metadata namespace
        elseif ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSAM then
          if wsdlRaw_namespaces[i].prefix ~= ffi.NULL then
            wsamNS = ffi.string(wsdlRaw_namespaces[i].prefix)
          else
            -- There is no prefix for the 'wsam' Namespace: we put an arbitrary value for 'xmlXPathRegisterNs'
            wsamNS = "wsam_kong"
          end        
        -- SOAP 1.1 NameSpace (example: soap)        
        elseif ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSDL1_1_SOAP1_1 then
          if wsdlRaw_namespaces[i].prefix ~= ffi.NULL then
            wsdlNS_SOAP1_1 = ffi.string(wsdlRaw_namespaces[i].prefix)
          else
            -- There is no prefix for the 'SOAP 1.1' Namespace: we put an arbitrary value for 'xmlXPathRegisterNs'
            wsdlNS_SOAP1_1 = "soap11_kong"
          end
        -- SOAP 1.2 NameSpace (example: soap12)
        elseif ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSDL1_1_SOAP1_2 then
          if wsdlRaw_namespaces[i].prefix ~= ffi.NULL then
            wsdlNS_SOAP1_2 = ffi.string(wsdlRaw_namespaces[i].prefix)
          else
            -- There is no prefix for the 'SOAP 1.1' Namespace: we put an arbitrary value for 'xmlXPathRegisterNs'
            wsdlNS_SOAP1_2 = "soap12_kong"
          end
        end
        i = i + 1
      end
      cacheSoapAction.wsdlDefinitions_type  = wsdlDefinitions_type
      cacheSoapAction.wsdlNS_SOAP1_1        = wsdlNS_SOAP1_1
      cacheSoapAction.wsdlNS_SOAP1_2        = wsdlNS_SOAP1_2
      cacheSoapAction.wsdlNS1_1             = wsdlNS1_1
      cacheSoapAction.wsdlNS2_0             = wsdlNS2_0
      cacheSoapAction.wsamNS                = wsamNS

    -- Else we don't find the <definitions> or <description>
    else
      errMessage = "Unable to find the 'wsdl:definitions' for WSDL 1.1 or 'wsdl2:description' for WSDL 2.0 in the WSDL definition"
      cacheSoapAction.wsdlDefinitions_typeError = errMessage
      kong.log.debug(errMessage)
    end
  -- Get from cache the wsdlDefinitions_type
  else
    kong.log.debug ("getSOAPActionFromWSDL: caching: Get 'wsdlDefinitions_type' from the cache")
    wsdlDefinitions_type  = cacheSoapAction.wsdlDefinitions_type
    errMessage            = cacheSoapAction.wsdlDefinitions_typeError
    wsdlNS_SOAP1_1        = cacheSoapAction.wsdlNS_SOAP1_1
    wsdlNS_SOAP1_2        = cacheSoapAction.wsdlNS_SOAP1_2
    wsdlNS1_1             = cacheSoapAction.wsdlNS1_1
    wsdlNS2_0             = cacheSoapAction.wsdlNS2_0
    wsamNS                = cacheSoapAction.wsamNS
  end
  
  if not errMessage then
      kong.log.debug("getSOAPActionFromWSDL: NameSpaces found: WSDL='" .. (wsdlNS1_1 or wsdlNS2_0 or 'nil') .. 
    "', WS-Addressing_Metadata='" .. (wsamNS or 'nil') .. 
    "', SOAP1.1='" .. (wsdlNS_SOAP1_1 or 'nil') .. 
    "', SOAP1.2='" .. (wsdlNS_SOAP1_2 or 'nil') .. "'")
  end

  -- Create ParserContext and XPathNewContext
  if not errMessage then

    -- If the XPath New Context is not in the cache and If there is no Context Error from Cache
    --  AND
    -- If the XPath Document is not in the cache and If there is no Document Error from Cache
    if not cacheSoapAction.contextPtr and not cacheSoapAction.contextErrMsg and
       not cacheSoapAction.document   and not cacheSoapAction.documentErrMsg then
      kong.log.debug ("getSOAPActionFromWSDL: caching: Compile 'contextPtr' and 'document' and Put them in the cache")
      parserCtx = libxml2.xmlNewParserCtxt()
      document  = libxml2.xmlCtxtReadMemory(parserCtx, WSDL)      
      if document then
        context = libxml2.xmlXPathNewContext(document)
        if not context then
          errMessage = "xmlXPathNewContext, no 'context' for the WSDL"
          cacheSoapAction.contextErrMsg = errMessage
          kong.log.debug(errMessage)
        end
      else
        errMessage = "xmlCtxtReadMemory, no 'document' for the WSDL"
        cacheSoapAction.documentErrMsg = errMessage
        kong.log.debug(errMessage)
      end
      cacheSoapAction.parserCtxPtr  = parserCtx
      cacheSoapAction.document      = document
      cacheSoapAction.contextPtr    = context      
    else
      kong.log.debug ("getSOAPActionFromWSDL: caching: Get 'contextPtr' and 'document' from the cache")
      parserCtx  = cacheSoapAction.parserCtxPtr
      document   = cacheSoapAction.document
      context    = cacheSoapAction.contextPtr
      if cacheSoapAction.documentErrMsg then
        errMessage = cacheSoapAction.documentErrMsg
      elseif cacheSoapAction.contextErrMsg then
        errMessage = cacheSoapAction.contextErrMsg
      else
        errMessage = nil  
      end
    end
  end

  -- In the WSDL 1.1 we have to find the right '<binding>' linked with the OperationName (set in <soap:Body> of the Request)
  -- and related to HTTP transport='http://schemas.xmlsoap.org/soap/http'
  -- and NOT related to other transports (like JMS: http://cxf.apache.org/transports/jms)
  -- 
  -- WSDL 1.1 Example: 
  -- <wsdl:definitions>
  --   <wsdl:binding name="JMSCalculatorSoap" type="tns:CalculatorSoap">
  --    <soap:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
  --     <wsdl:operation name="Add"/>
  --   <wsdl:binding
  --   <wsdl:binding name="CalculatorSoap" type="tns:CalculatorSoap">
  --     <soap:binding transport="http://schemas.xmlsoap.org/soap/http" />
  --     <wsdl:operation name="Add">
  --       <soap:operation soapAction="http://tempuri.org/Add" style="document" />
  --   <wsdl:binding name="CalculatorSoap12" type="tns:CalculatorSoap">
  --     <soap12:binding transport="http://schemas.xmlsoap.org/soap/http" />
  --     <wsdl:operation name="Add">
  --       <soap12:operation soapAction="http://tempuri.org/Add" style="document" />
  -- **************************
  -- In the WSDL 2.0 we have to find the right '<input>' linked with the OperationName (set in <soap:Body> of the Request)
  -- <wsdl2:description>
  --  <interface  name = "AddInterface" >
  --    <wsdl2:operation name="Add" pattern="http://www.w3.org/ns/wsdl/in-out" style="http://www.w3.org/ns/wsdl/style/iri">
  --      <input    messageLabel="In"  element="stns:AddSoapIn"  wsam:Action="http://tempuri.org/Add"/>
  -- **************************
  -- For WSDL 1.1 / WSDL 2.0: the SOAPAction/Action Must be related to operationName=Add (found in the SOAP/XML body Request)
  
  -- Register the NameSpaces to make an XPath expression
  if not errMessage then
    -- If the Register NS is not in the cache and If there is no Error from Cache
    if (not cacheSoapAction.registerNs_RC and
        not cacheSoapAction.registerNs_ErrMsg) then
      rc = true
      -- If it's a WSDL 1.1, register the NameSpaces related to WSDL 1.0, SOAP 1.1 or SOAP 1.2
      if wsdlDefinitions_type == xmlgeneral.WSDL1_1 then
        if wsdlNS1_1 then
          rc = libxml2.xmlXPathRegisterNs(context, wsdlNS1_1, xmlgeneral.schemaWSDL1_1)
        end
        -- If we found the SOAP 1.1 in WSDL and If we have to register the SOAP 1.1 Namespace (in relation with <soap:Envelope> Request)
        if rc and wsdlNS_SOAP1_1 and xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_1 then
          wsdlNS_SOAP = wsdlNS_SOAP1_1
          rc = libxml2.xmlXPathRegisterNs(context, wsdlNS_SOAP1_1, xmlgeneral.schemaWSDL1_1_SOAP1_1)
        end
        -- If we found the SOAP 1.2 in WSDL and If we have to register the SOAP 1.2 Namespace (in relation with <soap12:Envelope> Request)
        if rc and wsdlNS_SOAP1_2 and xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_2 then
          wsdlNS_SOAP = wsdlNS_SOAP1_2
          rc = libxml2.xmlXPathRegisterNs(context, wsdlNS_SOAP1_2, xmlgeneral.schemaWSDL1_1_SOAP1_2)
        end

      -- Else if it's a WSDL 2.0: Register the NameSpaces related to WSDL 2.0 and WS-Addressing Metadata
      elseif wsdlDefinitions_type == xmlgeneral.WSDL2_0 then
        if wsdlNS2_0 then
          rc = libxml2.xmlXPathRegisterNs(context, wsdlNS2_0, xmlgeneral.schemaWSDL2_0)
        end
        if rc and wsamNS then
          rc = libxml2.xmlXPathRegisterNs(context, wsamNS, xmlgeneral.schemaWSAM)
        end
      end
            
      if not rc then
        errMessage = "Failure registering NameSpaces for the XPath expression"
        kong.log.debug(errMessage)
      end

      cacheSoapAction.registerNs_RC     = rc
      cacheSoapAction.registerNs_ErrMsg = errMessage
      cacheSoapAction.wsdlNS_SOAP       = wsdlNS_SOAP
    else
      rc          = cacheSoapAction.registerNs_RC
      errMessage  = cacheSoapAction.registerNs_ErrMsg
      wsdlNS_SOAP = cacheSoapAction.wsdlNS_SOAP
    end
  end
  
  -- Check the NameSpaces presence in the WSDL
  if not errMessage then    
    -- If it's a WSDL 1.1, check the NameSpaces presence related to WSDL 1.1, SOAP 1.1 or SOAP 1.2
    if wsdlDefinitions_type == xmlgeneral.WSDL1_1 then
      -- If the WSDL Namespace prefix is not defined in the WSDL
      if wsdlNS1_1 == nil then
        errMessage = "Unable to find (in the WSDL 1.1) the Namespace prefix linked with the WSDL: '" .. xmlgeneral.schemaWSDL1_1 .. "'" 
      -- Else If the SOAP Namespace of the <soap:Envelope> Request is SOAP 1.1 and the SOAP 1.1 Namespace is not found in the WSDL
      elseif xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_1 and not wsdlNS_SOAP1_1 then
        errMessage = "Unable to find (in the WSDL 1.1) the Namespace prefix linked with the SOAP 1.1 Request: '" .. xmlgeneral.schemaWSDL1_1_SOAP1_1 .. "'"
      -- Else If the SOAP Namespace of the <soap:Envelope> Request is SOAP 1.2 and the SOAP 1.2 Namespace is not found in the WSDL
      elseif xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_2 and not wsdlNS_SOAP1_2 then
        errMessage = "Unable to find (in the WSDL 1.1) the Namespace prefix linked with the SOAP 1.2 Request: '" .. xmlgeneral.schemaWSDL1_1_SOAP1_2 .. "'"
      end
    -- Else if it's a WSDL 2.0, check the NameSpaces related to WSDL 2.0
    elseif wsdlDefinitions_type == xmlgeneral.WSDL2_0 then
      -- If the WSDL Namespace prefix is not defined in the WSDL
      if wsdlNS2_0 == nil then
        errMessage = "Unable to find (in the WSDL 2.0) the Namespace prefix linked with the WSDL: '" .. xmlgeneral.schemaWSDL2_0 .. "'" 
      elseif wsamNS == nil then
        errMessage = "Unable to find (in the WSDL 2.0) the Namespace prefix linked with the WSAM: '" .. xmlgeneral.schemaWSAM .. "'" 
      end
    end
    if errMessage then
      kong.log.debug(errMessage)
    end
  end
  
  -- WSDL 1.1: Execute the XPath expression to find the 'soapAction' attribute value and 
  -- the 'soapActionRequired' optional value in the WSDL
  if not errMessage and wsdlDefinitions_type == xmlgeneral.WSDL1_1 then
    -- Example: /wsdl:definitions/wsdl:binding/soap12:binding[@transport="http://schemas.xmlsoap.org/soap/http"]/parent::wsdl:binding/wsdl:operation[@name="Add"]/soap12:operation/@soapAction
    xpathReqRoot = "/"..wsdlNS1_1..":definitions/"..wsdlNS1_1..":binding/"..wsdlNS_SOAP..":binding[@transport=\"" .. xmlgeneral.schemaHttpTransport .. "\"]"..
                        "/parent::"..wsdlNS1_1..":binding/"..wsdlNS1_1..":operation[@name=\"" .. request_OperationName .. "\"]/"..wsdlNS_SOAP..":operation/"
    xpathReqRequired   = xpathReqRoot .. "@soapActionRequired"
    xpathReqSoapAction = xpathReqRoot .. "@soapAction"

    -- Execute the XPath expression to find the 'soapActionRequired' optional attribute
    object = libxml2.xmlXPathEvalExpression(xpathReqRequired, context)    

    errXPathSoapAction = " | XPath expression='".. xpathReqRequired.. "'"
    if object ~= ffi.NULL then
      -- If we found the XPath element
      if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then
        if libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0]) == 'true' then
          wsdlRequired_Value = true
        else
          wsdlRequired_Value = false
        end
        kong.log.debug("getSOAPActionFromWSDL: 'soapActionRequired' found in the WSDL: '" ..tostring(wsdlRequired_Value).."'")
      else
        -- As the attribute is optional, there is no error
        kong.log.debug("getSOAPActionFromWSDL: the optional 'xpathReqRequired' attribute is not found" .. errXPathSoapAction)
      end
    else
      errMessage = "Invalid XPath expression for 'soapActionRequired' attribute"
      kong.log.err(errMessage .. errXPathSoapAction)
    end

    if not errMessage then
      -- Execute the XPath expression to find the 'soapAction' attribute
      object = libxml2.xmlXPathEvalExpression(xpathReqSoapAction, context)
      errXPathSoapAction = " | XPath expression='" .. xpathReqSoapAction .. "'"

      if object ~= ffi.NULL then
        wsdlSoapAction_Value = nil
        -- If we found the XPath element
        if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then
          wsdlSoapAction_Value = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
        end
        
        -- If 'soapAction' attribute has a content
        if wsdlSoapAction_Value and wsdlSoapAction_Value ~= '' then
          kong.log.debug("getSOAPActionFromWSDL: 'soapAction' found in the WSDL: '" .. wsdlSoapAction_Value .. "'")
        else
          errMessage = "Unable to get the value of '"..wsdlNS_SOAP..":operation soapAction' attribute in the WSDL linked with '" ..request_OperationName.. "' Operation name"
          kong.log.err(errMessage ..  errXPathSoapAction)
        end
      else
        errMessage = "Invalid XPath expression for 'soapAction'"
        kong.log.err(errMessage .. errXPathSoapAction)
      end
    end

  -- Else WSDL 2.0: Execute the XPath expression to find the 'Action' attribute value
  -- See RFC: https://www.w3.org/TR/2007/REC-ws-addr-metadata-20070904/#explicitaction
  elseif not errMessage and wsdlDefinitions_type == xmlgeneral.WSDL2_0 then
    wsdlRequired_Value  = true
    -- Example: /wsdl:description/wsdl:interface/wsdl:operation[@name='Add']/wsdl:input[@messageLabel='In']/@wsam:Action
    xpathReqSoapAction = "/"..wsdlNS2_0..":description/"..wsdlNS2_0..":interface/"..wsdlNS2_0..":operation[@name=\"" .. 
                        request_OperationName .. "\"]/"..wsdlNS2_0..":input[@messageLabel='In']/@"..wsamNS..":Action"
    
    object = libxml2.xmlXPathEvalExpression(xpathReqSoapAction, context)
    errXPathSoapAction = " | XPath expression='" .. xpathReqSoapAction .. "'"

    if object ~= ffi.NULL then
      wsdlSoapAction_Value = nil
      -- If we found the XPath element
      if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then
        wsdlSoapAction_Value = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
      end
      
      -- If 'Action' attribute has a content
      if wsdlSoapAction_Value and wsdlSoapAction_Value ~= '' then        
        wsdl2_0_ActionFound = true
        kong.log.debug("getSOAPActionFromWSDL: 'Action' found in the WSDL: '" .. wsdlSoapAction_Value .. "'")
      else
        -- Here it's not an error because 'Action' attribute is optional
        kong.log.debug("getSOAPActionFromWSDL: No 'Action' attribute in the WSDL linked with '" ..request_OperationName.. "' Operation name" .. errXPathSoapAction .. ". Apply the default 'Action' pattern")
      end      
    else
      errMessage = "Invalid XPath expression 'Action'"
      kong.log.err(errMessage .. errXPathSoapAction)
    end
    -- If the Action is not found: apply the 'Default Action Pattern for WSDL 2.0'
    if not errMessage and not wsdl2_0_ActionFound then
      -- Find the 'targetNamespace'
      -- Example: /wsdl:description/@targetNamespace
      xpathReqSoapAction = "/"..wsdlNS2_0..":description/@targetNamespace"
      object = libxml2.xmlXPathEvalExpression(xpathReqSoapAction, context)
      errXPathSoapAction = " | XPath expression='" .. xpathReqSoapAction .. "'"
      if object ~= ffi.NULL then
        if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then
          targetNamespace = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
        end
        -- If 'targetNamespace' has not content
        if not targetNamespace or targetNamespace == '' then
          errMessage = "Unable to get the value of 'targetNamespace' attribute in the WSDL" .. errXPathSoapAction
        end
      else
        errMessage = "Invalid XPath expression for 'targetNamespace'" .. errXPathSoapAction
      end
      -- Find the 'interface' Name
      -- Example: /wsdl:description/wsdl:interface/wsdl:operation[@name='Add']/parent::wsdl:interface/@name
      if not errMessage then
        xpathReqSoapAction = "/"..wsdlNS2_0..":description/"..wsdlNS2_0..":interface/"..wsdlNS2_0..
                             ":operation[@name=\""..request_OperationName.. "\"]/parent::"..wsdlNS2_0..":interface/@name"
        object = libxml2.xmlXPathEvalExpression(xpathReqSoapAction, context)
        errXPathSoapAction = " | XPath expression='" .. xpathReqSoapAction .. "'"
        if object ~= ffi.NULL then
          if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then
            interfaceName = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
          end
          -- If 'interfaceName' has not content
          if not interfaceName or interfaceName == '' then
            errMessage = "Unable to get the value of 'interface' name in the WSDL" .. errXPathSoapAction
          end
        else
          errMessage = "Invalid XPath expression for 'interface' name" .. errXPathSoapAction
        end
      end
      -- Find the 'pattern' Attribute
      -- Example: /wsdl:description/wsdl:interface/wsdl:operation[@name='Add']/@pattern
      if not errMessage then
        xpathReqSoapAction = "/"..wsdlNS2_0..":description/"..wsdlNS2_0..":interface/"..wsdlNS2_0..
                             ":operation[@name=\""..request_OperationName.. "\"]/@pattern"
        object = libxml2.xmlXPathEvalExpression(xpathReqSoapAction, context)
        errXPathSoapAction = " | XPath expression='" .. xpathReqSoapAction .. "'"
        if object ~= ffi.NULL then
          if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then
            pattern = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
          end
          -- If 'pattern' has not content
          if not pattern or pattern == '' then
            errMessage = "Unable to get the value of 'pattern' attribute in the WSDL" .. errXPathSoapAction
          -- Else if the 'pattern' has inconsistent values regarding W3C (https://www.w3.org/TR/2007/REC-ws-addr-metadata-20070904/#defactionwsdl20)
          elseif  pattern ~= xmlgeneral.schemaWSDL_WSAM_in_out and
                  pattern ~= xmlgeneral.schemaWSDL_WSAM_in_out_opt then
            errMessage = "the 'pattern' found in WSDL is '" ..pattern.. "' and must be '"..xmlgeneral.schemaWSDL_WSAM_in_out.."' or " ..
                        "'"..xmlgeneral.schemaWSDL_WSAM_in_out_opt.."'"
          end
        else
          errMessage = "Invalid XPath expression for 'pattern' attribute" .. errXPathSoapAction
        end
      end
      kong.log.debug( "getSOAPActionFromWSDL: Names and Attributes found in WSDL for 'Default Action Pattern for WSDL':" ..
      "', targetNamespace='" .. (targetNamespace or 'nil') .. 
      "', interface='"       .. (interfaceName or 'nil') .. 
      "', pattern='"         .. (pattern or 'nil') .. "'")

      if not errMessage then
        local delimiter
        if string.find(targetNamespace, "/") then 
          delimiter = "/"
          -- If the last character is '/' we remove it
          if targetNamespace:sub(-1) == '/' then
            targetNamespace = string.sub(targetNamespace, 1, -2)
          end
        else
          delimiter = "."    
        end
        
        local directionToken = "Request"
        wsdlSoapAction_Value = targetNamespace ..delimiter.. interfaceName ..delimiter.. request_OperationName .. directionToken
      end
    end
  end

  return wsdlSoapAction_Value, wsdlRequired_Value, errMessage
end

-------------------------------------------------
-- Get the Operation Name from the SOAP Envelope
-- Exemple: OperationName='Add'
--   <soap:Envelope xmlns:xsi=....">
--      <soap:Body>
--        <Add xmlns="http://tempuri.org/">      
-------------------------------------------------
function xmlgeneral.getOperationNameFromSOAPEnvelope (xmlRequest_doc, verbose)
  local errMessage
  local xmlNodePtrRoot
  local currentNode
  local nodeName
  local operationName
  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING)
  
  xmlRequest_doc, errMessage = libxml2ex.xmlReadMemory(xmlRequest_doc, nil, nil, default_parse_options, verbose, false)

  if not errMessage then
    -- Get root element '<soap:Envelope>' from the SOAP Request
    xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xmlRequest_doc)
    if not xmlNodePtrRoot or xmlNodePtrRoot.name == ffi.NULL or (xmlNodePtrRoot.name ~= ffi.NULL and ffi.string(xmlNodePtrRoot.name)) ~= "Envelope"  then
      errMessage = "Unable to find 'soap:Envelope'"
    end
  end
  
  -- Get the Operation Name in '<soap:Body>' (for instance '<Add>')
  if not errMessage then
    currentNode = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
    -- Retrieve '<soap:Body>' Node
    while currentNode ~= ffi.NULL do
      if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE and currentNode.name ~= ffi.NULL then
        nodeName = ffi.string(currentNode.name)
        if nodeName == "Body" then
          break
        end
      end
      currentNode = ffi.cast("xmlNode *", currentNode.next)
    end
    if nodeName == "Body" then
      currentNode = libxml2.xmlFirstElementChild(currentNode)
      if currentNode ~= ffi.NULL and tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE and currentNode.name ~= ffi.NULL then
        operationName = ffi.string(currentNode.name)
      else
        errMessage = "Unable to find the Operation Name inside 'soap:Body'"
      end
    else
      errMessage = "Unable to find 'soap:Body'"
    end
  end
  return operationName, errMessage
end

------------------------------------
-- Validate the 'SOAPAction' header
------------------------------------
function xmlgeneral.validateSOAPAction_Header (pluginId, SOAPRequest, WSDL, SOAPAction_Header, verbose, async)
  local i
  local temp
  local xmlRequest_doc
  local xmlWSDL_doc
  local errMessage
  local raw_namespaces
  local xmlNodePtrRoot
  local xmlWSDLNodePtrRoot
  local currentNode
  local nodeName
  local SOAPAction11_Header_Value
  local SOAPAction12_Header_Value
  local tContent = {}
  local tAction = {}
  local SOAPAction_Header_Value
  local wsdlSOAPAction_Header_Value
  local request_OperationName
  local soapFaultCode         = xmlgeneral.soapFaultCodeClient
  local action12_found        = 0
  local nsSOAP_11_12_found    = 0
  local wsdlRequired_Value    = false
  local soapBody_found        = false
  local wsdlDefinitions_found = false
  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING)

  -- If 'SOAPAction' header doesn't have to be validated 
  if SOAPAction_Header == xmlgeneral.SOAPAction_Header_No then
    -- The validation of 'SOAPAction' header is not required. Return 'no error'
    return nil, soapFaultCode
  end

  -- Get 'SOAPAction' header for SOAP 1.1
  SOAPAction11_Header_Value = kong.request.get_header(xmlgeneral.SOAPAction)

  -- Get 'action' in Content-Type header for SOAP 1.2
  temp = kong.request.get_header("Content-Type")
  if temp ~= nil then    
    -- Split the Content-Type with semicolon character (;)
    -- Example: Content-Type:'text/xml;charset=utf-8;action="http://tempuri.org/Add"'
    for part in temp:gmatch("([^;%s]+)") do
      table.insert(tContent, part)
    end
    for i, entryContent in ipairs(tContent) do
      if string.find(entryContent, xmlgeneral.action .. "=") then
        action12_found = action12_found + 1
        -- We found 2 (or more) 'action'
        if action12_found > 1 then
          break
        end
        
        -- Split the 'action' with equal character (=)
        for part in (entryContent .. "="):gmatch('([^=]*)=') do
          table.insert(tAction, part)
        end
        if #tAction == 2 then
          SOAPAction12_Header_Value = tAction[2]
        end
      end
    end
  end

  -- If multiple 'action' have been found 
  --   OR
  -- If one 'action' has ben found but it isn't correctly defined
  if action12_found >= 2 or (action12_found == 1 and SOAPAction12_Header_Value == nil) then
    errMessage = "'action' has been found in Content-Type header but it's not correctly defined"
  end

  if not errMessage then
    if SOAPAction11_Header_Value and SOAPAction12_Header_Value then
      errMessage = "'SOAPAction' for SOAP 1.1 and 'action' for SOAP 1.2 have been defined simultaneously"
    end
  end

  if SOAPAction11_Header_Value then
    SOAPAction_Header_Value = SOAPAction11_Header_Value
  elseif SOAPAction12_Header_Value then
    -- If required remove leading double-quote
    if string.sub(SOAPAction12_Header_Value, 1 , 1) == '"' then
      SOAPAction12_Header_Value = string.sub(SOAPAction12_Header_Value, 2)
      -- Remove trailing double-quote and don't check if it's really there;
      -- by doing that it will raise an error if there is a leading but no trailing double quote
      SOAPAction12_Header_Value = string.sub(SOAPAction12_Header_Value, 1, #SOAPAction12_Header_Value - 1)
    elseif string.sub(SOAPAction12_Header_Value, 1 , 1) == '\'' then
      SOAPAction12_Header_Value = string.sub(SOAPAction12_Header_Value, 2)
      SOAPAction12_Header_Value = string.sub(SOAPAction12_Header_Value, 1, #SOAPAction12_Header_Value - 1)
    end    
    SOAPAction_Header_Value = SOAPAction12_Header_Value
  end

  -- If 'SOAPAction' header is null and it's allowed by the plugin configuration
  if not errMessage then
    if SOAPAction_Header == xmlgeneral.SOAPAction_Header_Yes_Null and
      (SOAPAction_Header_Value == nil) then
      -- The validation of 'SOAPAction' header is not required. Return 'no error'
      return nil, soapFaultCode
    end
  end

  -- If there is no WSDL definition in the plugin configuration 
  if not errMessage then
    if not WSDL then
      errMessage = "No WSDL definition found: it's mandatory to validate the 'SOAPAction' header"
    end
  end
  
  -- Parse an XML in-memory document from the SOAP Request and build a tree
  if not errMessage then
    xmlRequest_doc, errMessage = libxml2ex.xmlReadMemory(SOAPRequest, nil, nil, default_parse_options, verbose, false)
  end

  -- Get root element '<soap:Envelope>' from the SOAP Request
  if not errMessage then
    xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xmlRequest_doc)
    if not xmlNodePtrRoot or xmlNodePtrRoot.name == ffi.NULL or
      (xmlNodePtrRoot.name ~= ffi.NULL and ffi.string(xmlNodePtrRoot.name) ~= "Envelope")  then
      errMessage = "Unable to find 'Envelope' tag"
    end
  end

  -- Get the List of all NameSpaces of the SOAP Request and find the NameSpace related to SOAP 1.1 or SOAP 1.2
  if not errMessage then
    raw_namespaces = libxml2.xmlGetNsList(xmlRequest_doc, xmlNodePtrRoot)
    i = 0
    while raw_namespaces and raw_namespaces[i] ~= ffi.NULL and raw_namespaces[i].href ~= ffi.NULL do
      if  ffi.string(raw_namespaces[i].href) == xmlgeneral.schemaSOAP1_1 then
        nsSOAP_11_12_found = xmlgeneral.SOAP1_1
      elseif ffi.string(raw_namespaces[i].href) == xmlgeneral.schemaSOAP1_2 then
        nsSOAP_11_12_found = xmlgeneral.SOAP1_2
      end
      if nsSOAP_11_12_found ~= 0 then
        break
      end
      i = i + 1
    end
    if nsSOAP_11_12_found == 0 then
      errMessage = "Unable to find the namespace of 'Envelope' tag. The expected values are '" .. 
                    xmlgeneral.schemaSOAP1_1 .. "'' or '" .. xmlgeneral.schemaSOAP1_2 .. "'"
    end
  end

  -- Check the right usage of SOAPAction/action regarding the Namespace (SOAP 1.1 / SOAP 1.2)
  if not errMessage then
    if  nsSOAP_11_12_found == xmlgeneral.SOAP1_1 and SOAPAction12_Header_Value then
      errMessage = "Found a SOAP 1.1 envelope and an 'action' field in the 'Content-Type' header linked with for SOAP 1.2"
    elseif nsSOAP_11_12_found == xmlgeneral.SOAP1_2 and SOAPAction11_Header_Value then
      errMessage = "Found a SOAP 1.2 envelope and a 'SOAPAction' header linked with for SOAP 1.1"
    end
  end

  -- Get the Operation Name in '<soap:Body>' (for instance '<Add>')
  if not errMessage then
    currentNode = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
    -- Retrieve '<soap:Body>' Node
    while currentNode ~= ffi.NULL do
      if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE and currentNode.name ~= ffi.NULL then
        nodeName = ffi.string(currentNode.name)
        if nodeName == "Body" then
          soapBody_found = true
          break
        end
      end
      currentNode = ffi.cast("xmlNode *", currentNode.next)
    end
    if soapBody_found then
      currentNode = libxml2.xmlFirstElementChild(currentNode)
      if currentNode ~= ffi.NULL and tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE and currentNode.name ~= ffi.NULL then
        request_OperationName = ffi.string(currentNode.name)
        kong.log.debug("validate 'SOAPAction' Header - Found in SOAP Request: operationName=" .. request_OperationName)
      else
        errMessage = "Unable to find the Operation Name inside 'Body' tag"
      end
    else
      errMessage = "Unable to find 'Body' tag"
    end
  end

  -- Get the 'SOAPAction' value from WSDL related to the Operation Name (retrieved from the SOAP Request)
  if not errMessage then
    wsdlSOAPAction_Header_Value, wsdlRequired_Value, errMessage = xmlgeneral.getSOAPActionFromWSDL(
                                                                    pluginId,
                                                                    WSDL, 
                                                                    request_OperationName,
                                                                    ffi.string(raw_namespaces[i].href),
                                                                    verbose,
                                                                    async)
    if not errMessage then
      if  SOAPAction_Header_Value == nil then
        -- If the WSDL has soapActionRequired="true" attribute
        if wsdlRequired_Value == true then
          errMessage = "The 'SOAPAction' header is not set but according to the WSDL this value is 'Required'"
        else
          -- No error, as the WSDL has soapActionRequired="false" or no soapActionRequired attribute (and the default value is "false")
        end
      -- Elseif there is a mismacth between the 'SOAPAction' header and the Operation name
      elseif wsdlSOAPAction_Header_Value ~= SOAPAction_Header_Value then
        errMessage = "The Operation Name found in '"..ffi.string(raw_namespaces[i].prefix)..":Body' is '"..request_OperationName.."'. "..
                     "According to the WSDL the 'SOAPAction' should be '" .. (wsdlSOAPAction_Header_Value or '').. "' and not '" .. (SOAPAction_Header_Value or '').. "'"
      end
    end

  end
  
  if not errMessage then
    kong.log.debug("validate 'SOAPAction' Header - Successful validation of '" .. (SOAPAction_Header_Value or '') .. "' value")  
  else
    errMessage = "Validation of 'SOAPAction' header: " .. errMessage
    kong.log.debug (errMessage)
  end

  return errMessage, soapFaultCode
end

---------------------------------------------
-- Search a XPath and Compare it to a value
---------------------------------------------
function xmlgeneral.RouteByXPath (pluginId, XMLtoSearch, XPathRegisterNs, RouteXPathTargets)
  local rcXpath         = 0
  local rc              = false
  local parserCtx       = nil
  local context         = nil
  local document        = nil
  local errMessage      = nil

  kong.log.debug("RouteByXPath, XMLtoSearch: " .. XMLtoSearch)

  -- Get the 'Route By XPath' Cache table  
  local cacheRouteByXPath = kong.xmlSoapPtrCache.plugins[pluginId].routeByXPath
  
  -- If the Parser Context is not in the cache
  if not cacheRouteByXPath.parserCtxPtr then
    kong.log.debug ("RouteByXPath, caching: Create the Parser Context and Put it in the cache")
    parserCtx = libxml2.xmlNewParserCtxt()    
    cacheRouteByXPath.parserCtxPtr = parserCtx
  else
    kong.log.debug ("RouteByXPath, caching: Get the Parser Context from cache")
    parserCtx = cacheRouteByXPath.parserCtxPtr
  end

  document  = libxml2.xmlCtxtReadMemory(parserCtx, XMLtoSearch)
  
  if not document then
    errMessage = "RouteByXPath, xmlCtxtReadMemory error, no document"
    kong.log.err (errMessage)
  else      
    context = libxml2.xmlXPathNewContext(document)
    if not context then
      errMessage = "RouteByXPath, xmlXPathNewContext, no 'context'"
      kong.log.err(errMessage)
    end
  end
  
  if not errMessage then
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
      rc = false
      if prefix and uri then
        -- Register NameSpace
        rc = libxml2.xmlXPathRegisterNs(context, prefix, uri)
      end
      if rc then
        kong.log.debug("RouteByXPath, successful registering NameSpace for '" .. XPathRegisterNs[i] .. "'")
      else
        errMessage = "RouteByXPath, failure registering NameSpace for '" .. XPathRegisterNs[i] .. "'"
        kong.log.err(errMessage)
      end
    end
  end

  if not errMessage then
    -- Go on each Route XPath Target
    for i, RouteXPathTarget in pairs(RouteXPathTargets) do
      
      kong.log.debug ("RouteByXPath: XPath expression: '"..RouteXPathTarget.XPath.."'")
      local object = libxml2.xmlXPathEvalExpression(RouteXPathTarget.XPath, context)
      if object ~= ffi.NULL then
        
        -- If we found the XPath element
        if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then        
            local nodeContent = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
            kong.log.debug("libxml2.xmlNodeGetContent: " .. nodeContent)
            if nodeContent == RouteXPathTarget.XPathCondition then
              rcXpath = i
              break
            end
        else
          kong.log.debug ("RouteByXPath, object.nodesetval is null")  
        end
      else
        kong.log.debug ("RouteByXPath, object is null")
      end
    end
  end

  if rcXpath > 0 then
    kong.log.debug ("RouteByXPath: Ok, "..
                    "with XPath='" ..RouteXPathTargets[rcXpath].XPath.. 
                    "' and XPathCondition='" ..RouteXPathTargets[rcXpath].XPathCondition.."'")
  else
    kong.log.debug ("RouteByXPath: Ko, not having the proper XPath expression or the right condition")
  end
  return rcXpath
end

----------------------------------------------------
-- Function to split version string into components
----------------------------------------------------
local function split_version(version)
  local t = {}
  for part in version:gmatch("([^.]+)") do
      table.insert(t, tonumber(part))
  end
  return t
end

----------------------------------------------------
-- Function to compare two version strings
-- If   version_B  <= version_A => it returns false
-- Else version_B  >  version_A => it returns true
----------------------------------------------------
function xmlgeneral.compare_versions(vA, vB)
  local vA_parts = split_version(vA)
  local vB_parts = split_version(vB)
  
  for i = 1, math.max(#vA_parts, #vB_parts) do
      local vA_part = vA_parts[i] or 0
      local vB_part = vB_parts[i] or 0
      if vA_part < vB_part then
          return true
      elseif vA_part > vB_part then
          return false
      end
  end
  return false
end

return xmlgeneral