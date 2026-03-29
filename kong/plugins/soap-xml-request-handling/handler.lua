-- handler.lua
local plugin = {
    PRIORITY = 75,
    VERSION = "1.4.6",
  }

local xmlgeneral = nil
local libxml2ex  = nil

------------------------------------------------------------------------------------------------------------------------------------
-- XSLT TRANSFORMATION - BEFORE XSD: Transform the XML request with XSLT (XSLTransformation) before XSD Validation
-- WSDL/XSD VALIDATION             : Validate XML request with its WSDL or XSD schema
--                                 : Validate the 'SOAPAction' header
-- XSLT TRANSFORMATION - AFTER XSD : Transform the XML request with XSLT (XSLTransformation) after XSD Validation
-- ROUTING BY XPATH                : change the Route of the request to a different hostname and path depending of XPath condition
------------------------------------------------------------------------------------------------------------------------------------
function plugin:requestSOAPXMLhandling(plugin_conf, soapEnvelope)
  local soapEnvelopeTransformed = soapEnvelope
  local xmlPtrDoc
  local errMessage
  local XMLXSDMatching
  local xmlDeclaration
  local soapFaultBody
  local rcXpath
  local soapFaultCode       = xmlgeneral.soapFaultCodeServer
  local pluginId            = kong.plugin.get_id()
  
  -- If soapEnvelope is nil, it's probably related to the body size that exceeded the Nginx configuration
  if soapEnvelope == nil then
    -- Get the client request body that has been buffered to a temporary file
    local body_filepath = ngx.req.get_body_file()
    if body_filepath then
      local file_size = lfs.attributes(body_filepath, "size")
      local file
      kong.log.warn("The client request body is buffered to a temporary file size: ", file_size, " bytes")
      -- Read the file from the filesystem
      file, errMessage = io.open(body_filepath, "r")
      if not file then
        kong.log.err("readFile - Ko: Error opening file '" .. body_filepath .. "': " .. (errMessage or "nil"))
        errMessage = xmlgeneral.unableToGetBodyRequest        
      else
        soapEnvelopeTransformed = file:read("*a")  -- Read the entire file content
        file:close()  -- Close the file handle        
        if soapEnvelopeTransformed == nil then
          kong.log.err("readFile - Ko: Error reading file '" .. body_filepath .. "'")
          errMessage = xmlgeneral.unableToGetBodyRequest          
        else
          kong.log.debug("readFile - Ok: Read content file '", body_filepath, "'")
        end
      end
    else
      kong.log.err("Unable to get the client request body from temporary file")
      errMessage = xmlgeneral.unableToGetBodyRequest
    end

    if errMessage then
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                  pluginId,
                                                  plugin_conf,
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.GeneralError,
                                                  errMessage,
                                                  kong.ctx.shared.contentType.request,
                                                  soapFaultCode)
    end
  end
  
  -- If there is no error and
  -- If there is 'XSLT Transformation Before XSD' configuration then:
  --    => Apply XSL Transformation (XSLT) Before XSD
  if soapFaultBody == nil and plugin_conf.xsltTransformBefore then
    xmlPtrDoc, soapEnvelopeTransformed, xmlDeclaration, errMessage, soapFaultCode = 
      xmlgeneral.XSLTransform(xmlgeneral.RequestTypePlugin,
                              pluginId,
                              plugin_conf,
                              xmlgeneral.xsltBeforeXSD,
                              xmlPtrDoc,
                              soapEnvelopeTransformed,
                              plugin_conf.xsltTransformBefore)
    
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                  pluginId,
                                                  plugin_conf,                                                  
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError .. xmlgeneral.BeforeXSD,
                                                  errMessage,
                                                  kong.ctx.shared.contentType.request,
                                                  soapFaultCode)
    end
  end

  -- If there is no error and
  -- If Asynchronous External Entity Loader is enabled then
  if soapFaultBody == nil and plugin_conf.ExternalEntityLoader_Async then
    -- Do a sleep for waiting the end of Prefetch
    xmlgeneral.sleepForPrefetchEnd (libxml2ex.queueNamePrefix .. xmlgeneral.prefetchReqQueueName)    
  end
  
  -- If there is no error and
  -- If the plugin is defined with XSD SOAP schema and
  -- If the XSD SOAP schema is different from a comment definition then:
  --    => Validate the SOAP envelope with its schema
  if  soapFaultBody == nil and 
      ( (plugin_conf.xsdSoapSchema    and plugin_conf.xsdSoapSchema   ~= xmlgeneral.commentForEmptyXSD) or
        (plugin_conf.xsdSoap12Schema  and plugin_conf.xsdSoap12Schema ~= xmlgeneral.commentForEmptyXSD)) then
    
    -- Validate the SOAP envelope with its schema    
    xmlPtrDoc, errMessage, XMLXSDMatching, soapFaultCode = 
      xmlgeneral.XMLValidateWithXSD ( xmlgeneral.RequestTypePlugin,
                                      pluginId,
                                      plugin_conf,
                                      xmlgeneral.schemaTypeSOAP_All,
                                      1, -- SOAP schema is based on XSD and not WSDL, so it's always '1' (for 1st XSD entry)
                                      xmlPtrDoc,
                                      soapEnvelopeTransformed,
                                      plugin_conf.xsdSoapSchema,
                                      plugin_conf.xsdSoap12Schema,
                                      false
                                      )
    if errMessage ~= nil then
        -- Format a Fault code to Client
        soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                    pluginId,
                                                    plugin_conf,                                                    
                                                    xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                    errMessage,
                                                    kong.ctx.shared.contentType.request,
                                                    soapFaultCode)
    end
  end
  
  -- If there is no error and
  -- If the plugin is defined with XSD or WSDL API schema
  -- If the XSD API schema is different from a comment definition then:
  --    => Validate the API XML (included in the <soap:envelope>) with its schema
  if soapFaultBody == nil and plugin_conf.xsdApiSchema and plugin_conf.xsdApiSchema ~= xmlgeneral.commentForEmptyXSD then
    
    -- Validate the API XML with its schema
    xmlPtrDoc, errMessage, soapFaultCode = 
      xmlgeneral.XMLValidateWithWSDL (xmlgeneral.RequestTypePlugin,
                                      pluginId,
                                      plugin_conf,
                                      xmlgeneral.schemaTypeAPI,
                                      xmlPtrDoc,
                                      soapEnvelopeTransformed,
                                      plugin_conf.xsdApiSchema,
                                      false
                                    )
    
    if errMessage ~= nil then
        -- Format a Fault code to Client
        soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                    pluginId,
                                                    plugin_conf,                                                  
                                                    xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                    errMessage,
                                                    kong.ctx.shared.contentType.request,
                                                    soapFaultCode)
    end
  end

  -- If there is no error and
  --    => Validate the 'SOAPAction' header
  if soapFaultBody == nil then
    
    -- Validate the 'SOAPAction' header against the WSDL
    xmlPtrDoc, errMessage, soapFaultCode = xmlgeneral.validateSOAPAction_Header ( pluginId,
                                                                                  plugin_conf,
                                                                                  xmlPtrDoc,
                                                                                  soapEnvelopeTransformed
                                                                                )
    
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                  pluginId,
                                                  plugin_conf,                                                  
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                  errMessage,
                                                  kong.ctx.shared.contentType.request,
                                                  soapFaultCode)
    end
  end

  -- If there is no error and
  -- If there is 'XSLT Transformation After XSD' configuration then:
  --    => Apply XSL Transformation (XSLT) After XSD
  if soapFaultBody == nil and plugin_conf.xsltTransformAfter then
    xmlPtrDoc, soapEnvelopeTransformed, xmlDeclaration, errMessage, soapFaultCode = 
      xmlgeneral.XSLTransform(xmlgeneral.RequestTypePlugin,
                              pluginId,
                              plugin_conf,
                              xmlgeneral.xsltAfterXSD,
                              xmlPtrDoc,
                              soapEnvelopeTransformed,
                              plugin_conf.xsltTransformAfter)

    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                  pluginId,
                                                  plugin_conf,                                                  
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError .. xmlgeneral.AfterXSD,
                                                  errMessage,
                                                  kong.ctx.shared.contentType.request,
                                                  soapFaultCode)
    end
  end

  -- If there is no error and
  -- If the plugin is defined with Routing XPath Targets then:
  --    => Change the Route By XPath if the condition is satisfied  
  if soapFaultBody == nil and plugin_conf.RouteXPathTargets and next(plugin_conf.RouteXPathTargets) then
    -- Get Route By XPath and check if the condition is satisfied
    xmlPtrDoc, rcXpath, errMessage, soapFaultCode = 
      xmlgeneral.RouteByXPath(pluginId,
                              plugin_conf,
                              xmlPtrDoc,
                              soapEnvelopeTransformed)
    
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                  pluginId,
                                                  plugin_conf,                                                  
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XPathRoutingError,
                                                  errMessage,
                                                  kong.ctx.shared.contentType.request,
                                                  soapFaultCode)
    -- If the condition is satisfied we change the Upstream
    elseif rcXpath > 0 then
      local parse_url = require("socket.url").parse
      local parsed    = parse_url(plugin_conf.RouteXPathTargets[rcXpath].URL)
      local port
      local path
      local query

      if (parsed and parsed.scheme and parsed.host) then        
        kong.service.request.set_scheme(parsed.scheme)        
        if (not parsed.path) then
          path = '/'
        else
          path = parsed.path
        end
        kong.service.request.set_path(path)
        if (not parsed.port) then
          if parsed.scheme == 'https' then
              port = 443
          else 
              port = 80
          end
        else
            port = parsed.port
        end
        -- First, consider that the Host is a Kong Upstream
        local ok, err = kong.service.set_upstream(parsed.host)

        -- If there is an error it means that the Host is not a Kong Upstream
        if not ok then
          -- Change Hostname and port
          local ok, err = kong.service.set_target(parsed.host, tonumber(port))
        end
        if parsed.query then
          kong.service.request.set_raw_query(parsed.query)
          query = '?' .. parsed.query
        else
          query = ''
        end
        kong.log.debug("Upstream changed successfully to ", parsed.scheme, "://", parsed.host, ":", tonumber(port), path, query)
      else
        kong.log.err("RouteByXPath: Unable to get scheme or host")
      end
    end    
  end
  
  -- If there is no error
  --    AND
  -- If an XSLT Transformation has been applied 
  --    AND 
  -- If there is no need to Remove Empty NameSpace
  --    => Dump the transformed SOAP envelope
  if soapFaultBody == nil and 
      (plugin_conf.xsltTransformBefore or plugin_conf.xsltTransformAfter) and
      not plugin_conf.xsltRemoveEmptyNameSpace then
    -- Dump the transformed SOAP envelope
    soapEnvelopeTransformed, errMessage = xmlgeneral.xmlDump (xmlPtrDoc, nil, xmlDeclaration, plugin_conf.xsltRemoveEmptyNameSpace)
    if errMessage then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTypePlugin,
                                                  pluginId,
                                                  plugin_conf,                                                  
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.GeneralError,
                                                  errMessage,
                                                  kong.ctx.shared.contentType.request,
                                                  soapFaultCode)
    end
  end

  -- If there is no Error and If an XSLT Transformation has been applied
  if soapFaultBody == nil and soapEnvelopeTransformed ~= nil then 
    -- If there is JSON <-> XML Transformation we have to change the Request 'Content-Type'
    -- Change the Request 'Content-Type' according to the soapEnvelopeTransformed Type
    local bodyContentType = xmlgeneral.getBodyContentType(soapEnvelopeTransformed)

    -- If the Request's 'Content-Type' is JSON and the soapEnvelopeTransformed type is XML
    if kong.ctx.shared.contentType.request == xmlgeneral.JSON and bodyContentType == xmlgeneral.XMLContentTypeBody then
      kong.service.request.set_header("Content-Type", xmlgeneral.SOAP1_1ContentType)
      kong.log.debug("JSON<->XML Transformation: Change the Request's 'Content-Type' from JSON to XML (", xmlgeneral.SOAP1_1ContentType, ")")
    -- Else If the Request's 'Content-Type' is XML and the soapEnvelopeTransformed type is JSON
    elseif kong.ctx.shared.contentType.request ~= xmlgeneral.JSON and bodyContentType == xmlgeneral.JSONContentTypeBody then
      -- Check if the body has been transformed to a JSON type, due to an XSLT transformation (SOAP/XML -> JSON)
      kong.service.request.set_header("Content-Type", xmlgeneral.JSONContentType)
      kong.log.debug("JSON<->XML Transformation: Change the Request's 'Content-Type' from XML to JSON (", xmlgeneral.JSONContentType, ")")
    else
      -- The Request 'Content-Type' is compatible with the Body
      kong.log.debug("JSON<->XML Transformation: Don't change the Request's 'Content-Type' as it's compatible with the Body type")
    end
  else
    -- Here there is an Error or the 'soapEnvelopeTransformed' is 'nil' because there is no transformation: so we keep the original SOAP envelope
    -- and there is no need to call 'kong.service.request.set_raw_body' later
  end
  
  return soapEnvelopeTransformed, soapFaultBody, soapFaultCode

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
  xmlgeneral.pluginConfigure (configs, xmlgeneral.RequestTypePlugin)
