local KongGzip = require("kong.tools.gzip")

-- handler.lua
local plugin = {
    PRIORITY = 70,
    VERSION = "1.2.0",
  }

local xmlgeneral = nil
local libxml2ex  = nil

-----------------------------------------------------------------------------------------
-- XSLT TRANSFORMATION - BEFORE XSD: Transform the XML response Before (XSD VALIDATION)
-- WSDL/XSD VALIDATION             : Validate XML request with its WSDL or XSD schema
-- XSLT TRANSFORMATION - AFTER XSD : Transform the XML response After (XSD VALIDATION)
-----------------------------------------------------------------------------------------
function plugin:responseSOAPXMLhandling(plugin_conf, soapEnvelope, contentTypeJSON)
  local soapEnvelopeTransformed
  local soapFaultBody
  local sleepForPrefetchEnd = false
  
  -- If there is 'XSLT Transformation Before XSD' configuration then:
  -- => we apply XSL Transformation (XSLT) Before
  if plugin_conf.xsltTransformBefore then
    local errMessage
    soapEnvelopeTransformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransformBefore, plugin_conf.VerboseResponse)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError .. xmlgeneral.BeforeXSD,
                                                  errMessage,
                                                  contentTypeJSON)
    end
  else
    soapEnvelopeTransformed = soapEnvelope
  end
  
  -- If there is no error and
  -- If there is a configuration for XSD SOAP schema validation then:
  -- => We validate the SOAP XML with its schema
  if soapFaultBody == nil and plugin_conf.xsdSoapSchema then
    
    -- Do a sleep for waiting the end of Prefetch (only if it's not already done)
    if not sleepForPrefetchEnd then
      sleepForPrefetchEnd = xmlgeneral.sleepForPrefetchEnd (plugin_conf.ExternalEntityLoader_Async, plugin_conf.xsdSoapSchemaInclude, libxml2ex.queueNamePrefix .. xmlgeneral.prefetchResQueueName)
    end

    -- Validate the SOAP envelope with its schema
    local errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, xmlgeneral.schemaTypeSOAP, soapEnvelopeTransformed, plugin_conf.xsdSoapSchema, plugin_conf.VerboseResponse, false)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                  errMessage,
                                                  contentTypeJSON)
    end
  end
  
  -- If there is no error and
  -- If there is a configuration for XSD or WSDL API schema validation then:
  -- => Validate the API XML (included in the <soap:envelope>) with its schema
  if soapFaultBody == nil and plugin_conf.xsdApiSchema then
  
    -- Do a sleep for waiting the end of Prefetch (only if it's not already done)
    if not sleepForPrefetchEnd then
      sleepForPrefetchEnd = xmlgeneral.sleepForPrefetchEnd (plugin_conf.ExternalEntityLoader_Async, plugin_conf.xsdApiSchemaInclude, libxml2ex.queueNamePrefix .. xmlgeneral.prefetchResQueueName)
    end

    local errMessage = xmlgeneral.XMLValidateWithWSDL (plugin_conf, xmlgeneral.schemaTypeAPI, soapEnvelopeTransformed, plugin_conf.xsdApiSchema, plugin_conf.VerboseResponse, false)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                  errMessage,
                                                  contentTypeJSON)
    end
  end

  -- If there is no error and
  -- If there is 'XSLT Transformation After XSD' configuration then
  -- => we apply XSL Transformation (XSLT) After
  if soapFaultBody == nil and plugin_conf.xsltTransformAfter then    
    local errMessage
    soapEnvelopeTransformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelopeTransformed, plugin_conf.xsltTransformAfter, plugin_conf.VerboseResponse)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError .. xmlgeneral.AfterXSD,
                                                  errMessage,
                                                  contentTypeJSON)
    end
  end
  
  return soapEnvelopeTransformed, soapFaultBody

end

------------------------------------------------------
-- Executed upon every Nginx worker process’s startup
------------------------------------------------------
function plugin:init_worker ()
  xmlgeneral = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")
  libxml2ex  = require("kong.plugins.soap-xml-handling-lib.libxml2ex")

  -- Initialize the SOAP/XML plugin
  xmlgeneral.initializeXmlSoapPlugin ()

