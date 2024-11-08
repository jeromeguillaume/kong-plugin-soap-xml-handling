-- Notes:
-- Some characters, called magic characters, have special meanings when used in a pattern. The magic characters are
-- ( ) . % + - * ? [ ^ $

-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers         = require "spec.helpers"
local request_common  = require "spec.common.request"
local request_common  = require "spec.common.request"
local soap12_common   = require "spec.common.soap12"

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-request-handling"

local calculator_soap11_Add_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
		<!-- My Comment -->
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
			<intB>7</intB>
    </Add>
  </soap:Body>
</soap:Envelope>
]]

local calculator_soap11_Subtract_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
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
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The 'SOAPAction' header is not set but according to the WSDL this value is 'Required'</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Add_XSD_VALIDATION_Failed_No_Header_But_Required = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not ''</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Add_XSD_VALIDATION_Failed_Mismatch_Header = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not 'http://tempuri.org/Subtract'</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Subtract_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not ''</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Subtract_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not 'http://tempuri.org/Add'</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]
  

local calculator_soap11_Multiply_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not ''</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Multiply_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not 'http://tempuri.org/Add'</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

---------------------------------------------------
-- This WSDL provides:
-- soap 1.1 -> 4 operations defined
--    Add       with    soapActionRequired="true"
--    Subtract  with    soapActionRequired="false"
--    Multiply  without soapActionRequired
--    Divide    without soapActionRequired
--
-- soap 1.2 -> 4 operations defined (like above)
---------------------------------------------------
local calculatorWSDL_soap11_soap12= [[
<?xml version="1.0" encoding="utf-8"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <wsdl:types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <s:element name="Add">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="AddResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="AddResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Subtract">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="SubtractResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="SubtractResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Multiply">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="MultiplyResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="MultiplyResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Divide">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="DivideResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="DivideResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
    </s:schema>
  </wsdl:types>
  <wsdl:message name="AddSoapIn">
    <wsdl:part name="parameters" element="tns:Add" />
  </wsdl:message>
  <wsdl:message name="AddSoapOut">
    <wsdl:part name="parameters" element="tns:AddResponse" />
  </wsdl:message>
  <wsdl:message name="SubtractSoapIn">
    <wsdl:part name="parameters" element="tns:Subtract" />
  </wsdl:message>
  <wsdl:message name="SubtractSoapOut">
    <wsdl:part name="parameters" element="tns:SubtractResponse" />
  </wsdl:message>
  <wsdl:message name="MultiplySoapIn">
    <wsdl:part name="parameters" element="tns:Multiply" />
  </wsdl:message>
  <wsdl:message name="MultiplySoapOut">
    <wsdl:part name="parameters" element="tns:MultiplyResponse" />
  </wsdl:message>
  <wsdl:message name="DivideSoapIn">
    <wsdl:part name="parameters" element="tns:Divide" />
  </wsdl:message>
  <wsdl:message name="DivideSoapOut">
    <wsdl:part name="parameters" element="tns:DivideResponse" />
  </wsdl:message>
  <wsdl:portType name="CalculatorSoap">
    <wsdl:operation name="Add">
      <wsdl:documentation xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">Adds two integers. This is a test WebService. ©DNE Online</wsdl:documentation>
      <wsdl:input message="tns:AddSoapIn" />
      <wsdl:output message="tns:AddSoapOut" />
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <wsdl:input message="tns:SubtractSoapIn" />
      <wsdl:output message="tns:SubtractSoapOut" />
    </wsdl:operation>
    <wsdl:operation name="Multiply">
      <wsdl:input message="tns:MultiplySoapIn" />
      <wsdl:output message="tns:MultiplySoapOut" />
    </wsdl:operation>
    <wsdl:operation name="Divide">
      <wsdl:input message="tns:DivideSoapIn" />
      <wsdl:output message="tns:DivideSoapOut" />
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="JMSCalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <wsdl:operation name="Add">
      <soap:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="CalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="Add">
      <soap:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Multiply">
      <soap:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Divide">
      <soap:operation soapAction="http://tempuri.org/Divide" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="JMSCalculatorSoap12" type="tns:CalculatorSoap">
    <soap12:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <wsdl:operation name="Add">
      <soap12:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap12:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="CalculatorSoap12" type="tns:CalculatorSoap">
    <soap12:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="Add">
      <soap12:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap12:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Multiply">
      <soap12:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Divide">
      <soap12:operation soapAction="http://tempuri.org/Divide" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="Calculator">
    <wsdl:port name="CalculatorSoap" binding="tns:CalculatorSoap">
      <soap:address location="http://www.dneonline.com/calculator.asmx" />
    </wsdl:port>
    <wsdl:port name="CalculatorSoap12" binding="tns:CalculatorSoap12">
      <soap12:address location="http://www.dneonline.com/calculator.asmx" />
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
]]

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
      
      local calculator_service = blue_print.services:insert({
          protocol = "http",
          host = "www.dneonline.com",
          port = 80,
          path = "/calculator.asmx",
        })
      
      local calculator_wsdl_soap11_ok = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_11_ok" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_soap11_ok,
        config = {
          VerboseRequest = true,
          xsdApiSchema = calculatorWSDL_soap11_soap12,
          SOAPAction_Header_Validation = "yes"
        }
      }

      local calculator_wsdl_soap12_ok = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_12_ok" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_soap12_ok,
        config = {
          VerboseRequest = true,
          xsdApiSchema = calculatorWSDL_soap11_soap12,
          SOAPAction_Header_Validation = "yes",
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

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL) and Header mismacthes with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Subtract"
          },
          body = calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Subtract"
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches(calculator_soap11_Subtract_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL) and Header mismacthes with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches(calculator_soap11_Subtract_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Multiply"
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)
      
      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches(calculator_soap11_Multiply_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL) and Header mismacthes with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml; charset=utf-8", content_type)
        assert.matches(calculator_soap11_Multiply_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      --------------------------------------------------------------------------------------------------
      -- SOAP 1.2
      --------------------------------------------------------------------------------------------------
      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"true\" (in WSDL) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("application/soap+xml; charset=utf-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"false\" (in WSDL) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Subtract"
          },
          body = calculator_soap12_Subtract_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("application/soap+xml; charset=utf-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header without soapActionRequired (in WSDL) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Multiply"
          },
          body = calculator_soap12_Multiply_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("application/soap+xml; charset=utf-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)
  
		end)		
	end)
  ::continue::
end