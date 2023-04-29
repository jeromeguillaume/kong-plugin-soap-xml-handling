
local typedefs = require "kong.db.schema.typedefs"
local xmlgeneral   = require("kong.plugins.soap-xml-handling-lib.xmlgeneral")

return {
  name = "soap-xml-request-handling",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { xsdApiSchema = { type = "string", required = false }, },
          { xsdSoapSchema = { type = "string", required = false, default = xmlgeneral.XSD_SOAP }, },
          { xsltTransformAfter = { type = "string", required = false }, },
          { xsltTransformBefore = { type = "string", required = false }, },
          { RouteToPath = { type = "string", required = false }, },
          { RouteToUpstream = { type = "string", required = false }, },
          { RouteXPath = { type = "string", required = false }, },
          { RouteXPathCondition = { type = "string", required = false }, },
          { RouteXPathRegisterNs = { type = "array",  required = false, elements = {type = "string"}, default = {"soap,http://schemas.xmlsoap.org/soap/envelope/"}},},
        },
    }, },
  },
}