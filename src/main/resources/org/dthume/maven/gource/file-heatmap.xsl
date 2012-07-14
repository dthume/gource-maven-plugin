<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0">
	
  <xsl:import href="heatmap-base.xsl" />
  
  <xsl:template name="postwalk-changes" as="element()*">
    <xsl:param name="changes" as="element()*" tunnel="yes" />
    <xsl:variable name="maxUpdates" as="xs:integer">
      <xsl:for-each-group select="$changes" group-by="@file">
        <xsl:sort order="descending" data-type="number" select="
          count(current-group())" />
        <xsl:if test="position() = 1">
          <xsl:sequence select="count(current-group())" />
        </xsl:if>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:call-template name="postwalk-changes-recur">
      <xsl:with-param name="maxUpdates" select="$maxUpdates" tunnel="yes" />
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="postwalk-changes-update-state" as="element()*">
    <xsl:param name="currentChange" as="element()*" tunnel="yes" />
    <xsl:param name="state" as="element()*" tunnel="yes" />
    <xsl:variable name="currentState" as="element()?" select="
      $state[@file = $currentChange/@file]" />
    <xsl:sequence select="$state except $currentState" />
    <xsl:choose>
      <xsl:when test="empty($currentState)">
        <state file="{$currentChange/@file}" updates="1" />
      </xsl:when>
      <xsl:otherwise>
        <state file="{$currentChange/@file}"
          updates="{1 + xs:integer($currentState/@updates)}" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="postwalk-changes-update-result" as="element()*">
    <xsl:param name="currentChange" as="element()" tunnel="yes" />
    <xsl:param name="state" as="element()*" tunnel="yes" />
    <xsl:param name="result" as="element()*" tunnel="yes" />
    <xsl:param name="maxUpdates" as="xs:integer" tunnel="yes" />
    <xsl:variable name="heat" as="xs:decimal" select="
          xs:integer($state[@file = $currentChange/@file]/@updates)
      div $maxUpdates" />
    <xsl:sequence select="$result" />
    <change heat="{$heat}">
      <xsl:copy-of select="$currentChange/@*" />
    </change>
  </xsl:template>
</xsl:stylesheet>