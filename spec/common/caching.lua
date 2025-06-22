local caching_common = {}

caching_common.pluginRequest  = "soap-xml-request-handling"
caching_common.pluginResponse = "soap-xml-response-handling"

caching_common.pluginReq_log  = "\\["..caching_common.pluginRequest.."\\] "
caching_common.pluginRes_log  = "\\["..caching_common.pluginResponse.."\\] "

caching_common.libxslt  = "libxslt"
caching_common.libsaxon = "saxon"

caching_common.TTL = 2

caching_common.compile_xslt               = "XSLT transformation, caching: Compile the XSLT and Put it in the cache"
caching_common.compile_wsdl               = "WSDL Validation, caching: Compile the WSDL and Put it in the cache"
caching_common.compile_wsdl_TTL           = "WSDL Validation, caching: TTL \\("..caching_common.TTL.." s\\) is reached, so re-compile the WSDL"
caching_common.compile_wsdl_XSDError      = "WSDL Validation, caching: Not all XSDs are correctly compiled, so re-compile the WSDL"
caching_common.compile_xsd                = "XSD Validation, caching: Compile the XSD and Put it in the cache"
caching_common.compile_xsd_TTL            = "XSD Validation, caching: TTL \\("..caching_common.TTL.." s\\) is reached, so re-compile the XSD"
caching_common.compile_xsd_Error          = "XSD Validation, caching: All the pointers need to be recreated for consistency"
caching_common.compile_SOAPAction         = nil -- It doesn't exist because SOAPAction leverages WSDL caching (that is already compiled)
caching_common.compile_SOAPAction_ctx_doc = "getSOAPActionFromWSDL: caching: Compile 'contextPtr' and 'document' and Put them in the cache"
caching_common.compile_routeByXPath       = "RouteByXPath, caching: Create the Parser Context and Put it in the cache"
caching_common.wsdl_prefetch              = "XMLValidateWithWSDL, prefetch: so get all XSDs and raise the download of External Entities"
caching_common.xsd_prefetch               = "XSD Validation, prefetch: Compile XSD and Raise the download of External Entities"
caching_common.wsdl_async                 = "WSDL Validation, no WSDL caching due to Asynchronous external entities"
caching_common.xsd_async                  = "XSD Validation, no XSD caching due to Asynchronous external entities"
caching_common.SOAPAction_async           = "getSOAPActionFromWSDL: no WSDL caching due to Asynchronous external entities"
caching_common.get_xslt                   = "XSLT transformation, caching: Get the compiled XSLT from cache"
caching_common.get_wsdl                   = "WSDL Validation, caching: Get the compiled WSDL from cache"
caching_common.get_xsd                    = "XSD Validation, caching: Get the compiled XSD from cache"
caching_common.get_SOAPAction             = "getSOAPActionFromWSDL: caching: Get the compiled WSDL from cache"
caching_common.get_SOAPAction_wsdlDef     = "getSOAPActionFromWSDL: caching: Get 'wsdlDefinitions_type' from the cache"
caching_common.get_SOAPAction_ctx_ptr     = "getSOAPActionFromWSDL: caching: Get 'contextPtr' and 'document' from the cache"
caching_common.get_routeByXPath           = "RouteByXPath, caching: Get the Parser Context from cache"

caching_common.calculator_Request_XSLT_change_intB = [[
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output version="1.0" method="xml" encoding="utf-8" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='intB']">
    <xsl:copy-of select="."/>
      <intB>13</intB>
  </xsl:template>
</xsl:stylesheet>
]]

return caching_common