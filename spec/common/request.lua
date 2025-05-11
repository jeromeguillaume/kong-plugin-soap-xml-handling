-- Notes:
-- Some characters, called magic characters, have special meanings when used in a pattern. The magic characters are
-- ( ) . % + - * ? [ ^ $

local helpers = require "spec.helpers"
local request_common = {}

request_common.calculator_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
    </Add>
  </soap:Body>
</soap:Envelope>
]]

request_common.calculator_Full_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
			<intB>7</intB>
    </Add>
  </soap:Body>
</soap:Envelope>
]]

request_common.calculator_Request_SOAP_No_soapBody_ko= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
</soap:Envelope>
]]

request_common.calculator_Request_SOAP_No_Operation_ko= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
  </soap:Body>
</soap:Envelope>
]]

request_common.calculator_Request_SOAP_ko= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope2 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
    </Add>
  </soap:Body>
</soap:Envelope2>
]]

request_common.calculator_Request_API_ko= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Add xmlns="http://tempuri.org/">
      <intC>5</intC>
    </Add>
  </soap:Body>
</soap:Envelope>
]]

request_common.calculator_Subtract_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Body>
		<Subtract xmlns="http://tempuri.org/">
			<intA>5</intA>
		</Subtract>
	</soap:Body>
</soap:Envelope>
]]

request_common.calculator_Subtract_Full_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Body>
		<Subtract xmlns="http://tempuri.org/">
			<intA>5</intA>
			<intB>1</intB>
		</Subtract>
	</soap:Body>
</soap:Envelope>
]]

request_common.calculator_Power_Full_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Body>
		<Power xmlns="http://tempuri.org/">
			<intA>5</intA>
			<intB>1</intB>
		</Power>
	</soap:Body>
</soap:Envelope>
]]

request_common.calculator_Response = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
]]

request_common.calculator_Request_XSLT_BEFORE_with_params = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:param name="intA_param" select="1"/>
   <xsl:param name="intB_param" select="2"/>
  <xsl:output version="1.0" method="xml" encoding="utf-8" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='intA']">
      <intA><xsl:value-of select="$intA_param"/></intA>
  </xsl:template>
  <xsl:template match="//*[local-name()='intB']">
      <intB><xsl:value-of select="$intB_param"/></intB>
  </xsl:template>
</xsl:stylesheet>
]]

request_common.calculator_Request_XSLT_AFTER_with_params = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:param name="intA_after_xsd_param" select="1"/>
   <xsl:param name="intB_after_xsd_param" select="2"/>
  <xsl:output version="1.0" method="xml" encoding="utf-8" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='intA']">
      <intA><xsl:value-of select="$intA_after_xsd_param"/></intA>
  </xsl:template>
  <xsl:template match="//*[local-name()='intB']">
      <intB><xsl:value-of select="$intB_after_xsd_param"/></intB>
  </xsl:template>
</xsl:stylesheet>
]]

request_common.calculator_Request_XSLT_BEFORE_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>
        <errorMessage>SOAP/XML process failure</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>
        <errorMessage>Invalid XSLT definition. Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_2_0_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>
        <errorMessage>Invalid XSLT definition. compilation error. xsl:version: only 1.1 features are supported</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_BEFORE_Failed_401_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Unauthorized</faultstring>
      <detail>
        <errorMessage>HTTP Error code is 401</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_BEFORE_Failed_502_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>An invalid response was received from the upstream server</faultstring>
      <detail>
        <errorMessage>HTTP Error code is 502</errorMessage>
        <backendHttpCode>502</backendHttpCode>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_BEFORE = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output version="1.0" method="xml" encoding="utf-8" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='intA']">
    <xsl:copy-of select="."/>
      <intB>8</intB>
  </xsl:template>
</xsl:stylesheet>
]]

request_common.calculator_Request_XSD_VALIDATION = [[
<s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema">
  <s:element name="Add">
    <s:complexType>
      <s:sequence>
        <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
        <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
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
</s:schema>
]]

