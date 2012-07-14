<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:local="todo://local"
  version="2.0">
	
  <xsl:import href="postwalk-changes-base.xsl" />
  
  <xsl:variable name="startColor" as="element()">
    <color r="0" g="0" b="192" />
  </xsl:variable>
  
  <xsl:variable name="endColor" as="element()">
    <color r="255" g="0" b="0" />
  </xsl:variable>
  
  <xsl:function name="local:int-to-hex" as="xs:string">
    <xsl:param name="in" as="xs:integer"/>
    <xsl:sequence select="
      if ($in eq 0) then '00' else concat(
        if ($in gt 16) then local:int-to-hex($in idiv 16) else '',
        substring('0123456789ABCDEF', ($in mod 16) + 1, 1)
      )"/>
  </xsl:function>
  
  <xsl:template mode="parse-changelog" match="changelog">
    <xsl:variable name="heated" as="element()*">
      <xsl:next-match />
    </xsl:variable>
    <xsl:apply-templates mode="color-heated-changes" select="$heated" />
  </xsl:template>
  
  <xsl:template mode="color-heated-changes" match="/ | @* | node()">
    <xsl:apply-templates mode="#current" select="@* | node()" />
  </xsl:template>

  <xsl:template mode="color-heated-changes" as="element()*" match="
    change[empty(@heat)]">
    <xsl:sequence select="." />
  </xsl:template>
  
  <xsl:function name="local:blend-colors" as="xs:string">
    <xsl:param name="start" as="xs:string" />
    <xsl:param name="end" as="xs:string" />
    <xsl:param name="ratio" as="xs:decimal" />
    <xsl:value-of select="
      local:int-to-hex(
        xs:integer(
            xs:decimal($start) * (1.0 - $ratio)
          + xs:decimal($end) * $ratio
        )
      )" />
  </xsl:function>
  
  <xsl:template mode="color-heated-changes" as="element()*" match="
    change[exists(@heat)]">
    <xsl:variable name="ratio" as="xs:decimal" select="xs:decimal(@heat)" />
    <xsl:variable name="color" select="
      concat(
        local:blend-colors($startColor/@r, $endColor/@r, $ratio),
        local:blend-colors($startColor/@g, $endColor/@g, $ratio),
        local:blend-colors($startColor/@b, $endColor/@b, $ratio)
      )" />
    <xsl:copy>
      <xsl:sequence select="@* except @heat" />
      <xsl:attribute name="color" select="$color" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>