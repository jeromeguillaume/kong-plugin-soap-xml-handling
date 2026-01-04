-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers         = require "spec.helpers"
local request_common  = require "spec.common.request"
local response_common = require "spec.common.response"
local soap12_common   = require "spec.common.soap12"

-- Add a Worker Process for enabling the synchronous download of external entities
helpers.setenv("KONG_NGINX_WORKER_PROCESSES", "2")

helpers.setenv("KONG_LOG_LEVEL", "debug")

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse
local xsltLibrary = "libxslt"

for _, strategy in helpers.all_strategies() do
  --if strategy == "off" then
  --  goto continue
  --end

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
            VerboseRequest = true,
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.request-response.xsd"] = request_common.calculator_Request_Response_XSD_VALIDATION
            },
            xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok,
            xsdSoap12Schema = soap12_common.soap12_XSD,
            xsdSoap12SchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_soap12_XSD_with_import_no_download_ok_route,
          config = {
            VerboseResponse = true,
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.request-response.xsd"] = request_common.calculator_Request_Response_XSD_VALIDATION
            },
            xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok,
            xsdSoap12Schema = soap12_common.soap12_XSD,
            xsdSoap12SchemaInclude = {
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
            VerboseRequest = true,
            ExternalEntityLoader_Timeout = 5,
            ExternalEntityLoader_Async = true,
            xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok,
            xsdSoap12Schema = soap12_common.soap12_XSD,
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_soap12_XSD_with_async_download_ok_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_Timeout = 5,
            xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok,
            xsdSoap12Schema = soap12_common.soap12_XSD,
          }
        }

        local calculator_soap12_XSD_with_sync_download_ok_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_soap12_XSD_with_sync_download_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap12_XSD_with_sync_download_ok_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = false,
            xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok,
            xsdSoap12Schema = soap12_common.soap12_XSD,
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_soap12_XSD_with_sync_download_ok_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok,
            xsdSoap12Schema = soap12_common.soap12_XSD,
          }
        }
        
        local calculator_soap11_no_XSD_ko_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_soap11_no_XSD_ko" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap11_no_XSD_ko_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = false,
            xsdSoapSchema = nil,
            xsdSoap12Schema = soap12_common.soap12_XSD,
            xsdSoap12SchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }

        local calculator_soap12_no_XSD_ko_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_soap12_no_XSD_ko" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap12_no_XSD_ko_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = false,
          }
        }
        
        local local_req_invalid_soap_ns_termination_route = blue_print.routes:insert{
          paths = { "/local_calculator_invalid_soap_ns_req_termination" }
        }
        blue_print.plugins:insert {
          name = "request-termination",
          route = local_req_invalid_soap_ns_termination_route,
          config = {
            status_code = 200,
            content_type = "text/xml; charset=utf-8",
            body = response_common.calculator_Response_Invalid_SOAP_NameSpace
          }	
        }
        local calculator_local_invalid_soap_ns_service = blue_print.services:insert({
          protocol = "http",
          host = "localhost",
          port = 9000,
          path = "/local_calculator_invalid_soap_ns_req_termination",
        })

        local calculator_invalid_soap_ns_ko_route = blue_print.routes:insert{
          service = calculator_local_invalid_soap_ns_service,
          paths = { "/calculator_invalid_soap_ns_ko" }
          }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_invalid_soap_ns_ko_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            xsdSoap12Schema = soap12_common.soap12_XSD,
            xsdSoap12SchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }

        local calculator_soap12_RoutingByXPath_hostname_route = blue_print.routes:insert{
          service= calculator_service,
          paths= { "/calculator_soap12_RoutingByXPath_hostname_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap12_RoutingByXPath_hostname_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            xsdSoap12Schema = soap12_common.soap12_XSD,
            xsdSoap12SchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            },
            RouteXPathRegisterNs = {
      				request_common.ROUTING_BY_XPATH_ns_default,
				      soap12_common.ROUTING_BY_XPATH_soap12_ns_default,
			      },
            RouteXPathTargets = {
              {
                  URL= "http://ws.soap2.calculator:8080/ws",
                  XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
                  XPathCondition= "5"
              },
              {
                  URL= "http://ws.soap2.calculator:8080/ws",
                  XPath= "/soap12:Envelope/soap12:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
                  XPathCondition= "5"
              },              
            }
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
      
      it("2+6|Request and Response plugins|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.1 req/res - XSD (SOAP env) + WSDL (API) Validation with import no download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_import_no_download_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
	      local content_type = assert.response(r).has.header("Content-Type")
	      assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	      assert.matches('<AddResult>12</AddResult>', body)
      end)
      
      it("2+6|Request and Response plugins|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.2 req/res - XSD (SOAP env) + WSDL (API) Validation with import no download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_import_no_download_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2+6|Request and Response plugins|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.1 req/res - XSD (SOAP env) + WSDL (API) Validation with Async download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_async_download_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
	      local content_type = assert.response(r).has.header("Content-Type")
	      assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	      assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2+6|Request and Response plugins|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.2 req/res - XSD (SOAP env) + WSDL (API) Validation with Async download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_async_download_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2+6|Request and Response plugins|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.1 req/res - XSD (SOAP env) + WSDL (API) Validation with Sync download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_sync_download_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
	      local content_type = assert.response(r).has.header("Content-Type")
	      assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	      assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2+6|Request and Response plugins|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.2 req/res - XSD (SOAP env) + WSDL (API) Validation with Sync download - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_sync_download_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      -- Unable to unset 'xsdSoapSchema' in the plugin configuration for Pongo (it's do-able with Kong Manager...)

--      it("2|No SOAP 1.1 XSD definition - KO", function()
--        -- invoke a test request
--        local r = client:post("/calculator_soap11_no_XSD_ko", {
--          headers = {
--            ["Content-Type"] = "text/xml;charset=utf-8",
--          },
--          body = request_common.calculator_Full_Request,
--        })
--
--        -- validate that the request failed: response status 500, Content-Type and right match
--        local body = assert.response(r).has.status(500)
--	      local content_type = assert.response(r).has.header("Content-Type")
--	      assert.matches("text/xml%;%s-charset=utf%-8", content_type)
--	      assert.matches(request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_Failed_with_no_11_schema_verbose, body)
--      end)
      
      it("2|No SOAP 1.2 XSD definition - KO", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_no_XSD_ko", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(soap12_common.calculator_soap12_Request_XSD_VALIDATION_Failed_with_no_12_schema, body)
      end)

      it("2|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.1 req/res - Invalid SOAP namespace - Ko", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_import_no_download_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request_Invalid_SOAP_NameSpace,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
	      local content_type = assert.response(r).has.header("Content-Type")
	      assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	      assert.matches(request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_Invalid_Namespace_Client_verbose, body)
      end)
      
      it("2|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.2 req/res - Invalid SOAP namespace - Ko", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_XSD_with_import_no_download_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = request_common.calculator_Request_Invalid_SOAP_NameSpace,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
	      local content_type = assert.response(r).has.header("Content-Type")
	      assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
	      assert.matches(soap12_common.calculator_soap12_Request_XSD_VALIDATION_Failed_Invalid_NameSpace, body)
      end)
      
      it("6|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.1 req/res - Invalid SOAP namespace - Ko", function()
        -- invoke a test request
        local r = client:post("/calculator_invalid_soap_ns_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
	      local content_type = assert.response(r).has.header("Content-Type")
	      assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	      assert.matches(response_common.calculator_Response_XSD_SOAP_VALIDATION_REQUEST_Invalid_Namespace_Client_verbose, body)
      end)
    
    it("6|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.2 req/res - Invalid SOAP namespace - Ko", function()
        -- invoke a test request
        local r = client:post("/calculator_invalid_soap_ns_ko", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
	      local content_type = assert.response(r).has.header("Content-Type")
	      assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
	      assert.matches(soap12_common.calculator_soap12_Response_XSD_VALIDATION_Failed_Invalid_NameSpace, body)
      end)

      it("2+4|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.1 req/res - ROUTING BY XPATH with 'hostname' - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_RoutingByXPath_hostname_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })
        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.equal("soap2", x_soap_region)
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)      
      end)

      it("2+4|Multiple SOAP XSD definitions (1.1 and 1.2) - SOAP 1.2 req/res - ROUTING BY XPATH with 'hostname' - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_soap12_RoutingByXPath_hostname_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = soap12_common.calculator_soap12_Request,
        })
        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.equal("soap2", x_soap_region)
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)      
      end)

		end)    

	end)
  ::continue::
end
