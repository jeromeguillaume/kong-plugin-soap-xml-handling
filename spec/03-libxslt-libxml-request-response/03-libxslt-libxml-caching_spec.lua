-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers                   = require "spec.helpers"
local request_common            = require "spec.common.request"
local response_common           = require "spec.common.response"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse
local xsltLibrary    = "libxslt"

local pluginRequest_log   = "\\["..pluginRequest.."\\] "
local pluginResponse_log  = "\\["..pluginResponse.."\\] "

local caching_compile_xslt                = "XSLT transformation, caching: Compile the XSLT and Put it in the cache"
local caching_compile_wsdl                = "WSDL Validation, caching: Compile the WSDL and Put it in the cache"
local caching_compile_xsd                 = "XSD Validation, caching: Compile the XSD and Put it in the cache"
local caching_compile_SOAPAction          = nil -- It doesn't exist because it uses the WSDL caching
local caching_compile_routeByXPath        = "RouteByXPath, caching: Create the Parser Context and Put it in the cache"

local caching_compile_wsdl_prefetch       = "XMLValidateWithWSDL, prefetch: so get all XSDs and raise the download of External Entities"
local caching_compile_xsd_prefetch        = "XSD Validation, prefetch: Compile XSD and Raise the download of External Entities"

local caching_compile_wsdl_async          = "WSDL Validation, no WSDL caching due to Asynchronous external entities"
local caching_compile_xsd_async           = "XSD Validation, no XSD caching due to Asynchronous external entities"
local caching_compile_SOAPAction_async  = "getSOAPActionFromWSDL: no WSDL caching due to Asynchronous external entities"

local caching_get_xslt                    = "XSLT transformation, caching: Get the compiled XSLT from cache"
local caching_get_wsdl                    = "WSDL Validation, caching: Get the compiled WSDL from cache"
local caching_get_xsd                     = "XSD Validation, caching: Get the compiled XSD from cache"
local caching_get_SOAPAction              = "getSOAPActionFromWSDL: caching: Get the compiled WSDL from cache"
local caching_get_routeByXPath            = "RouteByXPath, caching: Get the Parser Context from cache"

----------------------------------------------------------------------------------------------------
-- This WSDL 1.1 provides:
--   The Namespace prefix of wsdl 1.1 is 'wsdl'
--   The Namespace prefix of soap 1.1 is 'soap'
--   The Namespace prefix of soap 1.2 is 'soap12'
--   JMS and HTTP transport and the plugin supports only HTTP Transport
--
-- soap 1.1 -> 2 HTTP operations defined with transport="http://schemas.xmlsoap.org/soap/http"/
--    Add       with    soapActionRequired="true"
--    Subtract  with    soapActionRequired="false"
--
-- soap 1.1 -> 2 JMS operations defined with transport="http://cxf.apache.org/transports/jms"/
--
-- soap 1.2 -> 5 HTTP operations + 2 JMS operations defined (like above)
----------------------------------------------------------------------------------------------------
local calculatorWSDL11_soap_soap12= [[
<?xml version="1.0" encoding="utf-8"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <wsdl:types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <s:element name="Add">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="AddResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="AddResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Subtract">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="SubtractResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="SubtractResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
    </s:schema>
  </wsdl:types>
  <wsdl:message name="AddSoapIn">
    <wsdl:part name="parameters" element="tns:Add" />
  </wsdl:message>
  <wsdl:message name="AddSoapOut">
    <wsdl:part name="parameters" element="tns:AddResponse" />
  </wsdl:message>
  <wsdl:message name="SubtractSoapIn">
    <wsdl:part name="parameters" element="tns:Subtract" />
  </wsdl:message>
  <wsdl:message name="SubtractSoapOut">
    <wsdl:part name="parameters" element="tns:SubtractResponse" />
  </wsdl:message>
  <wsdl:portType name="CalculatorSoap">
    <wsdl:operation name="Add">
      <wsdl:documentation xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">Adds two integers. This is a test WebService. ©DNE Online</wsdl:documentation>
      <wsdl:input message="tns:AddSoapIn" />
      <wsdl:output message="tns:AddSoapOut" />
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <wsdl:input message="tns:SubtractSoapIn" />
      <wsdl:output message="tns:SubtractSoapOut" />
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="CalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="Add">
      <soap:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="Calculator">
    <wsdl:port name="CalculatorSoap" binding="tns:CalculatorSoap">
      <soap:address location="http://www.dneonline.com/calculator.asmx" />
    </wsdl:port>    
  </wsdl:service>
</wsdl:definitions>
]]

local calculator_Request_XSLT_change_intB = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output version="1.0" method="xml" encoding="utf-8" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='intB']">
    <xsl:copy-of select="."/>
      <intB>13</intB>
  </xsl:template>
</xsl:stylesheet>
]]

