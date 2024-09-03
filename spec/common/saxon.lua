local helpers = require "spec.helpers"
local split   = require("kong.tools.string").split
local saxon_common = {}

saxon_common.calculator_Request= {
  operation = "Add",
  intA = 50,
  intB = 10
}

saxon_common.responsePlugin_config_ok = {
    VerboseResponse = false,
    xsltLibrary = xsltLibrary,
    xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
}

saxon_common.calculator_Request_XSLT_BEFORE = [[
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template name="main">
    <xsl:param name="request-body" required="yes"/>
    <xsl:variable name="json" select="fn:json-to-xml($request-body)"/>    
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <xsl:variable name="operation" select="$json/map/string[@key='operation']"/>    
        <xsl:element name="{$operation}" xmlns="http://tempuri.org/">
          <intA>
            <xsl:value-of select="$json/map/number[@key='intA']"/>
          </intA>
          <intB>
            <xsl:value-of select="$json/map/number[@key='intB']"/>
          </intB>              
        </xsl:element>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
</xsl:stylesheet>
]]

saxon_common.calculator_Response_XSLT_AFTER = [[
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2005/xpath-functions" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xpath-default-namespace="http://tempuri.org/" exclude-result-prefixes="fn">
  <xsl:mode on-no-match="shallow-skip"/>
  <xsl:output method="text"/>
  
  <xsl:template match="/soap:Envelope/soap:Body/*[ends-with(name(), 'Response')]/*[ends-with(name(), 'Result')]">
    <xsl:variable name="json-result">
      <map xmlns="http://www.w3.org/2005/xpath-functions">
        <number key="result">
          <xsl:value-of select="text()"/>
        </number>
      </map>
    </xsl:variable>
    <xsl:value-of select="fn:xml-to-json($json-result)"/>
  </xsl:template>
</xsl:stylesheet>
]]

saxon_common.calculator_JSON_2_XML_Transformation_ok = { 
  result = 60 
}

saxon_common.error_message_Request_XSLT_transfo_before_XSD_val = {
  message = 'Request - XSLT transformation failed (before XSD validation)'
}

saxon_common.error_message_Request_XSLT_transfo_before_XSD_val_verbose = {
  message = 'Request - XSLT transformation failed (before XSD validation)',
  message_verbose = 'SXXP0003:  Error reported by XML parser: Content is not allowed in prolog.'
}

saxon_common.error_message_Request_XSLT_transfo_before_XSD_Template_val_verbose = {
  message = 'Request - XSLT transformation failed (before XSD validation)',
  message_verbose = 'Template XXmainXX does not exist'
}

saxon_common.error_message_Response_XSLT_transfo_after_XSD_val = {
  message = 'Response - XSLT transformation failed (after XSD validation)'
}

saxon_common.error_message_Response_XSLT_transfo_after_XSD_val_verbose = {
  message = 'Response - XSLT transformation failed (after XSD validation)',
  message_verbose = 'SXXP0003:  Error reported by XML parser: Content is not allowed in prolog. SOAP/XML Web Service - HTTP code: 200'
}