request_common.calculator_Request_Response_XSD_VALIDATION = [[
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Add" type="tem:AddType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="Subtract" type="tem:SubtractType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="SubtractType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="AddResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>]]

request_common.calculator_Request_Response_Add_XSD_VALIDATION = [[
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Add" type="tem:AddType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="AddResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>]]

request_common.calculator_Request_Response_Subtract_XSD_VALIDATION = [[
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Subtract" type="tem:SubtractType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="SubtractType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="SubtractResponse" type="tem:SubtractResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="SubtractResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="SubtractResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>]]

request_common.calculator_Request_XSD_API_VALIDATION_invalid = [[
s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema">
</s:schema>
]]

request_common.calculator_Request_XSD_VALIDATION_Failed_shortened = [[
<faultstring>Request %- XSD validation failed</faultstring>
]]

request_common.calculator_Request_XSD_VALIDATION_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>SOAP/XML process failure</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_VALIDATION_Failed_Client = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>SOAP/XML process failure</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_SOAP_INPUT_VALIDATION_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Invalid XSD schema. Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found. Error code: 3067, Line: 0, Message: Failed to parse the XML resource 'in_memory_buffer'.</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_API_VALIDATION_INPUT_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Invalid WSDL/XSD schema. Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Error Node: Envelope2, Error code: 1845, Line: 1, Message: Element '{http://schemas.xmlsoap.org/soap/envelope/}Envelope2': No matching global declaration available for the validation root.</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Error Node: intC, Error code: 1871, Line: 1, Message: Element '{http://tempuri.org/}intC': This element is not expected. Expected is %( {http://tempuri.org/}intA %).</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_Add_Expected_intB_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Error Node: Add, Error code: 1871, Line: 4, Message: Element '{http://tempuri.org/}Add': Missing child element%(s%). Expected is %( {http://tempuri.org/}intB %).</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_Subtract_Expected_intB_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Error Node: Subtract, Error code: 1871, Line: 4, Message: Element '{http://tempuri.org/}Subtract': Missing child element%(s%). Expected is %( {http://tempuri.org/}intB %).</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_empty_SOAP_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Invalid XML input. Unable to find the 'soap:Envelope'</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_NO_soapBody_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Error Node: Envelope, Error code: 1871, Line: 1, Message: Element '{http://schemas.xmlsoap.org/soap/envelope/}Envelope': Missing child element%(s%). Expected is one of %( {http://schemas.xmlsoap.org/soap/envelope/}Header, {http://schemas.xmlsoap.org/soap/envelope/}Body %).</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_API_VALIDATION_no_operation_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Invalid XML input. Unable to find the Operation tag in the 'soap:Body'</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSD_API_VALIDATION_Power_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Error Node: Power, Error code: 1845, Line: 4, Message: Element '{http://tempuri.org/}Power': No matching global declaration available for the validation root.</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_AFTER = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='Subtract']">
    <Add xmlns="http://tempuri.org/"><xsl:apply-templates select="@*|node()" /></Add>
  </xsl:template>
</xsl:stylesheet>
]]

request_common.calculator_Request_XSLT_AFTER_invalid = [[
xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
</xsl:stylesheet>
]]

request_common.calculator_Request_XSLT_AFTER_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSLT transformation failed %(after XSD validation%)</faultstring>
      <detail>
        <errorMessage>SOAP/XML process failure</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_AFTER_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSLT transformation failed %(after XSD validation%)</faultstring>
      <detail>
        <errorMessage>Invalid XSLT definition. Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">   
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
  <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//*[local-name()='Subtract']">
    <Add xmlns="http://tempuri.org/"><xsl:apply-templates select="@*|node()" /></Add>
  </xsl:template>
  <xsl:template match="//*[local-name()='intA']">
    <intA>10</intA>
  </xsl:template>
  <xsl:template match="//*[local-name()='intB']">
    <intB><xsl:apply-templates select="@*|node()" /></intB>
  </xsl:template>
</xsl:stylesheet>
]]

request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH_Failed_503 = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>The upstream server is currently unavailable</faultstring>
      <detail>
        <errorMessage>SOAP/XML process failure</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH_Failed_503_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>The upstream server is currently unavailable</faultstring>
      <detail>
        <errorMessage>HTTP Error code is 503</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

request_common.ROUTING_BY_XPATH_ns_default = "soap,http://schemas.xmlsoap.org/soap/envelope/"
request_common.calculator_Request_ROUTING_BY_XPATH_ns_tempuri = "tempuri_kong,http://tempuri.org/"

request_common.calculatorWSDL_one_import_for_req_res_ok = [[
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                  xmlns:tns="http://tempuri.org/"
                  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                  name="tempuri.org"
                  targetNamespace="http://tempuri.org/">
  <wsdl:documentation>tempuri.org - Add and Subtract calculation
  </wsdl:documentation>
  <wsdl:types>
    <!-- XSD schema for the Request and the Response -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:9000/tempuri.org.request-response.xsd"/>
    </xsd:schema>
  </wsdl:types>
</wsdl:definitions>
]]

request_common.calculatorWSDL_req_only_with_async_download_Ok = [[
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                  xmlns:tns="http://tempuri.org/"
                  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                  name="tempuri.org"
                  targetNamespace="http://tempuri.org/">
  <wsdl:documentation>tempuri.org - Add and Subtract calculation
  </wsdl:documentation>
  <wsdl:types>
    <!-- XSD schema for the Request -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:9000/tempuri.org.request.xsd"/>
    </xsd:schema>
  </wsdl:types>
</wsdl:definitions>
]]

request_common.calculatorWSDL_req_res_multiple_imports_Ok = [[
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                  xmlns:tns="http://tempuri.org/"
                  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                  name="tempuri.org"
                  targetNamespace="http://tempuri.org/">
  <wsdl:documentation>tempuri.org - Add and Subtract calculation
  </wsdl:documentation>
  <wsdl:types>
    	<!-- XSD schema for Add (Request and Response) -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:9000/tempuri.org.req.res.add.xsd"/>
    </xsd:schema>
		<!-- XSD schema for Subtract (Request and Response) -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:9000/tempuri.org.req.res.subtract.xsd"/>
    </xsd:schema>
  </wsdl:types>
</wsdl:definitions>
]]

request_common.calculatorWSDL_with_async_download_Failed = [[
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                  xmlns:tns="http://tempuri.org/"
                  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                  name="tempuri.org"
                  targetNamespace="http://tempuri.org/">
  <wsdl:documentation>tempuri.org - Add and Subtract calculation
  </wsdl:documentation>
  <wsdl:types>
    <!-- XSD schema for the Request and the Response -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:9000/DOES_NOT_EXIST"/>
    </xsd:schema>
  </wsdl:types>
</wsdl:definitions>
]]

request_common.calculatorWSDL_no_import_multiple_xsd_ok = [[
<?xml version="1.0" encoding="utf-8"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <wsdl:types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema">
      <s:element name="Divide">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Add">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
    </s:schema>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema">
      <s:element name="Add">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="0" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="0" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Mutliple">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
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
    </s:schema>
  </wsdl:types>
</wsdl:definitions>
]]

request_common.calculatorWSDL_v2_no_import_wsdl_defaultNS_xsd_schema_ok = [[
<?xml version="1.0" encoding="utf-8" ?>
<!-- Content from https://jenkov.com/tutorials/wsdl/overview.html -->
<!-- WSDL v2 with <description> tag -->
<!-- 'wsdl' Namespace is the default Namespace and there is no prefix => xmlns   ="http://www.w3.org/ns/wsdl"         -->
<!-- 'xs'   Namespace has a prefix                                    => xmlns:xs="http://www.w3.org/2001/XMLSchema"> -->
<description
    xmlns=           "http://www.w3.org/ns/wsdl"
    targetNamespace= "http://tempuri.org/"
    xmlns:tns=       "http://tempuri.org/"
    xmlns:stns =     "http://tempuri.org/"
    xmlns:wsoap=     "http://www.w3.org/ns/wsdl/soap"
    xmlns:soap=      "http://www.w3.org/2003/05/soap-envelope"
    xmlns:wsdlx=     "http://www.w3.org/ns/wsdl-extensions"
    xmlns:xs=        "http://www.w3.org/2001/XMLSchema">

  <documentation>
    This is the web service documentation.
  </documentation>

  <types>
    <xs:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <xs:element name="Add" type="typeAdd" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeAdd">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="intA" type="xs:int" />
          <xs:element minOccurs="1" maxOccurs="1" name="intB" type="xs:int" />
        </xs:sequence>
      </xs:complexType>
 
      <xs:element name="AddResponse" type="typeAddResponse" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeAddResponse">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="AddResult" type="xs:int" />
        </xs:sequence>
      </xs:complexType>

    </xs:schema>
  </types>

  <interface  name = "AddInterface" >
    <fault name = "invalidAddFault"  element = "stns:invalidAddError"/>
    <operation name="calculatorOperation" pattern="http://www.w3.org/ns/wsdl/in-out" style="http://www.w3.org/ns/wsdl/style/iri" wsdlx:safe = "true">
      <input    messageLabel="In"  element="stns:Add" />
      <output   messageLabel="Out" element="stns:AddResponse" />
      <outfault messageLabel="Out" ref    ="tns:invalidAddFault" />    
    </operation>
  </interface>

  <binding name="calculatorSOAPBinding"
          interface="tns:AddInterface"
          type="http://www.w3.org/ns/wsdl/soap"
          wsoap:protocol="http://www.w3.org/2003/05/soap/bindings/HTTP/">
    <fault ref="tns:invalidAddFault" wsoap:code="soap:Sender"/>
    <operation ref="tns:calculatorOperation"
      wsoap:mep="http://www.w3.org/2003/05/soap/mep/soap-response"/>
  </binding>

  <service name ="calculatorService" interface="tns:AddInterface">
     <endpoint name ="calculatorEndpoint" binding ="tns:calculatorSOAPBinding" address ="http://www.dneonline.com/calculator.asmx"/>
  </service>

</description>]]

request_common.calculatorWSDL_v2_no_import_wsdl2_description_xsd_defaultNS_ok= [[
<?xml version="1.0" encoding="utf-8" ?>
<!-- Content from https://jenkov.com/tutorials/wsdl/overview.html -->
<!-- WSDL v2 with <description> tag -->
<!-- 'wsdl' Namespace has a prefix                                    => xmlns:wsdl="http://www.w3.org/ns/wsdl"         -->
<!-- 'xsd'  Namespace is the default Namespace and there is no prefix => xmlns     ="http://www.w3.org/2001/XMLSchema"> -->
<wsdl2:description
    xmlns:wsdl2=     "http://www.w3.org/ns/wsdl"
    targetNamespace= "http://tempuri.org/"
    xmlns:tns=       "http://tempuri.org/"
    xmlns:stns =     "http://tempuri.org/"
    xmlns:wsoap=     "http://www.w3.org/ns/wsdl/soap"
    xmlns:soap=      "http://www.w3.org/2003/05/soap-envelope"
    xmlns:wsdlx=     "http://www.w3.org/ns/wsdl-extensions"
    xmlns=           "http://www.w3.org/2001/XMLSchema">

  <wsdl2:documentation>
    This is the web service documentation.
  </wsdl2:documentation>

  <wsdl2:types>
    <schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <element name="Add" type="tempuri:typeAdd" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeAdd">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="intA" type="int" />
          <element minOccurs="1" maxOccurs="1" name="intB" type="int" />
        </sequence>
      </complexType>
 
      <element name="AddResponse" type="tempuri:typeAddResponse" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeAddResponse">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="AddResult" type="int" />
        </sequence>
      </complexType>

    </schema>
  </wsdl2:types>

  <wsdl2:interface  name = "AddInterface" >

    <wsdl2:fault name = "invalidAddFault"  element = "stns:invalidAddError"/>

    <wsdl2:operation name="calculatorOperation"
            pattern="http://www.w3.org/ns/wsdl/in-out"
            style="http://www.w3.org/ns/wsdl/style/iri"
            wsdlx:safe = "true">

      <wsdl2:input    messageLabel="In"  element="stns:Add" />
      <wsdl2:output   messageLabel="Out" element="stns:AddResponse" />
      <wsdl2:outfault messageLabel="Out" ref    ="tns:invalidAddFault" />
    
    </wsdl2:operation>

  </wsdl2:interface>

  <wsdl2:binding name="calculatorSOAPBinding"
          interface="tns:AddInterface"
          type="http://www.w3.org/ns/wsdl/soap"
          wsoap:protocol="http://www.w3.org/2003/05/soap/bindings/HTTP/">

    <wsdl2:fault ref="tns:invalidAddFault" wsoap:code="soap:Sender"/>

    <wsdl2:operation ref="tns:calculatorOperation"
      wsoap:mep="http://www.w3.org/2003/05/soap/mep/soap-response"/>

  </wsdl2:binding>

  <wsdl2:service
       name     ="calculatorService"
       interface="tns:AddInterface">

     <wsdl2:endpoint name ="calculatorEndpoint"
            binding ="tns:calculatorSOAPBinding"
            address ="http://www.dneonline.com/calculator.asmx"/>

  </wsdl2:service>

</wsdl2:description>
]]

request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_missing_intB_Add_Failed_Client_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Error Node: Add, Error code: 1871, Line: 4, Message%: Element '{http://tempuri.org/}Add': Missing child element%(s%). Expected is %( {http://tempuri.org/}intB %).</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

-------------------------------------------------------------------------------
-- SOAP/XML REQUEST plugin: configure the Kong entities (Service/Route/Plugin)
-------------------------------------------------------------------------------
function request_common.lazy_setup (PLUGIN_NAME, blue_print, xsltLibrary)

	local calculator_service = blue_print.services:insert({
		protocol = "http",
		host = "ws.soap1.calculator",
		port = 8080,
		path = "/ws",
	})

	local calculatorXSLT_beforeXSD_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_ok" }
		}
	
	blue_print.plugins:insert {
			name = PLUGIN_NAME,
			route = calculatorXSLT_beforeXSD_route,
			config = {
				VerboseRequest = false,
				xsltLibrary = xsltLibrary,
				xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE
			}
	}

	local calculatorXSLT_beforeXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_with_xslt_Params_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_with_xslt_Params_ok_route,
		config = {
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE_with_params,
			xsltParams = {
				["intA_param"] = "1111",
				["intB_param"] = "3333",
			},
		}
	}

	local calculatorXSLT_beforeXSD_invalid_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_invalid" }
	}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_invalid_route,
		-- it lacks the '<' beginning tag
		config = {
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = [[
				xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				</xsl:stylesheet>
			]]
		}
	}

	local calculatorXSLT_beforeXSD_invalid_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_invalid_verbose" }
	}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_invalid_verbose_route,
		-- it lacks the '<' beginning tag
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = [[
				xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				</xsl:stylesheet>
			]]
		}	
	}

	local calculatorXSLT_beforeXSD_xslt2_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_xslt2" }
	}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_xslt2_route,
		-- XSLT 2.0 (or more) not supported by libxslt
		config = {
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = [[<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn"> <xsl:output method="xml" indent="yes"/> <xsl:template name="main"> <xsl:param name="request-body" required="yes"/> <xsl:variable name="json" select="fn:json-to-xml($request-body)"/> <soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"> <soap12:Body> <CelsiusToFahrenheit xmlns="https://www.w3schools.com/xml/"> <Celsius><xsl:value-of select="$json/map/number[@key='degree-celsius']"/></Celsius> </CelsiusToFahrenheit> </soap12:Body> </soap12:Envelope> </xsl:template> </xsl:stylesheet>]]
		}	
	}
	
	local calculatorXSLT_beforeXSD_xslt2_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_xslt2_verbose" }
	}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_xslt2_verbose_route,
		-- XSLT 2.0 (or more) not supported by libxslt
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = [[<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn"> <xsl:output method="xml" indent="yes"/> <xsl:template name="main"> <xsl:param name="request-body" required="yes"/> <xsl:variable name="json" select="fn:json-to-xml($request-body)"/> <soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"> <soap12:Body> <CelsiusToFahrenheit xmlns="https://www.w3schools.com/xml/"> <Celsius><xsl:value-of select="$json/map/number[@key='degree-celsius']"/></Celsius> </CelsiusToFahrenheit> </soap12:Body> </soap12:Envelope> </xsl:template> </xsl:stylesheet>]]
		}	
	}

	local local_req_termination_route = blue_print.routes:insert{
		paths = { "/local_calculator_req_termination" }
	}
	blue_print.plugins:insert {
		name = "request-termination",
		route = local_req_termination_route,
		config = {
			status_code = 200,
			content_type = "text/xml;charset=utf-8",
			body = request_common.calculator_Response
		}	
	}
	local calculator_local_service = blue_print.services:insert({
		protocol = "http",
		host = "localhost",
		port = 9000,
		path = "/local_calculator_req_termination",
	})

	local calculatorXSLT_beforeXSD_request_termination = blue_print.routes:insert{
		service = calculator_local_service,
		paths = { "/calculatorXSLT_beforeXSD_request_termination" }
	}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_request_termination,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE
		}
	}

	local calculatorXSLT_beforeXSD_basic_auth_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_basic_auth" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_basic_auth_route,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE
		}
	}
	blue_print.plugins:insert {
		name = "basic-auth",
		route = calculatorXSLT_beforeXSD_basic_auth_route,
		config = {
		}	
	}

	local calculator_invalid_host_service = blue_print.services:insert({
		protocol = "http",
		host = "127.0.0.2",
		port = 80,
		path = "/calculator.asmx",
	})			
	local calculatorXSLT_beforeXSD__invalid_host_route = blue_print.routes:insert{
		service = calculator_invalid_host_service,
		paths = { "/calculatorXSLT_beforeXSD_invalid_host" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD__invalid_host_route,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE
		}
	}

	local calculator_xsd_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION
		}
	}

	local calculator_xsd_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_ok_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_verbose_route,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION
		}
	}

	local calculator_xsd_soap_invalid_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_SOAP_invalid" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_soap_invalid_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdSoapSchema = request_common.calculator_Request_XSD_API_VALIDATION_invalid
		}
	}

	local calculator_xsd_soap_invalid_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_SOAP_invalid_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_soap_invalid_verbose_route,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdSoapSchema = request_common.calculator_Request_XSD_API_VALIDATION_invalid
		}
	}

	local calculator_xsd_api_invalid_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_API_invalid" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_api_invalid_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_API_VALIDATION_invalid
		}
	}

	local calculator_xsd_api_invalid_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_API_invalid_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_api_invalid_verbose_route,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_API_VALIDATION_invalid
		}
	}

	local calculatorXSLT_afterXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_afterXSD_with_xslt_Params_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_afterXSD_with_xslt_Params_ok_route,
		config = {
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE_with_params,
			xsltParams = {
        ["intA_param"] = "1111",
        ["intB_param"] = "3333",
        ["intA_after_xsd_param"] = "22222",
        ["intB_after_xsd_param"] = "44444",
      },
      xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_with_params,
		}
	}

	local calculatorXSLT_afterXSD_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_afterXSD_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_afterXSD_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER
		}
	}

	local calculatorXSLT_afterXSD_invalid_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_afterXSD_invalid" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_afterXSD_invalid_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_invalid
		}
	}

	local calculatorXSLT_afterXSD_invalid_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_afterXSD_invalid_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_afterXSD_invalid_verbose_route,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_invalid
		}
	}

	local upstream_ws_soap2_calculator = blue_print.upstreams:insert()
	blue_print.targets:insert({
		upstream = upstream_ws_soap2_calculator,
		target = "ws.soap2.calculator:8080",
	})

	local calculatorRoutingByXPath_upstream_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorRoutingByXPath_upstream_entity_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorRoutingByXPath_upstream_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH,
			RouteXPathRegisterNs = {
				request_common.ROUTING_BY_XPATH_ns_default,
				request_common.calculator_Request_ROUTING_BY_XPATH_ns_tempuri
			},
			RouteXPathTargets = {
				{
						URL= "http://" .. upstream_ws_soap2_calculator.name .. "/ws",
						XPath= "/soap:Envelope/soap:Body/tempuri_kong:Add/tempuri_kong:intA",
						XPathCondition= "10"
				},
			}
	}}
	local culatorRoutingByXPath_hostname_route = blue_print.routes:insert{
		service= calculator_service,
		paths= { "/calculatorRoutingByXPath_hostname_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = culatorRoutingByXPath_hostname_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH,
			RouteXPathTargets = {
				{
						URL= "http://ws.soap2.calculator:8080/ws",
						XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
						XPathCondition= "10"
				},
			}
		}
	}

	local culatorRoutingByXPath_hostname_2_XPath_targets_route = blue_print.routes:insert{
		service= calculator_service,
		paths= { "/calculatorRoutingByXPath_hostname_2_XPath_targets_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = culatorRoutingByXPath_hostname_2_XPath_targets_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH,
			RouteXPathTargets = {
				{
						URL= "http://NOT_EXISTING.COM",
						XPath= "/NOT_EXISTING",
						XPathCondition= "/NOT_EXISTING"
				},
				{
					URL= "http://ws.soap2.calculator:8080/ws",
					XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
					XPathCondition= "10"
			},
			}
		}
	}

	local culatorRoutingByXPath_hostname_XPath_not_succeeded_route = blue_print.routes:insert{
		service= calculator_service,
		paths= { "/calculatorRoutingByXPath_hostname_XPath_not_succeeded_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = culatorRoutingByXPath_hostname_XPath_not_succeeded_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH,
			RouteXPathTargets = {
				{
						URL= "http://ws.soap2.calculator:8080/ws",
						XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
						XPathCondition= "***NOT_FOUND***"
				},
			}
		}
	}

	local calculatorRoutingByXPath_hostname_invalid_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorRoutingByXPath_hostname_invalid" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorRoutingByXPath_hostname_invalid_route,
		config = {
			VerboseRequest = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH,
			RouteXPathTargets = {
				{
						URL= "https://ecs.syr.edu.ABCDEFGHIJKLMNOPQRSTU:443/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx",
						XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
						XPathCondition= "10"
				},
			}
		}
	}

	local calculatorRoutingByXPath_hostname_invalid_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorRoutingByXPath_hostname_invalid_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorRoutingByXPath_hostname_invalid_verbose_route,
		config = {
			VerboseRequest = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE,
			xsdApiSchema = request_common.calculator_Request_XSD_VALIDATION,
			xsltTransformAfter = request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH,
			RouteXPathTargets = {
				{
						URL= "https://ecs.syr.edu.ABCDEFGHIJKLMNOPQRSTU:443/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx",
						XPath= "/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']",
						XPathCondition= "10"
				},
			}
		}
	}

	local tempui_org_request_response_xsd = blue_print.routes:insert{
		paths = { "/tempuri.org.request-response.xsd" }
	}
	blue_print.plugins:insert {
		name = "request-termination",
		route = tempui_org_request_response_xsd,
		config = {
			status_code = 200,
			content_type = "text/xml;charset=utf-8",
			body = request_common.calculator_Request_Response_XSD_VALIDATION
		}	
	}
	local calculator_wsdl_ok = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_with_async_download_verbose_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_ok,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			ExternalEntityLoader_Async = true,
			xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok
		}
	}
	
	local calculator_wsdl_invalid_import_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_with_async_download_invalid_import" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_invalid_import_route,
		config = {
			VerboseRequest = false,
			ExternalEntityLoader_CacheTTL = 15,
			ExternalEntityLoader_Async = true,
			xsdApiSchema = request_common.calculatorWSDL_with_async_download_Failed
		}
	}
	local calculator_wsdl_invalid_import_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_with_async_download_invalid_import_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_invalid_import_verbose_route,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			ExternalEntityLoader_Async = true,
			xsdApiSchema = request_common.calculatorWSDL_with_async_download_Failed
		}
	}

	local calculator_wsdl_with_import_no_download_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_with_import_no_download_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_with_import_no_download_route,
		config = {
			VerboseRequest = false,
			xsdApiSchemaInclude = {
				["http://localhost:9000/tempuri.org.request-response.xsd"] = request_common.calculator_Request_Response_XSD_VALIDATION
			},
			xsdApiSchema = request_common.calculatorWSDL_one_import_for_req_res_ok
		}
	}
	
	local calculator_wsdl_no_import_mutliple_xsd_add_in_xsd1_ok = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_no_import_multiple_XSD_Add_in_XSD1_verbose_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_no_import_mutliple_xsd_add_in_xsd1_ok,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			xsdApiSchema = request_common.calculatorWSDL_no_import_multiple_xsd_ok
		}
	}

	local calculator_wsdl_no_import_mutliple_xsd_subtract_in_xsd2_ok = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_no_import_multiple_XSD_Subtract_in_XSD2_verbose_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_no_import_mutliple_xsd_subtract_in_xsd2_ok,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			xsdApiSchema = request_common.calculatorWSDL_no_import_multiple_xsd_ok
		}
	}

	local calculator_wsdl_no_import_mutliple_xsd_power_not_defined_in_xsds_ko = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_no_import_multiple_XSD_Power_not_defined_in_XSDs_verbose_ko" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_no_import_mutliple_xsd_power_not_defined_in_xsds_ko,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			ExternalEntityLoader_Async = true,
			xsdApiSchema = request_common.calculatorWSDL_no_import_multiple_xsd_ok
		}
	}

	local calculator_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			xsdApiSchema = request_common.calculatorWSDL_req_res_multiple_imports_Ok,
			xsdApiSchemaInclude = {
				["http://localhost:9000/tempuri.org.req.res.add.xsd"] = request_common.calculator_Request_Response_Add_XSD_VALIDATION,
				["http://localhost:9000/tempuri.org.req.res.subtract.xsd"] = request_common.calculator_Request_Response_Subtract_XSD_VALIDATION,
			},
		}
	}

	local calculator_wsdl_v2_no_import_wsdl_defaultNS_xsd_schema_ok = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_v2_no_import_wsdl_defaultNS_xsd_schema_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_v2_no_import_wsdl_defaultNS_xsd_schema_ok,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			xsdApiSchema = request_common.calculatorWSDL_v2_no_import_wsdl_defaultNS_xsd_schema_ok
		}
	}

	local calculatorWSDL_v2_no_import_wsdl2_description_xsd_defaultNS_ok = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_v2_no_import_wsdl2_description_xsd_defaultNS_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorWSDL_v2_no_import_wsdl2_description_xsd_defaultNS_ok,
		config = {
			VerboseRequest = true,
			ExternalEntityLoader_CacheTTL = 15,
			xsdApiSchema = request_common.calculatorWSDL_v2_no_import_wsdl2_description_xsd_defaultNS_ok
		}
	}

