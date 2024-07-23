-- handler.lua
local plugin = {
    PRIORITY = 75,
    VERSION = "1.0.11",
  }

------------------------------------------------------------------------------------------------------------------------------------
-- XSLT TRANSFORMATION - BEFORE XSD: Transform the XML request with XSLT (XSLTransformation) before XSD Validation
-- WSDL/XSD VALIDATION             : Validate XML request with its WSDL or XSD schema
-- XSLT TRANSFORMATION - AFTER XSD : Transform the XML request with XSLT (XSLTransformation) after XSD Validation
-- ROUTING BY XPATH                : change the Route of the request to a different hostname and path depending of XPath condition
------------------------------------------------------------------------------------------------------------------------------------
function plugin:requestSOAPXMLhandling(plugin_conf, soapEnvelope)
  local xmlgeneral = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")
  local soapEnvelope_transformed
  local errMessage
  local soapFaultBody

  soapEnvelope_transformed = soapEnvelope

  -- If there is 'XSLT Transformation Before XSD' configuration then:
  -- => we apply XSL Transformation (XSLT) Before XSD
  if plugin_conf.xsltTransformBefore then
    soapEnvelope_transformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransformBefore, plugin_conf.VerboseRequest)
    
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseRequest,
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError .. xmlgeneral.BeforeXSD,
                                                  errMessage)
    end
  end

  -- If there is no error and
  -- If the plugin is defined with XSD SOAP schema then:
  -- => we validate the SOAP envelope with its schema
  if soapFaultBody == nil and plugin_conf.xsdSoapSchema then
    errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 0, soapEnvelope_transformed, plugin_conf.xsdSoapSchema, plugin_conf.VerboseRequest, false)
    if errMessage ~= nil then
        -- Format a Fault code to Client
        soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseRequest,
                                                    xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                    errMessage)
    end
  end

  -- If there is no error and
  -- If the plugin is defined with XSD or WSDL API schema then:
  -- => we validate the API XML (included in the <soap:envelope>) with its schema
  if soapFaultBody == nil and plugin_conf.xsdApiSchema then
    
    -- Prefetch External Entities (i.e. Download XSD content)
    xmlgeneral.prefetchExternalEntities (plugin_conf, 2, plugin_conf.xsdApiSchema, plugin_conf.VerboseRequest)
    
    -- Validate the API XML with its schema
    errMessage = xmlgeneral.XMLValidateWithWSDL (plugin_conf, 2, soapEnvelope_transformed, plugin_conf.xsdApiSchema, plugin_conf.VerboseRequest, false)

    if errMessage ~= nil then
        -- Format a Fault code to Client
        soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseRequest,
                                                    xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                    errMessage)
    end
  end

  -- If there is no error and
  -- If there is 'XSLT Transformation After XSD' configuration then:
  -- => we apply XSL Transformation (XSLT) After XSD
  if soapFaultBody == nil and plugin_conf.xsltTransformAfter then
    soapEnvelope_transformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope_transformed, plugin_conf.xsltTransformAfter, plugin_conf.VerboseRequest)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (plugin_conf.VerboseRequest,
                                                  xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError .. xmlgeneral.AfterXSD,
                                                  errMessage)
    end
  end

  -- If there is no error and
  -- If the plugin is defined with Routing XPath properties then:
  -- => we change the Route By XPath if the condition is satisfied
    if soapFaultBody == nil and plugin_conf.RouteXPath and plugin_conf.RouteXPathCondition and plugin_conf.RouteToPath then
    -- Get Route By XPath and check if the condition is satisfied
    local rcXpath = xmlgeneral.RouteByXPath (kong, soapEnvelope_transformed, 
                                            plugin_conf.RouteXPath, plugin_conf.RouteXPathCondition, plugin_conf.RouteXPathRegisterNs)
    -- If the condition is statsfied we change the Upstream
    if rcXpath then
      local parse_url = require("socket.url").parse
      local parsed    = parse_url(plugin_conf.RouteToPath)
      local port
      local path
      local query

      if (parsed.scheme and parsed.host) then        
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
          kong.service.set_target(parsed.host, tonumber(port))          
        end
        if parsed.query then
          kong.service.request.set_raw_query(parsed.query)
          query = '?' .. parsed.query
        else
          query = ''
        end
        kong.log.debug("Upstream changed successfully to " .. parsed.scheme .. "://" .. parsed.host .. ":" .. tonumber(port) .. path .. query)
      else
        kong.log.err("RouteByXPath: Unable to get scheme or host")
      end
    end
  end
  
  -- If there is a JSON <-> XML transformation on the Request: change the 'Content-Type' header of the Request
  if plugin_conf.xsltLibrary == "saxon" then
    if plugin_conf.xsltSaxonTransformType == "xml-to-json" then
      kong.service.request.set_header("Content-Type", xmlgeneral.JsonContentType)
    elseif plugin_conf.xsltSaxonTransformType == "json-to-xml" then
      kong.service.request.set_header("Content-Type", xmlgeneral.XMLContentType)
    end
  end
  
  return soapEnvelope_transformed, soapFaultBody

