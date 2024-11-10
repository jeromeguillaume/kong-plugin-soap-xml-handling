local xmlgeneral = {}

local ffi               = require("ffi")
local libxml2           = require("xmlua.libxml2")
local libxml2ex         = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
local libxslt           = require("kong.plugins.soap-xml-handling-lib.libxslt")
local libsaxon4kong     = require("kong.plugins.soap-xml-handling-lib.libsaxon4kong")

local loaded, xml2 = pcall(ffi.load, "xml2")
local loaded, xslt = pcall(ffi.load, "xslt")

xmlgeneral.HTTPCodeSOAPFault  = 500

xmlgeneral.RequestTypePlugin  = 1
xmlgeneral.ResponseTypePlugin = 2

xmlgeneral.RequestTextError   = "Request"
xmlgeneral.ResponseTextError  = "Response"
xmlgeneral.GeneralError       = "General process failed"
xmlgeneral.SepTextError       = " - "
xmlgeneral.XSLTError          = "XSLT transformation failed"
xmlgeneral.XSDError           = "XSD validation failed"
xmlgeneral.BeforeXSD          = " (before XSD validation)"
xmlgeneral.AfterXSD           = " (after XSD validation)"

xmlgeneral.schemaWSDL             = "http://schemas.xmlsoap.org/wsdl/"
xmlgeneral.schemaHttpTransport    = "http://schemas.xmlsoap.org/soap/http"
xmlgeneral.schemaSOAP1_1          = "http://schemas.xmlsoap.org/soap/envelope/"
xmlgeneral.schemaSOAP1_2          = "http://www.w3.org/2003/05/soap-envelope"
xmlgeneral.schemaWSDL1_1_SOAP1_1  = "http://schemas.xmlsoap.org/wsdl/soap/"
xmlgeneral.schemaWSDL1_1_SOAP1_2  = "http://schemas.xmlsoap.org/wsdl/soap12/"
xmlgeneral.xmlnsXsdHref           = "http://www.w3.org/2001/XMLSchema"
xmlgeneral.xsdSchema          = "schema"
xmlgeneral.schemaTypeSOAP     = 0
xmlgeneral.schemaTypeAPI      = 2
xmlgeneral.XMLContentType     = "text/xml; charset=utf-8"
xmlgeneral.JSONContentType    = "application/json"
xmlgeneral.SOAPAction         = "SOAPAction"
xmlgeneral.SOAPAction_Header_No        = "no"
xmlgeneral.SOAPAction_Header_Yes_Null  = "yes_null_allowed"
xmlgeneral.SOAPAction_Header_Yes       = "yes"

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
  -- Replace " by '
  detailErrMsg = string.gsub(detailErrMsg, "\"", "'")

  -- If it's a SOAP/XML Request then the Fault Message is SOAP/XML text
  if contentTypeJSON == false then
    -- Replace '<' and '>' symbols by a full-text representation, thus avoiding incorrect XML parsing later
    detailErrMsg = string.gsub(detailErrMsg, "<", "Less Than")
    detailErrMsg = string.gsub(detailErrMsg, ">", "Greater Than")
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
-- Get the content type of the body by getting the first character:
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
local asyncPrefetch_Schema_Validation_callback = function(_, prefetchConf_entries)
  local errMessage
  local child
  local WSDL
  local verbose
  local xsdHashKey
  local rc = true
  kong.log.debug("asyncPrefetch_Schema_Validation_callback - Begin")
  
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
      errMessage = xmlgeneral.XMLValidateWithWSDL (_, child, nil, WSDL, verbose, true)
      
      -- If the prefetch succeeded
      if not errMessage then
        xsdHashKey.prefetchStatus = xmlgeneral.prefetchStatusOk
        xsdHashKey.duration = ngx.now() - xsdHashKey.started
        kong.log.debug("asyncPrefetch_Schema_Validation_callback: **Success** | duration=" .. xsdHashKey.duration)
      else
        kong.log.debug("asyncPrefetch_Schema_Validation_callback: err: " .. errMessage)
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
      kong.log.debug("asyncPrefetch_Schema_Validation_callback - Last status: " .. tostring(xsdHashKey.prefetchStatus) .. " Last message: " .. (errMessage or ''))
    
    -- Else the XSD 'hashKey' is not found in the 'entityLoader.hashKeys'
    else
      rc = false
      errMessage = "Unable to find XSD HashKey '" .. (prefetchConf_entry.xsdHashKey or "nil") .. "' in the 'entityLoader.hashKeys'"
      kong.log.debug("asyncPrefetch_Schema_Validation_callback: " .. errMessage)
    end
    ::continue::
  end
  return rc, errMessage
