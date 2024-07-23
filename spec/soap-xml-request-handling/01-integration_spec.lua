-- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
local helpers = require "spec.helpers"

-- matches our plugin name defined in the plugins's schema.lua
local PLUGIN_NAME = "soap-xml-request-handling"

-- Notes:
-- Some characters, called magic characters, have special meanings when used in a pattern. The magic characters are
-- ( ) . % + - * ? [ ^ $

local calculator_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Body>
		<Add xmlns="http://tempuri.org/">
			<intA>5</intA>
		</Add>
	</soap:Body>
</soap:Envelope>
]]

local calculator_Subtract_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Body>
		<Subtract xmlns="http://tempuri.org/">
			<intA>5</intA>
		</Subtract>
	</soap:Body>
</soap:Envelope>
]]
local calculator_Response = [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
]]

local calculator_Request_XSLT_BEFORE_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSLT transformation failed %(before XSD validation%)</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>Error code: 4, Line: 1, Message: Start tag expected, '<' not found</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSLT_BEFORE_Failed_401_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Unauthorized</faultstring>
      <detail>HTTP Error code is 401</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSLT_BEFORE_Failed_502_Error_Verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>An invalid response was received from the upstream server</faultstring>
      <detail>HTTP Error code is 502. SOAP/XML Web Service %- HTTP code: 502</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSLT_BEFORE = [[
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

local calculator_Request_XSD_VALIDATION = [[
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

local calculator_Request_XSD_VALIDATION_invalid = [[
s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema">
</s:schema>
]]

local calculator_Request_XSD_VALIDATION_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSD_VALIDATION_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>WSDL validation %- errMessage Error code: 4, Line: 1, Message: Start tag expected, '<' not found</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSLT_AFTER = [[
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

local calculator_Request_XSLT_AFTER_invalid = [[
xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
</xsl:stylesheet>
]]

local calculator_Request_XSLT_AFTER_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSLT transformation failed %(after XSD validation%)</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSLT_AFTER_Failed_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSLT transformation failed %(after XSD validation%)</faultstring>
      <detail>Error code: 4, Line: 1, Message: Start tag expected, '<' not found</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//*[local-name()='Subtract']">
      <urn:add xmlns:urn="urn:calc"><xsl:apply-templates select="@*|node()" /></urn:add>
  </xsl:template>
  <xsl:template match="//*[local-name()='intA']">
    <a><xsl:apply-templates select="@*|node()" /></a>
  </xsl:template>
  <xsl:template match="//*[local-name()='intB']">
    <b><xsl:apply-templates select="@*|node()" /></b>
  </xsl:template>
</xsl:stylesheet>
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
				
				local calculator_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculator" }
					}
				
				blue_print.plugins:insert {
						name = PLUGIN_NAME,
						route = calculator_route,
						config = {
							VerboseRequest = false,
							xsltTransformBefore = calculator_Request_XSLT_BEFORE
						}
				}
				
				local calculator_ko_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculator_ko" }
				}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_ko_route,
					-- it lacks the '<' beginning tag
					config = {
						xsltTransformBefore = [[
							xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							</xsl:stylesheet>
						]]
					}
				}
				
				local calculator_ko_verbose_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculator_ko_verbose" }
				}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_ko_verbose_route,
					-- it lacks the '<' beginning tag
					config = {
						VerboseRequest = true,
						xsltTransformBefore = [[
							xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							</xsl:stylesheet>
						]]
					}	
				}

				local calculator_local_req_termination_route = blue_print.routes:insert{
					paths = { "/local_calculator_req_termination" }
				}
				blue_print.plugins:insert {
					name = "request-termination",
					route = calculator_local_req_termination_route,
					config = {
						status_code = 200,
						content_type = "text/xml; charset=utf-8",
						body = calculator_Response
					}	
				}
				local calculator_local_service = blue_print.services:insert({
					protocol = "http",
					host = "localhost",
					port = 9000,
					path = "/local_calculator_req_termination",
				})

				local calculator_route_local = blue_print.routes:insert{
					service = calculator_local_service,
					paths = { "/x_local_calculator" }
				}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_route_local,
					config = {
						VerboseRequest = true,
						xsltTransformBefore = calculator_Request_XSLT_BEFORE
					}
			  }
				
				local calculator_basic_auth_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculator_basic_auth" }
					}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_basic_auth_route,
					config = {
						VerboseRequest = true,
						xsltTransformBefore = calculator_Request_XSLT_BEFORE
					}
				}
				blue_print.plugins:insert {
					name = "basic-auth",
					route = calculator_basic_auth_route,
					config = {
					}	
				}
				
				local calculator_invalid_host_service = blue_print.services:insert({
					protocol = "http",
					host = "127.0.0.2",
					port = 80,
					path = "/calculator.asmx",
				})			
				local calculator_invalid_host_route = blue_print.routes:insert{
					service = calculator_invalid_host_service,
					paths = { "/calculator_invalid_host" }
					}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_invalid_host_route,
					config = {
						VerboseRequest = true,
						xsltTransformBefore = calculator_Request_XSLT_BEFORE
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
						VerboseRequest = true,
						xsltTransformBefore = calculator_Request_XSLT_BEFORE,
						xsdApiSchema = calculator_Request_XSD_VALIDATION
					}
				}

				local calculator_xsd_invalid_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculatorXSD_invalid" }
					}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_xsd_invalid_route,
					config = {
						VerboseRequest = false,
						xsltTransformBefore = calculator_Request_XSLT_BEFORE,
						xsdApiSchema = calculator_Request_XSD_VALIDATION_invalid
					}
				}

				local calculator_xsd_invalid_verbose_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculatorXSD_invalid_verbose" }
					}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_xsd_invalid_verbose_route,
					config = {
						VerboseRequest = true,
						xsltTransformBefore = calculator_Request_XSLT_BEFORE,
						xsdApiSchema = calculator_Request_XSD_VALIDATION_invalid
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
						xsltTransformBefore = calculator_Request_XSLT_BEFORE,
						xsdApiSchema = calculator_Request_XSD_VALIDATION,
						xsltTransformAfter = calculator_Request_XSLT_AFTER
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
						xsltTransformBefore = calculator_Request_XSLT_BEFORE,
						xsdApiSchema = calculator_Request_XSD_VALIDATION,
						xsltTransformAfter = calculator_Request_XSLT_AFTER_invalid
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
						xsltTransformBefore = calculator_Request_XSLT_BEFORE,
						xsdApiSchema = calculator_Request_XSD_VALIDATION,
						xsltTransformAfter = calculator_Request_XSLT_AFTER_invalid
					}
				}

				local upstream_ecs_syr_edu = blue_print.upstreams:insert()
				blue_print.targets:insert({
					upstream = upstream_ecs_syr_edu,
					target = "ecs.syr.edu:443",
				})

				local calculatorRoutingByXPath_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculatorRoutingByXPath_ok" }
					}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculatorRoutingByXPath_route,
					config = {
						VerboseRequest = false,
						xsltTransformBefore = calculator_Request_XSLT_BEFORE,
						xsdApiSchema = calculator_Request_XSD_VALIDATION,
						xsltTransformAfter = calculator_Request_XSLT_AFTER_ROUTING_BY_XPATH,
						RouteToPath = "https://" .. upstream_ecs_syr_edu.name .. "/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx?op=Add",
						RouteXPath = "/soap:Envelope/soap:Body/*[local-name() = 'add']/*[local-name() = 'a']",
						RouteXPathCondition = "5",
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
			it("1|XSLT (BEFORE XSD) - Valid transformation", function()

				-- invoke a test request
				local r = client:post("/calculator", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})

				-- validate that the request succeeded: response status 200, Content-Type and right math
				local body = assert.response(r).has.status(200)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches('<AddResult>13</AddResult>', body)
			end)

			it("1|XSLT (BEFORE XSD) - Invalid XSLT input", function()

				-- invoke a test request
				local r = client:post("/calculator_ko", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})

				-- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
				local body = assert.response(r).has.status(500)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSLT_BEFORE_Failed, body)
			end)

			it("1|XSLT (BEFORE XSD) - Invalid XSLT with Verbose", function()

				-- invoke a test request
				local r = client:post("/calculator_ko_verbose", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})

				-- validate that the request failed: response status 500, Content-Type and Error message 'XSLT transformation failed'
				local body = assert.response(r).has.status(500)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose, body)
			end)

			it("1|XSLT (BEFORE XSD) - Valid transformation with 'request-termination' plugin (200)", function()

				-- invoke a test request
				local r = client:post("/x_local_calculator", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})
				
				-- validate that the request succeeded: response status 200, Content-Type and right math
				local body = assert.response(r).has.status(200)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches('<AddResult>13</AddResult>', body)
			end)

			it("1|XSLT (BEFORE XSD) - Valid transformation with 'basic_auth' plugin (401) with Verbose", function()

				-- invoke a test request
				local r = client:post("/calculator_basic_auth", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})
				
				-- validate that the request succeeded: response status 401, Content-Type and right Match
				local body = assert.response(r).has.status(401)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSLT_BEFORE_Failed_401_Error_Verbose, body)
			end)

			it("1|XSLT (BEFORE XSD) - Invalid Hostname service (502) with Verbose ", function()

				-- invoke a test request
				local r = client:post("/calculator_invalid_host", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})
				
				-- validate that the request succeeded: response status 502, Content-Type and right match
				local body = assert.response(r).has.status(502)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSLT_BEFORE_Failed_502_Error_Verbose, body)
			end)

			it("1+2|XSD Validation - Ok", function()

				-- invoke a test request
				local r = client:post("/calculatorXSD_ok", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})

				-- validate that the request succeeded: response status 200, Content-Type and right math
				local body = assert.response(r).has.status(200)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches('<AddResult>13</AddResult>', body)
			end)

			it("1+2|XSD Validation - Invalid XSD input", function()

				-- invoke a test request
				local r = client:post("/calculatorXSD_invalid", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})

				-- validate that the request succeeded: response status 500, Content-Type and right match
				local body = assert.response(r).has.status(500)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSD_VALIDATION_Failed, body)
			end)

			it("1+2|XSD Validation - Invalid XSD input with verbose", function()

				-- invoke a test request
				local r = client:post("/calculatorXSD_invalid_verbose", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})

				-- validate that the request succeeded: response status 500, Content-Type and right match
				local body = assert.response(r).has.status(500)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSD_VALIDATION_Failed_verbose, body)
			end)

			it("1+2+3|XSLT (AFTER XSD) - Ok", function()

				-- invoke a test request
				local r = client:post("/calculatorXSLT_afterXSD_ok", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Subtract_Request,
				})

				-- validate that the request succeeded: response status 200, Content-Type and right math
				local body = assert.response(r).has.status(200)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches('<AddResult>13</AddResult>', body)
			end)

			it("1+2+3|XSD Validation - Invalid XSD input", function()
			
				-- invoke a test request
				local r = client:post("/calculatorXSLT_afterXSD_invalid", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Subtract_Request,
				})

				-- validate that the request succeeded: response status 500, Content-Type and right math
				local body = assert.response(r).has.status(500)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSLT_AFTER_Failed, body)
			end)

			it("1+2+3|XSD Validation - Invalid XSD input with verbose", function()
			
				-- invoke a test request
				local r = client:post("/calculatorXSLT_afterXSD_invalid_verbose", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Subtract_Request,
				})

				-- validate that the request succeeded: response status 500, Content-Type and right match
				local body = assert.response(r).has.status(500)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSLT_AFTER_Failed_verbose, body)
			end)

			it("1+2+3+4|ROUTING BY XPATH - Ok", function()
			
				-- invoke a test request
				local r = client:post("/calculatorRoutingByXPath_ok", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Subtract_Request,
				})

				-- validate that the request succeeded: response status 500, Content-Type and right match
				local body = assert.response(r).has.status(500)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_Request_XSLT_AFTER_Failed_verbose, body)
			end)

  	end)

	end)
 ::continue::

end