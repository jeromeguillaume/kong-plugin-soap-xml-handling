-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers         = require "spec.helpers"
local request_common  = require "spec.common.request"
local soap12_common   = require "spec.common.soap12"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local PLUGIN_NAME    = pluginRequest
local xsltLibrary = "libxslt"

-- Change the request body size for testing large body requests
helpers.setenv("KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE", "16k")


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
        local blue_print = helpers.get_db_utils(strategy, nil, { pluginRequest })
        
        local local_products_req_termination_route = blue_print.routes:insert{
          paths = { "/local_products_req_termination" }
        }
        blue_print.plugins:insert {
          name = "request-termination",
          route = local_products_req_termination_route,
          config = {
            status_code = 200,
            content_type = "text/xml;charset=utf-8",
            body = "<message>Ok</message>"
          }	
        }
        local products_local_service = blue_print.services:insert({
          protocol = "http",
          host = "localhost",
          port = 9000,
          path = "/local_products_req_termination",
        })
        
        local productsXSD_large_body_16k_with_verbose_ok = blue_print.routes:insert{
          service = products_local_service,
          paths = { "/productsXSD_large_body_16k_with_verbose_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = productsXSD_large_body_16k_with_verbose_ok,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdApiSchema = request_common.productsXSD,
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
      
			it("2|XSD Validation - large body 16K - Ok", function()
				local products_soapEnv_16k = helpers.file.read("/kong-plugin/spec/fixtures/products/2-products-soapEnv-16k.xml")

        -- invoke a test request
        local r = client:post("/productsXSD_large_body_16k_with_verbose_ok", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = products_soapEnv_16k,
        })

        -- validate that the request failed: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<message>Ok</message>', body)
			end)

		end)

	end)
  ::continue::
end
