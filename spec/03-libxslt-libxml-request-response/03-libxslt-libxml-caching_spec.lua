-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers                   = require "spec.helpers"
local request_common            = require "spec.common.request"
local response_common           = require "spec.common.response"
local soapAction_common         = require "spec.common.soapAction"
local soap12_common             = require "spec.common.soap12"
local caching_common            = require "spec.common.caching"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = caching_common.pluginRequest
local pluginResponse = caching_common.pluginResponse
local PLUGIN_NAME    = pluginRequest..","..pluginResponse

-- Force the number of Worker Process (for checking the cache behavior on the same worker)
helpers.setenv("KONG_NGINX_WORKER_PROCESSES", "1")

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
        
        local calculator_fullSoapXml_handling_Request_Response_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_Async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = caching_common.libxslt,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsltTransformBefore = request_common.calculator_Request_XSLT_AFTER,
            xsdApiSchema = soapAction_common.calculatorWSDL11_soap_soap12,
            xsltTransformAfter = caching_common.calculator_Request_XSLT_change_intB,
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
            ExternalEntityLoader_CacheTTL = caching_common.TTL,            
            xsltLibrary = caching_common.libxslt,
            xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
            xsltTransformAfter = response_common.calculator_Request_XSLT_AFTER
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_Sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = caching_common.libxslt,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsltTransformBefore = request_common.calculator_Request_XSLT_AFTER,
            xsdApiSchema = soapAction_common.calculatorWSDL11_soap_soap12,
            xsltTransformAfter = caching_common.calculator_Request_XSLT_change_intB,
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
          route = calculator_fullSoapXml_handling_Request_Response_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,            
            xsltLibrary = caching_common.libxslt,
            xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
            xsltTransformAfter = response_common.calculator_Request_XSLT_AFTER
          }
        }
        
        local calculatorWSDL_with_async_download_invalid_import_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_with_async_download_invalid_import" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_with_async_download_invalid_import_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = true,
            xsdApiSchema = request_common.calculatorWSDL_with_async_download_Failed
          }
        }

        local calculatorWSDL_with_multiple_imports_include_XSD_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_with_multiple_imports_include_XSD_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_with_multiple_imports_include_XSD_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsdApiSchema = request_common.calculatorWSDL_req_res_multiple_imports_Ok,
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = request_common.calculator_Request_Response_Add_XSD_VALIDATION,
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = request_common.calculator_Request_Response_Subtract_XSD_VALIDATION,
            },
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorWSDL_with_multiple_imports_include_XSD_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsdApiSchema = request_common.calculatorWSDL_req_res_multiple_imports_Ok,
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = request_common.calculator_Request_Response_Add_XSD_VALIDATION,
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = request_common.calculator_Request_Response_Subtract_XSD_VALIDATION,
            },
          }
        }

        local calculatorReq_XSLT_beforeXSD_invalid_verbose_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorReq_XSLT_beforeXSD_invalid_verbose" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorReq_XSLT_beforeXSD_invalid_verbose_route,
          -- it lacks the '<' beginning tag
          config = {
            VerboseRequest = true,
            xsltLibrary = caching_common.libxslt,
            xsltTransformBefore = [[
              xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
              </xsl:stylesheet>
            ]]
          }	
        }

        local calculatorRes_XSLT_beforeXSD_invalid_verbose_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorRes_XSLT_beforeXSD_invalid_verbose" }
          }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorRes_XSLT_beforeXSD_invalid_verbose_route,
          config = {
            VerboseResponse = true,
            xsltLibrary = caching_common.libxslt,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_invalid
          }
        }

        local calculator_wsdl11_soap_xsd_defined_instead_of_wsdl_ko = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_SOAPAction_xsd_defined_instead_of_wsdl_ko" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_wsdl11_soap_xsd_defined_instead_of_wsdl_ko,
          config = {
            VerboseRequest = true,
            xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,          
            SOAPAction_Header = "yes"        
          }
        }

        local calculator_soap12_with_included_import_no_download_route_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_soap12_with_included_import_no_download_route_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap12_with_included_import_no_download_route_ok,
          config = {
            VerboseRequest = false,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsdSoapSchema = soap12_common.soap12_XSD,
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_soap12_with_included_import_no_download_route_ok,
          config = {
            VerboseResponse = false,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsdSoapSchema = soap12_common.soap12_XSD,
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }

        local calculator_soap12_with_import_async_download_route_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_soap12_with_import_async_download_route_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap12_with_import_async_download_route_ok,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,            
            xsdSoapSchema = soap12_common.soap12_XSD
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_soap12_with_import_async_download_route_ok,
          config = {
            VerboseResponse = false,
            ExternalEntityLoader_Async = true,            
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsdSoapSchema = soap12_common.soap12_XSD
          }
        }

        local calculator_xsd_soap_invalid_verbose_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSD_SOAP_invalid_verbose" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_xsd_soap_invalid_verbose_route,
          config = {
            VerboseRequest = true,
            xsdSoapSchema = request_common.calculator_Request_XSD_API_VALIDATION_invalid
          }
        }

        -- start kong
        assert(helpers.start_kong({
            -- use the custom test template to create a local mock server
            nginx_conf = "spec/fixtures/custom_nginx.template",
            proxy_listen = "0.0.0.0:9000 reuseport, 0.0.0.0:9443 ssl",         
            -- make sure our plugin gets loaded
            plugins = "bundled," .. PLUGIN_NAME
          }))
      end)

      lazy_teardown(function()
				helpers.stop_kong(nil, true)
			end)
      
      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - NO Import - Async download - Ok", function()
        -- clean the log file
        helpers.clean_logfile()
        
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_Async_ok", {
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

        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.xsd_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.SOAPAction_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_routeByXPath)
        
        -- Plugin Response: Check in the log that the XSLT / WSDL definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.xsd_async)
      end)

      it("1+2+3+4+5+6+7|** Execute the same test: check that the WSDL/XSD definitions are compiled again (due to Asynchronous) and XSLT/RouteByXPath are still cached (before TTL is exceeded) **", function()
        -- clean the log file
        helpers.clean_logfile()
        
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_Async_ok", {
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

        -- Plugin Request: Check in the log that the WSDL / XSD / SOAPAction definitions were compiled for the 1st time (and not found in the cache)        
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.xsd_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.SOAPAction_async)
        
        -- Plugin Request: Check in the log that the XSLT / XPathRouting definitions used the cache
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xslt)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_routeByXPath)
        
        -- Plugin Response: Check in the log that the WSDL / XSD definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.xsd_async)

        -- Plugin Response: Check in the log that the XSLT definition used the cache
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xslt)
        
      end) 

      it("1+2+3+4+5+6+7|** Execute the same test: check that the WSDL/XSD definitions are compiled again (due to Asynchronous) and XSLT/RouteByXPath are compiled again (after TTL is exceeded) **", function()
        -- clean the log file
        helpers.clean_logfile()
        
        print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
        ngx.sleep(caching_common.TTL)

        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_Async_ok", {
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

                -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.xsd_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.SOAPAction_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_routeByXPath)
        
        -- Plugin Response: Check in the log that the XSLT / WSDL definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.xsd_async)
        
      end)      

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - NO Import - Sync download - Ok", function()
        -- clean the log file
        helpers.clean_logfile()
        
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_Sync_ok", {
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

        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_SOAPAction_ctx_doc)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_routeByXPath)
        
        -- Plugin Response: Check in the log that the XSLT / WSDL definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
      end)

      it("1+2+3+4+5+6+7|** Execute the same test (before TTL is exceeded): check that the definitions are still cached **", function()
        -- clean the log file
        helpers.clean_logfile()
        
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_Sync_ok", {
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

        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions used the cache
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xslt)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xsd)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction_wsdlDef)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction_ctx_ptr)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_routeByXPath)
        
        -- Plugin Response: Check in the log that the XSLT / WSDL definition used the cache
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xslt)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_wsdl)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xsd)
        
      end)
      
      it("1+2+3+4+5+6+7|** Execute the same test (after TTL is exceeded): check that the definitions are compiled again (due to TTL exceeded) **", function()
        -- clean the log file
        helpers.clean_logfile()

        print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
        ngx.sleep(caching_common.TTL)
        
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_Sync_ok", {
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

        -- Plugin Request: Check in the log that the XSLT / WSDL / SOAPAction / XPathRouting definitions were recompiled due to TTL exceeded
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl_TTL)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_TTL)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_SOAPAction_ctx_doc)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_routeByXPath)
        
        -- Plugin Response: Check in the log that the XSLT / WSDL definition were recompiled due to TTL exceeded
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl_TTL)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd_TTL)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
        
      end)
      
      it("2|WSDL Validation with Async download - Invalid Import", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_async_download_invalid_import", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed_shortened, body)
	      assert.matches("<errorMessage>.*Failed to.*'http://localhost:9000/DOES_NOT_EXIST'.*</errorMessage>", body)

        -- Plugin Request: Check in the log that the WSDL / XSDs definitions were recompiled due to Error
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.xsd_async)        
      end)

      it("** Execute the same test - Invalid Import: check that the definitions are compiled again (due to Async) **", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_async_download_invalid_import", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed_shortened, body)
	      assert.matches("<errorMessage>.*Failed to.*'http://localhost:9000/DOES_NOT_EXIST'.*</errorMessage>", body)

        -- Plugin Request: Check in the log that the WSDL / XSDs definitions were recompiled due to Error
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.wsdl_async)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.xsd_async)
      end)

      it("2+6|WSDL Validation with multiple imports included XSD no download - Add in XSD#1", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_imports_include_XSD_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Full_Request,
        })
        
        -- validate that the request failed: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
        -- Plugin Request/Response: Check in the log that the WSDL / XSDs definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
      end)

      it("2+6|** Execute more or less the same test by using Subtract in XSD#2 (before TTL is exceeded): check that the definitions are still cached **", function()
        -- clean the log file
        helpers.clean_logfile()
        
        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_imports_include_XSD_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request failed: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("<SubtractResult>4</SubtractResult>", body)
        
        -- Plugin Request/Response: Check in the log that the WSDL definitions were not re-compiled
        assert.logfile().has.no.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.no.line(caching_common.pluginRes_log..caching_common.compile_wsdl)

        -- Plugin Request/Response: Check in the log that the WSDL / XSDs definitions used the cache
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_wsdl)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xsd)
      end)

      it("2+6|** Execute the same test (after  TTL is exceeded): check that the definitions are compiled again (due to TTL exceeded) **", function()
        -- clean the log file
        helpers.clean_logfile()
        
        print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
        ngx.sleep(caching_common.TTL)

        -- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_imports_include_XSD_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"            
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request failed: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("<SubtractResult>4</SubtractResult>", body)
        
        -- Plugin Request: Check in the log that the WSDL / XSDs definitions / SOAPAction were recompiled (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl_TTL)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl_TTL)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)

      end)
      
      it("1|XSLT (BEFORE XSD) - Invalid XSLT input", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculatorReq_XSLT_beforeXSD_invalid_verbose", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose, body)
        
        -- Plugin Request: Check in the log that the XSLT definition was compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)

      end)

      it("1|** Execute the same test - Invalid XSLT input: check that the definition is found in the cache **", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculatorReq_XSLT_beforeXSD_invalid_verbose", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose, body)
        
        -- Plugin Request: Check in the log that the XSLT definition used the cache
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xslt)

      end)

      it("5|XSLT (BEFORE XSD) - Invalid XSLT input", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculatorRes_XSLT_beforeXSD_invalid_verbose", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = response_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(response_common.calculator_Response_XSLT_BEFORE_Failed_verbose, body)
        
        -- Plugin Response: Check in the log that the XSLT definition was compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)

      end)

      it("5|** Execute the same test - Invalid XSLT input: check that the definition is found in the cache **", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculatorRes_XSLT_beforeXSD_invalid_verbose", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = response_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(response_common.calculator_Response_XSLT_BEFORE_Failed_verbose, body)
        
        -- Plugin Response: Check in the log that the XSLT definition used the cache
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xslt)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header - XSD defined instead of WSDL - Ko", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_xsd_defined_instead_of_wsdl_ko", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add",
            ["Connection"] = "keep-alive"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(soapAction_common.calculator_soap11_XSD_VALIDATION_Failed_XSD_Instead_of_WSDL, body)

        -- Plugin Request: Check in the log that the WSDL / XSDs / SOAPAction definitions were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction)
      end)

      it("2|** Execute the same test: check that the definition/error is found in the cache **", function()
        -- clean the log file
        helpers.clean_logfile()
        
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_xsd_defined_instead_of_wsdl_ko", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add",
            ["Connection"] = "keep-alive"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(soapAction_common.calculator_soap11_XSD_VALIDATION_Failed_XSD_Instead_of_WSDL, body)

        -- Plugin Request: Check in the log that the WSDL / XSDs / SOAPAction definitions used the cache
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xsd)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction_wsdlDef)
        
      end)

      it("2+6|SOAP 1.2 - XSD Validation (SOAP env) with included import no download - Ok", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculator_soap12_with_included_import_no_download_route_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)

        -- Plugin Request/Response: Check in the log that the XSD definition was compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
      end)

      it("2+6|** Execute the same test (before TTL is exceeded): check that the definitions are still cached **", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculator_soap12_with_included_import_no_download_route_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)

        -- Plugin Request/Response: Check in the log that the XSD definition used the cache
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xsd)

      end)

      it("2+6|** Execute the same test (after  TTL is exceeded): check that the definitions are compiled again (due to TTL exceeded) **", function()
        -- clean the log file
        helpers.clean_logfile()

        print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
        ngx.sleep(caching_common.TTL)

        -- invoke a test request
        local r = client:post("/calculator_soap12_with_included_import_no_download_route_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)

        -- Plugin Request/Response: Check in the log that the XSD definition was recompiled (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_TTL)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd_TTL)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
      end)

      it("2+6|SOAP 1.2 - XSD Validation (SOAP 1.2 env) with import Async download - Ok", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculator_soap12_with_import_async_download_route_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)

        -- Plugin Request/Response: Check in the log that the XSD definition was compiled due to Asynchronous download
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.xsd_async)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.xsd_async)
      end)
      
      it("2+6|SOAP 1.2 - XSD Validation (SOAP 1.2 env) with import Async download - Ok", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculator_soap12_with_import_async_download_route_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)

        -- Plugin Request/Response: Check in the log that the XSD definition was compiled due to Asynchronous download
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.xsd_async)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.xsd_async)
        
      end)
      
      it("2|XSD Validation - Invalid SOAP XSD input", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculatorXSD_SOAP_invalid_verbose", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_SOAP_INPUT_VALIDATION_Failed_verbose, body)

        -- Plugin Request: Check in the log that the XSD definition was recompiled (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
      end)
      
      it("2|** Execute the same test - Invalid SOAP XSD input: check that the definition compiled again (due to error) **", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculatorXSD_SOAP_invalid_verbose", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_SOAP_INPUT_VALIDATION_Failed_verbose, body)

        -- Plugin Request: Check in the log that the XSD definition was recompiled (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
      end)

		end)

	end)
  ::continue::
end