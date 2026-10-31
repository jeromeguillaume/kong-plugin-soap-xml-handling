-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers             = require "spec.helpers"
local request_common      = require "spec.common.request"
local response_common     = require "spec.common.response"
local soapAction_common   = require "spec.common.soapAction"
local soap12_common       = require "spec.common.soap12"
local caching_common      = require "spec.common.caching"
local saxon_common        = require "spec.common.saxon"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse
local xsltLibrary    = "saxon"

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
    describe("libxml+saxon |", function()
			
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

        local httpbin_service = blue_print.services:insert({
          protocol = "http",
          host = "httpbin",
          port = 8080,
          path = "/anything",
          name = "httpbin"
        })

        local calculator_JSON_2_XML_Transformation_ok_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_JSON_2_XML_Transformation_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_JSON_2_XML_Transformation_ok_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/JSON_2_XML/1_json2xml_XSLT_BEFORE.xslt"
          }
        }
        blue_print.plugins:insert { 
          name = pluginResponse,
          route = calculator_JSON_2_XML_Transformation_ok_route,
          config = {
            VerboseResponse = true,
            xsltLibrary = xsltLibrary,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/JSON_2_XML/7_json2xml_XSLT_AFTER.xslt"
          }
        }
        
        local calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/invalidXML/1_3_5_7_invalid_XSLT.xslt"
          }
        }

        local calculatorXSLT_beforeXSD_req_invalid_filepath_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_beforeXSD_req_invalid_filepath_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_beforeXSD_req_invalid_filepath_xml_def_file_route,
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___.xml"
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
      
      it ("1+2+6+7|JSON to XML Transformation - XML Definitions in Files - Ok", function()
				-- invoke a test request
        local r = client:post("/calculator_JSON_2_XML_Transformation_ok", {
          headers = {
            ["Content-Type"] = "application/json",
          },
          body = saxon_common.calculator_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("application/json", content_type)
        local json = assert.response(r).has.jsonbody()
        assert.same (saxon_common.calculator_JSON_2_XML_Transformation_ok, json)
			end)

      it("1|XSLT (BEFORE XSD) - Invalid XSLT input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(saxon_common.error_XML_message_Request_XSLT_transfo_before_XSD_val_verbose, body)
      end)

      it("1|XSLT (BEFORE XSD) - Invalid File path - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_beforeXSD_req_invalid_filepath_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("'/kong%-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___%.xml: No such file or directory'", body)
      end)



		end)		
	end)
  ::continue::
end