end

--------------------------------------------------------------------------------------
-- Process linked with the 'configure' phase
--  libxml -> Enable the prefetch Validation of SOAP Schema and WSDL/XSD Api Schemas
--            It concerns the new on and the existing schemas that previously failed
--------------------------------------------------------------------------------------
function xmlgeneral.pluginConfigure_XSD_Validation_Prefetch (plugin_id, config, requestTypePlugin, xsdSchemaInclude, child, queueName, queue_conf)

  local xsdHashKey = libxml2ex.hash_key(xsdSchemaInclude)
  -- If it's the 1st time the XSD API Schema is seen
  if kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey] == nil then
    kong.log.debug("XSD_Validation_Prefetch: it's the 1st time the XSD Schema is seen, hashKey=" .. xsdHashKey)
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey] = {
      prefetchStatus = xmlgeneral.prefetchStatusInit,
      started  = ngx.now(),
      duration =  0

    }
  -- Else If the XSD Api Schema is already known and the Prefetch status is Ko
  elseif kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].prefetchStatus == xmlgeneral.prefetchStatusKo then
    kong.log.debug("XSD_Validation_Prefetch: the XSD Schema is known but the Prefetch status is Ko. Let's try another Prefetch, hashKey=" .. xsdHashKey)
    -- So let's try another Prefetch
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].prefetchStatus = xmlgeneral.prefetchStatusInit
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].started  = ngx.now()
    kong.xmlSoapAsync.entityLoader.hashKeys[xsdHashKey].duration =  0

  else
    -- Else If the XSD Api Schema is already known and the Prefetch status is Init/Running/Ok
    --   => Don't change anything
  end

  -- Set the information of the plugin using the Schema
  if requestTypePlugin == xmlgeneral.RequestTypePlugin then
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
      plugin_id = plugin_id,
      xsdHashKey = xsdHashKey,
      child = child
    }
    -- Asynchronously execute the Prefetch of External Entities
    local rc, err = kong.xmlSoapAsync.entityLoader.prefetchQueue.enqueue(queue_conf, asyncPrefetch_Schema_Validation_callback, nil , prefetchConf)            
    if err then
      kong.log.err("XSD_Validation_Prefetch, prefetchQueue: " .. err)
    end
  end
end

