-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers             = require "spec.helpers"
local request_common      = require "spec.common.request"
local response_common     = require "spec.common.response"
local soapAction_common   = require "spec.common.soapAction"
local soap12_common       = require "spec.common.soap12"
local caching_common      = require "spec.common.caching"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse
local xsltLibrary    = "libxslt"

for _, strategy in helpers.all_strategies() do
  if strategy == "off" then
    goto continue
  end

	describe(PLUGIN_NAME .. ": [#" .. strategy .. "]", function()
    -- Will be initialized before_each nested test
    local client

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
        
        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_CacheTTL = 3600,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xml",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12-import.xml",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xml",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/6_XSD-KongResult.xml",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xml",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xml"
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
      
     it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files - No import - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add",
            ["Connection"] = "keep-alive"
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
        
			end)

		end)		
	end)
  ::continue::
end