end

------------------------------------------------------------------------------------------------
-- Executed every time the Kong plugin iterator is rebuilt (after changes to configure plugins)
------------------------------------------------------------------------------------------------
function plugin:configure (configs)
  -- If required load the 'saxon' library 
  xmlgeneral.pluginConfigure (configs, xmlgeneral.ResponseTypePlugin)
end

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)
  
  -- Initialize the ContentTypeJSON table for storing the Content-Type of the Request
  xmlgeneral.initializeContentTypeJSON ()
  
  -- Initialize the contextual data related to the External Entities
  xmlgeneral.initializeContextualDataExternalEntities (plugin_conf)
  
  -- Check if there is 'xsdApiSchemaInclude'
  local xsdApiSchemaInclude = false
  if plugin_conf.xsdApiSchemaInclude then
    for k,v in pairs(plugin_conf.xsdApiSchemaInclude) do            
      xsdApiSchemaInclude = true
      break
    end
  end
  
  -- If the plugin is defined with XSD or WSDL API schema and
  -- If Asynchronous is enabled
  if  plugin_conf.xsdApiSchema               and
      plugin_conf.ExternalEntityLoader_Async then
    -- Wait for the end of Prefetch External Entities (i.e. Validate the XSD schema)  
    while kong.xmlSoapAsync.entityLoader.prefetchQueue.exists(libxml2ex.queueNamePrefix .. xmlgeneral.prefetchResQueueName) do
      -- This 'sleep' happens only one time per Plugin configuration update
      ngx.sleep(libxml2ex.xmlSoapSleepAsync)
    end
  end

  -- Enables buffered proxying, which allows plugins to access Service body and response headers at the same time
  -- Mandatory calling 'kong.service.response.get_raw_body()' in 'header_filter' phase

  -- If http version is 'HTTP/2' the enable_buffering doesn't work so the 'soap-xml-response-handling' 
  -- cannot work and we 'disable' it
  if ngx.req.http_version() < 2 then
    kong.service.request.enable_buffering()
  else
    local errMsg =  "Try calling 'kong.service.request.enable_buffering' with http/" .. ngx.req.http_version() .. 
                    " please use http/1.x instead. The plugin is disabled"
    kong.log.err(errMsg)
    kong.ctx.shared.xmlSoapHandlingFault = {
      error = true,
      pluginId = -1,
      soapEnvelope = errMsg
    }
  end
end