end

------------------------------------------------------
-- Executed upon every Nginx worker process’s startup
------------------------------------------------------
function plugin:init_worker ()
  local xmlgeneral = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")

  -- Initialize the SOAP/XML plugin
  xmlgeneral.initializeXmlSoapPlugin ()

  -- Initialize the Saxon library
  xmlgeneral.initializeSaxon()

  -- Create the Saxon Processor
  xmlgeneral.createSaxonProcessor()

  -- Create the XSLT 3.0 processor
  xmlgeneral.createXslt30ProcessorKong()

end

------------------------------------------------------------------------------------------------
-- Executed every time the Kong plugin iterator is rebuilt (after changes to configure plugins)
------------------------------------------------------------------------------------------------
function plugin:configure (configs)
  
end

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)
  local xmlgeneral = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")
  
  -- Initialize the contextual data related to the External Entities
  xmlgeneral.initializeContextualDataExternalEntities (plugin_conf)
 
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  -- Handle all SOAP/XML topics of the Request: XSLT before, XSD validation, XSLT After and Routing by XPath
  local soapEnvelope_transformed, soapFaultBody = plugin:requestSOAPXMLhandling (plugin_conf, soapEnvelope)

  -- If there is an error during SOAP/XML we change the HTTP staus code and
  -- the Body content (with the detailed error message) will be changed by 'body_filter' phase
  if soapFaultBody ~= nil then    

      -- Set the Global Fault Code to the "Request and Response SOAP/XML handling" plugins 
      -- It prevents to apply other XML/SOAP handling whereas there is already an error
      kong.ctx.shared.xmlSoapHandlingFault = {
        error = true,
        otherPlugin = false,
        priority = plugin.PRIORITY,
        soapEnvelope = soapFaultBody
      }

      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault (plugin_conf,
                                        xmlgeneral.HTTPCodeSOAPFault,
                                        soapFaultBody)
  end

  -- If the SOAP Body request has been changed (for instance, the XPath Routing alone doesn't change it)
  if soapEnvelope_transformed then
    -- We did a successful SOAP/XML handling, so we change the SOAP body request
    kong.service.request.set_raw_body(soapEnvelope_transformed)
  end

end

-----------------------------------------------------------------------------------------
-- Executed when all response headers bytes have been received from the upstream service
-----------------------------------------------------------------------------------------
function plugin:header_filter(plugin_conf)
  local xmlgeneral = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")
  local soapFaultBody

  -- In case of error set by other plugin (like Rate Limiting) or by the Service itself (timeout)
  --    we don't consider as an error the 'request-termination' plugin (get_source()="exit" and get_status()=200)
  -- we reformat the JSON message to SOAP/XML Fault
  if kong.ctx.shared.xmlSoapHandlingFault == nil and
    ( (kong.response.get_source() == "exit" and kong.response.get_status() ~= 200) 
        or 
       kong.response.get_source() == "error") then
    
    if plugin_conf.xsltSaxonTransformType ~= "json-to-xml" then
      kong.log.debug("A pending error has been set by other plugin or by the service itself: we format the error messsage in SOAP/XML Fault")
      
      soapFaultBody = xmlgeneral.reformatJsonToSoapFault(plugin_conf.VerboseRequest)
      -- We aren't able to call 'kong.response.set_raw_body()' at this stage to change the body content
      -- but it will be done by 'body_filter' phase
      kong.response.set_header("Content-Length", #soapFaultBody)
      kong.response.set_header("Content-Type", xmlgeneral.XMLContentType)
    end

    -- Set the Global Fault Code to the "Request and Response SOAP/XML handling" plugins 
    -- It prevents to apply other XML/SOAP handling whereas there is already an error
    kong.ctx.shared.xmlSoapHandlingFault = {
      error = true,
      otherPlugin = true,
      priority = plugin.PRIORITY,
      soapEnvelope = soapFaultBody
    }
    
  end

end

------------------------------------------------------------------------------------------------------------------
-- Executed for each chunk of the response body received from the upstream service.
-- Since the response is streamed back to the client, it can exceed the buffer size and be streamed chunk by chunk.
-- This function can be called multiple times
------------------------------------------------------------------------------------------------------------------
function plugin:body_filter(plugin_conf)

  -- In case of error set by other plugin (like Rate Limiting) or by the Service itself (timeout)
  -- we reformat the JSON message to SOAP/XML Fault
  if  kong.ctx.shared.xmlSoapHandlingFault and 
      kong.ctx.shared.xmlSoapHandlingFault.otherPlugin == true and
      plugin_conf.xsltSaxonTransformType ~= "json-to-xml" then
      kong.response.set_raw_body(kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope)
  end
end

return plugin