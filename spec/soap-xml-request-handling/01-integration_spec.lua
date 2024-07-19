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

local calculator_XSLT_Before_Failed = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema%-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSLT transformation failed %(before XSD validation%)</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

local calculator_XSLT_Before_Failed_XSLT_Error_Verbose = [[
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

local calculator_XSLT_Before_Failed_401_Error_Verbose = [[
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

local calculator_XSLT_Before_Failed_502_Error_Verbose = [[
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

local function calculator_Request_xsltTransformBefore(blue_print, calculator_route, debug)
	return blue_print.plugins:insert {
		name = PLUGIN_NAME,
		route = calculator_route,
		config = {
			VerboseRequest = debug,
			xsltTransformBefore = [[
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
		}
	}
end

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
    describe("libxml", function()
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
				local req_plugin = calculator_Request_xsltTransformBefore(blue_print, calculator_route, false)
				
				local calculator_route_ko = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculator_ko" }
				}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_route_ko,
					-- it lacks the '<' beginning tag
					config = {
						xsltTransformBefore = [[
							xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							</xsl:stylesheet>
						]]
					}
				}
				
				local calculator_route_ko_verbose = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculator_ko_verbose" }
				}
				blue_print.plugins:insert {
					name = PLUGIN_NAME,
					route = calculator_route_ko_verbose,
					-- it lacks the '<' beginning tag
					config = {
						VerboseRequest = true,
						xsltTransformBefore = [[
							xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							</xsl:stylesheet>
						]]
					}	
				}

				local calculator_route_local_req_termination = blue_print.routes:insert{
					paths = { "/local_calculator_req_termination" }
				}
				blue_print.plugins:insert {
					name = "request-termination",
					route = calculator_route_local_req_termination,
					config = {
						status_code = 200,
						content_type = "text/xml; charset=utf-8",
						body = calculator_Response
					}	
				}
				local calculator_service_local = blue_print.services:insert({
					protocol = "http",
					host = "localhost",
					port = 9000,
					path = "/local_calculator_req_termination",
				})

				local calculator_route_local = blue_print.routes:insert{
					service = calculator_service_local,
					paths = { "/x_local_calculator" }
				}
				local req_plugin = calculator_Request_xsltTransformBefore(blue_print, calculator_route_local)
				
				local calculator_basic_auth_route = blue_print.routes:insert{
					service = calculator_service,
					paths = { "/calculator_basic_auth" }
					}
				local req_plugin = calculator_Request_xsltTransformBefore(blue_print, calculator_basic_auth_route, true)
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
			local req_plugin = calculator_Request_xsltTransformBefore(blue_print, calculator_invalid_host_route, true)


				-- start kong
				assert(helpers.start_kong({
					-- use the custom test template to create a local mock server
					nginx_conf = "spec/fixtures/custom_nginx.template",
					-- make sure our plugin gets loaded
					plugins = "bundled," .. PLUGIN_NAME
				}))
				

    	end)
			it("XSLT (Before XSD) - Valid transformation", function()

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

			it("XSLT (Before XSD) - Invalid XSLT", function()

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
				assert.matches(calculator_XSLT_Before_Failed, body)
			end)

			it("XSLT (Before XSD) - Invalid XSLT with Verbose", function()

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
				assert.matches(calculator_XSLT_Before_Failed_XSLT_Error_Verbose, body)
			end)

			it("XSLT (Before XSD) - Valid transformation with 'request-termination' plugin (200)", function()

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

			it("XSLT (Before XSD) - Valid transformation with 'basic_auth' plugin (401) with Verbose", function()

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
				assert.matches(calculator_XSLT_Before_Failed_401_Error_Verbose, body)
			end)

			it("XSLT (Before XSD) - Invalid Hostname service (502) with Verbose ", function()

				-- invoke a test request
				local r = client:post("/calculator_invalid_host", {
					headers = {
						["Content-Type"] = "text/xml; charset=utf-8",
					},
					body = calculator_Request,
				})
				
				-- validate that the request succeeded: response status 502, Content-Type and right Match
				local body = assert.response(r).has.status(502)
				local content_type = assert.response(r).has.header("Content-Type")
				assert.equal("text/xml; charset=utf-8", content_type)
				assert.matches(calculator_XSLT_Before_Failed_502_Error_Verbose, body)
			end)

  	end)

	end)
 ::continue::

end