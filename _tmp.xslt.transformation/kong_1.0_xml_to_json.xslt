<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" />
<xsl:template match="/">{
  "companyName": "<xsl:value-of select="root/companyName"/>",
  "city": "<xsl:value-of select="root/city"/>",
  "state": "<xsl:value-of select="root/state"/>",
  "country": "<xsl:value-of select="root/country"/>",
  "offices": [<xsl:for-each select="root/offices/site">
    "<xsl:value-of select="."/>"
     <xsl:if test="position() != last()">
       <xsl:text>,</xsl:text>
     </xsl:if>
    </xsl:for-each>
    ]
}
</xsl:template>
</xsl:stylesheet>