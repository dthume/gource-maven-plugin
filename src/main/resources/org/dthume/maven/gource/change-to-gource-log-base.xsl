<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0">
	
  <xsl:output method="text" />
  
  <xsl:param name="userRegex" as="xs:string" select="'^(.+)$'" />
  <xsl:param name="userRegexReplacement" as="xs:string" select="'$1'" />
  
  <xsl:variable name="modificationTypes" as="element()*">
    <type maven="added" gource="A" />
    <type maven="copied" gource="A" />
    <type maven="deleted" gource="D" />
    <type maven="modified" gource="M" />
    <type maven="renamed" gource="A" />
    <type maven="#default" gource="M" />
  </xsl:variable>
  
  <xsl:template match="/changelog">
    <xsl:variable name="parsed" as="element()*">
      <xsl:apply-templates mode="parse-changelog" select="." />
    </xsl:variable>
		<xsl:for-each select="$parsed">
      <xsl:value-of select="
        string-join(
          (@ts, @user, @type, @file, @color),
          '|'
        )" />
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
	</xsl:template>

  <xsl:template match="/ | @* | node()"
    mode="parse-changelog parse-user">
    <xsl:apply-templates mode="#current" select="@* | node()" />
  </xsl:template>
  
  <xsl:template mode="parse-changelog" as="element()*" match="entry">
    <xsl:variable name="user">
      <xsl:apply-templates mode="parse-user" select="." />
    </xsl:variable>
    <xsl:apply-templates mode="#current" select="@* | node()">
      <xsl:with-param name="ts" as="xs:string" tunnel="yes" select="@ts" />
      <xsl:with-param name="user" tunnel="yes" select="$user" />
      <xsl:with-param name="currentEntry" tunnel="yes" select="." />
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="parse-user" match="entry">
    <xsl:value-of select="replace(author, $userRegex, $userRegexReplacement)" />
  </xsl:template>
  
  <xsl:template mode="preprocess-changes" match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@* | node()" />
    </xsl:copy>
  </xsl:template>  
  
  <xsl:template mode="parse-changelog" as="element()*" match="file">
    <xsl:param name="user" tunnel="yes" />
    <xsl:param name="ts" as="xs:string" tunnel="yes" />
    <xsl:variable name="baseChanges" as="element()*">
      <xsl:if test="'renamed' = action">
        <change ts="{$ts}" user="{$user}" file="{old-name}" type="D" />
      </xsl:if>
      <change ts="{$ts}" user="{$user}" file="{name}" type="{
          (
            $modificationTypes[@maven = current()/action]/@gource,
            $modificationTypes[@maven = '#default']/@gource
          )[1]
        }" />
    </xsl:variable>
    <xsl:apply-templates mode="preprocess-changes" select="$baseChanges" />
  </xsl:template>
</xsl:stylesheet>