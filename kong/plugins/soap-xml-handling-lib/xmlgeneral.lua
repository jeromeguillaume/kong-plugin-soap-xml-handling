local xmlgeneral = {}

xmlgeneral.HTTPCodeSOAPFault = 500

xmlgeneral.RequestTextError   = "Request"
xmlgeneral.ResponseTextError  = "Response"
xmlgeneral.SepTextError       = " - "
xmlgeneral.XSLTError          = "XSLT transformation failed"
xmlgeneral.XSDError           = "XSD validation failed"

xmlgeneral.XSD_SOAP = [[
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
            targetNamespace="http://schemas.xmlsoap.org/soap/envelope/" >
  <!-- Envelope, header and body -->
  <xs:element name="Envelope" type="tns:Envelope" />
  <xs:complexType name="Envelope" >
    <xs:sequence>
      <xs:element ref="tns:Header" minOccurs="0" />
      <xs:element ref="tns:Body" minOccurs="1" />
      <xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" />
  </xs:complexType>
  <xs:element name="Header" type="tns:Header" />
  <xs:complexType name="Header" >
    <xs:sequence>
      <xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" />
  </xs:complexType>

  <xs:element name="Body" type="tns:Body" />
  <xs:complexType name="Body" >
    <xs:sequence>
      <xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##any" processContents="lax" >
    <xs:annotation>
      <xs:documentation>
      Prose in the spec does not specify that attributes are allowed on the Body element
    </xs:documentation>
    </xs:annotation>
  </xs:anyAttribute>
  </xs:complexType>
        
  <!-- Global Attributes.  The following attributes are intended to be usable via qualified attribute names on any complex type referencing them.  -->
  <xs:attribute name="mustUnderstand" >	
      <xs:simpleType>
      <xs:restriction base='xs:boolean'>
      <xs:pattern value='0|1' />
    </xs:restriction>
    </xs:simpleType>
  </xs:attribute>
  <xs:attribute name="actor" type="xs:anyURI" />
  <xs:simpleType name="encodingStyle" >
    <xs:annotation>
    <xs:documentation>
      'encodingStyle' indicates any canonicalization conventions followed in the contents of the containing element.  For example, the value 'http://schemas.xmlsoap.org/soap/encoding/' indicates the pattern described in SOAP specification
    </xs:documentation>
  </xs:annotation>
    <xs:list itemType="xs:anyURI" />
  </xs:simpleType>
  <xs:attribute name="encodingStyle" type="tns:encodingStyle" />
  <xs:attributeGroup name="encodingStyle" >
    <xs:attribute ref="tns:encodingStyle" />
  </xs:attributeGroup>
  <xs:element name="Fault" type="tns:Fault" />
  <xs:complexType name="Fault" final="extension" >
    <xs:annotation>
    <xs:documentation>
      Fault reporting structure
    </xs:documentation>
  </xs:annotation>
    <xs:sequence>
      <xs:element name="faultcode" type="xs:QName" />
      <xs:element name="faultstring" type="xs:string" />
      <xs:element name="faultactor" type="xs:anyURI" minOccurs="0" />
      <xs:element name="detail" type="tns:detail" minOccurs="0" />      
    </xs:sequence>
  </xs:complexType>
  <xs:complexType name="detail">
    <xs:sequence>
      <xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##any" processContents="lax" /> 
  </xs:complexType>
</xs:schema>
]]

---------------------------------
-- Format the SOAP Fault message
---------------------------------
function xmlgeneral.formatSoapFault(ErrMsg, ErrEx)
  local soapErrMsg = "\
<?xml version=\"1.0\" encoding=\"utf-8\"?> \
<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"> \
  <soap:Body> \
    <soap:Fault>\
      <faultcode>soap:Client</faultcode>\
      <faultstring>" .. ErrMsg .. ": " .. ErrEx .. "</faultstring>\
      <detail/>\
    </soap:Fault>\
  </soap:Body>\
