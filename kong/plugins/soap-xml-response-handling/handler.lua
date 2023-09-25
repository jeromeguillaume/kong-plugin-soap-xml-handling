local xmlgeneral = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")
local kongUtils = require("kong.tools.utils")

-- handler.lua
local plugin = {
    PRIORITY = 70,
    VERSION = "1.0.4",
  }

-----------------------------------------------------------------------------------------
-- XSLT TRANSFORMATION - BEFORE XSD: Transform the XML response Before (XSD VALIDATION)
-- XSD VALIDATION: Validate the XML response with its XSD schema
-- XSLT TRANSFORMATION - AFTER XSD: Transform the XML response After (XSD VALIDATION)
-----------------------------------------------------------------------------------------
function plugin:responseSOAPXMLhandling(plugin_conf, soapEnvelope)
  local soapEnvelopeTransformed
  local soapFaultBody
  
  -- If there is 'XSLT Transformation Before XSD' configuration then:
  -- => we apply XSL Transformation (XSLT) Before
  if plugin_conf.xsltTransformBefore then
    local errMessage
    soapEnvelopeTransformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransformBefore, plugin_conf.VerboseResponse)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError .. xmlgeneral.BeforeXSD,
                                                  errMessage)
    end
  else
    soapEnvelopeTransformed = soapEnvelope
  end
  
  -- If there is no error and
  -- If there is a configuration for XSD SOAP schema validation then:
  -- => We validate the SOAP XML with its schema
  if soapFaultBody == nil and plugin_conf.xsdSoapSchema then
    local errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 0, soapEnvelopeTransformed, plugin_conf.xsdSoapSchema, plugin_conf.VerboseResponse)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                  errMessage)
    end
  end
  
  -- If there is no error and
  -- If there is a configuration for XSD or WSDL API schema validation then:
  -- => we validate the SOAP XML with its schema
  if soapFaultBody == nil and plugin_conf.xsdApiSchema then  
    local errMessage = xmlgeneral.XMLValidateWithWSDL (plugin_conf, 2, soapEnvelopeTransformed, plugin_conf.xsdApiSchema, plugin_conf.VerboseResponse)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseResponse,
                                                  xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                  errMessage)
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
                                                  errMessage)
    end
  end
  
  return soapEnvelopeTransformed, soapFaultBody

end

------------------------------------------------------
-- Executed upon every Nginx worker process’s startup
------------------------------------------------------
function plugin:init_worker (plugin_conf)
  
  -- Initialize the Error handler at the initialization plugin
  xmlgeneral.initializeHandlerLoader (plugin_conf)
  
end

