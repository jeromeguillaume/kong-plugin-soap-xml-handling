-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers                   = require "spec.helpers"
local request_common            = require "spec.common.request"
local response_common           = require "spec.common.response"
local soapAction_common         = require "spec.common.soapAction"
local soap12_common             = require "spec.common.soap12"
local saxon_common              = require "spec.common.saxon"
local caching_common            = require "spec.common.caching"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = caching_common.pluginRequest
local pluginResponse = caching_common.pluginResponse
local PLUGIN_NAME    = pluginRequest..","..pluginResponse

-- Force the number of Worker Process (for checking the cache behavior on the same worker)
helpers.setenv("KONG_NGINX_WORKER_PROCESSES", "1")

for _, strategy in helpers.all_strategies() do
  --if strategy == "off" then
  --  goto continue
  --end

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
        local calculator_REQ_RES_XSLT_beforeXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_REQ_RES_XLST_with_xslt_Params_ok" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_REQ_RES_XSLT_beforeXSD_with_xslt_Params_ok_route,
          config = {
            xsltLibrary = caching_common.libsaxon,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE_with_params,
            xsltParams = {
              ["intA_param"] = "1111",
              ["intB_param"] = "3333",
            },
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculator_REQ_RES_XSLT_beforeXSD_with_xslt_Params_ok_route,
          config = {
            xsltLibrary = caching_common.libsaxon,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_with_params,
            xsltParams = {
              ["result_tag"] = "kongResultFromParam",
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
            xsltLibrary = caching_common.libsaxon,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
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
            xsltLibrary = caching_common.libsaxon,
            ExternalEntityLoader_CacheTTL = caching_common.TTL,
            xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_invalid
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
      
      it("1+5|XSLT (BEFORE XSD) - Request and Response - With xslt Params - Ok", function()
        -- clean the log file
        helpers.clean_logfile()
        
        -- invoke a test request
        local r = client:post("/calculator_REQ_RES_XLST_with_xslt_Params_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("<kongResultFromParam>4444</kongResultFromParam>", body)

        -- Plugin Request: Check in the log that the XSLT definition was compiled for the 1st time (and not found in the cache)
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
        
        -- Plugin Response: Check in the log that the XSLT definition was compiled for the 1st time (and not found in the cache)        
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)        
      end)

      it("1+5|** Execute the same test (before TTL is exceeded): check that the XSLT definition is found in the cache **", function()
        -- clean the log file
          helpers.clean_logfile()

        -- invoke a test request
        local r = client:post("/calculator_REQ_RES_XLST_with_xslt_Params_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("<kongResultFromParam>4444</kongResultFromParam>", body)
        
        -- Plugin Request: Check in the log that the XSLT definition used the caching
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.get_xslt)
        
        -- Plugin Response: Check in the log that the XSLT definition used the caching
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xslt)
      end)

      it("1+5|** Execute the same test (after TTL is exceeded): check that the XSLT definition is compiled again (due to TTL exceeded) **", function()
        -- clean the log file
        helpers.clean_logfile()
        
        print("** Sleep "..(caching_common.TTL).." s for reaching the cache TTL **")
        ngx.sleep(caching_common.TTL)

        -- invoke a test request
        local r = client:post("/calculator_REQ_RES_XLST_with_xslt_Params_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("<kongResultFromParam>4444</kongResultFromParam>", body)
        
        -- Plugin Request: Check in the log that the XSLT definition was compiled again
        assert.logfile().has.line(caching_common.pluginReq_log..caching_common.compile_xslt)
        
        -- Plugin Response: Check in the log that the XSLT definition was compiled again
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.compile_xslt)        
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
        assert.matches(saxon_common.error_message_Request_XSLT_transfo_before_XSD_val_verbose.message_verbose, body)
        
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
        assert.matches(saxon_common.error_message_Request_XSLT_transfo_before_XSD_val_verbose.message_verbose, body)
        
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
        assert.matches(saxon_common.error_message_Request_XSLT_transfo_before_XSD_val_verbose.message_verbose, body)
        
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
        assert.matches(saxon_common.error_message_Request_XSLT_transfo_before_XSD_val_verbose.message_verbose, body)
        
        -- Plugin Request: Check in the log that the XSLT definition used the cache
        assert.logfile().has.line(caching_common.pluginRes_log..caching_common.get_xslt)

      end)

		end)

	end)
  ::continue::
end