--------------------------------------------------------------------------------------
-- Process linked with the 'configure' phase
--  libxml -> Enable the prefetch Validation
--  saxon  -> If required load the 'saxon' library
--
-- If there is a change in Request  Plugins 'pluginConfigure' called
-- If there is a change in Response Plugins 'pluginConfigure' is called another time
--------------------------------------------------------------------------------------
function xmlgeneral.pluginConfigure (configs, requestTypePlugin)
  local saxon = false
  local iCount = 0

  if configs then
    local queueName
    
    if requestTypePlugin == xmlgeneral.RequestTypePlugin then
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
      if requestTypePlugin == xmlgeneral.RequestTypePlugin then
        entityHashKey.ReqPluginRemove = true
      else
        entityHashKey.ResPluginRemove = true
      end
      iCount = iCount + 1
    end
    kong.log.debug("pluginConfigure, BEGIN #entityLoader.hashKeys=" .. tostring(iCount))    
    
    -- Parse all instances of the plugin
    for _, config in ipairs(configs) do
      local plugin_id = config.__plugin_id
      
      -- If saxon library is enabled
      if config.xsltLibrary == 'saxon' then
        saxon = true
      end

      -- Check if there is 'xsdSoapSchemaInclude'
      local xsdSoapSchemaInclude = false
      if config.xsdSoapSchemaInclude then
        for k,v in pairs(config.xsdSoapSchemaInclude) do            
          xsdSoapSchemaInclude = true
          break
        end
      end

      -- Check if there is 'xsdApiSchemaInclude'
      local xsdApiSchemaInclude = false
      if config.xsdApiSchemaInclude then
        for k,v in pairs(config.xsdApiSchemaInclude) do            
          xsdApiSchemaInclude = true
          break
        end
      end
      
      -- If Kong 'stream_listen' is enabled the 'kong.ctx.shared' is not properly set
      -- the Schema included in the plugin conf or the Asynchronous download can't work
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
          xmlgeneral.pluginConfigure_XSD_Validation_Prefetch (plugin_id, config, requestTypePlugin, config.xsdSoapSchema, xmlgeneral.schemaTypeSOAP, queueName, queue_conf)
        end

        -- If an API XSD Schema is defined and
        -- If the XSD content is NOT included in the plugin configuration
        if      config.xsdApiSchema  and
            not xsdApiSchemaInclude then
          kong.log.debug("pluginConfigure, Validation Prefetch of API Schema")
          xmlgeneral.pluginConfigure_XSD_Validation_Prefetch (plugin_id, config, requestTypePlugin, config.xsdApiSchema, xmlgeneral.schemaTypeAPI, queueName, queue_conf)
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

  -- Check if there is 'xsdSchemaInclude'
  local xsdApiSchemaIncluded = false
  if xsdApiSchemaInclude then
    for k,v in pairs(xsdApiSchemaInclude) do            
      xsdApiSchemaIncluded = true
      break
    end
  end

  -- If Asynchronous is enabled and 
  -- If XSD content is NOT included in the plugin configuration
  if  ExternalEntityLoader_Async and 
      not xsdApiSchemaIncluded   then
    
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
    -- see example in the repo: _tmp.xslt.transformation/xslt-v3-tester_kong_json-to-xml_with_template.xslt
    -- xsltSaxonTemplate='main' and xsltSaxonTemplateParam='request-body'
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
  if child == xmlgeneral.schemaTypeSOAP then
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
      -- If we don't find <soap:Body>
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

