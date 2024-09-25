<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template name="main">
    <xsl:param name="request-body" required="yes"/>
    <xsl:variable name="json" select="fn:json-to-xml($request-body)"/>    
      <root>
        <companyName><xsl:value-of select="$json/map/string[@key='companyName']"/></companyName>
        <city><xsl:value-of select="$json/map/string[@key='city']"/></city>
        <state><xsl:value-of select="$json/map/string[@key='state']"/></state>
        <country><xsl:value-of select="$json/map/string[@key='country']"/></country>
        <offices>
        	<xsl:for-each select="$json/map/array[@key='offices']/string">
        		<site><xsl:value-of select="."/></site>
        	</xsl:for-each>
        </offices>
        <products>
        	<xsl:for-each select="$json/map/array[@key='products']/map/map">
        		<product>
        			<xsl:attribute name="name"><xsl:value-of select="@key"/></xsl:attribute>
					<version><xsl:value-of select="number[@key='version']"/></version>
			    	<saas><xsl:value-of select="boolean[@key='saas']"/></saas>
        		</product>
        	</xsl:for-each>
        </products>
      </root>
  </xsl:template>
  <xsl:template match="/">
      <xsl:call-template name="main">
      	<xsl:with-param name="request-body">
        {
  "companyName": "KongHQ",
  "city": "SAN FRANCISCO",
  "state": "CA",
  "country": "USA",
  "offices": [
    "San Francisco (HQ)",
    "Chicago",
    "London",
    "Bangalore",
    "Singapore",
    "Shangai",
    "Japan"
  ],
  "products": [
    {
      "Kong konnect": {
        "version": 2024,
        "saas": true
      }
    },
    {
      "Kong AI Gateway": {
        "version": 3.8,
        "saas": false
      }
    },
    {
      "Kong Ingress Controller": {
        "version": 3.3,
        "saas": false
      }
    },
    {
      "Kong Mesh": {
        "version": 2.8,
        "saas": false
      }
    },
    {
      "Insomnia": {
        "version": 10,
        "saas": false
      }
    }
  ]
		}
      	</xsl:with-param>
      </xsl:call-template>
      <xsl:apply-templates />
   </xsl:template>
</xsl:stylesheet>