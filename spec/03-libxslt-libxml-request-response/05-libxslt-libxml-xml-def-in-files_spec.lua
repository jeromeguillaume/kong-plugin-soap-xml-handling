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
        
        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "1_XSLT_BEFORE.xslt",
            xsdApiSchema = "2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "5_XSLT_BEFORE.xslt",
            xsdApiSchema = "2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }


        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "1_XSLT_BEFORE.xslt",
            xsdApiSchema = "2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "5_XSLT_BEFORE.xslt",
            xsdApiSchema = "2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "7_XSLT_AFTER.xslt"
          }
        }

        local calculatorWSDL_with_multiple_XSD_http_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_with_multiple_XSD_http_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_with_multiple_XSD_http_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_http_import.wsdl",
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Add_XSD.xsd",
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Subtract_XSD.xsd"
            },
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorWSDL_with_multiple_XSD_http_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_http_import.wsdl",
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Add_XSD.xsd",
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Subtract_XSD.xsd"
            },
          }
        }

        local calculatorWSDL_with_multiple_XSD_file_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_with_multiple_XSD_file_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_with_multiple_XSD_file_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import.wsdl"
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorWSDL_with_multiple_XSD_file_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import.wsdl"
          }
        }

        local calculatorXSLT_beforeXSD_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_beforeXSD_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_beforeXSD_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/invalidXML/1_3_5_7_invalid_XSLT.xslt"
          }
        }

        local calculatorXSLT_WSDL_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_WSDL_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/invalidXML/2_6_invalid_WSDL.wsdl"            
          }
        }

        local calculatorXSLT_afterXSD_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_afterXSD_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_afterXSD_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/invalidXML/1_3_5_7_invalid_XSLT.xslt"
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
      
      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files - No import - Sync - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_ok", {
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

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files - No import - Async - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_ok", {
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
      
      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files with path Prefix - No import - Sync - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_ok", {
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

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files at root ignoring path Prefix - No import - Sync - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_ok", {
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

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files at root ignoring path Prefix - No import - Async - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_ok", {
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

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files with path Prefix - No import - Async - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_ok", {
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

      it("2+6|WSDL Validation with multiple XSD http imported with include definitions - XML Definition in Files - Add in XSD#1 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_XSD_http_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "text/xml;charset=utf-8",
            },
            body = request_common.calculator_Full_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("text/xml%;%s-charset=utf%-8", content_type)
          assert.matches('<AddResult>12</AddResult>', body)      
			end)

      it("2+6|WSDL Validation with multiple XSD http imported with include definitions - XML Definition in Files - Subtract in XSD#2 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_XSD_http_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "text/xml;charset=utf-8",
            },
            body = request_common.calculator_Subtract_Full_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("text/xml%;%s-charset=utf%-8", content_type)
          assert.matches("<SubtractResult>4</SubtractResult>", body)
			end)

      it("2+6|WSDL Validation with multiple XSD file imported - XML Definition in Files - Add in XSD#1 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_XSD_file_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "text/xml;charset=utf-8",
            },
            body = request_common.calculator_Full_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("text/xml%;%s-charset=utf%-8", content_type)
          assert.matches('<AddResult>12</AddResult>', body)      
			end)

      it("2+6|WSDL Validation with multiple XSD file imported - XML Definition in Files - Subtract in XSD#2 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_XSD_file_imported_with_include_defintion_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "text/xml;charset=utf-8",
            },
            body = request_common.calculator_Subtract_Full_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("text/xml%;%s-charset=utf%-8", content_type)
          assert.matches("<SubtractResult>4</SubtractResult>", body)
			end)

      it("1|XSLT (BEFORE XSD) - Invalid XSLT input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_beforeXSD_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose, body)
      end)

      it("2|WSDL - Invalid WSDL input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_INPUT_Failed_verbose, body)
      end)

      it("3|XSLT (AFTER XSD) - Invalid XSLT input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_afterXSD_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSLT_AFTER_Failed_verbose, body)                                      
      end)

		end)		
	end)
  ::continue::
end