-----------------------------------------------------------------------------------------
-- Executed when all response headers bytes have been received from the upstream service
-----------------------------------------------------------------------------------------
function plugin:access(plugin_conf)
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
      priority = -1,
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

  -- In case of error set SOAP/XML plugin, we don't do anything to avoid an issue.
  -- If we call get_raw_body (), without calling request.enable_buffering(), it will raise an error and 
  -- it happens when a previous plugin called kong.response.exit(): in this case all 'header_filter' and 'body_filter'
  -- are called (and the 'access' is not called which enables the enable_buffering())
  if kong.ctx.shared.xmlSoapHandlingFault and 
     kong.ctx.shared.xmlSoapHandlingFault.error then
    kong.log.debug("A pending error has been set by SOAP/XML plugin: we do nothing in this plugin")
    return
  end
  
  -- In case of error set by other plugin (like Rate Limiting) or by the Service itself (timeout)
  -- In case where the 'soap-xml-request-handling' plugin is not enabled
  -- we reformat the JSON message to SOAP/XML Fault
  if kong.response.get_source() == "exit" or kong.response.get_source() == "error" then
    kong.log.debug("A pending error has been set by other plugin or by the Service itself: we format the error messsage in SOAP/XML Fault")
    soapFaultBody = xmlgeneral.reformatJsonToSoapFault(plugin_conf.VerboseResponse)
    kong.response.clear_header("Content-Length")
    kong.response.set_header("Content-Type", "text/xml; charset=utf-8")
  else
    -- Get SOAP Envolope from the Body
    soapEnvelope = kong.service.response.get_raw_body()
    -- There is no SOAP envelope (or Body content) so we don't do anything
    if not soapEnvelope then
      kong.log.debug("The Body is 'nil': nothing to do")
      return
    end
  end
  
  -- If the Body is deflated/zipped, we inflate/unzip it
  if kong.response.get_header("Content-Encoding") == "gzip" then
    local soapDeflated, err = kongUtils.inflate_gzip(soapEnvelope)
    
    if err then
      err = "Failed to inflate the gzipped SOAP/XML Body: " .. err
      soapFaultBody = xmlgeneral.formatSoapFault(plugin_conf.VerboseResponse, "soap-xml-response-handling - Internal Error", err)
      kong.log.err(err)
    else
      soapEnvelope = soapDeflated
    end
  end
  
  -- If there is no error
  if soapFaultBody == nil then
    -- Handle all SOAP/XML topics of the Response: XSLT before, XSD validation and XSLT After
    soapEnvelopeTransformed, soapFaultBody = plugin:responseSOAPXMLhandling (plugin_conf, soapEnvelope)
  end
  
  -- If there is an error during SOAP/XML we change the HTTP staus code and
  -- the Body content (with the detailed error message) will be changed by 'body_filter' phase
  if soapFaultBody ~= nil then
    -- If the Body is zipped we removed it
    -- We don't have to deflate/zip it because there will have an error message with a few number of characters
    if kong.response.get_header("Content-Encoding") == "gzip" then
      kong.response.clear_header("Content-Encoding")
    end
    -- When the response was originated by successfully contacting the proxied Service
    if kong.response.get_source() == "service" then
      -- Change the HTTP Status and Return a Fault code to Client
      kong.response.set_status(xmlgeneral.HTTPCodeSOAPFault)
    else
      -- When other plugin (like Rate Limiting) or 
      -- the Service itself (timeout) have already raised an error: we don't change the HTTP Error code
    end
    kong.response.set_header("Content-Length", #soapFaultBody)

    -- Set the Global Fault Code to Request and Response XLM/SOAP plugins 
    -- It prevents to apply XML/SOAP handling whereas there is already an error
    kong.ctx.shared.xmlSoapHandlingFault = {
      error = true,
      priority = plugin.PRIORITY,
      soapEnvelope = soapFaultBody
    }
  -- If the SOAP envelope is transformed
  elseif soapEnvelopeTransformed then
    -- If the Backend API Body is deflated/zipped, we deflate/zip the new transformed SOAP/XML Body
    if kong.response.get_header("Content-Encoding") == "gzip" then
      local soapInflated, err = kongUtils.deflate_gzip(soapEnvelopeTransformed)
      if err then
        kong.log.err("Failed to deflate the gzipped SOAP/XML Body: " .. err)
        -- We are unable to deflate/zip new transformed SOAP/XML Body, so we remove the 'Content-Encoding' header
        kong.response.clear_header("Content-Encoding")
      else
        soapEnvelopeTransformed = soapInflated
      end
    end
    -- We aren't able to call 'kong.response.set_raw_body()' at this stage to change the body content
    -- but it will be done by 'body_filter' phase
    kong.response.set_header("Content-Length", #soapEnvelopeTransformed)

    -- We set the new SOAP Envelope for cascading Plugins because they are not able to retrieve it
    -- by calling 'kong.response.get_raw_body ()' in header_filter
    kong.ctx.shared.xmlSoapHandlingFault = {
      error = false,
      priority = plugin.PRIORITY,
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
  
  -- If there is a pending error set by SOAP/XML plugin we do anything except for the Plugin itself
  if  kong.ctx.shared.xmlSoapHandlingFault      and
    kong.ctx.shared.xmlSoapHandlingFault.error  and 
    kong.ctx.shared.xmlSoapHandlingFault.priority ~= plugin.PRIORITY then
    kong.log.debug("A pending error has been set by SOAP/XML plugin: we do nothing in this plugin")
    return
  end

  -- Get modified SOAP envelope set by the plugin itself on 'header_filter'
  if  kong.ctx.shared.xmlSoapHandlingFault  and
      kong.ctx.shared.xmlSoapHandlingFault.priority == plugin.PRIORITY then
    
    if kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope then
      -- Set the modified SOAP envelope
      kong.response.set_raw_body(kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope)
    end
  end
end

return plugin