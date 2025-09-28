-- Notes:
-- Some characters, called magic characters, have special meanings when used in a pattern. The magic characters are
-- ( ) . % + - * ? [ ^ $

-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers           = require "spec.helpers"
local request_common    = require "spec.common.request"
local request_common    = require "spec.common.request"
local soap12_common     = require "spec.common.soap12"
local soapAction_common = require "spec.common.soapAction"

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-request-handling"

local calculator_soap11_Subtract_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Header>
    <auth:Authentication xmlns:auth="http://example.com/auth">
        <auth:Username>user123</auth:Username>
        <auth:Password>securepassword</auth:Password>
    </auth:Authentication>
    <trans:TransactionID xmlns:trans="http://example.com/transaction">12345</trans:TransactionID>
  </soap:Header>
  <soap:Body>
		<!-- My Comment -->
    <Subtract xmlns="http://tempuri.org/">
      <intA>10</intA>
			<intB>3</intB>
    </Subtract>
  </soap:Body>
</soap:Envelope>
]]

local calculator_soap11_Multiply_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
		<!-- My Comment -->
    <Multiply xmlns="http://tempuri.org/">
      <intA>8</intA>
			<intB>4</intB>
    </Multiply>
  </soap:Body>
</soap:Envelope>
]]

local calculator_soap11_Divide_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
		<!-- My Comment -->
    <Divide xmlns="http://tempuri.org/">
      <intA>8</intA>
			<intB>4</intB>
    </Divide>
  </soap:Body>
</soap:Envelope>
]]
local calculator_soap11_Power_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
		<!-- My Comment -->
    <Power xmlns="http://tempuri.org/">
      <intA>8</intA>
			<intB>4</intB>
    </Power>
  </soap:Body>
</soap:Envelope>
]]

local calculator_soap12_Add_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <!-- My Comment -->
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Add>
  </soap12:Body>
</soap12:Envelope>
]]

local calculator_soap12_Subtract_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <!-- My Comment -->
    <Subtract xmlns="http://tempuri.org/">
      <intA>10</intA>
      <intB>3</intB>
    </Subtract>
  </soap12:Body>
</soap12:Envelope>
]]

local calculator_soap12_Multiply_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <!-- My Comment -->
    <Multiply xmlns="http://tempuri.org/">
      <intA>8</intA>
      <intB>4</intB>
    </Multiply>
  </soap12:Body>
</soap12:Envelope>
]]

local calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: The 'SOAPAction' header is not set but according to the WSDL this value is 'Required'</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Add_XSD_VALIDATION_Failed_No_Header_But_Required = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not ''</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Add_XSD_VALIDATION_Failed_Mismatch_Header = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not 'http://tempuri.org/Subtract'</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Subtract_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not ''</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Subtract_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not 'http://tempuri.org/Add'</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Multiply_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not ''</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Multiply_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not 'http://tempuri.org/Add'</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Divide_XSD_VALIDATION_Failed_sopAction_attibute_is_empty= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: Unable to get the value of 'soap:operation soapAction' attribute in the WSDL linked with 'Divide' Operation name</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Power_XSD_VALIDATION_Failed_sopAction_attibute_is_not_defined= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: Unable to get the value of 'soap:operation soapAction' attribute in the WSDL linked with 'Power' Operation name</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap12_XSD_VALIDATION_Failed_No_Header_But_Required = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: The 'SOAPAction' header is not set but according to the WSDL this value is 'Required'</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap12_Add_XSD_VALIDATION_Failed_No_Header_But_Required = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not ''</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap12_Add_XSD_VALIDATION_Failed_Mismatch_Header = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not 'http://tempuri.org/Subtract'</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap12_Subtract_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not ''</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap12_Subtract_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not 'http://tempuri.org/Add'</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap12_Multiply_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not ''</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap12_Multiply_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not 'http://tempuri.org/Add'</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap11_XSD_VALIDATION_Failed_NO_WSDL_Definition= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: No WSDL definition found: it's mandatory to validate the 'SOAPAction' header</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_XSD_VALIDATION_Failed_SOAPAction_and_action_defined_simultaneously= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: 'SOAPAction' for SOAP 1.1 and 'action' for SOAP 1.2 have been defined simultaneously</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_XSD_VALIDATION_Failed_SOAP11_with_action= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: Found a SOAP 1.1 envelope and an 'action' field in the 'Content%-Type' header linked with for SOAP 1.2</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap12_XSD_VALIDATION_Failed_SOAP12_with_SOAPAction= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap%-envelope" xmlns:f="http://www.example.org/faults" xmlns:xml="http://www.w3.org/XML/1998/namespace">
  <env:Body>
    <env:Fault>
      <env:Code>
        <env:Value>env:Sender</env:Value>
      </env:Code>
      <env:Reason>
        <env:Text xml:lang="en">Request %- XSD validation failed</env:Text>
      </env:Reason>
      <env:Detail>
        <f:errorDetails>
          <f:errorMessage>Validation of 'SOAPAction' header: Found a SOAP 1.2 envelope and a 'SOAPAction' header linked with for SOAP 1.1</f:errorMessage>
        </f:errorDetails>
      </env:Detail>
    </env:Fault>
  </env:Body>
