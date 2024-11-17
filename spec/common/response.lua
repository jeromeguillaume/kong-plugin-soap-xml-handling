-- Notes:
-- Some characters, called magic characters, have special meanings when used in a pattern. The magic characters are
-- ( ) . % + - * ? [ ^ $

local helpers         = require "spec.helpers"
local request_common  = require "spec.common.request"
local KongGzip        = require "kong.tools.gzip"
local response_common = {}

response_common.calculator_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Body>
		<Add xmlns="http://tempuri.org/">
			<intA>5</intA>
      <intB>8</intB>
		</Add>
	</soap:Body>
</soap:Envelope>
]]

response_common.calculator_Response_General_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- General process failed</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_General_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- General process failed</faultstring>
      <detail>Content%-encoding of type 'deflate' is not supported. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSLT_BEFORE = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//*[local-name()='AddResult']">
    <KongResult><xsl:apply-templates select="@*|node()" /></KongResult>
  </xsl:template>
</xsl:stylesheet>
]]

response_common.calculator_Response_XSLT_BEFORE_invalid = [[
xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
</xsl:stylesheet>
]]

response_common.calculator_Response_XSLT_BEFORE_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSLT transformation failed %(before XSD validation%)</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSLT_BEFORE_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSLT_BEFORE_Failed_XSLT_2_0_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>compilation error. xsl:version: only 1.1 features are supported. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSD_VALIDATION = [[
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="AddResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>]]

response_common.calculator_Response_XSD_VALIDATION_Kong = [[
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="KongResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
]]

response_common.calculatorWSDL_req_only_with_async_download_Ok = [[
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
    <!-- XSD schema for the Response -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:9000/tempuri.org.response.xsd"/>
    </xsd:schema>
  </wsdl:types>
</wsdl:definitions>
]]


response_common.calculator_Response_XSD_VALIDATION_Failed_shortened = [[
<faultstring>Response %- XSD validation failed</faultstring>
]]

response_common.calculator_Response_XSD_VALIDATION_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSD validation failed</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSD_SOAP_INPUT_VALIDATION_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSD validation failed</faultstring>
      <detail>Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found. Error code: 3067, Line: 0, Message: Failed to parse the XML resource 'in_memory_buffer'. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSD_API_VALIDATION_INPUT_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSD validation failed</faultstring>
      <detail>WSDL validation %- errMessage Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSD_SOAP_invalid_definition = [[<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/" targetNamespace="http://schemas.xmlsoap.org/soap/envelope/" > <!-- EnvelopeKong, header and body --> <xs:element name="EnvelopeKong" type="tns:EnvelopeKong" /> <xs:complexType name="EnvelopeKong" ><xs:sequence><xs:element ref="tns:Header" minOccurs="0" /><xs:element ref="tns:Body" minOccurs="1" /><xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##other" processContents="lax" /></xs:complexType><xs:element name="Header" type="tns:Header" /><xs:complexType name="Header" ><xs:sequence><xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##other" processContents="lax" /></xs:complexType><xs:element name="Body" type="tns:Body" /><xs:complexType name="Body" ><xs:sequence><xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##any" processContents="lax" ><xs:annotation><xs:documentation>Prose in the spec does not specify that attributes are allowed on the Body element</xs:documentation></xs:annotation></xs:anyAttribute></xs:complexType><!-- Global Attributes.  The following attributes are intended to be usable via qualified attribute names on any complex type referencing them.  --><xs:attribute name="mustUnderstand" ><xs:simpleType><xs:restriction base='xs:boolean'><xs:pattern value='0|1' /></xs:restriction></xs:simpleType></xs:attribute><xs:attribute name="actor" type="xs:anyURI" /><xs:simpleType name="encodingStyle" ><xs:annotation><xs:documentation>'encodingStyle' indicates any canonicalization conventions followed in the contents of the containing element.  For example, the value 'http://schemas.xmlsoap.org/soap/encoding/' indicates the pattern described in SOAP specification</xs:documentation></xs:annotation><xs:list itemType="xs:anyURI" /></xs:simpleType><xs:attribute name="encodingStyle" type="tns:encodingStyle" /><xs:attributeGroup name="encodingStyle" ><xs:attribute ref="tns:encodingStyle" /></xs:attributeGroup><xs:element name="Fault" type="tns:Fault" /><xs:complexType name="Fault" final="extension" ><xs:annotation><xs:documentation>Fault reporting structure</xs:documentation></xs:annotation><xs:sequence><xs:element name="faultcode" type="xs:QName" /><xs:element name="faultstring" type="xs:string" /><xs:element name="faultactor" type="xs:anyURI" minOccurs="0" /><xs:element name="detail" type="tns:detail" minOccurs="0" /></xs:sequence></xs:complexType><xs:complexType name="detail"><xs:sequence><xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##any" processContents="lax" /> </xs:complexType></xs:schema>]]

response_common.calculator_Response_XSD_SOAP_invalid_definition_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSD validation failed</faultstring>
      <detail>Error Node: Envelope, Error code: 1845, Line: 2, Message: Element '{http://schemas.xmlsoap.org/soap/envelope/}Envelope': No matching global declaration available for the validation root. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSD_API_invalid_definition = [[
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="KONG_AddResponse" type="tem:KONG_AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="KONG_AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="KongResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
]]

response_common.calculator_Response_XSD_API_invalid_definition_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSD validation failed</faultstring>
      <detail>Error Node: AddResponse, Error code: 1845, Line: 2, Message: Element '{http://tempuri.org/}AddResponse': No matching global declaration available for the validation root. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Request_XSLT_AFTER = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" exclude-result-prefixes="soapenv">
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <!-- remove all elements in the soapenv namespace -->
  <xsl:template match="soapenv:*">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  <!-- for the remaining elements (i.e. elements in the default namespace) ... -->
  <xsl:template match="*">
      <!-- ... create a new element with similar name in no-namespace -->
      <xsl:element name="{local-name()}">
          <xsl:apply-templates select="@*|node()"/>
      </xsl:element>
  </xsl:template>
  <!-- convert attributes to elements -->
  <xsl:template match="@*">
      <xsl:element name="{local-name()}">
          <xsl:value-of select="." />
      </xsl:element>
  </xsl:template>
</xsl:stylesheet>
]]

response_common.calculator_Response_XML = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<AddResponse><KongResult>13</KongResult></AddResponse>]]

