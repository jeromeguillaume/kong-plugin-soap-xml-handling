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
	<soap:Header>
    <auth:Authentication xmlns:auth="http://example.com/auth">
        <auth:Username>user123</auth:Username>
        <auth:Password>securepassword</auth:Password>
    </auth:Authentication>
    <trans:TransactionID xmlns:trans="http://example.com/transaction">12345</trans:TransactionID>
  </soap:Header>
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

local calculator_soap11_Divide_XSD_VALIDATION_Failed_sopAction_attibute_is_empty= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: Unable to get the value of 'soap:operation soapAction' attribute in the WSDL linked with 'Divide' Operation name</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap11_Power_XSD_VALIDATION_Failed_sopAction_attibute_is_not_defined= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: Unable to get the value of 'soap:operation soapAction' attribute in the WSDL linked with 'Power' Operation name</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap12_Add_XSD_VALIDATION_Failed_No_Header_But_Required = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not ''</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap12_Add_XSD_VALIDATION_Failed_Mismatch_Header = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not 'http://tempuri.org/Subtract'</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap12_Subtract_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not ''</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap12_Subtract_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Subtract'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Subtract' and not 'http://tempuri.org/Add'</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]
  

local calculator_soap12_Multiply_XSD_VALIDATION_Failed_Empty_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not ''</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap12_Multiply_XSD_VALIDATION_Failed_Mismatch_Header= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: The Operation Name found in 'soap12:Body' is 'Multiply'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Multiply' and not 'http://tempuri.org/Add'</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap_XSD_VALIDATION_Failed_NO_WSDL_Definition= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: No WSDL definition found: it's mandatory to validate the 'SOAPAction' header</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_soap_XSD_VALIDATION_Failed_XSD_Instead_of_WSDL= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>Validation of 'SOAPAction' header: Unable to find the 'wsdl:definitions' in the WSDL</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

----------------------------------------------------------------------------------------------------
-- This WSDL provides:
--   The Namespace prefix of wsdl 1.0 is 'wsdl'
--   The Namespace prefix of soap 1.1 is 'soap'
--   The Namespace prefix of soap 1.2 is 'soap12'
--   JMS and HTTP transport and the plugin supports only HTTP Transport
--
-- soap 1.1 -> 5 HTTP operations defined with transport="http://schemas.xmlsoap.org/soap/http"/
--    Add       with    soapActionRequired="true"
--    Subtract  with    soapActionRequired="false"
--    Multiply  without soapActionRequired
--    Divide    with    soapAction=''           (which is not correctly defined)
--    Power     with    no soapAction attribute (which is not correctly defined)
--
-- soap 1.1 -> 2 JMS operations defined with transport="http://cxf.apache.org/transports/jms"/
--
-- soap 1.2 -> 5 HTTP operations + 2 JMS operations defined (like above)
----------------------------------------------------------------------------------------------------

