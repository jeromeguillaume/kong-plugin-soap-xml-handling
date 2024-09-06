-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers = require "spec.helpers"
local split   = require("kong.tools.string").split

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-request-handling,soap-xml-response-handling"
local plugins = split(PLUGIN_NAME, ',')
local pluginRequest  = plugins[1]
local pluginResponse = plugins[2]

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
    describe("libxml+saxon |", function()
			
			lazy_setup(function()			
        -- A BluePrint gives us a helpful database wrapper to
        --    manage Kong Gateway entities directly.
        -- This function also truncates any existing data in an existing db.
        -- The custom plugin name is provided to this function so it mark as loaded
        
        local blue_print = helpers.get_db_utils(strategy, nil, { pluginRequest,  pluginResponse })
				
				local saxon_context = saxon_common.lazy_setup(PLUGIN_NAME, blue_print, "saxon")
					
				-- start kong
				assert(helpers.start_kong({
					-- use the custom test template to create a local mock server
					nginx_conf = "spec/fixtures/custom_nginx.template",
					-- make sure our plugin gets loaded
					plugins = "bundled," .. PLUGIN_NAME
				}))
		
    	end)
      it ("1+2+6+7|JSON to XML Transformation - Ok", function()
				saxon_common._1_2_6_7_JSON_2_XML_Transformation_Ok (assert, client)
			end)      
      it("1|XSLT (BEFORE XSD) - Request - Invalid XSLT input", function()
				saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_XSLT_input (assert, client)
			end)
      it("1|XSLT (BEFORE XSD) - Request - Invalid XSLT input with verbose", function()
				saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_XSLT_input_with_verbose (assert, client)
			end)
      it("1|XSLT (BEFORE XSD) - Request - Invalid Saxon template input", function()
				saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_Saxon_template_input (assert, client)
			end)
      it("1|XSLT (BEFORE XSD) - Request - Invalid Saxon template input with verbose", function()
				saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_Saxon_template_input_with_verbose (assert, client)
			end)
      it("1+2+6+7|XSLT (BEFORE XSD) - Response - Invalid XSLT input", function()
				saxon_common._1_2_6_7_RES_XSLT_AFTER_XSD_Invalid_XSLT_input (assert, client)
			end)
      it("1+2+6+7|XSLT (BEFORE XSD) - Response - Invalid XSLT input with verbose", function()
				saxon_common._1_2_6_7_RES_XSLT_AFTER_XSD_Invalid_XSLT_input_with_verbose (assert, client)
			end)
		end)		
	end)
  ::continue::
end