--------------------------------------------------------------------------------------------------------
-- Get the 'SOAPAction' value from WSDL related to the Operation Name (retrieved from the SOAP Request)
--------------------------------------------------------------------------------------------------------
function xmlgeneral.getSOAPActionFromWSDL (WSDL, request_OperationName, xmlnsSOAPEnvelope_hRef, verbose)

  local rc                    = false
  local wsdlDefinitions_found = false
  local context               = nil
  local object                = nil
  local errMessage            = nil
  local xmlWSDL_doc           = nil
  local xmlWSDLNodePtrRoot    = nil
  local nodeName              = nil
  local parserCtx             = nil
  local document              = nil
  local xpathReqRoot          = nil
  local xpathReqSoapAction    = nil
  local xpathReqRequired      = nil
  local wsdlRaw_namespaces    = nil
  local wsdlNS                = nil
  local wsdlNS_SOAP           = nil
  local wsdlNS_SOAP1_1        = nil
  local wsdlNS_SOAP1_2        = nil
  local wsdlSoapAction_Value  = nil
  local wsdlRequired_Value    = false
  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING)

  -- Parse an XML in-memory document from the WSDL and build a tree
  xmlWSDL_doc, errMessage = libxml2ex.xmlReadMemory(WSDL, nil, nil, default_parse_options, verbose)
  if not errMessage then

    -- Retrieve the <wsdl:definitions>
    xmlWSDLNodePtrRoot = libxml2.xmlDocGetRootElement(xmlWSDL_doc)
    if xmlWSDLNodePtrRoot then
      if tonumber(xmlWSDLNodePtrRoot.type) == ffi.C.XML_ELEMENT_NODE then
        nodeName = ffi.string(xmlWSDLNodePtrRoot.name)
        if nodeName == "definitions" then
          wsdlDefinitions_found = true
        end
      end
    end

    if wsdlDefinitions_found then
      kong.log.debug("getSOAPActionFromWSDL: <wsdl:definitions> found")
      -- Get the List of all NameSpaces of the WSDL and find the NameSpace related to WSDL and SOAP 1.1 and SOAP 1.2
      wsdlRaw_namespaces = libxml2.xmlGetNsList(xmlWSDL_doc, xmlWSDLNodePtrRoot)
      local i = 0
      while wsdlRaw_namespaces and wsdlRaw_namespaces[i] ~= ffi.NULL do
        -- WSDL namespace (example: wsdl)
        if     ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSDL then
          wsdlNS = ffi.string(wsdlRaw_namespaces[i].prefix)
        -- SOAP 1.1 namespace (example: soap)        
        elseif ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSDL1_1_SOAP1_1 then
          wsdlNS_SOAP1_1 = ffi.string(wsdlRaw_namespaces[i].prefix)
        -- SOAP 1.2 namespace (example: soap12)
        elseif ffi.string(wsdlRaw_namespaces[i].href) == xmlgeneral.schemaWSDL1_1_SOAP1_2 then
          wsdlNS_SOAP1_2 = ffi.string(wsdlRaw_namespaces[i].prefix)
        end
        i = i + 1
      end
      kong.log.debug("getSOAPActionFromWSDL: NameSpaces found: WSDL='" .. (wsdlNS or 'nil') .. 
                      "', SOAP1.1='" .. (wsdlNS_SOAP1_1 or 'nil') .. 
                      "', SOAP1.2='" .. (wsdlNS_SOAP1_2 or 'nil') .. "'")
      
    -- Else we don't find the <wsdl:definitions>
    else
      errMessage = "Unable to find the 'wsdl:definitions' in the WSDL"
      kong.log.debug(errMessage)
    end
  end

  if not errMessage then
    parserCtx = libxml2.xmlNewParserCtxt()
    document  = libxml2.xmlCtxtReadMemory(parserCtx, WSDL)
    
    if document then
      context = libxml2.xmlXPathNewContext(document)
      if not context then
        errMessage = "xmlXPathNewContext, no 'context' for the WSDL"
        kong.log.debug(errMessage)
      end
    else
      errMessage = "xmlCtxtReadMemory, no 'document' for the WSDL"
      kong.log.debug(errMessage)
    end
  end

  -- In the WSDL we have to find the right '<wsdl:binding>' linked with the OperationName (set in <soap:Body> of the Request)
  -- and related to HTTP transport='http://schemas.xmlsoap.org/soap/http'
  -- and NOT related to other transports (like JMS: http://cxf.apache.org/transports/jms)
  -- 
  -- WSDL Example: 
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
  --  
  --   Must be related to operationName=Add (found in the SOAP/XML body Request)
  
  -- Register the NameSpaces to make a XPath request
  if not errMessage then
    rc = true
    if wsdlNS then
      rc = libxml2.xmlXPathRegisterNs(context, wsdlNS, xmlgeneral.schemaWSDL)
    end
    -- If we found the SOAP 1.1 in WSDL and If we have to register the SOAP 1.1 Namespace (in relation with <soap:Envelope> Request)
    if rc and wsdlNS_SOAP1_1 and xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_1 then
      wsdlNS_SOAP = wsdlNS_SOAP1_1
      rc = libxml2.xmlXPathRegisterNs(context, wsdlNS_SOAP1_1, xmlgeneral.schemaWSDL1_1_SOAP1_1)
    end
    -- If we found the SOAP 1.2 in WSDL and If we have to register the SOAP 1.2 Namespace (in relation with <soap:Envelope> Request)
    if rc and wsdlNS_SOAP1_2 and xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_2 then
      wsdlNS_SOAP = wsdlNS_SOAP1_2
      rc = libxml2.xmlXPathRegisterNs(context, wsdlNS_SOAP1_2, xmlgeneral.schemaWSDL1_1_SOAP1_2)
    end
    if not rc then
      errMessage = "Failure registering NameSpaces for the XPath request"
      kong.log.debug(errMessage)
    end
  end
  
  -- Check the NameSpaces prefix in the WSDL
  if not errMessage then
    -- If the WSDL Namespace prefix is not defined in the WSDL
    if not wsdlNS then
      errMessage = "Unable to find (in the WSDL) the Namespace prefix linked with the WSDL: '" .. xmlgeneral.schemaWSDL .. "'"  
    -- Else If the SOAP Namespace of the <soap:Envelope> Request is SOAP 1.1 and the SOAP 1.1 Namespace is not found in the WSDL
    elseif xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_1 and not wsdlNS_SOAP1_1 then
      errMessage = "Unable to find (in the WSDL) the Namespace prefix linked with the SOAP 1.1 Request: '" .. xmlgeneral.schemaWSDL1_1_SOAP1_1 .. "'"
    -- Else If the SOAP Namespace of the <soap:Envelope> Request is SOAP 1.2 and the SOAP 1.2 Namespace is not found in the WSDL
    elseif xmlnsSOAPEnvelope_hRef == xmlgeneral.schemaSOAP1_2 and not wsdlNS_SOAP1_2 then
      errMessage = "Unable to find (in the WSDL) the Namespace prefix linked with the SOAP 1.2 Request: '" .. xmlgeneral.schemaWSDL1_1_SOAP1_2 .. "'"
    end
    if errMessage then
      kong.log.debug(errMessage)
    end
  end
  
  -- Execute the XPath request to find the 'soapAction' attribute value and 
  -- the 'soapActionRequired' optional value in the WSDL
  if not errMessage then
    -- Example: /wsdl:definitions/wsdl:binding/soap12:binding[@transport="http://schemas.xmlsoap.org/soap/http"]/parent::wsdl:binding/wsdl:operation[@name="Add"]/soap12:operation/@soapAction
    xpathReqRoot = "/"..wsdlNS..":definitions/"..wsdlNS..":binding/"..wsdlNS_SOAP..":binding[@transport=\"" .. xmlgeneral.schemaHttpTransport .. "\"]"..
                        "/parent::"..wsdlNS..":binding/"..wsdlNS..":operation[@name=\"" .. request_OperationName .. "\"]/"..wsdlNS_SOAP..":operation/"
    xpathReqRequired   = xpathReqRoot .. "@soapActionRequired"
    xpathReqSoapAction = xpathReqRoot .. "@soapAction"
    kong.log.debug("getSOAPActionFromWSDL: the XPath request to get (from the WSDL) 'soapAction'= '"..xpathReqRoot.."', " ..
                    "'xpathReqRequired'= '"..xpathReqRequired .."'")

    -- Execute the XPath request to find the 'soapActionRequired' optional attribute
    object = libxml2.xmlXPathEvalExpression(xpathReqRequired, context)    
    local errXPathSoapAction = " | XPath request='".. xpathReqRequired.. "'"
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
        kong.log.debug("getSOAPActionFromWSDL: the optional 'xpathReqRequired' attribute is not found")
      end
    else
      errMessage = "Invalid XPath request 'soapActionRequired'"
      kong.log.err(errMessage .. errXPathSoapAction)
    end

    if not errMessage then
      -- Execute the XPath request to find the 'soapAction' attribute
      object = libxml2.xmlXPathEvalExpression(xpathReqSoapAction, context)
      local errXPathSoapAction = " | XPath request='" .. xpathReqSoapAction .. "'"

      if object ~= ffi.NULL then
        -- If we found the XPath element
        if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then
          wsdlSoapAction_Value = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
        else      
          errMessage = "No value for XPath request 'soapAction'"
          kong.log.err(errMessage .. errXPathSoapAction)
        end
        
        -- If 'soapAction' attribute has a content
        if wsdlSoapAction_Value and wsdlSoapAction_Value ~= '' then
          kong.log.debug("getSOAPActionFromWSDL: 'soapAction' found in the WSDL: '" .. wsdlSoapAction_Value .. "'")
        else
          errMessage = "Unable to get the value of '"..wsdlNS_SOAP..":operation soapAction' attribute in the WSDL linked with '" ..request_OperationName.. "' Operation name"
          kong.log.err(errMessage ..  errXPathSoapAction)
        end
      end      
    else
      errMessage = "Invalid XPath request 'soapAction'"
      kong.log.err(errMessage .. errXPathSoapAction)
    end
  
  end

  return wsdlSoapAction_Value, wsdlRequired_Value, errMessage
end

------------------------------------
-- Validate the 'SOAPAction' header
------------------------------------
function xmlgeneral.validateSOAPAction_Header (SOAPRequest, SOAPAction_Header_Value, WSDL, SOAPAction_Header, verbose)
  local i
  local xmlRequest_doc
  local xmlWSDL_doc
  local errMessage
  local raw_namespaces
  local xmlNodePtrRoot
  local xmlWSDLNodePtrRoot
  local currentNode
  local nodeName
  local wsdlSOAPAction_Header_Value
  local request_OperationName
  local wsdlRequired_Value    = false
  local soapBody_found        = false
  local nsSOAP_11_12_found    = false
  local wsdlDefinitions_found = false
  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING)

  -- If 'SOAPAction' header doesn't have to be validated 
  --   OR
  -- If 'SOAPAction' header is null and it's allowed by the plugin configuration
  if SOAPAction_Header == xmlgeneral.SOAPAction_Header_No or
    (SOAPAction_Header == xmlgeneral.SOAPAction_Header_Yes_Null and
    (SOAPAction_Header_Value == nil))
      then
    -- The validation of 'SOAPAction' header is not required. Return 'no error'
    return nil
  end

  -- If there is no WSDL definition in the plugin configuration 
  if not WSDL then
    errMessage = "No WSDL definition found: it's mandatory to validate the 'SOAPAction' header"
  end
  
  -- Parse an XML in-memory document from the SOAP Request and build a tree
  if not errMessage then
    xmlRequest_doc, errMessage = libxml2ex.xmlReadMemory(SOAPRequest, nil, nil, default_parse_options, verbose)
  end

  -- Get root element '<soap:Envelope>' from the SOAP Request
  if not errMessage then
    xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xmlRequest_doc)
    if not xmlNodePtrRoot or ffi.string(xmlNodePtrRoot.name) ~= "Envelope"  then
      errMessage = "Unable to find 'soap:Envelope'"
    end
  end

  -- Get the List of all NameSpaces of the SOAP Request and find the NameSpace related to SOAP 1.1 or SOAP 1.2
  if not errMessage then
    raw_namespaces = libxml2.xmlGetNsList(xmlRequest_doc, xmlNodePtrRoot)
    i = 0
    while raw_namespaces and raw_namespaces[i] ~= ffi.NULL do
      if  ffi.string(raw_namespaces[i].href) == xmlgeneral.schemaSOAP1_1 or
          ffi.string(raw_namespaces[i].href) == xmlgeneral.schemaSOAP1_2 then
            nsSOAP_11_12_found = true
        break
      end
      i = i + 1
    end
    if not nsSOAP_11_12_found then
      errMessage = "Unable to find the namespace of 'soap:Envelope'. The expected values are '" .. 
                    xmlgeneral.schemaSOAP1_1 .. "'' or '" .. xmlgeneral.schemaSOAP1_2 .. "'"
    end
  end

  -- Get the Operation Name in '<soap:Body>' (for instance '<Add>')
  if not errMessage then
    currentNode = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
    -- Retrieve '<soap:Body>' Node
    while currentNode ~= ffi.NULL do
      if tonumber(currentNode.type) == ffi.C.XML_ELEMENT_NODE then
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
      if currentNode ~= ffi.NULL then
        request_OperationName = ffi.string(currentNode.name)
        kong.log.debug("validate 'SOAPAction' Header - Found in SOAP Request: operationName=" .. request_OperationName)
      else
        errMessage = "Unable to find the Operation Name inside 'soap:Body'"
      end
    else
      errMessage = "Unable to find 'soap:Body'"
    end
  end

  -- Get the 'SOAPAction' value from WSDL related to the Operation Name (retrieved from the SOAP Request)
  if not errMessage then
    wsdlSOAPAction_Header_Value, wsdlRequired_Value, errMessage = xmlgeneral.getSOAPActionFromWSDL(
                                                                    WSDL, 
                                                                    request_OperationName,
                                                                    ffi.string(raw_namespaces[i].href),
                                                                    verbose)
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