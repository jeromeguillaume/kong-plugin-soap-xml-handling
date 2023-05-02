
local typedefs      = require "kong.db.schema.typedefs"
local xmldefinition = require("kong.plugins.soap-xml-handling-lib.xmldefinition")

return {
  name = "soap-xml-request-handling",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { RouteToPath = { type = "string", required = false }, },
          { RouteToUpstream = { type = "string", required = false }, },
          { RouteXPath = { type = "string", required = false }, },
          { RouteXPathCondition = { type = "string", required = false }, },
          { RouteXPathRegisterNs = { type = "array",  required = false, elements = {type = "string"}, default = {"soap,http://schemas.xmlsoap.org/soap/envelope/"}},},
          { VerboseRequest = { type = "boolean", required = false }, },
          { xsdApiSchema = { type = "string", required = false }, },
          { xsdSoapSchema = { type = "string", required = false, default = xmldefinition.XSD_SOAP }, },
          { xsltTransformAfter = { type = "string", required = false }, },
          { xsltTransformBefore = { type = "string", required = false }, },
        },
    }, },
  },
}