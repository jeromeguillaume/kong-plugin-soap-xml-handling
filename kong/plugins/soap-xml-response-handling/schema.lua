
local typedefs      = require "kong.db.schema.typedefs"
local xmldefinition = require("kong.plugins.soap-xml-handling-lib.xmldefinition")

return {
  name = "soap-xml-response-handling",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { VerboseResponse = { type = "boolean", required = false }, },
          { xsltTransformBefore = { type = "string", required = false }, },
          { xsdApiSchema = { type = "string", required = false }, },
          { xsdSoapSchema = { type = "string", required = false, default = xmldefinition.XSD_SOAP }, },
          { xsltTransformAfter = { type = "string", required = false }, },
        },
    }, },
  },
}