response_common.calculator_Response_XSLT_AFTER_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSLT transformation failed %(after XSD validation%)</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_XSLT_AFTER_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSLT transformation failed %(after XSD validation%)</faultstring>
      <detail>Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

response_common.calculator_Response_No_soapBody = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
</soap:Envelope>]]

response_common.calculator_Response_XSD_SOAP_VALIDATION_REQUEST_blank_soap_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSD validation failed</faultstring>
      <detail>Error code: 4, Line: 1, Message: Start tag expected, 'Less Than' not found. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]


-------------------------------------------------------------------------------
-- SOAP/XML REQUEST plugin: configure the Kong entities (Service/Route/Plugin)
-------------------------------------------------------------------------------
function response_common.lazy_setup (PLUGIN_NAME, blue_print, xsltLibrary)

	local calculator_service = blue_print.services:insert({
		protocol = "http",
		host = "www.dneonline.com",
		port = 80,
		path = "/calculator.asmx",
	})

	local calculatorXSLT_beforeXSD_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_ok" }
		}

	blue_print.plugins:insert {
			name = PLUGIN_NAME,
			route = calculatorXSLT_beforeXSD_route,
			config = {
				VerboseResponse = false,
				xsltLibrary = xsltLibrary,
				xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE
			}
	}
  
  local calculatorXSLT_beforeXSD_invalid_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_invalid" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_invalid_route,
		config = {
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_invalid
		}
	}

  local calculatorXSLT_beforeXSD_invalid_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_invalid_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_invalid_verbose_route,
		config = {
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_invalid
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
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = [[<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn"> <xsl:output method="xml" indent="yes"/> <xsl:template name="main"> <xsl:param name="request-body" required="yes"/> <xsl:variable name="json" select="fn:json-to-xml($request-body)"/> <soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"> <soap12:Body> <CelsiusToFahrenheit xmlns="https://www.w3schools.com/xml/"> <Celsius><xsl:value-of select="$json/map/number[@key='degree-celsius']"/></Celsius> </CelsiusToFahrenheit> </soap12:Body> </soap12:Envelope> </xsl:template> </xsl:stylesheet>]]
		}	
	}

  local calculatorXSLT_beforeXSD_unknown_content_type_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_unknown_content_type" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_unknown_content_type_route,
		config = {
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE
		}
	}
  blue_print.plugins:insert {
		name = 'response-transformer',
		route = calculatorXSLT_beforeXSD_unknown_content_type_route,
		config = {
			replace = {
        headers = 
        {'Content-Encoding:deflate'}
      }
		}
	}

  local calculatorXSLT_beforeXSD_unknown_content_type_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSLT_beforeXSD_unknown_content_type_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSLT_beforeXSD_unknown_content_type_verbose_route,
		config = {
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE
		}
	}
  blue_print.plugins:insert {
		name = 'response-transformer',
		route = calculatorXSLT_beforeXSD_unknown_content_type_verbose_route,
		config = {
			replace = {
        headers = 
        {'Content-Encoding:deflate'}
      }
		}
	}

  local calculatorXSD_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculatorXSD_route,
		config = {
      VerboseResponse = false,
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
      xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong
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
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdSoapSchema = response_common.calculator_Response_XSLT_BEFORE_invalid
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
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdSoapSchema = response_common.calculator_Response_XSLT_BEFORE_invalid
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
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdApiSchema = response_common.calculator_Response_XSLT_BEFORE_invalid
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
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdApiSchema = response_common.calculator_Response_XSLT_BEFORE_invalid
		}
	}

  local calculator_xsd_soap_invalid_response_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_SOAP_invalid_response" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_soap_invalid_response_route,
		config = {
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdSoapSchema = response_common.calculator_Response_XSD_SOAP_invalid_definition
		}
	}

  local calculator_xsd_soap_invalid_response_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_SOAP_invalid_response_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_soap_invalid_response_verbose_route,
		config = {
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdSoapSchema = response_common.calculator_Response_XSD_SOAP_invalid_definition
		}
	}

  local calculator_xsd_api_invalid_response_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_API_invalid_response" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_api_invalid_response_route,
		config = {
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdApiSchema = response_common.calculator_Response_XSD_API_invalid_definition
		}
	}

  local calculator_xsd_api_invalid_response_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorXSD_API_invalid_response_verbose" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_xsd_api_invalid_response_verbose_route,
		config = {
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdApiSchema = response_common.calculator_Response_XSD_API_invalid_definition
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
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
			xsltTransformAfter = response_common.calculator_Request_XSLT_AFTER
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
			VerboseResponse = false,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
			xsltTransformAfter = response_common.calculator_Response_XSLT_BEFORE_invalid
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
			VerboseResponse = true,
			xsltLibrary = xsltLibrary,
			xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE,
			xsdApiSchema = response_common.calculator_Response_XSD_VALIDATION_Kong,
			xsltTransformAfter = response_common.calculator_Response_XSLT_BEFORE_invalid
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
			content_type = "text/xml; charset=utf-8",
			body = request_common.calculator_Request_Response_XSD_VALIDATION
		}	
	}
	local calculator_wsdl_ok = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculatorWSDL_with_async_download_ok" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_ok,
		config = {
			VerboseResponse = false,
			ExternalEntityLoader_CacheTTL = 15,
			ExternalEntityLoader_Async = true,
			xsdApiSchema = request_common.calculatorWSDL_with_async_download_Ok
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
			VerboseResponse = false,
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
			VerboseResponse = true,
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
			VerboseResponse = true,
			xsdApiSchemaInclude = {
				["http://localhost:9000/tempuri.org.request-response.xsd"] = request_common.calculator_Request_Response_XSD_VALIDATION
			},
			xsdApiSchema = request_common.calculatorWSDL_with_async_download_Ok
		}
	}

	local local_res_termination_blank_soap_route = blue_print.routes:insert{
		paths = { "/local_calculator_res_termination_blank_soap" }
	}
	blue_print.plugins:insert {
		name = "request-termination",
		route = local_res_termination_blank_soap_route,
		config = {
			status_code = 200,
			content_type = "text/xml; charset=utf-8",
			body = ' '
		}	
	}
	local calculator_local_blank_soap_service = blue_print.services:insert({
		protocol = "http",
		host = "localhost",
		port = 9000,
		path = "/local_calculator_res_termination_blank_soap",
	})
	local calculator_wsdl_blank_soap_route = blue_print.routes:insert{
		service = calculator_local_blank_soap_service,
		paths = { "/calculatorWSDL_blank_soap_ko" }
		}
	blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_wsdl_blank_soap_route,
		config = {
			VerboseResponse = true,
			xsdApiSchema = request_common.calculatorWSDL_with_async_download_Ok
		}
	}

	local local_res_termination_no_soapBody_route = blue_print.routes:insert{
		paths = { "/local_calculator_res_termination_no_soapBody" }
	}
	blue_print.plugins:insert {
		name = "request-termination",
		route = local_res_termination_no_soapBody_route,
		config = {
			status_code = 200,
			content_type = "text/xml; charset=utf-8",
			body = response_common.calculator_Response_No_soapBody
		}	
	}
	local calculator_local_no_soapBody_service = blue_print.services:insert({
		protocol = "http",
		host = "localhost",
		port = 9000,
		path = "/local_calculator_res_termination_no_soapBody",
	})

	local local_res_termination_api_no_operation_route = blue_print.routes:insert{
		paths = { "/local_calculator_res_termination_api_no_operation" }
	}
	blue_print.plugins:insert {
		name = "request-termination",
		route = local_res_termination_api_no_operation_route,
		config = {
			status_code = 200,
			content_type = "text/xml; charset=utf-8",
			body = response_common.calculator_Response_No_soapBody
		}	
	}
	local calculator_local_api_no_operation = blue_print.services:insert({
		protocol = "http",
		host = "localhost",
		port = 9000,
		path = "/local_calculator_res_termination_api_no_operation",
	})

