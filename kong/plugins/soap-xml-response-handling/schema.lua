
local typedefs = require "kong.db.schema.typedefs"
local xmlgeneral   = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")

return {
  name = "soap-xml-response-handling",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { xsltTransformBefore = { type = "string", required = false }, },
          { xsdApiSchema = { type = "string", required = false }, },
          { xsdSoapSchema = { type = "string", required = false, default = xmlgeneral.XSD_SOAP }, },
          { xsltTransformAfter = { type = "string", required = false }, },
        },
    }, },
  },
}