for _, strategy in helpers.all_strategies() do
  if strategy == "off" then
    goto continue
  end

	describe(PLUGIN_NAME .. ": [#" .. strategy .. "]", function()
    
    setup(function()
    end)

    -- before_each runs before each child describe
    before_each(function()
      client = helpers.proxy_client()
    end)

    -- after_each runs after each child describe
    after_each(function()
      if client then client:close() end          
    end)

    -- a nested describe defines an actual test on the plugin behavior
    describe("libxml+libxslt |", function()
			
      lazy_setup(function()			
    
        -- A BluePrint gives us a helpful database wrapper to
        --    manage Kong Gateway entities directly.
        -- This function also truncates any existing data in an existing db.
        -- The custom plugin name is provided to this function so it mark as loaded
        local blue_print = helpers.get_db_utils(strategy, nil, { pluginRequest,  pluginResponse })
              
        local calculator_service = blue_print.services:insert({
            protocol = "http",
            host = "ws.soap1.calculator",
            port = 8080,
            path = "/ws",
          })
        
        local calculator_fullSoapXml_handling_Request_Response_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            xsltTransformBefore = request_common.calculator_Request_XSLT_AFTER,
            xsdApiSchema = calculatorWSDL11_soap_soap12,
            xsltTransformAfter = calculator_Request_XSLT_change_intB,
            SOAPAction_Header = "yes",
            RouteXPathTargets = {
              {
                  URL= "http://ws.soap2.calculator:8080/ws",
                  XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
                  XPathCondition= "5"
              },
            }
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_fullSoapXml_handling_Request_Response_route,
          config = {
            VerboseResponse = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
            xsltTransformAfter = response_common.calculator_Request_XSLT_AFTER
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_Async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsltTransformBefore = request_common.calculator_Request_XSLT_AFTER,
            xsdApiSchema = calculatorWSDL11_soap_soap12,
            xsltTransformAfter = calculator_Request_XSLT_change_intB,
            SOAPAction_Header = "yes",
            RouteXPathTargets = {
              {
                  URL= "http://ws.soap2.calculator:8080/ws",
                  XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
                  XPathCondition= "5"
              },
            }
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_fullSoapXml_handling_Request_Response_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = xsltLibrary,
            xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
            xsltTransformAfter = response_common.calculator_Request_XSLT_AFTER
          }
        }
        
        -- start kong
        assert(helpers.start_kong({
          -- use the custom test template to create a local mock server
          nginx_conf = "spec/fixtures/custom_nginx.template",
          -- make sure our plugin gets loaded
          plugins = "bundled," .. PLUGIN_NAME
        }))
    
      end)

      lazy_teardown(function()
				helpers.stop_kong(nil, true)
			end)
      
     it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - NO Import - ExternalEntityLoader_Async=false, - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)

        -- Here we check in the log that Prefetching of WSDL and XSDs was done: this is not related to this spectif test
        -- Check now because the log will be cleaned in the next test (clean_logfile())
        assert.logfile().has.line(caching_compile_wsdl_prefetch)
        assert.logfile().has.line(caching_compile_xsd_prefetch)

        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(pluginRequest_log..caching_compile_xslt)
        assert.logfile().has.line(pluginRequest_log..caching_compile_wsdl)
        assert.logfile().has.line(pluginRequest_log..caching_compile_xsd)
        assert.logfile().has.line(pluginRequest_log..caching_get_SOAPAction)
        assert.logfile().has.line(pluginRequest_log..caching_compile_routeByXPath)

        -- Plugin Response: Check in the log that the XSLT / WSDL definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(pluginResponse_log..caching_compile_xslt)
        assert.logfile().has.line(pluginResponse_log..caching_compile_wsdl)
        assert.logfile().has.line(pluginResponse_log..caching_compile_xsd)
     end)

     it("1+2+3+4+5+6+7|** Execute the same test: check the 'caching' works **", function()        
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })
        
        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions were not re-compiled
        assert.logfile().has.no.line(pluginRequest_log..caching_compile_wsdl)

        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions used the caching
        assert.logfile().has.line(pluginRequest_log..caching_get_xslt)
        assert.logfile().has.line(pluginRequest_log..caching_get_wsdl)
        assert.logfile().has.line(pluginRequest_log..caching_get_xsd)
        assert.logfile().has.line(pluginRequest_log..caching_get_SOAPAction)
        assert.logfile().has.line(pluginRequest_log..caching_get_routeByXPath)

        -- Plugin Request: Check in the log that the XSLT / WSDL definitions were not re-compiled
        assert.logfile().has.no.line(pluginResponse_log..caching_compile_wsdl)

        -- Plugin Request: Check in the log that the XSLT / WSDL definitions used the caching
        assert.logfile().has.line(pluginResponse_log..caching_get_xslt)
        assert.logfile().has.line(pluginResponse_log..caching_get_wsdl)
        assert.logfile().has.line(pluginResponse_log..caching_get_xsd)

     end)

    it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - NO Import - ExternalEntityLoader_Async=true - Ok", function()
      -- clean the log file
      helpers.clean_logfile()
      
      -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_Async_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        

        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions were compiled for the 1st time (and not found in the cache)        
        assert.logfile().has.line(pluginRequest_log..caching_compile_xslt)
        assert.logfile().has.line(pluginRequest_log..caching_compile_wsdl_async)
        assert.logfile().has.line(pluginRequest_log..caching_compile_xsd_async)
        assert.logfile().has.line(pluginRequest_log..caching_compile_SOAPAction_async)
        assert.logfile().has.line(pluginRequest_log..caching_compile_routeByXPath)
        
        -- Plugin Response: Check in the log that the XSLT / WSDL definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(pluginResponse_log..caching_compile_xslt)
        assert.logfile().has.line(pluginResponse_log..caching_compile_wsdl_async)
        assert.logfile().has.line(pluginResponse_log..caching_compile_xsd_async)
     end)

		end)		
	end)
  ::continue::
end