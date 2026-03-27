<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:variable name="backendHttpCode" select="//*[local-name()='backendHttpCode']"/>
  <xsl:template match="//*[local-name()='faultstring']">
    <faultstring>**** My Error custom **** ('<xsl:apply-templates select="@*|node()" />')</faultstring>
  </xsl:template>
  <xsl:template match="//*[local-name()='detail']">
  	<detail>
      <errorMessage>REDACTED</errorMessage>
      <xsl:if test="$backendHttpCode!=''">
        <backendHttpCode><xsl:value-of select="$backendHttpCode"/></backendHttpCode>
	    </xsl:if>
    </detail>
  </xsl:template>
</xsl:stylesheet>