</env:Envelope>]]

local calculator_soap11_Multiply_XSD_VALIDATION_WSDL20_Failed_Invalid_Pattern= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: the 'pattern' found in WSDL is 'http://www.w3.org/ns/wsdl/in%-%out%-INVALID%-URL%-FOR%-TEST%-ONLY' and must be 'http://www.w3.org/ns/wsdl/in%-out' or 'http://www.w3.org/ns/wsdl/in%-opt%-out'</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

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
    describe("libxml |", function()
			
      lazy_setup(function()			
        -- A BluePrint gives us a helpful database wrapper to
        --    manage Kong Gateway entities directly.
        -- This function also truncates any existing data in an existing db.
        -- The custom plugin name is provided to this function so it mark as loaded
        local blue_print = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })
        
        local calculator_service = blue_print.services:insert({
          protocol = "http",
          host = "ws.soap1.calculator",
          port = 8080,
          path = "/ws",
        })
            
        local calculator_wsdl11_soap11_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_SOAPAction_11_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_soap11_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL11_soap_soap12,
            SOAPAction_Header = "yes"
          }
        }

        local tempui_org_add_req_res_xsd = blue_print.routes:insert{
          paths = { "/tempuri.org.req.res.add.xsd" }
        }
        blue_print.plugins:insert {
          name = "request-termination",
          route = tempui_org_add_req_res_xsd,
          config = {
            status_code = 200,
            content_type = "text/xml;charset=utf-8",
            body = request_common.calculator_Request_Response_Add_XSD_VALIDATION
          }	
        }

        local calculator_wsdl11_soap11_async_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_SOAPAction_11_async_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_soap11_async_ok,
          config = {
            VerboseRequest = true,
            ExternalEntityLoader_CacheTTL = 15,
			      ExternalEntityLoader_Async = true,
            ExternalEntityLoader_Timeout = 5,
            xsdApiSchema = soapAction_common.calculatorWSDL11_soap_import_Ok,
            SOAPAction_Header = "yes"
          }
        }

        local calculator_wsdl11_kong11_stands_for_soap11_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_SOAPAction_kong_wsdl_kong11_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_kong11_stands_for_soap11_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL11_kong_wsdl_kong11_kong12,
            SOAPAction_Header = "yes"
          }
        }

        local calculator_wsdl11_defaultNS_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_SOAPAction_kong_wsdl_defaultNS_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_defaultNS_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL11_defaultNS_wsdl_kong11_kong12,
            SOAPAction_Header = "yes"
          }
        }

        local calculator_wsdl11_soap12_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_action_12_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_soap12_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL11_soap_soap12,
            SOAPAction_Header = "yes",
            xsdSoapSchema = soap12_common.soap12_XSD,
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }

        local calculator_wsdl11_kong12_stands_for_soap12_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_action12_kong_wsdl_kong12_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_kong12_stands_for_soap12_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL11_kong_wsdl_kong11_kong12,
            SOAPAction_Header = "yes",
            xsdSoapSchema = soap12_common.soap12_XSD,
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }

        local calculator_wsdl11_soap_xsd_defined_instead_of_wsdl_ko = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_SOAPAction_xsd_defined_instead_of_wsdl_ko" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_soap_xsd_defined_instead_of_wsdl_ko,
          config = {
            VerboseRequest = true,
            xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,          
            SOAPAction_Header = "yes"        
          }
        }
        
        local calculator_wsdl11_soap11_yes_null_allowed_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL11_SOAPAction_yes_null_allowed_11_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl11_soap11_yes_null_allowed_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL11_soap_soap12,
            SOAPAction_Header = "yes_null_allowed"
          }
        }

        local calculator_wsdl20_soap11_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL20_SOAPAction_11_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl20_soap11_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL20_wsdl2,
            SOAPAction_Header = "yes"
          }
        }

        local calculator_wsdl20_soap12_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL20_action_12_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl20_soap12_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL20_wsdl2,
            SOAPAction_Header = "yes",
            xsdSoapSchema = soap12_common.soap12_XSD,
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
          }
        }

        local calculator_wsdl20_soap11_defaultNS_wsdl_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL20_SOAPAction_11_defaultNS_wsdl_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl20_soap11_defaultNS_wsdl_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL20_defaultNS_wsdl,
            SOAPAction_Header = "yes"
          }
        }

        local calculator_wsdl20_soap12_defaultNS_wsdl_ok = blue_print.routes:insert{
          service = calculator_service,
          paths = { "/calculatorWSDL20_action_12_defaultNS_wsdl_ok" }
          }
        blue_print.plugins:insert {
          name = PLUGIN_NAME,
          route = calculator_wsdl20_soap12_defaultNS_wsdl_ok,
          config = {
            VerboseRequest = true,
            xsdApiSchema = soapAction_common.calculatorWSDL20_defaultNS_wsdl,
            SOAPAction_Header = "yes",
            xsdSoapSchema = soap12_common.soap12_XSD,
            xsdSoapSchemaInclude = {
              ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
            }
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
      
      --------------------------------------------------------------------------------------------------
      -- WSDL 1.1 | SOAP 1.1
      --------------------------------------------------------------------------------------------------
      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL 1.1) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL 1.1) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Subtract"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Subtract"
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL 1.1) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Subtract_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL 1.1) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Subtract_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Multiply"
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL 1.1) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)
      
      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Multiply_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL 1.1) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Multiply_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong11' for 'soap' 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_kong_wsdl_kong11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong11' for 'soap' 1.1) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_kong_wsdl_kong11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL | wsdl Default Namespace) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_kong_wsdl_defaultNS_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL | wsdl Default Namespace) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_kong_wsdl_defaultNS_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      --------------------------------------------------------------------------------------------------
      -- WSDL 1.1 | SOAP 1.2
      --------------------------------------------------------------------------------------------------
      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"true\" (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"',
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header (with single quote) with soapActionRequired=\"true\" (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action=\'http://tempuri.org/Add\'',
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header (without quote) with soapActionRequired=\"true\" (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action=http://tempuri.org/Add',
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"true\" (in WSDL 1.1) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"true\" (in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action=""',
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Add_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"true\" (in WSDL 1.1) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Subtract"',
          },
          body = calculator_soap12_Add_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Add_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"false\" (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Subtract"',
          },
          body = calculator_soap12_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"false\" (in WSDL 1.1) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = calculator_soap12_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"false\" (in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action=""',
          },
          body = calculator_soap12_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Subtract_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"false\" (in WSDL 1.1) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"',
          },
          body = calculator_soap12_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Subtract_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header without soapActionRequired (in WSDL 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Multiply"',
          },
          body = calculator_soap12_Multiply_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header without soapActionRequired (in WSDL 1.1) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = calculator_soap12_Multiply_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)
      
      it("2|WSDL Validation - 'action' 1.2 Http header without soapActionRequired (in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action=""',
          },
          body = calculator_soap12_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Multiply_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header without soapActionRequired (in WSDL 1.1) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"',
          },
          body = calculator_soap12_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Multiply_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"true\" (in WSDL 1.1 | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong12' for 'soap' 1.2) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action12_kong_wsdl_kong12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"',
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header with soapActionRequired=\"true\" (in WSDL 1.1 | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong12' for 'soap' 1.2) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action12_kong_wsdl_kong12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)
      
      --------------------------------------------------------------------------------------------------
      -- WSDL 1.1 / WSDL 2.0 | SOAP 1.1/1.2 Miscellaneous
      --------------------------------------------------------------------------------------------------
      it("2|WSDL Validation - 'SOAPAction' Http header - XSD defined instead of WSDL - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_xsd_defined_instead_of_wsdl_ko", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(soapAction_common.calculator_soap11_XSD_VALIDATION_Failed_XSD_Instead_of_WSDL, body)        
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapActionRequired=\"true\" (in WSDL 1.1) and 'yes_null_allowed' - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapActionRequired=\"true\" (in WSDL 1.1) and header is Null and 'yes_null_allowed' - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapActionRequired=\"true\" (in WSDL 1.1) and Header is '' and 'yes_null_allowed' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapAction='' (not properly defined in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Divide_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Divide_XSD_VALIDATION_Failed_sopAction_attibute_is_empty, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with no soapAction (defined in WSDL 1.1) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Power_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Power_XSD_VALIDATION_Failed_sopAction_attibute_is_not_defined, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' and 'action' defined simultaneously (WSDL 1.1) - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = 'text/xml; charset=utf-8; action="http://tempuri.org/Add"',
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_SOAPAction_and_action_defined_simultaneously, body)        
      end)
      
      it("2|WSDL Validation - SOAP 1.1 envelope with 'action' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = 'text/xml; charset=utf-8; action="http://tempuri.org/Add"',
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_SOAP11_with_action, body)        
      end)

      it("2|WSDL Validation - SOAP 1.2 envelope with 'SOAPAction' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_action_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_XSD_VALIDATION_Failed_SOAP12_with_SOAPAction, body)        
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL 1.1) - Async enabled - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_async_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL 1.1) - Async enabled - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL11_SOAPAction_11_async_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Subtract"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)


      --------------------------------------------------------------------------------------------------
      -- WSDL 2.0 | SOAP 1.1/1.2
      --------------------------------------------------------------------------------------------------
      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header (WSDL 2.0) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL20_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header (WSDL 2.0) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL20_action_12_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"',
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header (WSDL 2.0 without 'wsam:Action') - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL20_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/SubtractInterface/SubtractRequest"
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header (WSDL 2.0 without 'wsam:Action' and invalid pattern URL) - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL20_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/MultiplyInterface/MultiplyRequest"
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Multiply_XSD_VALIDATION_WSDL20_Failed_Invalid_Pattern, body)
      end)
      
      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header (WSDL 2.0 | wsdl Default Namespace) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL20_SOAPAction_11_defaultNS_wsdl_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = soapAction_common.calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'action' 1.2 Http header (WSDL 2.0 | wsdl Default Namespace) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL20_action_12_defaultNS_wsdl_ok", {
          headers = {
            ["Content-Type"] = 'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"',
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)
    
    end)

  end)  
	::continue::
end
