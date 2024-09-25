<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template name="main">
    <xsl:variable name="json" select="fn:json-to-xml(.)"/>    
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
  <xsl:template match="/">
      <xsl:call-template name="main">
       </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>