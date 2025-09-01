-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers             = require "spec.helpers"
local request_common      = require "spec.common.request"
local response_common     = require "spec.common.response"
local soapAction_common   = require "spec.common.soapAction"
local soap12_common       = require "spec.common.soap12"
local caching_common      = require "spec.common.caching"

-- matches our plugin name defined in the plugins's schema.lua
local pluginRequest  = "soap-xml-request-handling"
local pluginResponse = "soap-xml-response-handling"
local PLUGIN_NAME    = pluginRequest..","..pluginResponse
local xsltLibrary    = "libxslt"

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
        local blue_print = helpers.get_db_utils(strategy, nil, { pluginRequest,  pluginResponse })
              
        local calculator_service = blue_print.services:insert({
            protocol = "http",
            host = "ws.soap1.calculator",
            port = 8080,
            path = "/ws",
          })    
        
        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "2_6_soap11.xsd",
            xsdApiSchema = "2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "5_XSLT_BEFORE.xslt",
            xsdSoapSchema = "2_6_soap11.xsd",
            xsdApiSchema = "2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "2_6_soap11.xsd",
            xsdApiSchema = "2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator",
            xsltTransformBefore = "5_XSLT_BEFORE.xslt",
            xsdSoapSchema = "2_6_soap11.xsd",
            xsdApiSchema = "2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator/empty1/empty2",
            xsltTransformBefore = "../../1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "../../2_6_soap11.xsd",
            xsdApiSchema = "../../2_6_WSDL11_soap12_file_import_relative_path.wsdl",
            xsltTransformAfter = "../../3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator/empty1/empty2",
            xsltTransformBefore = "../../5_XSLT_BEFORE.xslt",
            xsdSoapSchema = "../../2_6_soap11.xsd",
            xsdApiSchema = "../../2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "../../7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator/empty1/empty2",
            xsltTransformBefore = "../../1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "../../2_6_soap11.xsd",
            xsdApiSchema = "../../2_6_WSDL11_soap12_file_import_relative_path.wsdl",
            xsltTransformAfter = "../../3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            filePathPrefix = "/kong-plugin/spec/fixtures/calculator/empty1/empty2",
            xsltTransformBefore = "../../5_XSLT_BEFORE.xslt",
            xsdSoapSchema = "../../2_6_soap11.xsd",
            xsdApiSchema = "../../2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "../../7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            -- The '___DOES_NOT_EXIST___ is intentionally set to a non-existing path and is ignored bacause all other files path start by '/'
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            -- The '___DOES_NOT_EXIST___ is intentionally set to a non-existing path and is ignored bacause all other files path start by '/'
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }

        local calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_route,
          config = {
            VerboseRequest = true,
            xsltLibrary = xsltLibrary,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,
            -- The '___DOES_NOT_EXIST___ is intentionally set to a non-existing path and is ignored bacause all other files path start by '/'
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/1_XSLT_BEFORE.xslt",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/3_XSLT_AFTER.xslt",
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
          route = calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = true,
            ExternalEntityLoader_CacheTTL = 3600,            
            xsltLibrary = caching_common.libxslt,
            -- The '___DOES_NOT_EXIST___ is intentionally set to a non-existing path and is ignored bacause all other files path start by '/'
            filePathPrefix = "/kong-plugin/spec/fixtures/___DOES_NOT_EXIST___",            
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/5_XSLT_BEFORE.xslt",
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_KongResult.wsdl",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/7_XSLT_AFTER.xslt"
          }
        }

        local calculatorWSDL_soap12_with_multiple_XSD_http_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_soap12_with_multiple_XSD_http_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_soap12_with_multiple_XSD_http_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap12.xsd",
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_soap12_2001_xml.xsd"
            },
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_http_import.wsdl",
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Add_XSD.xsd",
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Subtract_XSD.xsd"
            },
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorWSDL_soap12_with_multiple_XSD_http_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_Async = false,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap12.xsd",
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_soap12_2001_xml.xsd"
            },
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_http_import.wsdl",
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Add_XSD.xsd",
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Subtract_XSD.xsd"
            },
          }
        }

        local calculatorWSDL_soap12_with_multiple_XSD_file_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_soap12_with_multiple_XSD_file_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok" }
          }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_soap12_with_multiple_XSD_file_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap12_file_import.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import.wsdl"
          }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorWSDL_soap12_with_multiple_XSD_file_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_route,
          config = {
            VerboseResponse = true,
            ExternalEntityLoader_CacheTTL = 3600,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap12_file_import.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import.wsdl"
          }
        }

        local calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/invalidXML/1_3_5_7_invalid_XSLT.xslt"
          }
        }

        local calculatorXSD_SOAP_req_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSD_SOAP_req_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSD_SOAP_req_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/invalidXML/2_6_invalid_soap11.xsd"
          }
        }

        local calculatorXSD_SOAP12_req_invalid_content_include_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSD_SOAP12_req_invalid_content_include_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSD_SOAP12_req_invalid_content_include_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap12.xsd",
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = "/kong-plugin/spec/fixtures/calculator/invalidXML/2_6_invalid_soap12_2001_xml.xsd"
            }
          }
        }

        local calculatorWSDL_API_req_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_API_req_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_API_req_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/invalidXML/2_6_invalid_WSDL.wsdl"            
          }
        }

        local calculatorWSDL_API_req_invalid_content_include_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_API_req_invalid_content_include_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_API_req_invalid_content_include_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_http_import.wsdl",
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Add_XSD.xsd",
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = "/kong-plugin/spec/fixtures/calculator/invalidXML/2_6_invalid_Subtract_XSD.xsd"
            }
          }
        }

        local calculatorXSLT_afterXSD_req_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_afterXSD_req_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_afterXSD_req_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/invalidXML/1_3_5_7_invalid_XSLT.xslt"
          }
        }

        local calculatorXSLT_beforeXSD_res_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_beforeXSD_res_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorXSLT_beforeXSD_res_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseResponse = true,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/invalidXML/1_3_5_7_invalid_XSLT.xslt"
          }
        }

        local calculatorXSD_SOAP_res_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSD_SOAP_res_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorXSD_SOAP_res_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            VerboseResponse = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/invalidXML/2_6_invalid_soap11.xsd"
          }
        }

        local calculatorWSDL_API_res_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_API_res_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorWSDL_API_res_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseResponse = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/invalidXML/2_6_invalid_WSDL.wsdl"            
          }
        }

        local calculatorXSLT_afterXSD_res_invalid_content_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_afterXSD_res_invalid_content_xml_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginResponse,
          route = calculatorXSLT_afterXSD_res_invalid_content_xml_def_file_route,
          -- it lacks the '<' beginning tag
          config = {
            xsltLibrary = xsltLibrary,
            VerboseResponse = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/invalidXML/1_3_5_7_invalid_XSLT.xslt"
          }
        }
                
        local calculatorXSLT_beforeXSD_req_invalid_filepath_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_beforeXSD_req_invalid_filepath_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_beforeXSD_req_invalid_filepath_xml_def_file_route,
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsltTransformBefore = "/kong-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___.xml"
          }
        }

        local calculatorXSD_SOAP_req_invalid_filepath_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSD_SOAP_req_invalid_filepath_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSD_SOAP_req_invalid_filepath_xml_def_file_route,
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___.xml"
          }
        }

        local calculatorXSD_SOAP12_req_invalid_include_filepath_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSD_SOAP12_req_invalid_include_filepath_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSD_SOAP12_req_invalid_include_filepath_xml_def_file_route,
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap12.xsd",
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = "/kong-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___.xml"
            }
          }
        }        
        
        local calculatorWSDL_API_req_invalid_filepath_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_API_req_invalid_filepath_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_API_req_invalid_filepath_xml_def_file_route,
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___.xml"
          }
        }

        local calculatorWSDL_API_req_invalid_include_filepath_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL_API_req_invalid_include_filepath_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorWSDL_API_req_invalid_include_filepath_xml_def_file_route,
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsdApiSchema = "/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_http_import.wsdl",
            xsdApiSchemaInclude = {
              ["http://localhost:9000/tempuri.org.req.res.add.xsd"] = "/kong-plugin/spec/fixtures/calculator/2_6_Add_XSD.xsd",
              ["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = "/kong-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___.xml"
            }
          }
        }
        
        local calculatorXSLT_afterXSD_req_invalid_filepath_xml_def_file_route = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorXSLT_afterXSD_req_invalid_filepath_def_file_ko" }
        }
        blue_print.plugins:insert {
          name = pluginRequest,
          route = calculatorXSLT_afterXSD_req_invalid_filepath_xml_def_file_route,
          config = {
            xsltLibrary = xsltLibrary,
            VerboseRequest = true,
            xsdSoapSchema = "/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd",
            xsltTransformAfter = "/kong-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___.xml"
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
      
      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files - No import - Sync - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_sync_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files - No import - Async - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_no_import_async_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)
      
      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files with path Prefix - No import - Sync - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_sync_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files with path Prefix - No import - Async - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_no_import_async_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files with path Prefix and Relative path - No import - Sync - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_sync_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files with path Prefix and Relative path - No import - Async - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_path_prefix_relative_path_no_import_async_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files at root ignoring path Prefix - No import - Sync - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_sync_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)

      it("1+2+3+4+5+6+7|Request and Response plugins|Full SOAP/XML handling - XML Definitions in Files at root ignoring path Prefix - No import - Async - Ok", function()
        -- invoke a test request
        local r = client:post("/calculator_fullSoapXml_handling_Request_Response_xml_def_file_root_ignoring_path_prefix_no_import_async_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = request_common.calculator_Subtract_Full_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.equal("soap2", x_soap_region)
        assert.matches(response_common.calculator_Response_XML_18, body)        
        
			end)

      it("2+6|SOAP 1.2 - WSDL Validation with multiple XSD http imported with include definitions - XML Definition in Files - Add in XSD#1 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_soap12_with_multiple_XSD_http_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
            },
            body = soap12_common.calculator_soap12_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
          assert.matches('<AddResult>12</AddResult>', body)      
			end)

      it("2+6|SOAP 1.2 - WSDL Validation with multiple XSD http imported with include definitions - XML Definition in Files - Subtract in XSD#2 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_soap12_with_multiple_XSD_http_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
            },
            body = soap12_common.calculator_soap12_Subtract_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
          assert.matches("<SubtractResult>4</SubtractResult>", body)
			end)
      
      it("2+6|SOAP 1.2 - WSDL Validation with multiple XSD file imported - XML Definition in Files - Add in XSD#1 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_soap12_with_multiple_XSD_file_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
            },
            body = soap12_common.calculator_soap12_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
          assert.matches('<AddResult>12</AddResult>', body)      
			end)

      it("2+6|SOAP 1.2 - WSDL Validation with multiple XSD file imported - XML Definition in Files - Subtract in XSD#2 - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_soap12_with_multiple_XSD_file_imported_with_include_definition_xml_def_file_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
        		headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
            },
            body = soap12_common.calculator_soap12_Subtract_Request,
          })

          -- validate that the request failed: response status 200, Content-Type and right match
          local body = assert.response(r).has.status(200)
          local content_type = assert.response(r).has.header("Content-Type")
          assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
          assert.matches("<SubtractResult>4</SubtractResult>", body)
			end)

      it("1|XSLT (BEFORE XSD) - Invalid XSLT input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_beforeXSD_req_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose, body)
      end)
      
      it("2|XSD - Invalid SOAP XSD input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSD_SOAP_req_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'WSDL/XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_SOAP_INPUT_VALIDATION_Failed_verbose, body)
      end)

      it("2|XSD - Invalid SOAP 1.2 XSD input in include File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSD_SOAP12_req_invalid_content_include_xml_def_file_ko", {
          headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
            },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'WSDL/XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches("Failed to parse the XML resource 'http://www%.w3%.org/2001/xml%.xsd'", body)
      end)

      it("2|WSDL - Invalid API WSDL input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_API_req_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'WSDL/XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_INPUT_Failed_verbose, body)
      end)

      it("2|WSDL - Invalid API WSDL input in include File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_API_req_invalid_content_include_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'WSDL/XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("Failed to parse the XML resource 'http://localhost:9000/tempuri%.org%.req%.res%.subtract%.xsd'", body)
      end)

      it("3|XSLT (AFTER XSD) - Invalid XSLT input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_afterXSD_req_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(request_common.calculator_Request_XSLT_AFTER_Failed_verbose, body)                                      
      end)

      it("5|XSLT (BEFORE XSD) - Invalid XSLT input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_beforeXSD_res_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(response_common.calculator_Response_XSLT_BEFORE_Failed_verbose, body)
      end)

      it("6|XSD - Invalid SOAP XSD input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSD_SOAP_res_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'WSDL/XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(response_common.calculator_Response_XSD_SOAP_INPUT_VALIDATION_Failed_verbose, body)
      end)

      it("5|WSDL - Invalid WSDL API input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_API_res_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'WSDL/XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(response_common.calculator_Response_XSD_API_VALIDATION_INPUT_Failed_verbose, body)
      end)

      it("6|XSLT (AFTER XSD) - Invalid XSLT input in File - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_afterXSD_res_invalid_content_xml_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Full_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(response_common.calculator_Response_XSLT_AFTER_Failed_verbose, body)                                      
      end)

      it("1|XSLT (BEFORE XSD) - Invalid File path - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_beforeXSD_req_invalid_filepath_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("'/kong%-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___%.xml: No such file or directory'", body)
      end)

      it("2|XSD - Invalid SOAP XSD File path - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSD_SOAP_req_invalid_filepath_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("'/kong%-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___%.xml: No such file or directory'", body)
      end)

      it("2|XSD - Invalid include SOAP 1.2 XSD File path - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSD_SOAP12_req_invalid_include_filepath_def_file_ko", {
          headers = {
              ["Content-Type"] = "application/soap+xml; charset=utf-8",
            },
          body = soap12_common.calculator_soap12_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSD validation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches("Failed to parse the XML resource 'http://www%.w3%.org/2001/xml%.xsd'", body)
      end)

      it("2|WSDL - Invalid API XSD File path - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_API_req_invalid_filepath_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("'/kong%-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___%.xml: No such file or directory'", body)
      end)

      it("2|WSDL - Invalid include API XSD File path - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_API_req_invalid_include_filepath_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("Failed to parse the XML resource 'http://localhost:9000/tempuri%.org%.req%.res%.subtract%.xsd'", body)
      end)

      it("3|XSLT (AFTER XSD) - Invalid File path - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorXSLT_afterXSD_req_invalid_filepath_def_file_ko", {
          headers = {
            ["Content-Type"] = "text/xml;charset=utf-8",
          },
          body = request_common.calculator_Request,
        })

        -- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches("'/kong%-plugin/spec/fixtures/calculator/___DOES_NOT_EXIST___%.xml: No such file or directory'", body)
      end)


		end)		
	end)
  ::continue::
end