<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0">
	
  <xsl:import href="color-map-base.xsl" />

  <xsl:param name="colorMappings" as="element()*">
    <entry key="xsl" color="0000FF" />
    <entry key="xml" color="00FF00" />
    <entry key="java" color="FF0000" />
    <entry key="#default" color="FFFFFF" />
  </xsl:param>
  
  <xsl:template mode="extract-color-key" match="change" as="xs:string">
    <xsl:value-of select="replace(@file, '^(.*)\.([^\.]+)$', '$2')" />
  </xsl:template>
</xsl:stylesheet>