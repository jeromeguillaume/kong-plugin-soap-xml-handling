-- Notes:
-- Some characters, called magic characters, have special meanings when used in a pattern. The magic characters are
-- ( ) . % + - * ? [ ^ $

local helpers           = require "spec.helpers"
local request_common    = require "spec.common.request"
local response_common   = require "spec.common.response"
local soapAction_common = require "spec.common.soapAction"

local saxon_common = {}

saxon_common.calculator_Request= {
  operation = "Add",
  intA = 50,
  intB = 10
}

saxon_common.calculator_Request_XSLT_BEFORE = [[
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <xsl:variable name="json_var" select="fn:json-to-xml(.)"/>    
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <xsl:variable name="operation" select="$json_var/map/string[@key='operation']"/>    
        <xsl:element name="{$operation}" xmlns="http://tempuri.org/">
          <intA>
            <xsl:value-of select="$json_var/map/number[@key='intA']"/>
          </intA>
          <intB>
            <xsl:value-of select="$json_var/map/number[@key='intB']"/>
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
  message_verbose = 'Invalid XSLT definition. Error on line 1 column 1. SXXP0003   Error reported by XML parser: Content is not allowed in prolog.'
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
  message_verbose = 'Invalid XSLT definition. Error on line 1 column 1. SXXP0003   Error reported by XML parser: Content is not allowed in prolog.',
  backend_http_code = 200
}

saxon_common.error_message_Saxon_Library_not_Found_val_verbose = {
  message = 'Request - XSLT transformation failed (before XSD validation)',
  message_verbose = "Unable to load the XSLT library shared object or its dependency. Please check 'LD_LIBRARY_PATH' env variable and the presence of libraries"
}

saxon_common.error_message_Request_XSLT_transfo_before_XSD_Invalid_JSON_verbose = {
  message = 'Request - XSLT transformation failed (before XSD validation)',
  message_verbose = 'Invalid JSON input on line 1: Unescaped control character (xa)'
}

saxon_common.error_message_Response_XSD_validation_400_No_Content_Type_error_from_Upstream_verbose = {
  message = 'Response - XSD validation failed',
  message_verbose = "Invalid XML input. Error code: 4, Line: 1, Message: Start tag expected, '<' not found",
  backend_http_code = 400
}

saxon_common.error_XML_message_Request_XSLT_transfo_before_XSD_val_verbose = [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Request %- XSLT transformation failed %(before XSD validation%)</faultstring>
      <detail>
        <errorMessage>Invalid XSLT definition. Error on line 1 column 1. SXXP0003   Error reported by XML parser: Content is not allowed in prolog.</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

saxon_common.calculator_Request_XSLT_BEFORE_Failed_XSLT_Error_Verbose = [[
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

saxon_common.httpbin_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<root>
  <companyName>KongHQ</companyName>
  <city>SAN FRANCISCO</city>
  <state>CA</state>
  <country>USA</country>
  <offices>
    <site>San Francisco (HQ)</site>
    <site>Chicago</site>
    <site>London</site>
    <site>Bangalore</site>
    <site>Singapore</site>
    <site>Shangai</site>
    <site>Japan</site>
  </offices>
  <products>
    <product name="Kong konnect">
    	<version>2024</version>
    	<saas>true</saas>
    </product>
    <product name="Kong AI Gateway">
    	<version>3.8</version>
    	<saas>false</saas>
    </product>
    <product name="Kong Ingress Controller">
    	<version>3.3</version>
    	<saas>false</saas>
    </product>
    <product name="Kong Mesh">
    	<version>2.8</version>
    	<saas>false</saas>
    </product>
    <product name="Insomnia">
    	<version>10.0</version>
    	<saas>false</saas>
    </product>
  </products>
</root>]]

saxon_common.httpbin_Response_Ok= [[
<%?xml version="1.0" encoding="UTF%-8"%?>
<root>
   <companyName>KongHQ</companyName>
   <city>SAN FRANCISCO</city>
   <state>CA</state>
   <country>USA</country>
   <offices>
      <site>San Francisco %(HQ%)</site>
      <site>Chicago</site>
      <site>London</site>
      <site>Bangalore</site>
      <site>Singapore</site>
      <site>Shangai</site>
      <site>Japan</site>
   </offices>
   <products>
      <product name="Kong konnect">
         <version>2024</version>
         <saas>true</saas>
      </product>
      <product name="Kong AI Gateway">
         <version>3.8</version>
         <saas>false</saas>
      </product>
      <product name="Kong Ingress Controller">
         <version>3.3</version>
         <saas>false</saas>
      </product>
      <product name="Kong Mesh">
         <version>2.8</version>
         <saas>false</saas>
      </product>
      <product name="Insomnia">
         <version>10</version>
         <saas>false</saas>
      </product>
   </products>
</root>]]

saxon_common.httpbin_Request_XSD_VALIDATION=[[
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="root" type="rootType"/>
  <xs:complexType name="officesType">
    <xs:sequence>
      <xs:element name="site" maxOccurs="unbounded" minOccurs="0">
      </xs:element>
    </xs:sequence>
  </xs:complexType>
  <xs:complexType name="productType">
    <xs:sequence>
      <xs:element name="version" type="xs:float"/>
      <xs:element name="saas" type="xs:boolean" />
    </xs:sequence>
    <xs:attribute type="xs:string" name="name" use="optional"/>
  </xs:complexType>
  <xs:complexType name="productsType">
    <xs:sequence>
      <xs:element type="productType" name="product" maxOccurs="unbounded" minOccurs="0"/>
    </xs:sequence>
  </xs:complexType>
  <xs:complexType name="rootType">
    <xs:sequence>
      <xs:element type="xs:string" name="companyName"/>
      <xs:element type="xs:string" name="city"/>
      <xs:element type="xs:string" name="state"/>
      <xs:element type="xs:string" name="country"/>
      <xs:element type="officesType" name="offices" minOccurs="0"/>
      <xs:element type="productsType" name="products" minOccurs="0"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
]]

saxon_common.httpbin_Request_XSLT_AFTER = [[
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2005/xpath-functions" xmlns:fn="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:mode on-no-match="shallow-skip"/>
  <xsl:output method="text"/>
  
  <xsl:template match="/root">
    <xsl:variable name="json-result">
      <map xmlns="http://www.w3.org/2005/xpath-functions">
        <string key="companyName"><xsl:value-of select="companyName"/></string>
        <string key="city"><xsl:value-of select="city"/></string>
        <string key="state"><xsl:value-of select="state"/></string>
        <string key="country"><xsl:value-of select="country"/></string>
      <map key="offices">
        <array key="site">
          <xsl:for-each select="offices/site">
            <string><xsl:value-of select="."/></string>
          </xsl:for-each>
        </array>
        </map>
        <array key="products">
          <xsl:for-each select="products/product">
            <map>
              <xsl:element name="map">
              <xsl:attribute name="key"><xsl:value-of select="@name"/></xsl:attribute>
                <number key="version"><xsl:value-of select="./version"/></number>
                <boolean key="saas"><xsl:value-of select="./saas"/></boolean>
              </xsl:element>
            </map>
          </xsl:for-each>
        </array>
      </map>
    </xsl:variable>
    <xsl:value-of select="fn:xml-to-json($json-result)"/>
  </xsl:template>
</xsl:stylesheet>
]]

saxon_common.httpbin_Response_XSLT_BEFORE = [[
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <xsl:variable name="json_var" select="fn:json-to-xml(.)"/>
    <root>
      <companyName><xsl:value-of select="$json_var/map/map/string[@key='companyName']"/></companyName>
      <city><xsl:value-of select="$json_var/map/map/string[@key='city']"/></city>
      <state><xsl:value-of select="$json_var/map/map/string[@key='state']"/></state>
      <country><xsl:value-of select="$json_var/map/map/string[@key='country']"/></country>
      <offices>
        <xsl:for-each select="$json_var/map/map/map[@key='offices']/array[@key='site']/string">
          <site><xsl:value-of select="."/></site>
        </xsl:for-each>
      </offices>
      <products>
        <xsl:for-each select="$json_var/map/map/array[@key='products']/map/map">
          <product>
            <xsl:attribute name="name"><xsl:value-of select="@key"/></xsl:attribute>
              <version><xsl:value-of select="number[@key='version']"/></version>
              <saas><xsl:value-of select="boolean[@key='saas']"/></saas>
          </product>
        </xsl:for-each>
      </products>
    </root>
  </xsl:template>
</xsl:stylesheet>
]]

---------------------------------------------------------------------------------------------------
-- SOAP/XML REQUEST/RESPONSE plugin with Saxon: configure the Kong entities (Service/Route/Plugin)
---------------------------------------------------------------------------------------------------
function saxon_common.lazy_setup (PLUGIN_NAME, blue_print, xsltLibrary)

  local pluginRequest  = "soap-xml-request-handling"
  local pluginResponse = "soap-xml-response-handling"
  
	local calculator_service = blue_print.services:insert({
    protocol = "http",
    host = "ws.soap1.calculator",
    port = 8080,
    path = "/ws",
  })

	local httpbin_service = blue_print.services:insert({
		protocol = "http",
		host = "httpbin",
		port = 8080,
		path = "/anything",
    name = "httpbin"
	})

  local calculator_JSON_2_XML_Transformation_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_JSON_2_XML_Transformation_ok" }
	  }
	blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_JSON_2_XML_Transformation_ok_route,
    config = {
      VerboseRequest = true,
      xsltLibrary = xsltLibrary,
      xsdApiSchema = soapAction_common.calculatorWSDL11_soap_soap12,
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }
  blue_print.plugins:insert { 
    name = pluginResponse,
    route = calculator_JSON_2_XML_Transformation_ok_route,
    config = {
      VerboseResponse = true,
      xsltLibrary = xsltLibrary,
      xsdApiSchema = soapAction_common.calculatorWSDL11_soap_soap12,
      xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
    }
  }
  
  local httpbin_XML_2_JSON_Transformation_ok_route = blue_print.routes:insert{
		service = httpbin_service,
		paths = { "/calculator_XML_2_JSON_Transformation_ok" }
	}
	blue_print.plugins:insert {
    name = pluginRequest,
    route = httpbin_XML_2_JSON_Transformation_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsdSoapSchema =  saxon_common.httpbin_Request_XSD_VALIDATION,
      xsltTransformAfter = saxon_common.httpbin_Request_XSLT_AFTER
    }
  }
  blue_print.plugins:insert { 
    name = pluginResponse,
    route = httpbin_XML_2_JSON_Transformation_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsdSoapSchema = saxon_common.httpbin_Request_XSD_VALIDATION,
      xsltTransformBefore = saxon_common.httpbin_Response_XSLT_BEFORE
    }
  }

  local calculator_REQ_XSLT_beforeXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_REQ_XLST_with_xslt_Params_ok" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_REQ_XSLT_beforeXSD_with_xslt_Params_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE_with_params,
      xsltParams = {
        ["intA_param"] = "1111",
        ["intB_param"] = "3333",
      },
    }
  }

  local calculator_REQ_XSLT_afterXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_REQ_XLST_afterXSD_with_xslt_Params_ok" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_REQ_XSLT_afterXSD_with_xslt_Params_ok_route,
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

  local calculator_RES_XSLT_beforeXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_RES_XLST_with_xslt_Params_ok" }
	}
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_RES_XSLT_beforeXSD_with_xslt_Params_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_with_params,
      xsltParams = {
        ["result_tag"] = "kongResultFromParam",
      },
    }
  }

  local calculator_RES_XSLT_before_afterXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_RES_XLST_afterXSD_with_xslt_Params_ok" }
	}
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_RES_XSLT_before_afterXSD_with_xslt_Params_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_with_params,
      xsltTransformAfter = response_common.calculator_Response_XSLT_AFTER_with_params,
      xsltParams = {
        ["result_tag"] = "kongResultFromParam",
        ["result_tag_after_xsd"] = "kongResultFromParamAfterXSD"
      },
    }
  }

  
  local calculator_REQ_RES_XSLT_beforeXSD_with_xslt_Params_ok_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_REQ_RES_XLST_with_xslt_Params_ok" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_REQ_RES_XSLT_beforeXSD_with_xslt_Params_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = request_common.calculator_Request_XSLT_BEFORE_with_params,
      xsltParams = {
        ["intA_param"] = "1111",
        ["intB_param"] = "3333",
      },
    }
  }
  blue_print.plugins:insert {
    name = pluginResponse,
    route = calculator_REQ_RES_XSLT_beforeXSD_with_xslt_Params_ok_route,
    config = {
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = response_common.calculator_Response_XSLT_BEFORE_with_params,
      xsltParams = {
        ["result_tag"] = "kongResultFromParam",
      },
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
      -- it lacks the '<' beginning tag
      xsltTransformBefore = [[xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
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

  local calculator_RES_XSLT_afterXSD_invalid_XSLT_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/calculator_RES_XSLT_afterXSD_invalid_XSLT" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_RES_XSLT_afterXSD_invalid_XSLT_route,
    config = {
      xsltLibrary = xsltLibrary,
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
      xsltTransformAfter = [[xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				</xsl:stylesheet>
			]]
    }
  }
  local saxon_Library_not_found_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/saxon_Library_not_found" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = saxon_Library_not_found_route,
    config = {
      VerboseRequest = false,
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }

  local saxon_Library_not_found_verbose_route = blue_print.routes:insert{
		service = calculator_service,
		paths = { "/saxon_Library_not_found_verbose" }
	}
  blue_print.plugins:insert {
    name = pluginRequest,
    route = saxon_Library_not_found_verbose_route,
    config = {
      VerboseRequest = true,
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }

  local local_400_no_content_type_termination_route = blue_print.routes:insert{
		paths = { "/local_400_No_Content_Type" }
	}
	blue_print.plugins:insert {
		name = "request-termination",
		route = local_400_no_content_type_termination_route,
		config = {
			status_code = 400
		}	
	}

  local local_400_no_content_type_service = blue_print.services:insert({
		protocol = "http",
		host = "localhost",
		port = 9000,
		path = "/local_400_No_Content_Type",
	})

  local calculator_JSON_2_XML_Transformation_400_error_No_Content_Type_from_Upstream_ko_route = blue_print.routes:insert{
		service = local_400_no_content_type_service,
		paths = { "/calculator_JSON_2_XML_Transformation_400_error_No_Content_Type_from_Upstream_ko" }
	  }
	blue_print.plugins:insert {
    name = pluginRequest,
    route = calculator_JSON_2_XML_Transformation_400_error_No_Content_Type_from_Upstream_ko_route,
    config = {
      VerboseRequest = true,
      xsltLibrary = xsltLibrary,
      xsltTransformBefore = saxon_common.calculator_Request_XSLT_BEFORE
    }
  }
  blue_print.plugins:insert { 
    name = pluginResponse,
    route = calculator_JSON_2_XML_Transformation_400_error_No_Content_Type_from_Upstream_ko_route,
    config = {
      VerboseResponse = true,
      xsltLibrary = xsltLibrary,
      xsltTransformAfter = saxon_common.calculator_Response_XSLT_AFTER
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

function saxon_common._1_2_6_7_XML_2_JSON_Transformation_Ok (assert, client)
    -- invoke a test request
    local r = client:post("/calculator_XML_2_JSON_Transformation_ok", {
      headers = {
        ["Content-Type"] = "text/xml; charset=utf-8",
      },
      body = saxon_common.httpbin_Request,
    })
  
    -- validate that the request succeeded: response status 200, Content-Type and right match
    local body = assert.response(r).has.status(200)
    local content_type = assert.response(r).has.header("Content-Type")
    assert.matches("text/xml%;%s-charset=utf%-8", content_type)
    assert.matches(saxon_common.httpbin_Response_Ok, body)
end

function saxon_common._1_REQ_XSLT_BEFORE_XSD_with_xslt_Params_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_REQ_XLST_with_xslt_Params_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = request_common.calculator_Full_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.matches("text/xml%;%s-charset=utf%-8", content_type)
  assert.matches("<AddResult>4444</AddResult>", body)
end

function saxon_common._1_3_REQ_XSLT_AFTER_XSD_with_xslt_Params_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_REQ_XLST_afterXSD_with_xslt_Params_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = request_common.calculator_Full_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.matches("text/xml%;%s-charset=utf%-8", content_type)
  assert.matches("<AddResult>66666</AddResult>", body)
end

function saxon_common._5_RES_XSLT_BEFORE_XSD_with_xslt_Params_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_RES_XLST_with_xslt_Params_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = request_common.calculator_Full_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.matches("text/xml%;%s-charset=utf%-8", content_type)
  assert.matches("<kongResultFromParam>12</kongResultFromParam>", body)
end

function saxon_common._5_7_REQ_XSLT_AFTER_XSD_with_xslt_Params_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_RES_XLST_afterXSD_with_xslt_Params_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = request_common.calculator_Full_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.matches("text/xml%;%s-charset=utf%-8", content_type)
  assert.matches("<kongResultFromParamAfterXSD>12</kongResultFromParamAfterXSD>", body)
end

function saxon_common._1_5_RES_XSLT_BEFORE_XSD_with_xslt_Params_Ok (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_REQ_RES_XLST_with_xslt_Params_ok", {
    headers = {
      ["Content-Type"] = "text/xml; charset=utf-8",
    },
    body = request_common.calculator_Full_Request,
  })

  -- validate that the request succeeded: response status 200, Content-Type and right match
  local body = assert.response(r).has.status(200)
  local content_type = assert.response(r).has.header("Content-Type")
  assert.matches("text/xml%;%s-charset=utf%-8", content_type)
  assert.matches("<kongResultFromParam>4444</kongResultFromParam>", body)
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

function saxon_common._1_Saxon_Library_not_found (assert, client)
  -- invoke a test request
  local r = client:post("/saxon_Library_not_found", {
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
  assert.same (saxon_common.error_message_Request_XSLT_transfo_before_XSD_val, json)
end

function saxon_common._1_Saxon_Library_not_found_with_verbose (assert, client)
  -- invoke a test request
  local r = client:post("/saxon_Library_not_found_verbose", {
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
  assert.same (saxon_common.error_message_Saxon_Library_not_Found_val_verbose, json)
end

function saxon_common._1_REQ_XSLT_BEFORE_XSD_Invalid_JSON_request_with_verbose_ko (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_JSON_2_XML_Transformation_ok", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = '{\
    "intA": 50,\
    "intB": 10,\
    "operation": "Add\
      }',
    })

  -- validate that the request succeeded: response status 400, Content-Type and right match
	local body = assert.response(r).has.status(400)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Request_XSLT_transfo_before_XSD_Invalid_JSON_verbose, json)
end

function saxon_common._1_2_6_7_JSON_2_XML_Transformation_400_error_No_Content_Type_from_Upstream_Ko (assert, client)
  -- invoke a test request
  local r = client:post("/calculator_JSON_2_XML_Transformation_400_error_No_Content_Type_from_Upstream_ko", {
    headers = {
			["Content-Type"] = "application/json",
		},
    body = saxon_common.calculator_Request,
    })

  -- validate that the request succeeded: response status 500, Content-Type and right match
	local body = assert.response(r).has.status(500)
	local content_type = assert.response(r).has.header("Content-Type")
	assert.equal("application/json", content_type)
  local json = assert.response(r).has.jsonbody()
  assert.same (saxon_common.error_message_Response_XSD_validation_400_No_Content_Type_error_from_Upstream_verbose, json)
end



return saxon_common