</soap:Envelope>\
"
  kong.log.err ("formatSoapFault, soapErrMsg:" .. soapErrMsg)
  return soapErrMsg
end

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function xmlgeneral.returnSoapFault(plugin_conf, HTTPcode, soapErrMsg)  
  -- Sends a Fault code to client
  return kong.response.exit(HTTPcode, soapErrMsg, {["Content-Type"] = "text/xml; charset=utf-8"})
end

----------------------------------------------------------------------------------------
-- Prepare a XML declaration (which starts by '<?')
-- The XLST removes it; so if the user defines its xslt file with 
-- omit-xml-declaration="no" we format it and append it to SOAP/XML content (after XSLT)
--
-- Example: <?xml version="1.0" encoding="utf-8"?>
----------------------------------------------------------------------------------------
function xmlgeneral.XSLT_Format_XMLDeclaration(plugin_conf, version, encoding, omitXmlDeclaration, standalone, indent)
  local xmlDeclaration = ""
  local ffi = require("ffi")
  
  -- If we have to Format and Add (to SOAP/XML content) a XML declaration
  if omitXmlDeclaration == 0 then
    xmlDeclaration = "<?xml version=\""
    if version == ffi.NULL then
      xmlDeclaration = xmlDeclaration .. "1.0\""
    else
      xmlDeclaration = xmlDeclaration .. ffi.string(version) .. "\""
    end
    xmlDeclaration = xmlDeclaration .. " encoding=\""
    if encoding == ffi.NULL then
      xmlDeclaration = xmlDeclaration .. "utf-8\""
    else
      xmlDeclaration = xmlDeclaration .. ffi.string(encoding) .. "\""
    end
    if standalone == 1 then
      xmlDeclaration = xmlDeclaration .. " standalone=\"yes\""
    end
    xmlDeclaration = xmlDeclaration .. "?>"
    if indent == 1 then
      xmlDeclaration = xmlDeclaration .. "\n"
    end
  end
  
  return xmlDeclaration
end

