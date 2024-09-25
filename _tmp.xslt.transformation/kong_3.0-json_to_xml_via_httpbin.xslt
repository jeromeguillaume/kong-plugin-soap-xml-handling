<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template name="main">
    <xsl:param name="request-body" required="yes"/>
    <xsl:variable name="json_var" select="fn:json-to-xml($request-body)"/>
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