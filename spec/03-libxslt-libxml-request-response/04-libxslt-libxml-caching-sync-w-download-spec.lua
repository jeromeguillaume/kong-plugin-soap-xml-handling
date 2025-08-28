-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers                   = require "spec.helpers"
local request_common            = require "spec.common.request"
local response_common           = require "spec.common.response"
local soapAction_common         = require "spec.common.soapAction"
local soap12_common             = require "spec.common.soap12"
local caching_common            = require "spec.common.caching"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse

local client = nil
local firstWorkerId = nil
local maxRetries = 10

-- Add a Worker Process for enabling the synchronous download of external entities
helpers.setenv("KONG_NGINX_WORKER_PROCESSES", "2")

for _, strategy in helpers.all_strategies() do
  --if strategy == "off" then
  --  goto continue
  --end

	describe(PLUGIN_NAME .. ": [#" .. strategy .. "]", function()
    
    setup(function()

    end)

    -- before_each runs before each child describe
    before_each(function()      
        
        -- *** Don't create a 'client' on each test
        -- *** So the 'Connection=keep-alive' is usable for guaranteeing to go on the same Nginx worker PID ***
        -- ***
        --client = helpers.proxy_client()        
    end)

    -- after_each runs after each child describe
    after_each(function()
      -- *** See comment above ***
      --if client then client:close() end
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
        
        blue_print.plugins:insert {
          name = "pre-function",
          config = {
            header_filter = {
                "local pid = ngx.worker.pid() kong.response.set_header(\"X-Worker-Id\", pid or 'nil')"
            }
          }
        }

        local calculator_no_plugin_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_no_plugin_ok" }
        }

        local calculator_fullSoapXml_handling_Request_Response_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_route,
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
          route = calculator_fullSoapXml_handling_Request_Response_route,
          config = {
            VerboseResponse = true,
            xsltLibrary = caching_common.libxslt,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,            
            xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
            xsltTransformAfter = response_common.calculator_Request_XSLT_AFTER
          }
        }
        
        local calculatorWSDL_with_sync_download_invalid_import_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_with_sync_download_invalid_import" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_with_sync_download_invalid_import_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = false,
            xsdApiSchema = request_common.calculatorWSDL_with_async_download_Failed
          }
        }

        local calculator_soap12_with_import_sync_download_route_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_soap12_with_import_sync_download_route_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap12_with_import_sync_download_route_ok,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,            
            xsdSoapSchema = soap12_common.soap12_XSD
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_soap12_with_import_sync_download_route_ok,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsdSoapSchema = soap12_common.soap12_XSD
          }
        }

        local calculator_soap12_with_included_invalid_import_no_download_route_ko = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_soap12_with_included_invalid_import_no_download_route_ko" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_soap12_with_included_invalid_import_no_download_route_ko,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsdSoapSchema = soap12_common.soap12_XSD,
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = "<**INVALID XSD**>"
            }
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

      -- An 'invalidations:kong_db_cache' is done on the first request: the 'invalidation' prevents the Pongo script to correctly test the caching mechanism
      -- So call this request to trigger the 'invalidation' before the "soap-xml-handling" plugins are called
      --
      -- Example of 'invalidation' log:
      -- 2025/07/13 19:44:45 [debug] 127#0: *6 [lua] callback.lua:107: do_event(): worker-events: handling event; source=mlcache, event=mlcache:invalidations:kong_db_cache, wid=0
      it("N/A|No plugin, - Ok", function()
        -- invoke a test request      
        client = helpers.proxy_client()
        local r = client:post("/calculator_no_plugin_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8"
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
        if client then client:close() end
      end)

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - NO Import - Sync download, - Ok", function()
        -- invoke a test request        
        client = helpers.proxy_client()
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_ok", {
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
        firstWorkerId = assert.response(r).has.header("X-Worker-Id")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)
        
        -- Plugin Request: Check in the log that the XSLT / WSDL / XSDs / SOAPAction / XPathRouting definitions were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_SOAPAction_ctx_doc)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_routeByXPath)

        -- Plugin Response: Check in the log that the XSLT / WSDL /XSDs definition were compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)

      end)
     
      it("1+2+3+4+5+6+7|** Execute the same test (before TTL is exceeded): check that the definitions are still cached **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do
          -- clean the log file
          helpers.clean_logfile()

          -- invoke a test request
          local r = client:post("/calculator_fullSoapXml_handling_Request_Response_ok", {
            headers = {
              ["Content-Type"] = "text/xml; charset=utf-8",
              ["SOAPAction"] = "http://tempuri.org/Add",
              ["Connection"] = "keep-alive"
            },
            body = request_common.calculator_Subtract_Full_Request,
          })
          
          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else
            -- validate that the request succeeded: response status 200, Content-Type and right match
            local body = assert.response(r).has.status(200)
            local content_type = assert.response(r).has.header("Content-Type")
            local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
            
            assert.matches("text/xml%;%s-charset=utf%-8", content_type)
            assert.equal("soap2", x_soap_region)

            assert.matches(response_common.calculator_Response_XML_18, body)        
            
            -- Plugin Request: Check in the log that the WSDL definition was not re-compiled
            assert.logfile().has.no.line(caching_common.pluginReq_log..caching_common.compile_wsdl)

            -- Plugin Request: Check in the log that the XSLT / WSDL / XSDs / SOAPAction / XPathRouting definitions used the cache
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xslt)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_wsdl)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xsd)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction_wsdlDef)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction_ctx_ptr)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_routeByXPath)

            -- Plugin Request: Check in the log that the XSLT / WSDL / XSDs definitions were not re-compiled
            assert.logfile().has.no.line(caching_common.pluginRes_log..caching_common.compile_wsdl)

            -- Plugin Request: Check in the log that the XSLT / WSDL / XSDs definitions used the cache
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xslt)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_wsdl)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xsd)
            break
          end          
        end
      end)

      
      it("1+2+3+4+5+6+7|** Execute the same test (after  TTL is exceeded): check that the definitions are compiled again (due to TTL exceeded) **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do
          -- clean the log file
          helpers.clean_logfile()

          print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
          ngx.sleep(caching_common.TTL)

          -- invoke a test request
          local r = client:post("/calculator_fullSoapXml_handling_Request_Response_ok", {
            headers = {
              ["Content-Type"] = "text/xml; charset=utf-8",
              ["SOAPAction"] = "http://tempuri.org/Add",
              ["Connection"] = "keep-alive"
            },
            body = request_common.calculator_Subtract_Full_Request,
          })
          
          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else
            -- validate that the request succeeded: response status 200, Content-Type and right match
            local body = assert.response(r).has.status(200)
            local content_type = assert.response(r).has.header("Content-Type")
            local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
            assert.matches("text/xml%;%s-charset=utf%-8", content_type)
            assert.equal("soap2", x_soap_region)
            assert.matches(response_common.calculator_Response_XML_18, body)        
            
            -- Plugin Request: Check in the log that the XSLT / WSDL / XSDs / SOAPAction / XPathRouting definitions were compiled for the 1st time (and not found in the cache)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl_TTL)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_TTL)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_SOAPAction)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_SOAPAction_ctx_doc)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_routeByXPath)

            -- Plugin Response: Check in the log that the XSLT / WSDL /XSDs definition were compiled for the 1st time (and not found in the cache)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl_TTL)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd_TTL)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_wsdl)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)


            if client then client:close() end
            break
          end
        end
      end)

      it("2|WSDL Validation with sync download - Invalid Import", function()
        -- invoke a test request
        client = helpers.proxy_client()
        local r = client:post("/calculatorWSDL_with_sync_download_invalid_import", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        firstWorkerId = assert.response(r).has.header("X-Worker-Id")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed_shortened, body)
	      assert.matches("<errorMessage>.*Failed to.*'http://localhost:9000/DOES_NOT_EXIST'.*</errorMessage>", body)

        -- Plugin Request: Check in the log that the WSDL / XSDs definitions were recompiled due to the error
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)

      end)

      it("2|** Execute the same test - Invalid Import: check that the definitions are compiled again (due to an Error) **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do        
          -- clean the log file
          helpers.clean_logfile()

          -- invoke a test request
          local r = client:post("/calculatorWSDL_with_sync_download_invalid_import", {
            headers = {
              ["Content-Type"] = "text/xml;charset=utf-8",
              ["Connection"] = "keep-alive"
            },
            body = request_common.calculator_Full_Request,
          })
          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else            
            -- validate that the request failed: response status 500, Content-Type and right match
            local body = assert.response(r).has.status(500)
            local content_type = assert.response(r).has.header("Content-Type")
            assert.matches("text/xml%;%s-charset=utf%-8", content_type)
            assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed_shortened, body)
            assert.matches("<errorMessage>.*Failed to.*'http://localhost:9000/DOES_NOT_EXIST'.*</errorMessage>", body)
            
            -- Plugin Request: Check in the log that the WSDL / XSDs definitions were recompiled due to the error
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl_XSDError)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_wsdl)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
            if client then client:close() end
            break
          end
        end
      end)
            
      it("2+6|SOAP 1.2 - XSD Validation (SOAP env) with import Sync download - Ok", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        client = helpers.proxy_client()
        local r = client:post("/calculator_soap12_with_import_sync_download_route_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        firstWorkerId = assert.response(r).has.header("X-Worker-Id")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)

        -- Plugin Request/Response: Check in the log that the XSD definition was compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
      end)

      it("2+6|** Execute the same test (before TTL is exceeded): check that the definitions are still cached **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do        

          -- clean the log file
          helpers.clean_logfile()

          -- invoke a test request
          local r = client:post("/calculator_soap12_with_import_sync_download_route_ok", {
            headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
              ["Connection"] = "keep-alive"
            },
            body = soap12_common.calculator_soap12_Request,
          })

          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else
            -- validate that the request succeeded: response status 200, Content-Type and right match
            local body = assert.response(r).has.status(200)
            local content_type = assert.response(r).has.header("Content-Type")
            assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
            assert.matches('<AddResult>12</AddResult>', body)

            -- Plugin Request/Response: Check in the log that the XSD definition used the cache
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xsd)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xsd)
            break
          end
        end
      end)

      it("2+6|** Execute the same test (after  TTL is exceeded): check that the definitions are compiled again (due to TTL exceeded) **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do

          -- clean the log file
          helpers.clean_logfile()
          
          print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
          ngx.sleep(caching_common.TTL)
          -- invoke a test request
          local r = client:post("/calculator_soap12_with_import_sync_download_route_ok", {
            headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
              ["Connection"] = "keep-alive"
            },
            body = soap12_common.calculator_soap12_Request,
          })

          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else
            -- validate that the request succeeded: response status 200, Content-Type and right match
            local body = assert.response(r).has.status(200)
            local content_type = assert.response(r).has.header("Content-Type")
            assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
            assert.matches('<AddResult>12</AddResult>', body)

            -- Plugin Request/Response: Check in the log that the XSD definition was recompiled (and not found in the cache) due to TTL exceeded
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_TTL)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd_TTL)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
            
            if client then client:close() end
            break
          end
        end
      end)

      it("2+6|SOAP 1.2 - XSD Validation (SOAP env) Sync download - Included Invalid Import - Ko", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        client = helpers.proxy_client()
        local r = client:post("/calculator_soap12_with_included_invalid_import_no_download_route_ko", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        firstWorkerId = assert.response(r).has.header("X-Worker-Id")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('Failed to parse the XML resource', body)

        -- Plugin Request: Check in the log that the XSD definition was recompiled (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_TTL)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)        
      end)

      it("2+6|** Execute the same test - Invalid Import: check that the definitions are compiled again (due to an Error) **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do

          -- clean the log file
          helpers.clean_logfile()

          -- invoke a test request
          local r = client:post("/calculator_soap12_with_included_invalid_import_no_download_route_ko", {
            headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
              ["Connection"] = "keep-alive"
            },
            body = soap12_common.calculator_soap12_Request,
          })
          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else
            -- validate that the request succeeded: response status 500, Content-Type and right match
            local body = assert.response(r).has.status(500)
            local content_type = assert.response(r).has.header("Content-Type")
            assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
            assert.matches('Failed to parse the XML resource', body)

            -- Plugin Request: Check in the log that the XSD definition was recompiled due to the error
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_Error)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
            break
          end
        end
      end)

      it("2+6|** Execute the same test (after  TTL is exceeded): check that the definitions are compiled again (due to TTL exceeded) **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do

          -- clean the log file
          helpers.clean_logfile()

          print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
          ngx.sleep(caching_common.TTL)

          -- invoke a test request
          local r = client:post("/calculator_soap12_with_included_invalid_import_no_download_route_ko", {
            headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
              ["Connection"] = "keep-alive"
            },
            body = soap12_common.calculator_soap12_Request,
          })
          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else
            -- validate that the request succeeded: response status 500, Content-Type and right match
            local body = assert.response(r).has.status(500)
            local content_type = assert.response(r).has.header("Content-Type")
            assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
            assert.matches('Failed to parse the XML resource', body)

            -- Plugin Request/Response: Check in the log that the XSD definition was recompiled (and not found in the cache)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_TTL)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)

            if client then client:close() end
            break
          end
        end
      end)

      it("2+6|SOAP 1.2 - XSD Validation (SOAP env) with import Sync download - Ok", function()
        -- clean the log file
        helpers.clean_logfile()

        -- invoke a test request
        client = helpers.proxy_client()
        local r = client:post("/calculator_soap12_with_import_sync_download_route_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["Connection"] = "keep-alive"
          },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        firstWorkerId = assert.response(r).has.header("X-Worker-Id")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)

        -- Plugin Request/Response: Check in the log that the XSD definition was compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
      end)

      it("2+6|** Execute the same test (before TTL is exceeded): check that the definitions are still cached **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do

          -- clean the log file
          helpers.clean_logfile()

          -- invoke a test request
          local r = client:post("/calculator_soap12_with_import_sync_download_route_ok", {
            headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
              ["Connection"] = "keep-alive"
            },
            body = soap12_common.calculator_soap12_Request,
          })

          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else
            -- validate that the request succeeded: response status 200, Content-Type and right match
            local body = assert.response(r).has.status(200)
            local content_type = assert.response(r).has.header("Content-Type")
            assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
            assert.matches('<AddResult>12</AddResult>', body)

            -- Plugin Request/Response: Check in the log that the XSD definition used the cache
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xsd)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xsd)
            break
          end
        end
      end)

      it("2+6|** Execute the same test (after  TTL is exceeded): check that the definitions are compiled again (due to TTL exceeded) **", function()
        -- Do a loop for getting the same Nginx Worker ID as the 1st Test
        for i=1, maxRetries do
        
          -- clean the log file
          helpers.clean_logfile()
          
          print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
          ngx.sleep(caching_common.TTL)
          -- invoke a test request
          local r = client:post("/calculator_soap12_with_import_sync_download_route_ok", {
            headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
              ["Connection"] = "keep-alive"
            },
            body = soap12_common.calculator_soap12_Request,
          })
          
          local workerId = assert.response(r).has.header("X-Worker-Id")
          if workerId ~= firstWorkerId then
            print("** First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId .. " - retrying "..i.."/"..maxRetries.." **")
            client:close()
            client = helpers.proxy_client()
            if i == maxRetries then
              assert(false, "First Nginx Worker ID=" .. firstWorkerId .. " different from the current Worker ID=" .. workerId)
            end
          else          
            -- validate that the request succeeded: response status 200, Content-Type and right match
            local body = assert.response(r).has.status(200)
            local content_type = assert.response(r).has.header("Content-Type")
            assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
            assert.matches('<AddResult>12</AddResult>', body)

            -- Plugin Request/Response: Check in the log that the XSD definition was recompiled (and not found in the cache) due to TTL exceeded
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd_TTL)
            assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xsd)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd_TTL)
            assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xsd)
            
            if client then client:close() end
            break
          end
        end
     end)
      
		end)

	end)
  ::continue::
end
