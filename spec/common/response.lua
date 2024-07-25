-- Notes:
-- Some characters, called magic characters, have special meanings when used in a pattern. The magic characters are
-- ( ) . % + - * ? [ ^ $

local helpers = require "spec.helpers"
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

local calculator_Response_XSLT_BEFORE = [[
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

local calculator_Response_XSLT_BEFORE_invalid = [[
xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
</xsl:stylesheet>
]]

local calculator_Response_XSLT_BEFORE_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSLT transformation failed %(before XSD validation%)</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Response_XSLT_BEFORE_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Response %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>Error code: 4, Line: 1, Message: Start tag expected, '<' not found. SOAP/XML Web Service %- HTTP code: 200</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Response_XSD_VALIDATION = [[
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
				xsltTransformBefore = calculator_Response_XSLT_BEFORE
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
			xsltTransformBefore = calculator_Response_XSLT_BEFORE_invalid
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
			xsltTransformBefore = calculator_Response_XSLT_BEFORE_invalid
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
      xsltTransformBefore = calculator_Response_XSLT_BEFORE,
      xsdApiSchema = calculator_Response_XSD_VALIDATION
    }
	}
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
  
    -- validate that the request succeeded: response status 200, Content-Type and right math
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

  -- validate that the request succeeded: response status 500, Content-Type and right match
  local body = assert.response(r).has.status(500)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  assert.matches(calculator_Response_XSLT_BEFORE_Failed, body)
end

function response_common._5_XSLT_BEFORE_XSD_Invalid_XSLT_input_wiuth_Verbose (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSLT_beforeXSD_invalid_verbose", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request succeeded: response status 500, Content-Type and right match
  local body = assert.response(r).has.status(500)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  assert.matches(calculator_Response_XSLT_BEFORE_Failed_verbose, body)
end

function response_common._5_6_XSD_Validation_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculatorXSD_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = response_common.calculator_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right math
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("text/xml; charset=utf-8", content_type)
  assert.matches('<KongResult>13</KongResult>', body)	  
end

return response_common