end

------------------------------------------
-- SOAP/XML REQUEST plugin: Execute tests
------------------------------------------
function request_common._1_XSLT_BEFORE_XSD_Valid_transformation (assert, client)
		-- invoke a test request
		local r = client:post("/calculatorXSLT_beforeXSD_ok", {
			headers = {
				["Content-Type"] = "text/xml;charset=utf-8",
			},
			body = request_common.calculator_Request,
		})
	
		-- validate that the request succeeded: response status 200, Content-Type and right match
		local body = assert.response(r).has.status(200)
		local content_type = assert.response(r).has.header("Content-Type")
		assert.matches("text/xml%;%s-charset=utf%-8", content_type)
		assert.matches('<AddResult>13</AddResult>', body)	
end

function request_common._1_XSLT_BEFORE_XSD_with_xslt_Params_Ok (assert, client)
	-- invoke a test request	
	local r = client:post("/calculatorXSLT_beforeXSD_with_xslt_Params_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches("<AddResult>4444</AddResult>", body)
end


function request_common._1_XSLT_BEFORE_XSD_Invalid_XSLT_input(assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_invalid", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed, body)
end

function request_common._1_XSLT_BEFORE_XSD_Invalid_XSLT_with_Verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_invalid_verbose", {
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
end

function request_common._1_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported(assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_xslt2", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed, body)
end

function request_common._1_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported_with_Verbose(assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_xslt2_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_2_0_Error_Verbose, body)
end

function request_common._1_XSLT_BEFORE_XSD_Valid_transformation_with_request_termination_plugin_200 (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_request_termination", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})
	
	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>13</AddResult>', body)
end

function request_common._1_XSLT_BEFORE_XSD_Valid_transformation_with_basic_auth_plugin_401_with_Verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_basic_auth", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})
	
	-- validate that the request failed: response status 401, Content-Type and right Match
	local body = assert.response(r).has.status(401)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed_401_Error_Verbose, body)
end

function request_common._1_XSLT_BEFORE_XSD_Invalid_Hostname_service_502_with_Verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_invalid_host", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})
	
	-- validate that the request failed: response status 502, Content-Type and right match
	local body = assert.response(r).has.status(502)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_BEFORE_Failed_502_Error_Verbose, body)
end

function request_common._1_2_XSD_Validation_Ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>13</AddResult>', body)
end

function request_common._1_2_XSD_Validation_Invalid_SOAP_XSD_input (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_SOAP_invalid", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed, body)
end

function request_common._1_2_XSD_Validation_Invalid_SOAP_XSD_input_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_SOAP_invalid_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_SOAP_INPUT_VALIDATION_Failed_verbose, body)
end

function request_common._1_2_XSD_Validation_Invalid_API_XSD_input (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_API_invalid", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed, body)
end

function request_common._1_2_XSD_Validation_Invalid_API_XSD_input_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_API_invalid_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_INPUT_Failed_verbose, body)
end

function request_common._1_2_XSD_Validation_Invalid_SOAP_request (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request_SOAP_ko,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed_Client, body)
end

function request_common._1_2_XSD_Validation_Invalid_SOAP_request_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_ok_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request_SOAP_ko,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_Failed_Client_verbose, body)
end

function request_common._1_2_XSD_Validation_Invalid_API_request (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request_API_ko,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed_Client, body)
end

function request_common._1_2_XSD_Validation_Invalid_API_request_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_ok_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request_API_ko,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_Failed_verbose, body)
end

