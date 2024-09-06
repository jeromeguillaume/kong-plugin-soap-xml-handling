-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers = require "spec.helpers"

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-request-handling"

local request_common = require "spec.common.request"

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
    describe("libxml+libxslt |", function()
			
			lazy_setup(function()			
        -- A BluePrint gives us a helpful database wrapper to
        --    manage Kong Gateway entities directly.
        -- This function also truncates any existing data in an existing db.
        -- The custom plugin name is provided to this function so it mark as loaded
        local blue_print = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })
				
				local request_context = request_common.lazy_setup(PLUGIN_NAME, blue_print, "libxslt")
					
				-- start kong
				assert(helpers.start_kong({
					-- use the custom test template to create a local mock server
					nginx_conf = "spec/fixtures/custom_nginx.template",
					-- make sure our plugin gets loaded
					plugins = "bundled," .. PLUGIN_NAME
				}))
		
    	end)
			it ("1|XSLT (BEFORE XSD) - Valid transformation", function()
				request_common._1_XSLT_BEFORE_XSD_Valid_transformation (assert, client)
			end)

			it("1|XSLT (BEFORE XSD) - Invalid XSLT input", function()
				request_common._1_XSLT_BEFORE_XSD_Invalid_XSLT_input (assert, client)
			end)

			it("1|XSLT (BEFORE XSD) - Invalid XSLT with Verbose", function()
				request_common._1_XSLT_BEFORE_XSD_Invalid_XSLT_with_Verbose (assert, client)
			end)

			it("1|XSLT (BEFORE XSD) - XSLT 2.0 input - Not supported by libxslt", function()
				request_common._1_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported (assert, client)
			end)

			it("1|XSLT (BEFORE XSD) - XSLT 2.0 input - Not supported by libxslt with Verbose", function()
				request_common._1_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported_with_Verbose (assert, client)
			end)

			it("1|XSLT (BEFORE XSD) - Valid transformation with 'request-termination' plugin (200)", function()
				request_common._1_XSLT_BEFORE_XSD_Valid_transformation_with_request_termination_plugin_200 (assert, client)
			end)

			it("1|XSLT (BEFORE XSD) - Valid transformation with 'basic_auth' plugin (401) with Verbose", function()
				request_common._1_XSLT_BEFORE_XSD_Valid_transformation_with_basic_auth_plugin_401_with_Verbose (assert, client)
			end)

			it("1|XSLT (BEFORE XSD) - Invalid Hostname service (502) with Verbose", function()
				request_common._1_XSLT_BEFORE_XSD_Invalid_Hostname_service_502_with_Verbose (assert, client)
			end)

			it("1+2|XSD Validation - Ok", function()
				request_common._1_2_XSD_Validation_Ok (assert, client)
			end)

			it("1+2|XSD Validation - Invalid SOAP XSD input", function()
				request_common._1_2_XSD_Validation_Invalid_SOAP_XSD_input (assert, client)
			end)

			it("1+2|XSD Validation - Invalid SOAP XSD input with verbose", function()
				request_common._1_2_XSD_Validation_Invalid_SOAP_XSD_input_with_verbose (assert, client)
			end)

			it("1+2|XSD Validation - Invalid API XSD input", function()
				request_common._1_2_XSD_Validation_Invalid_API_XSD_input (assert, client)
			end)

			it("1+2|XSD Validation - Invalid API XSD input with verbose", function()
				request_common._1_2_XSD_Validation_Invalid_API_XSD_input_with_verbose (assert, client)
			end)

			it("1+2|XSD Validation - Invalid SOAP request", function()
				request_common._1_2_XSD_Validation_Invalid_SOAP_request (assert, client)
			end)

			it("1+2|XSD Validation - Invalid SOAP request with verbose", function()
				request_common._1_2_XSD_Validation_Invalid_SOAP_request_with_verbose (assert, client)
			end)

			it("1+2|XSD Validation - Invalid API request", function()
				request_common._1_2_XSD_Validation_Invalid_API_request (assert, client)
			end)

			it("1+2|XSD Validation - Invalid API request with verbose", function()
				request_common._1_2_XSD_Validation_Invalid_API_request_with_verbose (assert, client)
			end)

			it("1+2+3|XSLT (AFTER XSD) - Ok", function()
				request_common._1_2_3_XSLT_AFTER_XSD_Ok (assert, client)
			end)

			it("1+2+3|XSLT (AFTER XSD) - Invalid XSLT input", function()
				request_common._1_2_3_XSLT_AFTER_XSD_Invalid_XSLT_input (assert, client)
			end)

			it("1+2+3|XSLT (AFTER XSD) - Invalid XSLT input with verbose", function()
				request_common._1_2_3_XSLT_AFTER_XSD_Invalid_XSLT_input_with_verbose (assert, client)
			end)

			it("1+2+3+4|ROUTING BY XPATH with 'upstream' entity - Ok", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_upstream_entity_Ok (assert, client)
			end)
			
			it("1+2+3+4|ROUTING BY XPATH with 'hostname' - Ok", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Ok (assert, client)
			end)

			it("1+2+3+4|ROUTING BY XPATH with 'hostname' - Invalid Hostname (503)", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Invalid_Hostname_503 (assert, client)
			end)
			
			it("1+2+3+4|ROUTING BY XPATH with 'hostname' - Invalid Hostname (503) with verbose", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Invalid_Hostname_503_with_verbose (assert, client)
			end)

			it("2|WSDL Validation with async download - Ok", function()
				request_common._2_WSDL_Validation_with_async_download_Ok (assert, client)
			end)
			
			it("2|WSDL Validation with async download - Invalid Import", function()
				request_common._2_WSDL_Validation_with_async_download_Invalid_Import (assert, client)
			end)

			it("2|WSDL Validation with async download - Invalid Import with verbose", function()
				request_common._2_WSDL_Validation_with_async_download_Invalid_Import_with_verbose (assert, client)
			end)
			
			it("2|WSDL Validation with import no download - Ok", function()
				request_common._2_WSDL_Validation_with_import_no_download_Ok (assert, client)
			end)
		end)
		
	end)
 ::continue::

end