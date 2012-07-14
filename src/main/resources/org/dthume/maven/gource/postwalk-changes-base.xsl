<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0">
	
  <xsl:import href="change-to-gource-log-base.xsl" />
  
  <xsl:template mode="parse-changelog" match="changelog">
    <xsl:variable name="changes" as="element()*">
      <xsl:next-match />
    </xsl:variable>
    <xsl:variable name="state" as="element()*">
      <xsl:call-template name="postwalk-changes-create-initial-state">
        <xsl:with-param name="changes" select="$changes" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="postwalk-changes">
      <xsl:with-param name="changes" tunnel="yes" select="$changes" />
      <xsl:with-param name="state" tunnel="yes" select="$state" />
      <xsl:with-param name="result" tunnel="yes" select="()" />
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="postwalk-changes" as="element()*">
    <xsl:call-template name="postwalk-changes-recur" />
  </xsl:template>
  
  <xsl:template name="postwalk-changes-recur" as="element()*">
    <xsl:param name="changes" as="element()*" tunnel="yes" />
    <xsl:param name="state" as="element()*" tunnel="yes" />
    <xsl:param name="result" as="element()*" tunnel="yes" />
    <xsl:choose>
      <xsl:when test="empty($changes)">
        <xsl:for-each select="$result">
          <xsl:sequence select="." />
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="current" as="element()" select="
          $changes[1]" />
        <xsl:variable name="updatedState" as="element()*">
          <xsl:call-template name="postwalk-changes-update-state">
            <xsl:with-param name="currentChange" tunnel="yes" select="
              $current" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="newResult" as="element()*">
          <xsl:call-template name="postwalk-changes-update-result">
            <xsl:with-param name="currentChange" tunnel="yes" select="
              $current" />
            <xsl:with-param name="state" tunnel="yes" select="
              $updatedState" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="postwalk-changes-recur">
          <xsl:with-param name="changes" tunnel="yes" select="
            subsequence($changes, 2)" />
          <xsl:with-param name="state" tunnel="yes" select="
            $updatedState" />
          <xsl:with-param name="result" tunnel="yes" select="
            $newResult" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="postwalk-changes-create-initial-state" as="element()*">
    <xsl:param name="changes" as="element()*" />
    <xsl:sequence select="()" />
  </xsl:template>
  
  <xsl:template name="postwalk-changes-update-state" as="element()*">
    <xsl:param name="currentChange" as="element()*" tunnel="yes" />
    <xsl:param name="state" as="element()*" tunnel="yes" />
    <xsl:sequence select="$state" />
  </xsl:template>
  
  <xsl:template name="postwalk-changes-update-result" as="element()*">
    <xsl:param name="currentChange" as="element()" tunnel="yes" />
    <xsl:param name="result" as="element()" tunnel="yes" />
    <xsl:sequence select="($result, $currentChange)" />
  </xsl:template>
  
</xsl:stylesheet>