end

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)
  
  -- Initialize the contextual data related to the External Entities
  xmlgeneral.initializeContextualDataExternalEntities (plugin_conf)
  
  -- initialize the contentType table for storing the Content-Type of the Request
  xmlgeneral.initializeContentType ()

  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  -- Handle all SOAP/XML topics of the Request: XSLT before, XSD validation, XSLT After and Routing by XPath
  local soapEnvelopeTransformed, soapFaultBody, soapFaultCode = plugin:requestSOAPXMLhandling (plugin_conf, soapEnvelope)

  -- If there is an error during SOAP/XML we change the HTTP staus code and
  -- the Body content (with the detailed error message) will be changed by 'body_filter' phase
  if soapFaultBody ~= nil then
      -- Set the Global Fault Code to the "Request and Response SOAP/XML handling" plugins 
      -- It prevents to apply other XML/SOAP handling whereas there is already an error
      kong.ctx.shared.xmlSoapHandlingFault = {
        error = true,
        otherPlugin = false,
        pluginId = kong.plugin.get_id(),
        soapEnvelope = soapFaultBody
      }

      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault ( plugin_conf,
                                          soapFaultCode,                    
                                          soapFaultBody,
                                          kong.ctx.shared.contentType.request
                                        )
  end

  -- If the SOAP Body request has been changed (WSDL/XSD Validation and XPath Routing don't change it)
  if soapEnvelopeTransformed then
    -- We did a successful SOAP/XML handling, so we change the SOAP body request
    kong.service.request.set_raw_body(soapEnvelopeTransformed)
  end

end

------------------------------------------------------------------------------------------------------------
-- Executed when all response headers bytes have been received from the upstream service
-- Also called when an error is set by the plugin itself (like not a valid body regarding its WSDL/XSD )
-- or other plugin (like Rate Limiting) or by the Upstream service itself (timeout)
--
-- Examples of error:
--    source=exit     status=200 => The request termination plugin returns a 200
--    source=exit     status=401 => The apikey plugin (or another auth plugins) returns an error
--    source=exit     status=500 => the plugin itself returns an error
--    source=exit     status=503 => Kong can't reach the upstream hostname
--    source=error    status=502 => Upstream invalid port (seen as source=exit by Response plugin)
--    source=error    status=504 => The upstream response time exceeds the timeout configured in Kong
--                                  (seen as source=exit by Response plugin)
--    source=service  status=XXX => Managed by the Response plugin
------------------------------------------------------------------------------------------------------------
function plugin:header_filter(plugin_conf)
  local soapFaultBody
  local pluginId = kong.plugin.get_id()

  -- If needed: initialize the contentType table for storing the Content-Type of the Request
  xmlgeneral.initializeContentType ()
  
  -- In case of error set by other plugin (like Rate Limiting) or by the Service itself (timeout)
  --    we don't consider as an error the 'request-termination' plugin (get_source()="exit" and get_status()=200)
  -- we reformat the JSON message to SOAP/XML Fault
  -- The Request plugin doesn't take into account get_source() == "service" and get_status() ~= 200 
  --   because it's the responsibility of the Response plugin to handle the error in this case
  if kong.ctx.shared.xmlSoapHandlingFault == nil and
    ( (kong.response.get_source() == "exit" and kong.response.get_status() ~= 200) 
        or 
       kong.response.get_source() == "error") then
    
    -- If the Client sends an SOAP/XML request
    if kong.ctx.shared.contentType.request ~= xmlgeneral.JSON then
      kong.log.debug("A pending error has been set by other plugin or by the service itself: we format the error messsage in SOAP/XML Fault")
      
      soapFaultBody = xmlgeneral.addHttpErorCodeToSoapFault(xmlgeneral.RequestTypePlugin, pluginId, plugin_conf, kong.ctx.shared.contentType.request)
      -- At this stage we cannot call 'kong.response.set_raw_body()' to change the body content
      -- but it will be done by 'body_filter' phase
      kong.response.set_header("Content-Length", #soapFaultBody)
      kong.response.set_header("Content-Type", xmlgeneral.getContentType(kong.ctx.shared.contentType.request))
      -- This code raises an unexpected error in Kong log, for instance: 
      --    "[error] ... atempt to set status 500 via ngx.exit after sending out the response status 504
      -- see: https://konghq.atlassian.net/browse/FTI-6970
      kong.response.set_status(plugin_conf.customFaultCode or xmlgeneral.HTTPServerCodeSOAPFault)
    end

    -- Set the Global Fault Code to the "Request and Response SOAP/XML handling" plugins 
    -- It prevents to apply other XML/SOAP handling whereas there is already an error
    kong.ctx.shared.xmlSoapHandlingFault = {
      error = true,
      otherPlugin = true,
      pluginId = kong.plugin.get_id(),
      soapEnvelope = soapFaultBody
    }
    
  end

end

------------------------------------------------------------------------------------------------------------------
-- Executed for each chunk of the response body received from the upstream service.
-- Since the response is streamed back to the client, it can exceed the buffer size and be streamed chunk by chunk.
-- Also called when an error is set by other plugin (like Rate Limiting) or by the Service itself (timeout)
-- This function can be called multiple times
------------------------------------------------------------------------------------------------------------------
function plugin:body_filter(plugin_conf)

  -- In case of error set by other plugin (like Rate Limiting) or by the Service itself (timeout)
  --  => reformat the JSON message to SOAP/XML Fault (only if the Content-Type of the request is not a JSON)
  if  kong.ctx.shared.xmlSoapHandlingFault and 
      kong.ctx.shared.xmlSoapHandlingFault.otherPlugin == true and
      kong.ctx.shared.contentType.request ~= xmlgeneral.JSON then
    
    kong.response.set_raw_body(kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope)
  end
  
end

return plugin