-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers         = require "spec.helpers"
local request_common  = require "spec.common.request"
local response_common = require "spec.common.response"
local soap12_common   = require "spec.common.soap12"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse
local xsltLibrary = "libxslt"

for _, strategy in helpers.all_strategies() do
  if strategy == "off" then
    goto continue
  end

	describe(PLUGIN_NAME .. ": [#" .. strategy .. "]", function()
    -- Will be initialized before_each nested test
    local client

    setup(function()
    end)

    -- teardown runs after its parent describe block
    teardown(function()
      helpers.stop_kong(nil, true)
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
          host = "www.dneonline.com",
          port = 80,
          path = "/calculator.asmx",
        })

      local tempui_org_request_response_xsd = blue_print.routes:insert{
        paths = { "/tempuri.org.request-response.xsd" }
      }
      blue_print.plugins:insert {
        name = "request-termination",
        route = tempui_org_request_response_xsd,
        config = {
          status_code = 200,
          content_type = "text/xml; charset=utf-8",
          body = request_common.calculator_Request_Response_XSD_VALIDATION
        }
      }

      local calculator_soap12_XSD_with_import_no_download_ok_route = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculator_soap12_XSD_with_import_no_download_ok" }
        }
      blue_print.plugins:insert {
        name = pluginRequest,
        route = calculator_soap12_XSD_with_import_no_download_ok_route,
        config = {
          VerboseRequest = false,
          xsdApiSchemaInclude = {
            ["http://localhost:9000/tempuri.org.request-response.xsd"] = request_common.calculator_Request_Response_XSD_VALIDATION
          },
          xsdApiSchema = request_common.calculatorWSDL_with_async_download_Ok,
          xsdSoapSchema = soap12_common.soap12_XSD,
          xsdSoapSchemaInclude = {
            ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
          }
        }
      }
      blue_print.plugins:insert {
        name = pluginResponse,
        route = calculator_soap12_XSD_with_import_no_download_ok_route,
        config = {
          VerboseResponse = false,
          xsdApiSchemaInclude = {
            ["http://localhost:9000/tempuri.org.request-response.xsd"] = request_common.calculator_Request_Response_XSD_VALIDATION
          },
          xsdApiSchema = request_common.calculatorWSDL_with_async_download_Ok,
          xsdSoapSchema = soap12_common.soap12_XSD,
          xsdSoapSchemaInclude = {
            ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
          }
        }
      }
      
      local calculator_soap12_XSD_with_async_download_ok_route = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculator_soap12_XSD_with_async_download_ok" }
        }
      blue_print.plugins:insert {
        name = pluginRequest,
        route = calculator_soap12_XSD_with_async_download_ok_route,
        config = {
          VerboseRequest = false,
          ExternalEntityLoader_Async = true,
          xsdApiSchema = request_common.calculatorWSDL_with_async_download_Ok,
          xsdSoapSchema = soap12_common.soap12_XSD,
        }
      }
      blue_print.plugins:insert {
        name = pluginResponse,
        route = calculator_soap12_XSD_with_async_download_ok_route,
        config = {
          VerboseResponse = false,
          ExternalEntityLoader_Async = true,
          xsdApiSchema = request_common.calculatorWSDL_with_async_download_Ok,
          xsdSoapSchema = soap12_common.soap12_XSD,
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

      it("2+6|Request and Response plugins|SOAP 1.2 - XSD (SOAP env) + WSDL (API) Validation with import no download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_import_no_download_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("application/soap+xml; charset=utf-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)
      
      it("2+6|Request and Response plugins|SOAP 1.2 - XSD (SOAP env) + WSDL (API) Validation with async download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_async_download_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("application/soap+xml; charset=utf-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)
  
		end)		
	end)
  ::continue::
end
