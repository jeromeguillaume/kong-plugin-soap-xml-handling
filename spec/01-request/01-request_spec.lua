-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers = require "spec.helpers"

-- Add a Worker Process for enabling the synchronous download of external entities
helpers.setenv("KONG_NGINX_WORKER_PROCESSES", "2")

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-request-handling"
local request_common = require "spec.common.request"

for _, strategy in helpers.all_strategies() do
	if strategy == "off" then
    goto continue
	end

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
			
			lazy_teardown(function()
				helpers.stop_kong(nil, true)
			end)				
				
			it ("1|XSLT (BEFORE XSD) - Valid transformation", function()
				request_common._1_XSLT_BEFORE_XSD_Valid_transformation (assert, client)
			end)

			it ("1|XSLT (BEFORE XSD) - With xslt Params - Ok", function()
				request_common._1_XSLT_BEFORE_XSD_with_xslt_Params_Ok (assert, client)
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

			it("1+2|XSD Validation - Invalid SOAP request (no 'soap:Body') with verbose - Ko", function()
				request_common._1_2_XSD_Validation_Invalid_SOAP_request_without_soapBody_with_verbose_ko (assert, client)
			end)

			it("1+2|XSD Validation - Invalid API request (no Operation) with verbose - Ko", function()
				request_common._1_2_XSD_Validation_Invalid_API_request_without_Operation_with_verbose_ko (assert, client)
			end)
			
			it ("1+3|XSLT (AFTER XSD) - With xslt Params - Ok", function()
				request_common._1_3_XSLT_AFTER_XSD_with_xslt_Params_Ok (assert, client)
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

			it("1+2+3+4|ROUTING BY XPATH with 'hostname' and 2 XPath targets - Ok", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_2_XPath_targets_Ok (assert, client)
			end)

			it("1+2+3+4|ROUTING BY XPATH with 'hostname' and XPath not succeeded - Ok", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_XPath_not_succeeded_Ok (assert, client)
			end)			
			
			it("1+2+3+4|ROUTING BY XPATH with 'hostname' - Invalid Hostname (503)", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Invalid_Hostname_503 (assert, client)
			end)
			
			it("1+2+3+4|ROUTING BY XPATH with 'hostname' - Invalid Hostname (503) with verbose", function()
				request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Invalid_Hostname_503_with_verbose (assert, client)
			end)

			it("2|WSDL Validation with import sync download - Ok", function()
				request_common._2_WSDL_Validation_with_import_sync_download_Ok (assert, client)
			end)

			it("2|WSDL Validation with multiple imports sync download - Ko", function()
				request_common._2_WSDL_Validation_with_multiple_imports_sync_download_Ko (assert, client)
			end)

			it("2|WSDL Validation with multiple imports sync download - Add in XSD#1 - Ko", function()
				request_common.with_multiple_imports_sync_Add_in_XSD1_with_verbose_ko (assert, client)
			end)

			it("2|WSDL Validation with multiple imports sync download - Subtract in XSD#2 - Ko", function()
				request_common.with_multiple_imports_sync_Subtract_in_XSD2_with_verbose_ok (assert, client)
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

			it("2|XSD Validation - Invalid SOAP request (Empty) with verbose - Ko", function()
				request_common._2_WSDL_Validation_Invalid_SOAP_request_Empty_with_verbose_ko (assert, client)
			end)

			it("2|WSDL Validation with no import and multiple XSD - Add in XSD#1 - Ko", function()
				request_common._2_WSDL_Validation_no_Import_multiple_XSD_Add_in_XSD1_with_verbose_ko (assert, client)
			end)

			it("2|WSDL Validation with no import and multiple XSD - Subtract in XSD#2 - Ok", function()
				request_common._2_WSDL_Validation_no_Import_multiple_XSD_Subtract_in_XSD2_with_verbose_ok (assert, client)
			end)

			it("2|WSDL Validation with no import and multiple XSD - Power not defined in XSDs - Ko", function()
				request_common._2_WSDL_Validation_no_Import_multiple_XSD_Power_not_defined_in_XSDs_with_verbose_ok (assert, client)
			end)

			it("2|WSDL Validation with multiple XSD imported no download - Add in XSD#1 - Ok", function()
				request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Add_in_XSD1_with_verbose_ok (assert, client)
			end)

			it("2|WSDL Validation with multiple XSD imported no download - Subtract in XSD#2 - Ok", function()
				request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Subtract_in_XSD2_with_verbose_ok (assert, client)
			end)

			it("2|WSDL Validation with multiple XSD imported no download - Add in XSD#1 - Ko", function()
				request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Add_in_XSD1_with_verbose_ko (assert, client)
			end)

			it("2|WSDL Validation with multiple XSD imported no download - Subtract in XSD#2 - Ko", function()
				request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Subtract_in_XSD2_with_verbose_ko (assert, client)
			end)

			it("2|WSDL (v2) Validation with no import - 'wsdl' default Namespace - 'xs:schema' - Ok", function()
				request_common._2_WSDL_v2_Validation_no_Import_wsdl_defaultNS_xsd_schema_with_verbose_ok (assert, client)
			end)
			
			it("2|WSDL (v2) Validation with no import - 'wsdl2:description' - 'schema' default Namespace - Ok", function()
				request_common._2_WSDL_v2_Validation_no_Import_wsdl2_description_xsd_defaultNS_with_verbose_ok (assert, client)
			end)

			it("2|WSDL Validation with mixed XSD imported - included - and downloaded - Add in XSD#1 - Ok", function()
				request_common._2_WSDL_Validation_with_mixed_XSD_imported___included_and_downloaded_Add_in_XSD1_with_verbose_ok (assert, client)
			end)

			it("2|WSDL Validation with mixed XSD imported - included - and downloaded - Subtract in XSD#2 - Ok", function()
				request_common._2_WSDL_Validation_with_mixed_XSD_imported___included_and_downloaded_Subtract_in_XSD2_with_verbose_ok (assert, client)
			end)
			
		end)
		
	end)
 ::continue::

end