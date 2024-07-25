-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers = require "spec.helpers"

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-response-handling"

local response_common = require "spec.common.response"

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
    describe("libxml |", function()
			lazy_setup(function()
        -- A BluePrint gives us a helpful database wrapper to
        --    manage Kong Gateway entities directly.
        -- This function also truncates any existing data in an existing db.
        -- The custom plugin name is provided to this function so it mark as loaded
        local blue_print = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })
				
				local request_context = response_common.lazy_setup(PLUGIN_NAME, blue_print, "libxslt")
					
				-- start kong
				assert(helpers.start_kong({
					-- use the custom test template to create a local mock server
					nginx_conf = "spec/fixtures/custom_nginx.template",
					-- make sure our plugin gets loaded
					plugins = "bundled," .. PLUGIN_NAME
				}))
				

    	end)
			it ("5|XSLT (BEFORE XSD) - Valid transformation", function()
				response_common._5_XSLT_BEFORE_XSD_Valid_transformation (assert, client)
			end)

			it ("5|XSLT (BEFORE XSD) - Invalid XSLT input", function()
				response_common._5_XSLT_BEFORE_XSD_Invalid_XSLT_input (assert, client)
			end)

      it ("5|XSLT (BEFORE XSD) - Invalid XSLT input with Verbose", function()
				response_common._5_XSLT_BEFORE_XSD_Invalid_XSLT_input_wiuth_Verbose (assert, client)
			end)
      
      it("5+6|XSD Validation - Ok", function()
				response_common._5_6_XSD_Validation_Ok (assert, client)
			end)

  	end)

	end)
 ::continue::

end