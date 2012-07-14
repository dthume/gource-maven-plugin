<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0">
	
  <xsl:import href="color-map-base.xsl" />

  <xsl:param name="colorMappings" as="element()*">
    <entry key="user1" color="0000FF" />
    <entry key="#default" color="FFFFFF" />
  </xsl:param>
  
  <xsl:template mode="extract-color-key" match="change/@user" as="xs:string">
    <xsl:value-of select="." />
  </xsl:template>
</xsl:stylesheet>
