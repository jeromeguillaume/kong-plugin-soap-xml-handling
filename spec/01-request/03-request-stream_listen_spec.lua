-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers         = require "spec.helpers"
local request_common  = require "spec.common.request"
local soap12_common   = require "spec.common.soap12"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local PLUGIN_NAME    = pluginRequest
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
        -- Change the request body size for testing large body requests
        helpers.setenv("KONG_STREAM_LISTEN", "0.0.0.0:9999")

        -- A BluePrint gives us a helpful database wrapper to
        --    manage Kong Gateway entities directly.
        -- This function also truncates any existing data in an existing db.
        -- The custom plugin name is provided to this function so it mark as loaded
        local blue_print = helpers.get_db_utils(strategy, nil, { pluginRequest })
                
        local calculator_service = blue_print.services:insert({
          protocol = "http",
          host = "ws.soap1.calculator",
          port = 8080,
          path = "/ws",
        })

        local calculator_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_with_multiple_XSD_imported_no_download_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = 15,
            xsdApiSchema = request_common.calculatorWSDL_req_res_multiple_imports_Ok,
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = request_common.calculator_Request_Response_Add_XSD_VALIDATION,
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = request_common.calculator_Request_Response_Subtract_XSD_VALIDATION,
            },
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
      
      it("2|WSDL Validation with XSD imported no download - STREAM_LISTEN is enabled - Ok", function()
				-- invoke a test request
        local r = client:post("/calculatorWSDL_with_multiple_XSD_imported_no_download_ok", {
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

		end)

	end)
  ::continue::
end
