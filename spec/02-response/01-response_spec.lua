-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers = require "spec.helpers"

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-response-handling"

local response_common = require "spec.common.response"

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
				response_common._5_XSLT_BEFORE_XSD_Invalid_XSLT_input_with_verbose (assert, client)
			end)

			it("5|XSLT (BEFORE XSD) - XSLT 2.0 input - Not supported by libxslt", function()
				response_common._5_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported (assert, client)
			end)
			
			it("5|XSLT (BEFORE XSD) - XSLT 2.0 input - Not supported by libxslt with Verbose", function()
				response_common._5_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported_with_Verbose (assert, client)
			end)

      it ("5|XSLT (BEFORE XSD) - 'gzip' Content-encoding - Ok", function()
				response_common._5_XSLT_BEFORE_XSD_gzip_Content_Encoding_Ok (assert, client)
			end)

      it ("5|XSLT (BEFORE XSD) - Content-encoding - Unknown encoding", function()
				response_common._5_XSLT_BEFORE_XSD_Content_Encoding_Unknown_Encoding (assert, client)
			end)

      it ("5|XSLT (BEFORE XSD) - Content-encoding - Unknown encoding with verbose", function()
				response_common._5_XSLT_BEFORE_XSD_Content_Encoding_Unknown_Encoding_with_verbose (assert, client)
			end)
     
      it("5+6|XSD Validation - Ok", function()
				response_common._5_6_XSD_Validation_Ok (assert, client)
			end)

      it("5+6|XSD Validation - Invalid SOAP XSD input", function()
				response_common._5_6_XSD_Validation_Invalid_SOAP_XSD_input (assert, client)
			end)

      it("5+6|XSD Validation - Invalid SOAP XSD input with verbose", function()
				response_common._5_6_XSD_Validation_Invalid_SOAP_XSD_input_with_verbose (assert, client)
			end)
     
      it("5+6|XSD Validation - Invalid API XSD input", function()
				response_common._5_6_XSD_Validation_Invalid_API_XSD_input (assert, client)
			end)

      it("5+6|XSD Validation - Invalid API XSD input with verbose", function()
				response_common._5_6_XSD_Validation_Invalid_API_XSD_input_with_verbose (assert, client)
			end)

      it("5+6|XSD Validation - Invalid SOAP response", function()
				response_common._5_6_XSD_Validation_Invalid_SOAP_response (assert, client)
			end)

      it("5+6|XSD Validation - Invalid SOAP response with verbose", function()
				response_common._5_6_XSD_Validation_Invalid_SOAP_response_with_verbose (assert, client)
			end)

      it("5+6|XSD Validation - Invalid API response", function()
				response_common._5_6_XSD_Validation_Invalid_API_response (assert, client)
			end)

      it("5+6|XSD Validation - Invalid API response with verbose", function()
				response_common._5_6_XSD_Validation_Invalid_API_response_with_verbose (assert, client)
			end)

      it ("5+6+7|XSLT (AFTER XSD) - Ok", function()
				response_common._5_6_7_XSLT_AFTER_XSD_Ok (assert, client)
			end)

      it("5+6+7|XSLT (AFTER XSD) - Invalid XSLT input", function()
				response_common._5_6_7_XSLT_AFTER_XSD_Invalid_XSLT_input (assert, client)
			end)

      it("5+6+7|XSLT (AFTER XSD) - Invalid XSLT input with verbose", function()
				response_common._5_6_7_XSLT_AFTER_XSD_Invalid_XSLT_input_with_verbose (assert, client)
			end)

      it("6|WSDL Validation with async download - Ok", function()
				response_common._6_WSDL_Validation_with_async_download_Ok (assert, client)
			end)

      it("6|WSDL Validation with async download - Invalid Import", function()
				response_common._6_WSDL_Validation_with_async_download_Invalid_Import (assert, client)
			end)

      it("6|WSDL Validation with async download - Invalid Import with verbose", function()
				response_common._6_WSDL_Validation_with_async_download_Invalid_Import_with_verbose (assert, client)
			end)

      it("6|WSDL Validation with import no download - Ok", function()
				response_common._6_WSDL_Validation_with_import_no_download_Ok (assert, client)
			end)

			it("6|WSDL Validation - Invalid SOAP response (Blank) with verbose - Ko", function()
				response_common._6_WSDL_Validation_Invalid_SOAP_response_Blank_with_verbose_ko (assert, client)
			end)

			it("6|WSDL Validation - Invalid SOAP response (no 'soap:Body') with verbose - Ko", function()
				response_common._6_WSDL_Validation_Invalid_SOAP_response_without_soapBody_with_verbose_ko (assert, client)
			end)

			it("6|WSDL Validation - Invalid API response (no Operation) with verbose - Ko", function()
				response_common._6_WSDL_Validation_Invalid_API_response_without_operation_with_verbose_ko (assert, client)
			end)

  	end)

	end)
 ::continue::

end