---------------------------------------------------------------------------------------------------
-- SOAP/XML REQUEST/RESPONSE plugin with Saxon: configure the Kong entities (Service/Route/Plugin)
---------------------------------------------------------------------------------------------------
function saxon_common.lazy_setup (PLUGIN_NAME, blue_print, xsltLibrary)

  local plugins = split(PLUGIN_NAME, ',')
  local pluginRequest  = plugins[1]
  local pluginResponse = plugins[2]

	local calculator_service = blue_print.services:insert({
		protocol = "http",
		host = "www.dneonline.com",
		port = 80,
		path = "/calculator.asmx",
	})

  local calculator_JSON_2_XML_Transformation_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_JSON_2_XML_Transformation_ok" }
	  }
	blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_JSON_2_XML_Transformation_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltSaxonTemplate = 'main',
      xsltSaxonTemplateParam = 'request-body',
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }
  blue_print.plugins:insert { 
    name = pluginResponse,
    route = calculator_JSON_2_XML_Transformation_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
    }
  }

  local calculator_REQ_XSLT_beforeXSD_invalid_XSLT_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_REQ_XSLT_beforeXSD_invalid_XSLT" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_REQ_XSLT_beforeXSD_invalid_XSLT_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltSaxonTemplate = 'main',
      xsltSaxonTemplateParam = 'request-body',
      -- it lacks the '<' beginning tag
      xsltTransformBefore = [[
				xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				</xsl:stylesheet>
			]]
    }
  }
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_REQ_XSLT_beforeXSD_invalid_XSLT_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
    }
  }

  local calculator_REQ_XSLT_beforeXSD_invalid_XSLT_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_REQ_XSLT_beforeXSD_invalid_XSLT_verbose" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_REQ_XSLT_beforeXSD_invalid_XSLT_verbose_route,
    config = {
      VerboseRequest = true,
      xsltLibrary = xsltLibrary,
      xsltSaxonTemplate = 'main',
      xsltSaxonTemplateParam = 'request-body',
      -- it lacks the '<' beginning tag
      xsltTransformBefore = [[
				xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				</xsl:stylesheet>
			]]
    }
  }
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_REQ_XSLT_beforeXSD_invalid_XSLT_verbose_route,
    config = {
      VerboseResponse = true,
      xsltLibrary = xsltLibrary,
      xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
    }
  }
  
  local calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltSaxonTemplate = 'XXmainXX',
      xsltSaxonTemplateParam = 'request-body',
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
    }
  }

  local calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_verbose" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_verbose_route,
    config = {
      VerboseRequest = true,
      xsltLibrary = xsltLibrary,
      xsltSaxonTemplate = 'XXmainXX',
      xsltSaxonTemplateParam = 'request-body',
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_verbose_route,
    config = {
      VerboseResponse = true,
      xsltLibrary = xsltLibrary,
      xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
    }
  }


  local calculator_RES_XSLT_afterXSD_invalid_XSLT_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_RES_XSLT_afterXSD_invalid_XSLT" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_RES_XSLT_afterXSD_invalid_XSLT_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltSaxonTemplate = 'main',
      xsltSaxonTemplateParam = 'request-body',
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_RES_XSLT_afterXSD_invalid_XSLT_route,
    config = {
      xsltLibrary = xsltLibrary,
      -- it lacks the '<' beginning tag
      xsltTransformAfter = [[
				xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				</xsl:stylesheet>
			]]
    }
  }

  local calculator_RES_XSLT_afterXSD_invalid_XSLT_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_RES_XSLT_afterXSD_invalid_XSLT_verbose" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_RES_XSLT_afterXSD_invalid_XSLT_verbose_route,
    config = {
      VerboseRequest = true,
      xsltLibrary = xsltLibrary,
      xsltSaxonTemplate = 'main',
      xsltSaxonTemplateParam = 'request-body',
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_RES_XSLT_afterXSD_invalid_XSLT_verbose_route,
    config = {
      VerboseResponse = true,
      xsltLibrary = xsltLibrary,
      -- it lacks the '<' beginning tag
      xsltTransformAfter = [[
				xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				</xsl:stylesheet>
			]]
    }
  }

end

------------------------------------------------------------
-- Saxon REQUEST/RESPONSE plugins with Saxon: Execute tests
------------------------------------------------------------
function saxon_common._1_2_6_7_JSON_2_XML_Transformation_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_JSON_2_XML_Transformation_ok", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = saxon_common.calculator_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
	local body = assert.response(r).has.status(200)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.calculator_JSON_2_XML_Transformation_ok, json)
end

function saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_XSLT_input (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_REQ_XSLT_beforeXSD_invalid_XSLT", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = saxon_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Request_XSLT_transfo_before_XSD_val, json)
end

function saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_XSLT_input_with_verbose (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_REQ_XSLT_beforeXSD_invalid_XSLT_verbose", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = saxon_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Request_XSLT_transfo_before_XSD_val_verbose, json)
end

function saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_Saxon_template_input (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = saxon_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Request_XSLT_transfo_before_XSD_val, json)
end

function saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_Saxon_template_input_with_verbose (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_REQ_XSLT_beforeXSD_invalid_Saxon_template_verbose", {
    headers = {
      ["Content-Type"] = "application/json",
    },
    body = saxon_common.calculator_Request,
  })

  -- validate that the request failed: response status 500, Content-Type and right match
  local body = assert.response(r).has.status(500)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Request_XSLT_transfo_before_XSD_Template_val_verbose, json)
end

function saxon_common._1_2_6_7_RES_XSLT_AFTER_XSD_Invalid_XSLT_input (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_RES_XSLT_afterXSD_invalid_XSLT", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = saxon_common.calculator_Request,
  })

  -- validate that the response failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Response_XSLT_transfo_after_XSD_val, json)
end

function saxon_common._1_2_6_7_RES_XSLT_AFTER_XSD_Invalid_XSLT_input_with_verbose (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_RES_XSLT_afterXSD_invalid_XSLT_verbose", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = saxon_common.calculator_Request,
  })

  -- validate that the response failed: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Response_XSLT_transfo_after_XSD_val_verbose, json)
end
return saxon_common