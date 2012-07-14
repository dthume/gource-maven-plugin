<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0">
	
  <xsl:import href="change-to-gource-log-base.xsl" />

  <!--
    Sequence of `entry` elements with `key` and `color` attributes 
  -->
  <xsl:param name="colorMappings" as="element()*" select="()"/>
  
  <xsl:template mode="parse-changelog" match="changelog">
    <xsl:param name="colorMap" tunnel="yes" as="element()*" />
    <xsl:next-match>
      <xsl:with-param name="colorMap" tunnel="yes" select="
        if (exists($colorMap)) then $colorMap else $colorMappings"/>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:template mode="preprocess-changes" match="change">
    <xsl:param name="colorMap" tunnel="yes" as="element()*" />
    <xsl:variable name="colorKey" as="xs:string">
      <xsl:apply-templates mode="extract-color-key" select="." />
    </xsl:variable>
    <xsl:variable name="color" as="xs:string?" select="
      (
        $colorMap[@key = $colorKey]/@color,
        $colorMap[@key = '#default']/@color
      )[1]" />
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*" />
      <xsl:if test="exists($color) and 0 lt string-length($color)">
        <xsl:attribute name="color" select="$color" />
      </xsl:if>
      <xsl:apply-templates mode="#current" select="node()" />
    </xsl:copy>
  </xsl:template>  

  <xsl:template mode="extract-color-key" match="/ | @* | node()">
    <xsl:apply-templates mode="#current" select="@* | node()" />
  </xsl:template>
</xsl:stylesheet>