-----------------------------------------------------------------------------------------
-- Executed when all response headers bytes have been received from the upstream service
-----------------------------------------------------------------------------------------
function plugin:header_filter(plugin_conf)
  local soapEnvelopeTransformed
  local soapFaultBody
  local soapEnvelope
  local soapDeflated
  local err
  
  -- If needed: initialize the ContentTypeJSON table for storing the Content-Type of the Request
  xmlgeneral.initializeContentTypeJSON ()

  -- In case of error set by SOAP/XML plugin, we don't do anything to avoid an issue.
  -- If we call get_raw_body (), without calling request.enable_buffering(), it will raise an error and 
  -- it happens when a previous plugin called kong.response.exit(): in this case all 'header_filter' and 'body_filter'
  -- are called (and the 'access' is not called which enables the enable_buffering())
  if kong.ctx.shared.xmlSoapHandlingFault and 
     kong.ctx.shared.xmlSoapHandlingFault.error then
    kong.log.debug("A pending error has been set by other SOAP/XML plugin: we do nothing in this plugin")
    return
  end
  
  --  In case of 'request-termination' plugin
  if (kong.response.get_source() == "exit" and kong.response.get_status() == 200) then
    return
  
  -- If an error is set by other plugin (like Rate Limiting) or by the Service itself (timeout)
  elseif  (kong.response.get_source() == "exit" or 
          kong.response.get_source()  == "error") then
    -- If the Request Content-Type is JSON
    if kong.ctx.shared.contentTypeJSON.request == true then
      kong.log.debug("A pending error has been set by other plugin or by the Service itself")
      kong.response.set_header("Content-Type", xmlgeneral.JSONContentType)
      return
    -- Else the Request Content-Type is XML: we reformat the the error messsage in SOAP/XML Fault
    else
      kong.log.debug("A pending error has been set by other plugin or by the Service itself: we format the error messsage in SOAP/XML Fault")
      soapFaultBody = xmlgeneral.addHttpErorCodeToSoapFault(plugin_conf.VerboseResponse, kong.ctx.shared.contentTypeJSON.request)
      kong.response.clear_header("Content-Length")
      kong.response.set_header("Content-Type", xmlgeneral.XMLContentType)
    end
  else
    -- Get SOAP Envelope from the Body
    soapEnvelope = kong.service.response.get_raw_body()
    -- There is no SOAP envelope (or Body content) so we don't do anything
    if not soapEnvelope then
      kong.log.debug("The Body is 'nil': nothing to do")
      return
    end
  end
  
  -- If there is no error
  if soapFaultBody == nil then
    -- If the Body is deflated/zipped, we inflate/unzip it
    if kong.response.get_header("Content-Encoding") == "gzip" then
      local soapDeflated, err = KongGzip.inflate_gzip(soapEnvelope)
      if err then
        err = "Failed to inflate the gzipped SOAP/XML Body: " .. err
        soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                    xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.GeneralError,
                                                    err,
                                                    kong.ctx.shared.contentTypeJSON.request)
      else
        soapEnvelope = soapDeflated
      end
    -- If there is a 'Content-Encoding' type that is not supported (by 'KongGzip')
    elseif kong.response.get_header("Content-Encoding") then
      err = "Content-encoding of type '" .. kong.response.get_header("Content-Encoding") .. "' is not supported"
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.GeneralError,
                                                  err,
                                                  kong.ctx.shared.contentTypeJSON.request)
    end
  end
  
  -- If there is no error
  if soapFaultBody == nil then
    -- Handle all SOAP/XML topics of the Response: XSLT before, XSD validation and XSLT After
    soapEnvelopeTransformed, soapFaultBody = plugin:responseSOAPXMLhandling (plugin_conf, soapEnvelope, kong.ctx.shared.contentTypeJSON.request)
  end
  
  -- If there is an error during SOAP/XML process we change the HTTP staus code and
  -- the Body content (with the detailed error message) will be changed by 'body_filter' phase
  if soapFaultBody ~= nil then
    -- If the Body is zipped we removed it
    -- We don't have to deflate/zip it because there will have an error message with a few number of characters
    if kong.response.get_header("Content-Encoding") then
      kong.response.clear_header("Content-Encoding")
    end
    -- When the response was originated by successfully contacting the proxied Service
    if kong.response.get_source() == "service" then
      -- Change the HTTP Status and Return a Fault code to Client
      kong.response.set_status(xmlgeneral.HTTPCodeSOAPFault)
    else
      -- When another plugin (like Rate Limiting) or 
      -- the Service itself (timeout) has already raised an error: we don't change the HTTP Error code
    end
    kong.response.set_header("Content-Length", #soapFaultBody)

    -- If the Request Content-Type is JSON, we apply the same Content-Type on the Response for sending a JSON Error
    if kong.ctx.shared.contentTypeJSON.request == true then
      kong.response.set_header("Content-Type", xmlgeneral.JSONContentType)
      kong.log.debug("JSON<->XML Transformation: Change the Reponse's 'Content-Type' from XML to JSON")
    end

    -- Set the Global Fault Code to Request and Response XLM/SOAP plugins 
    -- It prevents to apply XML/SOAP handling whereas there is already an error
    kong.ctx.shared.xmlSoapHandlingFault = {
      error = true,
      pluginId = plugin.__plugin_id,
      soapEnvelope = soapFaultBody
    }
  -- If the SOAP envelope is transformed
  elseif soapEnvelopeTransformed then
    -- If the Backend API Body is deflated/zipped, we deflate/zip the new transformed SOAP/XML Body
    if kong.response.get_header("Content-Encoding") == "gzip" then
      local soapInflated, err = KongGzip.deflate_gzip(soapEnvelopeTransformed)
      
      if err then
        kong.log.err("Failed to deflate the gzipped SOAP/XML Body: " .. err)
        -- We are unable to deflate/zip new transformed SOAP/XML Body, so we remove the 'Content-Encoding' header
        -- and we return the non delated/zipped content
        kong.response.clear_header("Content-Encoding")
      else
        soapEnvelopeTransformed = soapInflated
      end
    end
    -- We cannot call 'kong.response.set_raw_body()' at this stage to change the body content
    -- but it will be done by 'body_filter' phase
    kong.response.set_header("Content-Length", #soapEnvelopeTransformed)
    
    -- If there is JSON <-> XML Transformation we have to change the Response 'Content-Type'
    -- Change the Response 'Content-Type' according to the Request 'Content-Type' AND the soapEnvelopeTransformed Type    
    local jsonResponse = xmlgeneral.compareToJSONType (kong.response.get_header("Content-Type"))
    local bodyContentType = xmlgeneral.getBodyContentType(plugin_conf, soapEnvelopeTransformed)
    
    -- If the Response 'Content-Type' is JSON and the Request 'Content-Type' is XML
    if jsonResponse == true and kong.ctx.shared.contentTypeJSON.request == false then
      -- If the soapEnvelopeTransformed type is XML
      if bodyContentType == xmlgeneral.XMLContentTypeBody then
        kong.response.set_header("Content-Type", xmlgeneral.XMLContentType)
        kong.log.debug("JSON<->XML Transformation: Change the Reponse's 'Content-Type' from JSON to XML")
      end
    -- Else If the Response 'Content-Type' is XML and the Request 'Content-Type' is JSON
    elseif jsonResponse == false and kong.ctx.shared.contentTypeJSON.request == true then
      -- If the soapEnvelopeTransformed type is JSON
      if bodyContentType == xmlgeneral.JSONContentTypeBody then
        kong.response.set_header("Content-Type", xmlgeneral.JSONContentType)
        kong.log.debug("JSON<->XML Transformation: Change the Reponse's 'Content-Type' from XML to JSON")
      end
    else
      -- The Reponse 'Content-Type' is compatible with the Request 'Content-Type'
      kong.log.debug("No JSON<->XML Transformation: Don't change the Reponse's 'Content-Type' as it's compatible with the Request 'Content-Type'")
    end
    
    -- We set the new SOAP Envelope for cascading Plugins because they are not able to retrieve it
    -- by calling 'kong.response.get_raw_body ()' in header_filter
    kong.ctx.shared.xmlSoapHandlingFault = {
      error = false,
      pluginId = plugin.__plugin_id,
      soapEnvelope = soapEnvelopeTransformed
    }
  end
  
end

------------------------------------------------------------------------------------------------------------------
-- Executed for each chunk of the response body received from the upstream service.
-- Since the response is streamed back to the client, it can exceed the buffer size and be streamed chunk by chunk.
-- This function can be called multiple times
------------------------------------------------------------------------------------------------------------------
function plugin:body_filter(plugin_conf)
  
  -- If there is a pending error set by other SOAP/XML plugin we do nothing except for the Plugin itself
  if  kong.ctx.shared.xmlSoapHandlingFault      and
    kong.ctx.shared.xmlSoapHandlingFault.error  and 
    kong.ctx.shared.xmlSoapHandlingFault.pluginId ~= plugin.__plugin_id then
    kong.log.debug("A pending error has been set by other SOAP/XML plugin: we do nothing in this plugin")
    return
  end

  -- Get modified SOAP envelope set by the plugin itself on 'header_filter'
  if  kong.ctx.shared.xmlSoapHandlingFault  and
      kong.ctx.shared.xmlSoapHandlingFault.pluginId == plugin.__plugin_id then
    
    if kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope then
      -- Set the modified SOAP envelope
      kong.response.set_raw_body(kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope)
    end
  end
end

return plugin