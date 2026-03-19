-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers = require "spec.helpers"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse

local saxon_common = require "spec.common.saxon"

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
    describe("libxml+saxon |", function()
			
			lazy_setup(function()			
        -- A BluePrint gives us a helpful database wrapper to
        --    manage Kong Gateway entities directly.
        -- This function also truncates any existing data in an existing db.
        -- The custom plugin name is provided to this function so it mark as loaded
        
        local blue_print = helpers.get_db_utils(strategy, nil, { pluginRequest,  pluginResponse })
				
				local saxon_context = saxon_common.lazy_setup(PLUGIN_NAME, blue_print, "saxon")
				helpers.unsetenv ("LD_LIBRARY_PATH")
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
               
      it("1|Saxon library not found", function()
        saxon_common._1_Saxon_Library_not_found (assert, client)
			end)

      it("1|Saxon library not found with verbose", function()
        saxon_common._1_Saxon_Library_not_found_with_verbose (assert, client)
			end)
      
		end)		
	end)
  ::continue::
end