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