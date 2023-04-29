-- handler.lua
local plugin = {
    PRIORITY = 75,
    VERSION = "1.0.0",
  }

------------------------------------------------------------------------------------------------------------------------------------
-- XSLT TRANSFORMATION - BEFORE XSD: Transform the XML request with XSLT (XSLTransformation) before XSD Validation
-- XSD VALIDATION                  : Validate XML request with its XSD schema
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
    soapEnvelope_transformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransformBefore)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError,
                                                  errMessage)
    end
  end

  -- If there is no error and
  -- If the plugin is defined with XSD SOAP schema then:
  -- => we validate the SOAP with its schema
  if soapFaultBody == nil and plugin_conf.xsdSoapSchema then
    errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 0, soapEnvelope_transformed, plugin_conf.xsdSoapSchema)    
    if errMessage ~= nil then
        -- Format a Fault code to Client
        soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                    errMessage)
    end
  end
  
  -- If there is no error and
  -- If the plugin is defined with XSD API schema then:
  -- => we validate the API XML (included in the <soap:envelope>) with its schema
  if soapFaultBody == nil and plugin_conf.xsdApiSchema then
    errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 2, soapEnvelope_transformed, plugin_conf.xsdApiSchema)
    if errMessage ~= nil then
        -- Format a Fault code to Client
        soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError,
                                                    errMessage)
    end
  end

  -- If there is 'XSLT Transformation After XSD' configuration then:
  -- => we apply XSL Transformation (XSLT) After XSD
  if soapFaultBody == nil and plugin_conf.xsltTransformAfter then
    soapEnvelope_transformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope_transformed, plugin_conf.xsltTransformAfter)
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError,
                                                  errMessage)
    end
  end

  -- If there is no error and
  -- If the plugin is defined with Routing XPath properties then:
  -- => we change the Route By XPath and if the condition is satisfied
  if soapFaultBody == nil and plugin_conf.RouteXPath and plugin_conf.RouteXPathCondition and plugin_conf.RouteToUpstream and plugin_conf.RouteToPath then
    -- Get Route By XPath and check if the condition is satisfied
    local rcXpath = xmlgeneral.RouteByXPath (kong, soapEnvelope_transformed, 
                                            plugin_conf.RouteXPath, plugin_conf.RouteXPathCondition, plugin_conf.RouteXPathRegisterNs)
    -- If the condition is statsfied we change the Upstream
    if rcXpath then
      kong.service.set_upstream(plugin_conf.RouteToUpstream)
      kong.service.request.set_path(plugin_conf.RouteToPath)
      kong.log.notice("Upstream changed successfully")
    end
  end

  return soapEnvelope_transformed, soapFaultBody

end

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  local xmlgeneral = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")
  
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

return plugin