------------------------------------------
-- Transform XML with XSLT Transformation
------------------------------------------
function xmlgeneral.XSLTransform(plugin_conf, XMLtoTransform, XSLT)
  local libxml2ex   = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
  local libxslt     = require("kong.plugins.soap-xml-handling-lib.libxslt")
  local libxml2     = require("xmlua.libxml2")
  local ffi         = require("ffi")
  local errMessage  = ""
  local err         = nil
  local style       = nil
  local xml_doc     = nil
  local errDump     = 0
  local xml_transformed_dump  = ""
  local xmlNodePtrRoot        = nil
  
  kong.log.notice("XSLT transformation, BEGIN: " .. XMLtoTransform)
  
  local default_parse_options = bit.bor(ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING,
                                        ffi.C.XML_PARSE_NONET)
                                        
  -- Load the XSLT document
  local xslt_doc, errMessage = libxml2ex.xmlReadMemory(XSLT, nil, nil, default_parse_options)
  
  if errMessage == nil then
    -- Parse XSLT document
    style = libxslt.xsltParseStylesheetDoc (xslt_doc)
    if style ~= nil then
      -- Load the complete XML document (with <soap:Envelope>)
      xml_doc, errMessage = libxml2ex.xmlReadMemory(XMLtoTransform, nil, nil, default_parse_options)
    else
      errMessage = "error calling 'xsltParseStylesheetDoc'"
    end
  end

  -- If the XSLT and the XML are correctly loaded and parsed
  if errMessage == nil then
    -- Transform the XML doc with XSLT transformation
    local xml_transformed = libxslt.xsltApplyStylesheet (style, xml_doc)
    
    if xml_transformed ~= nil then
      -- Dump into a String the canonized image of the XML transformed by XSLT
      xml_transformed_dump, errDump = libxml2ex.xmlC14NDocSaveTo (xml_transformed, nil)
      if errDump == 0 then
        -- If needed we wppend the xml declaration
        -- Example: <?xml version="1.0" encoding="utf-8"?>
        xml_transformed_dump = xmlgeneral.XSLT_Format_XMLDeclaration (
                                            plugin_conf, 
                                            style.version, 
                                            style.encoding,
                                            style.omitXmlDeclaration, 
                                            style.standalone, 
                                            style.indent) .. xml_transformed_dump

        -- Remove empty Namespace (example: xmlns="") added by XSLT library or transformation 
        xml_transformed_dump = xml_transformed_dump:gsub(' xmlns=""', '')
        kong.log.notice ("XSLT transformation, END: " .. xml_transformed_dump)
      else
        errMessage = "error calling 'xmlC14NDocSaveTo'"
      end
    else
      errMessage = "error calling 'xsltApplyStylesheet'"
    end

    --[[if xml_transformed ~= nil then

      -- Get Root Element, which is <soap:Envelope>
      xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xml_transformed)
      if xmlNodePtrRoot == nil then
        errMessage = "error calling 'xmlDocGetRootElement'"  
      end
    else
      errMessage = "error calling 'xsltApplyStylesheet'"
    end

    if xmlNodePtrRoot ~= nil then
      -- Dump into a String the XML transformed by XSLT
      xml_transformed_dump, errDump = libxml2ex.xmlNodeDump	(xml_transformed, xmlNodePtrRoot, 1, 1)
      
      if errDump == 0 then
        -- Remove empty Namespace (example: xmlns="") added by XSLT library or transformation 
        xml_transformed_dump = xml_transformed_dump:gsub(' xmlns=""', '')
        -- Dump into a String the XML transformed
        kong.log.notice ("XSLT transformation, END: " .. xml_transformed_dump)
      else
        errMessage = "error calling 'xmlNodeDump'"
      end
    end]]
  end
  
  if errMessage ~= nil then
    kong.log.err ("XSLT transformation, errMessage: " .. errMessage)
  end

  -- xmlCleanupParser()
  -- xmlMemoryDump()
  
  return xml_transformed_dump, errMessage
  
end

--------------------------------------
-- Validate a XML with its XSD schema
--------------------------------------
function xmlgeneral.XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, XSDSchema)
  local ffi           = require("ffi")
  local libxml2ex     = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
  local libxml2       = require("xmlua.libxml2")
  local errMessage    = nil
  local err           = nil
  local is_valid      = 0
  
  -- Create Parser Context
  local xsd_context = libxml2ex.xmlSchemaNewMemParserCtxt(XSDSchema)
  
  -- Create XSD schema
  local xsd_schema_doc, errMessage = libxml2ex.xmlSchemaParse(xsd_context)
  
  -- If there is no error loading the XSD schema
  if not errMessage then
    
    -- Create Validation context of XSD Schema
    local validation_context = libxml2ex.xmlSchemaNewValidCtxt(xsd_schema_doc)
    
    local default_parse_options = bit.bor(ffi.C.XML_PARSE_RECOVER)
    local xml_doc = libxml2ex.xmlReadMemory(XMLtoValidate, nil, nil, default_parse_options )
    
    -- if we have to find the 1st Child of API which is this example <Add ... /"> (and not the <soap> root)
    if child ~=0 then
      -- Example:
      -- <soap:Envelope xmlns:xsi=....">
      --    <soap:Body>
      --      <Add xmlns="http://tempuri.org/">
      --        <a>5</a>
      --        <b>7</b>
      --      </Add>
      --    </soap:Body>
      --  </soap:Envelope>
      
      -- Get Root Element, which is <soap:Envelope>
      local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_doc);
      -- Get Child Element, which is <soap:Body>
      local xmlNodePtrChild  = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
      -- Get WebService Child Element, which is, for instance, <Add xmlns="http://tempuri.org/">
      local xmlNodePtrChildWS = libxml2.xmlFirstElementChild(xmlNodePtrChild)

      -- Dump in a String the WebService part
      kong.log.notice ("XSD validation API part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrChildWS, 1, 1))

      -- Check validity of One element with its XSD schema
      is_valid, errMessage = libxml2ex.xmlSchemaValidateOneElement (validation_context, xmlNodePtrChildWS)
    else
      -- Get Root Element, which is <soap:Envelope>
      local xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xml_doc);
      kong.log.notice ("XSD validation SOAP part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrRoot, 1, 1))

      -- Check validity of XML with its XSD schema
      is_valid, errMessage = libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc)
      kong.log.notice ("is_valid: " .. is_valid)
    end
  end
  
  if not errMessage and is_valid == 0 then
    kong.log.notice ("XSD validation of SOAP schema: Ok")
  elseif errMessage then
    kong.log.err ("XSD validation of SOAP schema: Ko, " .. errMessage)
  else
    errMessage = "Ko"
    kong.log.err ("XSD validation of SOAP schema: ")
  end
  return errMessage