end

-------------------------------------------
-- SOAP/XML RESPONSE plugin: Execute tests
-------------------------------------------
function response_common._5_XSLT_BEFORE_XSD_Valid_transformation (assert, client)
    -- invoke a test request
    local r = client:post("/calculatorXSLT_beforeXSD_ok", {
      headers = {
        ["Content-Type"] = "text/xml; charset=utf-8",
      },
      body = response_common.calculator_Request,
    })
  
    -- validate that the request succeeded: response status 200, Content-Type and right match
    local body = assert.response(r).has.status(200)
    local content_type = assert.response(r).has.header("Content-Type")
    assert.equal("text/xml; charset=utf-8", content_type)
    assert.matches('<KongResult>13</KongResult>', body)	  
end

function response_common._5_XSLT_BEFORE_XSD_Invalid_XSLT_input (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSLT_beforeXSD_invalid", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
  local body = assert.response(r).has.status(500)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  assert.matches(response_common.calculator_Response_XSLT_BEFORE_Failed, body)
end

function response_common._5_XSLT_BEFORE_XSD_Invalid_XSLT_input_with_verbose (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSLT_beforeXSD_invalid_verbose", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
  local body = assert.response(r).has.status(500)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  assert.matches(response_common.calculator_Response_XSLT_BEFORE_Failed_verbose, body)
end

function response_common._5_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported(assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_xslt2", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSLT_BEFORE_Failed, body)
end

function response_common._5_XSLT_BEFORE_XSD_XSLT_2_0_input_Not_supported_with_Verbose(assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_beforeXSD_xslt2_verbose", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSLT_BEFORE_Failed_XSLT_2_0_Error_Verbose, body)
end

function response_common._5_XSLT_BEFORE_XSD_gzip_Content_Encoding_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSLT_beforeXSD_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
      ["Accept-Encoding"] = "gzip",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  local content_encoding = assert.response(r).has.header("Content-Encoding")
  assert.equal("gzip", content_encoding)
  local bodyDeflated, err = KongGzip.inflate_gzip(body)
  assert.matches('<KongResult>13</KongResult>', bodyDeflated)
end

function response_common._5_XSLT_BEFORE_XSD_Content_Encoding_Unknown_Encoding (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSLT_beforeXSD_unknown_content_type", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
      ["Accept-Encoding"] = "gzip",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
  local body = assert.response(r).has.status(500)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  local content_encoding = assert.response(r).has.no_header("Content-Encoding")
  assert.matches(response_common.calculator_Response_General_Failed, body)
  
end

function response_common._5_XSLT_BEFORE_XSD_Content_Encoding_Unknown_Encoding_with_verbose (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSLT_beforeXSD_unknown_content_type_verbose", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
      ["Accept-Encoding"] = "gzip",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
  local body = assert.response(r).has.status(500)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  local content_encoding = assert.response(r).has.no_header("Content-Encoding")
  assert.matches(response_common.calculator_Response_General_Failed_verbose, body)
end

function response_common._5_6_XSD_Validation_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSD_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  assert.matches('<KongResult>13</KongResult>', body)	  
end

function response_common._5_6_XSD_Validation_Invalid_SOAP_XSD_input (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_SOAP_invalid", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_VALIDATION_Failed, body)
end

function response_common._5_6_XSD_Validation_Invalid_SOAP_XSD_input_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_SOAP_invalid_verbose", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_SOAP_INPUT_VALIDATION_Failed_verbose, body)
end

function response_common._5_6_XSD_Validation_Invalid_API_XSD_input (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_API_invalid", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_VALIDATION_Failed, body)
end

function response_common._5_6_XSD_Validation_Invalid_API_XSD_input_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_API_invalid_verbose", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_API_VALIDATION_INPUT_Failed_verbose, body)
end

function response_common._5_6_XSD_Validation_Invalid_SOAP_response (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_SOAP_invalid_response", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})
	
	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)	
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_VALIDATION_Failed, body)
end

function response_common._5_6_XSD_Validation_Invalid_SOAP_response_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_SOAP_invalid_response_verbose", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_SOAP_invalid_definition_Failed_verbose, body)
end

function response_common._5_6_XSD_Validation_Invalid_API_response (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_API_invalid_response", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_VALIDATION_Failed, body)
end

function response_common._5_6_XSD_Validation_Invalid_API_response_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSD_API_invalid_response_verbose", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_API_invalid_definition_Failed_verbose, body)
end

function response_common._5_6_7_XSLT_AFTER_XSD_Ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorXSLT_afterXSD_ok", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XML, body)
end

function response_common._5_6_7_XSLT_AFTER_XSD_Invalid_XSLT_input (assert, client)	
	-- invoke a test request
	local r = client:post("/calculatorXSLT_afterXSD_invalid", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSLT_AFTER_Failed, body)
end

function response_common._5_6_7_XSLT_AFTER_XSD_Invalid_XSLT_input_with_verbose (assert, client)	
	-- invoke a test request
	local r = client:post("/calculatorXSLT_afterXSD_invalid_verbose", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = response_common.calculator_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSLT_AFTER_Failed_verbose, body)
end

function response_common._6_WSDL_Validation_with_async_download_Ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_async_download_ok", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches('<AddResult>12</AddResult>', body)
end

function response_common._6_WSDL_Validation_with_async_download_Invalid_Import (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_async_download_invalid_import", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_VALIDATION_Failed, body)
end

function response_common._6_WSDL_Validation_with_async_download_Invalid_Import_with_verbose (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_async_download_invalid_import_verbose", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_VALIDATION_Failed_shortened, body)
	assert.matches("<detail>.*Failed to.*'http://localhost:9000/DOES_NOT_EXIST'.*</detail>", body)
end

function response_common._6_WSDL_Validation_with_import_no_download_Ok (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_with_import_no_download_ok", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches('<AddResult>12</AddResult>', body)
end

function response_common._6_WSDL_Validation_blank_soap_request_with_verbose_ko (assert, client)
	-- invoke a test request
	local r = client:post("/calculatorWSDL_blank_soap_ko", {
		headers = {
			["Content-Type"] = "text/xml; charset=utf-8",
		},
		body = request_common.calculator_Full_Request,
	})

	-- validate that the request succeeded: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("text/xml; charset=utf-8", content_type)
	assert.matches(response_common.calculator_Response_XSD_SOAP_VALIDATION_REQUEST_blank_soap_Failed_verbose, body)
end


return response_common