
local typedefs = require "kong.db.schema.typedefs"
local XSD_SOAP = [[<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/" targetNamespace="http://schemas.xmlsoap.org/soap/envelope/" > <!-- Envelope, header and body --> <xs:element name="Envelope" type="tns:Envelope" /> <xs:complexType name="Envelope" ><xs:sequence><xs:element ref="tns:Header" minOccurs="0" /><xs:element ref="tns:Body" minOccurs="1" /><xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##other" processContents="lax" /></xs:complexType><xs:element name="Header" type="tns:Header" /><xs:complexType name="Header" ><xs:sequence><xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##other" processContents="lax" /></xs:complexType><xs:element name="Body" type="tns:Body" /><xs:complexType name="Body" ><xs:sequence><xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##any" processContents="lax" ><xs:annotation><xs:documentation>Prose in the spec does not specify that attributes are allowed on the Body element</xs:documentation></xs:annotation></xs:anyAttribute></xs:complexType><!-- Global Attributes.  The following attributes are intended to be usable via qualified attribute names on any complex type referencing them.  --><xs:attribute name="mustUnderstand" ><xs:simpleType><xs:restriction base='xs:boolean'><xs:pattern value='0|1' /></xs:restriction></xs:simpleType></xs:attribute><xs:attribute name="actor" type="xs:anyURI" /><xs:simpleType name="encodingStyle" ><xs:annotation><xs:documentation>'encodingStyle' indicates any canonicalization conventions followed in the contents of the containing element.  For example, the value 'http://schemas.xmlsoap.org/soap/encoding/' indicates the pattern described in SOAP specification</xs:documentation></xs:annotation><xs:list itemType="xs:anyURI" /></xs:simpleType><xs:attribute name="encodingStyle" type="tns:encodingStyle" /><xs:attributeGroup name="encodingStyle" ><xs:attribute ref="tns:encodingStyle" /></xs:attributeGroup><xs:element name="Fault" type="tns:Fault" /><xs:complexType name="Fault" final="extension" ><xs:annotation><xs:documentation>Fault reporting structure</xs:documentation></xs:annotation><xs:sequence><xs:element name="faultcode" type="xs:QName" /><xs:element name="faultstring" type="xs:string" /><xs:element name="faultactor" type="xs:anyURI" minOccurs="0" /><xs:element name="detail" type="tns:detail" minOccurs="0" /></xs:sequence></xs:complexType><xs:complexType name="detail"><xs:sequence><xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" /></xs:sequence><xs:anyAttribute namespace="##any" processContents="lax" /> </xs:complexType></xs:schema>]]

return {
  name = "soap-xml-request-handling",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { ExternalEntityLoader_Async = { type = "boolean", default = false, required = false }, },
          { ExternalEntityLoader_CacheTTL = { type = "integer", default = 3600, required = false }, },
          { ExternalEntityLoader_Timeout = { type = "integer", default = 1, required = false }, },
          { filePathPrefix = typedefs.path { required = false } },
          { RouteXPathRegisterNs = { type = "array",  required = false, 
              elements = {type = "string"}, 
                default = {"soap,http://schemas.xmlsoap.org/soap/envelope/"},
            },
          },
          { RouteXPathTargets = { type = "array", required = false,
              elements = { type = "record",
                required = true,
                fields = {
                  { URL = typedefs.url( { required = true} ) },
                  { XPath = {type = "string", required = true} },
                  { XPathCondition = {type = "string", required = true}}
                }
              }
            } 
          },          
          { SOAPAction_Header = {required = false, type = "string", default = "no",
            one_of = {
              "no",
              "yes_null_allowed",
              "yes",
            },
          },},
          { VerboseRequest = { type = "boolean", required = false }, },
          { xsdApiSchema = { type = "string", required = false }, },
          { xsdApiSchemaInclude = { type = "map", required = false, 
              keys = { type = "string", required = true },
              values = {type = "string", required = true},
          }},
          { xsdSoapSchema = { type = "string", required = false, default = XSD_SOAP }, },
          { xsdSoapSchemaInclude = { type = "map", required = false, 
            keys = { type = "string", required = true },
            values = {type = "string", required = true},
            }},
          { xsltLibrary = {required = true, type = "string", default = "libxslt",
            one_of = {
              "libxslt",
              "saxon",
            },
          },},
          { xsltTransformAfter = { type = "string", required = false }, },
          { xsltTransformBefore = { type = "string", required = false }, },
          { xsltParams = { type = "map", required = false, default = {},
            keys = { type = "string", required = true },
            values = {type = "string", required = true, referenceable = true },
          }},
        },
    }, },
  },

  entity_checks = {
    { custom_entity_check = {
      field_sources = { "config" },
      fn = function(entity)
        local config = entity.config

        -- Check that the Register Namespace is valid
        local XPathRegisterNs = config.RouteXPathRegisterNs
        for i = 1, #XPathRegisterNs do
          local prefix, uri
          local j = config.RouteXPathRegisterNs[i]:find(',', 1)
          if j then
            prefix  = string.sub(XPathRegisterNs[i], 1, j - 1)
            uri     = string.sub(XPathRegisterNs[i], j + 1, #XPathRegisterNs[i])
          end
          if (uri == nil or uri == '' or uri:find('%s')) or 
            (prefix == nil or prefix == '' or prefix:find('%s')) then
            return nil, "config.RouteXPathRegisterNs: invalid NameSpace or URI. The syntax is 'ns,uri' without space"
          end
        end

        -- Check that Asynchronous External Entity Loader and the Schema inclusion are not simutaneously enabled
        if ((config.xsdSoapSchemaInclude and type(config.xsdSoapSchemaInclude) == 'table' and next(config.xsdSoapSchemaInclude)) or 
            (config.xsdApiSchemaInclude  and type(config.xsdApiSchemaInclude ) == 'table' and next(config.xsdApiSchemaInclude))) and
            config.ExternalEntityLoader_Async then
          return nil, "config.xsdSoapSchemaInclude or config.xsdApiSchemaInclude cannot be used with config.ExternalEntityLoader_Async"
        end

        -- Check that if the SOAP Schema inclusion is defined, the 'xsdApiSchema' is defined too
        if (config.xsdSoapSchemaInclude and type(config.xsdSoapSchemaInclude) == 'table' and next(config.xsdSoapSchemaInclude)) and  
            type(config.xsdSoapSchema) == 'userdata' then
          return nil, "config.xsdSoapSchema must be defined if config.xsdSoapSchemaInclude is defined"
        end

        -- Check that if the API Schema inclusion is defined, the 'xsdSoapSchema' is defined too
        if (config.xsdApiSchemaInclude and type(config.xsdApiSchemaInclude) == 'table' and next(config.xsdApiSchemaInclude)) and  
            type(config.xsdApiSchema) == 'userdata' then
          return nil, "config.xsdApiSchema must be defined if config.xsdApiSchemaInclude is defined"
        end

        -- Check that if 'SOAPAction_Header' is enabled, the 'xsdApiSchema' is defined
        if config.SOAPAction_Header ~= "no" and type(config.xsdApiSchema) == 'userdata' then
          return nil, "config.xsdApiSchema must be defined if config.SOAPAction_Header is enabled"
        end

        return true
      end
    }},
  },
}