function request_common._1_2_XSD_Validation_Invalid_SOAP_request_without_soapBody_with_verbose_ko (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_ok_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request_SOAP_No_soapBody_ko,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_NO_soapBody_Failed_Client_verbose, body)
end

function request_common._1_2_XSD_Validation_Invalid_API_request_without_Operation_with_verbose_ko (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_ok_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request_SOAP_No_Operation_ko,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_no_operation_Failed_Client_verbose, body)
end

function request_common._1_3_XSLT_AFTER_XSD_with_xslt_Params_Ok (assert, client)
	-- invoke a test request	
	local r = client:post("/calculatorXSLT_afterXSD_with_xslt_Params_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches("<AddResult>66666</AddResult>", body)
end

function request_common._1_2_3_XSLT_AFTER_XSD_Ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_afterXSD_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>13</AddResult>', body)
end

function request_common._1_2_3_XSLT_AFTER_XSD_Invalid_XSLT_input (assert, client)	
	-- invoke a test request
	local r = client:post("/calculatorXSLT_afterXSD_invalid", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_AFTER_Failed, body)
end

function request_common._1_2_3_XSLT_AFTER_XSD_Invalid_XSLT_input_with_verbose (assert, client)	
	-- invoke a test request
	local r = client:post("/calculatorXSLT_afterXSD_invalid_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_AFTER_Failed_verbose, body)
end

function request_common._1_2_3_4_ROUTING_BY_XPATH_with_upstream_entity_Ok (assert, client)			
	-- invoke a test request
	local r = client:post("/calculatorRoutingByXPath_upstream_entity_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.equal("soap2", x_soap_region)
	assert.matches('<AddResult>18</AddResult>', body)
end

function request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Ok (assert, client)		
	-- invoke a test request
	local r = client:post("/calculatorRoutingByXPath_hostname_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
	assert.equal("soap2", x_soap_region)
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>18</AddResult>', body)
end

function request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_2_XPath_targets_Ok (assert, client)		
	-- invoke a test request
	local r = client:post("/calculatorRoutingByXPath_hostname_2_XPath_targets_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
	assert.equal("soap2", x_soap_region)
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>18</AddResult>', body)
end

function request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_XPath_not_succeeded_Ok (assert, client)		
	-- invoke a test request
	local r = client:post("/calculatorRoutingByXPath_hostname_XPath_not_succeeded_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	local x_soap_region = assert.response(r).has.header("X-SOAP-Region")
	assert.Not.equal("soap2", x_soap_region)
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>18</AddResult>', body)
end

function request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Invalid_Hostname_503 (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorRoutingByXPath_hostname_invalid", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request failed: response status 503, Content-Type and right match
	local body = assert.response(r).has.status(503)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH_Failed_503, body)
end

function request_common._1_2_3_4_ROUTING_BY_XPATH_with_hostname_Invalid_Hostname_503_with_verbose (assert, client)	
	-- invoke a test request
	local r = client:post("/calculatorRoutingByXPath_hostname_invalid_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request failed: response status 503, Content-Type and right match
	local body = assert.response(r).has.status(503)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH_Failed_503_verbose, body)
end

function request_common._2_WSDL_Validation_with_async_download_Ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_async_download_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>12</AddResult>', body)
end

function request_common._2_WSDL_Validation_with_async_download_Invalid_Import (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_async_download_invalid_import", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed, body)
end

function request_common._2_WSDL_Validation_with_async_download_Invalid_Import_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_async_download_invalid_import_verbose", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_VALIDATION_Failed_shortened, body)
	assert.matches("<errorMessage>.*Failed to.*'http://localhost:9000/DOES_NOT_EXIST'.*</errorMessage>", body)
end

function request_common._2_WSDL_Validation_with_import_no_download_Ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_import_no_download_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>12</AddResult>', body)
end

function request_common._2_WSDL_Validation_Invalid_SOAP_request_Empty_with_verbose_ko (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_async_download_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = '',
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_SOAP_VALIDATION_REQUEST_empty_SOAP_Failed_Client_verbose, body)
end

function request_common._2_WSDL_Validation_no_Import_multiple_XSD_Add_in_XSD1_with_verbose_ko (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_no_import_multiple_XSD_Add_in_XSD1_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_missing_intB_Add_Failed_Client_verbose, body)
end

function request_common._2_WSDL_Validation_no_Import_multiple_XSD_Subtract_in_XSD2_with_verbose_ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_no_import_multiple_XSD_Subtract_in_XSD2_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Full_Request,
	})

	-- validate that the request failed: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches("<SubtractResult>4</SubtractResult>", body)
end

function request_common._2_WSDL_Validation_no_Import_multiple_XSD_Power_not_defined_in_XSDs_with_verbose_ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_no_import_multiple_XSD_Power_not_defined_in_XSDs_verbose_ko", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Power_Full_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_Power_Failed_Client_verbose, body)
end


function request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Add_in_XSD1_with_verbose_ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>12</AddResult>', body)
end

function request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Subtract_in_XSD2_with_verbose_ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Full_Request,
	})

	-- validate that the request failed: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches("<SubtractResult>4</SubtractResult>", body)
end

function request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Add_in_XSD1_with_verbose_ko (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_Add_Expected_intB_Failed_Client_verbose, body)
end

function request_common._2_WSDL_Validation_with_multiple_XSD_imported_no_download_Subtract_in_XSD2_with_verbose_ko (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_multiple_XSD_imported_no_download_Add_in_XSD1_Subtract_in_XSD2_with_verbose_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Subtract_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches(request_common.calculator_Request_XSD_API_VALIDATION_REQUEST_Subtract_Expected_intB_Failed_Client_verbose, body)
end

function request_common._2_WSDL_v2_Validation_no_Import_wsdl_defaultNS_xsd_schema_with_verbose_ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_v2_no_import_wsdl_defaultNS_xsd_schema_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>12</AddResult>', body)
end

function request_common._2_WSDL_v2_Validation_no_Import_wsdl2_description_xsd_defaultNS_with_verbose_ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_v2_no_import_wsdl2_description_xsd_defaultNS_ok", {
		headers = {
			["Content-Type"] = "text/xml;charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.matches("text/xml%;%s-charset=utf%-8", content_type)
	assert.matches('<AddResult>12</AddResult>', body)
end

return request_common