end

---------------------------------------------
-- Search a XPath and Compares it to a value
---------------------------------------------
function xmlgeneral.RouteByXPath (kong, XMLtoSearch, XPath, XPathCondition, XPathRegisterNs)
  local ffi         = require("ffi")
  local libxml2ex   = require("kong.plugins.soap-xml-handling-lib.libxml2ex")
  local libxml2     = require("xmlua.libxml2")
  local rcXpath     = false
  
  kong.log.notice("RouteByXPath, XMLtoSearch: " .. XMLtoSearch)

  local context = libxml2.xmlNewParserCtxt()
  local document = libxml2.xmlCtxtReadMemory(context, XMLtoSearch)
  if not document then
    kong.log.err ("RouteByXPath, xmlCtxtReadMemory error, no document")
  end
  
  local context = libxml2.xmlXPathNewContext(document)
  
  -- Register NameSpace(s)
  kong.log.notice("XPathRegisterNs length: " .. #XPathRegisterNs)
  
  -- Go on each NameSpace definition
  for i = 1, #XPathRegisterNs do
    local prefix, uri
    local j = XPathRegisterNs[i]:find(',', 1)
    if j then
      prefix  = string.sub(XPathRegisterNs[i], 1, j - 1)
      uri     = string.sub(XPathRegisterNs[i], j + 1, #XPathRegisterNs[i])
    end
    local rc = false
    if prefix and uri then
      -- Register NameSpace
      rc = libxml2.xmlXPathRegisterNs(context, prefix, uri)
    end
    if rc then
      kong.log.notice("RouteByXPath, successful registering NameSpace for '" .. XPathRegisterNs[i] .. "'")
    else
      kong.log.err("RouteByXPath, failure registering NameSpace for '" .. XPathRegisterNs[i] .. "'")
    end
  end

  local object = libxml2.xmlXPathEvalExpression(XPath, context)
  if object ~= ffi.NULL then
    
    -- If we found the XPath element
    if object.nodesetval ~= ffi.NULL and object.nodesetval.nodeNr ~= 0 then        
        local nodeContent = libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0])
        kong.log.notice("libxml2.xmlNodeGetContent: " .. nodeContent)
        if nodeContent == XPathCondition then
          rcXpath = true
        end
    else
      kong.log.err ("RouteByXPath, object.nodesetval is null")  
    end
  else
    kong.log.err ("RouteByXPath, object is null")
  end
  local msg = "with XPath=\"" .. XPath .. "\" and XPathCondition=\"" .. XPathCondition .. "\""
  
  if rcXpath then
    kong.log.notice ("RouteByXPath: Ok " .. msg)
  else
    kong.log.notice ("RouteByXPath: Ko " .. msg)
  end
  return rcXpath
end

return xmlgeneral