local calculatorWSDL_soap_soap12= [[
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
      <s:element name="Power">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="PowerResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="PowerResult" type="s:int" />
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
  <wsdl:message name="PowerSoapIn">
    <wsdl:part name="parameters" element="tns:Power" />
  </wsdl:message>
  <wsdl:message name="PowerSoapOut">
    <wsdl:part name="parameters" element="tns:PowerResponse" />
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
        <wsdl:operation name="Power">
      <wsdl:input message="tns:PowerSoapIn" />
      <wsdl:output message="tns:PowerSoapOut" />
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
      <soap:operation soapAction="" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
      <wsdl:operation name="Power">
      <soap:operation style="document" />
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
      <soap12:operation soapAction="" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Power">
      <soap12:operation style="document" />
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

--------------------------------------------------------------------------------------------------------
-- This WSDL provides:
--   The Namespace prefix of wsdl 1.0 is 'kong_w_s_d_l'
--   The Namespace prefix of soap 1.1 is 'kong11'
--   The Namespace prefix of soap 1.2 is 'kong12'
--   JMS and HTTP transport and the plugin supports only HTTP Transport
--
-- soap 1.1 (kong11) -> 4 HTTP operations defined with transport="http://schemas.xmlsoap.org/soap/http"/
--    Add       with    soapActionRequired="true"
--    Subtract  with    soapActionRequired="false"
--    Multiply  without soapActionRequired
--    Divide    without soapActionRequired
--
-- soap 1.1 (kong11) -> 2 JMS operations defined with transport="http://cxf.apache.org/transports/jms"/
--
-- soap 1.2 (kong12) -> 4 HTTP operations + 2 JMS operations defined (like above)
--------------------------------------------------------------------------------------------------------
local calculatorWSDL_kong_wsdl_kong11_kong12= [[
<?xml version="1.0" encoding="utf-8"?>
<kong_w_s_d_l:definitions xmlns:kong11="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:kong12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:kong_w_s_d_l="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <kong_w_s_d_l:types>
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
  </kong_w_s_d_l:types>
  <kong_w_s_d_l:message name="AddSoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Add" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="AddSoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:AddResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="SubtractSoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Subtract" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="SubtractSoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:SubtractResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="MultiplySoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Multiply" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="MultiplySoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:MultiplyResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="DivideSoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Divide" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="DivideSoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:DivideResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:portType name="CalculatorSoap">
    <kong_w_s_d_l:operation name="Add">
      <kong_w_s_d_l:documentation xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">Adds two integers. This is a test WebService. ©DNE Online</kong_w_s_d_l:documentation>
      <kong_w_s_d_l:input message="tns:AddSoapIn" />
      <kong_w_s_d_l:output message="tns:AddSoapOut" />
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong_w_s_d_l:input message="tns:SubtractSoapIn" />
      <kong_w_s_d_l:output message="tns:SubtractSoapOut" />
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Multiply">
      <kong_w_s_d_l:input message="tns:MultiplySoapIn" />
      <kong_w_s_d_l:output message="tns:MultiplySoapOut" />
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Divide">
      <kong_w_s_d_l:input message="tns:DivideSoapIn" />
      <kong_w_s_d_l:output message="tns:DivideSoapOut" />
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:portType>
  <kong_w_s_d_l:binding name="JMSCalculatorSoap" type="tns:CalculatorSoap">
    <kong11:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <kong_w_s_d_l:operation name="Add">
      <kong11:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong11:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:binding name="CalculatorSoap" type="tns:CalculatorSoap">
    <kong11:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <kong_w_s_d_l:operation name="Add">
      <kong11:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong11:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Multiply">
      <kong11:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Divide">
      <kong11:operation soapAction="http://tempuri.org/Divide" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:binding name="JMSCalculatorSoap12" type="tns:CalculatorSoap">
    <kong12:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <kong_w_s_d_l:operation name="Add">
      <kong12:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong12:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:binding name="CalculatorSoap12" type="tns:CalculatorSoap">
    <kong12:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <kong_w_s_d_l:operation name="Add">
      <kong12:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong12:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Multiply">
      <kong12:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Divide">
      <kong12:operation soapAction="http://tempuri.org/Divide" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:service name="Calculator">
    <kong_w_s_d_l:port name="CalculatorSoap" binding="tns:CalculatorSoap">
      <kong11:address location="http://www.dneonline.com/calculator.asmx" />
    </kong_w_s_d_l:port>
    <kong_w_s_d_l:port name="CalculatorSoap12" binding="tns:CalculatorSoap12">
      <kong12:address location="http://www.dneonline.com/calculator.asmx" />
    </kong_w_s_d_l:port>
  </kong_w_s_d_l:service>
</kong_w_s_d_l:definitions>
]]

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
      
     
      local calculator_wsdl_soap11_ok = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_11_ok" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_soap11_ok,
        config = {
          VerboseRequest = true,
          xsdApiSchema = calculatorWSDL_soap_soap12,
          SOAPAction_Header = "yes"
        }
      }

      local calculator_wsdl_kong11_stands_for_soap11_ok = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_kong_wsdl_kong11_ok" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_kong11_stands_for_soap11_ok,
        config = {
          VerboseRequest = true,
          xsdApiSchema = calculatorWSDL_kong_wsdl_kong11_kong12,
          SOAPAction_Header = "yes"
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
          xsdApiSchema = calculatorWSDL_soap_soap12,
          SOAPAction_Header = "yes",
          xsdSoapSchema = soap12_common.soap12_XSD,
          xsdSoapSchemaInclude = {
            ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
          }
        }
      }

      local calculator_wsdl_kong12_stands_for_soap12_ok = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_kong_wsdl_kong12_ok" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_kong12_stands_for_soap12_ok,
        config = {
          VerboseRequest = true,
          xsdApiSchema = calculatorWSDL_kong_wsdl_kong11_kong12,
          SOAPAction_Header = "yes",
          xsdSoapSchema = soap12_common.soap12_XSD,
          xsdSoapSchemaInclude = {
            ["http://www.w3.org/2001/xml.xsd"] = soap12_common.soap12_import_XML_XSD
          }
        }
      }

      local calculator_wsdl_soap_wsdl_not_defined_in_plugin_ko = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_wsdl_not_defined_in_plugin_ko" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_soap_wsdl_not_defined_in_plugin_ko,
        config = {
          VerboseRequest = true,
          SOAPAction_Header = "yes"
        }
      }
      
      local calculator_wsdl_soap_xsd_defined_instead_of_wsdl_ko = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_xsd_defined_instead_of_wsdl_ko" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_soap_xsd_defined_instead_of_wsdl_ko,
        config = {
          VerboseRequest = true,
          xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,          
          SOAPAction_Header = "yes"        
        }
      }
      
      local calculator_wsdl_soap11_yes_null_allowed_ok = blue_print.routes:insert{
        service = calculator_service,
        paths = { "/calculatorWSDL_SOAPAction_yes_null_allowed_11_ok" }
        }
      blue_print.plugins:insert {
        name = PLUGIN_NAME,
        route = calculator_wsdl_soap11_yes_null_allowed_ok,
        config = {
          VerboseRequest = true,
          xsdApiSchema = calculatorWSDL_soap_soap12,
          SOAPAction_Header = "yes_null_allowed"
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

      --------------------------------------------------------------------------------------------------
      -- SOAP 1.1
      --------------------------------------------------------------------------------------------------
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
        assert.equal("text/xml;charset=utf-8", content_type)
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
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
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
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL) and Header mismatches with Operation Name - Ko", function()
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
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
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
        assert.equal("text/xml;charset=utf-8", content_type)
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
        assert.equal("text/xml;charset=utf-8", content_type)
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
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Subtract_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"false\" (in WSDL) and Header mismatches with Operation Name - Ko", function()
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
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
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
        assert.equal("text/xml;charset=utf-8", content_type)
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
        assert.equal("text/xml;charset=utf-8", content_type)
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
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Multiply_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header without soapActionRequired (in WSDL) and Header mismatches with Operation Name - Ko", function()
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
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Multiply_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong11' for 'soap' 1.1) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_kong_wsdl_kong11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.equal("text/xml;charset=utf-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.1 Http header with soapActionRequired=\"true\" (in WSDL | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong11' for 'soap' 1.1) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_kong_wsdl_kong11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required, body)
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
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"true\" (in WSDL) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"true\" (in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Add_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"true\" (in WSDL) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Subtract"
          },
          body = calculator_soap12_Add_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Add_XSD_VALIDATION_Failed_Mismatch_Header, body)
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
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<SubtractResult>7</SubtractResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"false\" (in WSDL) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
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

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"false\" (in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap12_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Subtract_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"false\" (in WSDL) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap12_Subtract_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Subtract_XSD_VALIDATION_Failed_Mismatch_Header, body)
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
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<MultiplyResult>32</MultiplyResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header without soapActionRequired (in WSDL) and NO header - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
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
      
      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header without soapActionRequired (in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap12_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Multiply_XSD_VALIDATION_Failed_Empty_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header without soapActionRequired (in WSDL) and Header mismatches with Operation Name - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap12_Multiply_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap12_Multiply_XSD_VALIDATION_Failed_Mismatch_Header, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"true\" (in WSDL | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong12' for 'soap' 1.2) - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_kong_wsdl_kong12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("application/soap%+xml;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' 1.2 Http header with soapActionRequired=\"true\" (in WSDL | 'kong_w_s_d_l' Namespace that stands for 'wsdl' and 'kong12' for 'soap' 1.2) and NO header - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_kong_wsdl_kong12_ok", {
          headers = {
            ["Content-Type"] = "application/soap+xml; charset=utf-8",
          },
          body = calculator_soap12_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)
      
      --------------------------------------------------------------------------------------------------
      -- SOAP 1.1/1.2 Miscellaneous
      --------------------------------------------------------------------------------------------------
      it("2|WSDL Validation - 'SOAPAction' Http header - WSDL not defined in the plugin - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_wsdl_not_defined_in_plugin_ko", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap_XSD_VALIDATION_Failed_NO_WSDL_Definition, body)        
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header - XSD defined instead of WSDL - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_xsd_defined_instead_of_wsdl_ko", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Add_Request,
        })

        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap_XSD_VALIDATION_Failed_XSD_Instead_of_WSDL, body)        
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapActionRequired=\"true\" (in WSDL) and 'yes_null_allowed' - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = "http://tempuri.org/Add"
          },
          body = calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapActionRequired=\"true\" (in WSDL) and header is Null and 'yes_null_allowed' - Ok", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
          },
          body = calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 200, Content-Type and right match
        local body = assert.response(r).has.status(200)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches('<AddResult>12</AddResult>', body)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapActionRequired=\"true\" (in WSDL) and Header is '' and 'yes_null_allowed' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_yes_null_allowed_11_ok", {
          headers = {
            ["Content-Type"] = "text/xml; charset=utf-8",
            ["SOAPAction"] = ""
          },
          body = calculator_soap11_Add_Request,
        })
        
        -- validate that the request succeeded: response status 500, Content-Type and right match
        local body = assert.response(r).has.status(500)
        local content_type = assert.response(r).has.header("Content-Type")
        assert.matches("text/xml%;%s-charset=utf%-8", content_type)
        assert.matches(calculator_soap11_Add_XSD_VALIDATION_Failed_No_Header_But_Required, body)
      end)

      it("2|WSDL Validation - 'SOAPAction' Http header with soapAction='' (not properly defined in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_yes_null_allowed_11_ok", {
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

      it("2|WSDL Validation - 'SOAPAction' Http header with no soapAction (defined in WSDL) and Header is '' - Ko", function()
        -- invoke a test request
        local r = client:post("/calculatorWSDL_SOAPAction_yes_null_allowed_11_ok", {
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

		end)    
	end)
  ::continue::
end