<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" exclude-result-prefixes="soapenv">
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <!-- remove all elements in the soapenv namespace -->
  <xsl:template match="soapenv:*">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  <!-- for the remaining elements (i.e. elements in the default namespace) ... -->
  <xsl:template match="*">
      <!-- ... create a new element with similar name in no-namespace -->
      <xsl:element name="{local-name()}">
          <xsl:apply-templates select="@*|node()"/>
      </xsl:element>
  </xsl:template>
  <!-- convert attributes to elements -->
  <xsl:template match="@*">
      <xsl:element name="{local-name()}">
          <xsl:value-of select="." />
      </xsl:element>
  </xsl:template>
</xsl:stylesheet>