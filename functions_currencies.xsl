<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:till="http://www.sitzextase.de"
    
    xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output name="html" method="html" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
    <xsl:output name="xml" method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <!-- this stylesheet provides various functions to other stylesheets.-->
    <!-- v1a: added regex expression to allow for variable input -->
    <!-- v1: stylesheets have been split from BachFunctions -->
    
    
    <!-- currency exchange -->
    <!-- £1 = 1l = 20s = 240d !! -->
    <xsl:template name="funcCurExchange">
        <xsl:param name="pInput"/>
        <xsl:param name="pL" select="number(tokenize($pInput,'([.,&quot;\-])')[1])"/>
        <xsl:param name="pS" select="number(tokenize($pInput,'([.,&quot;\-])')[2])"/>
        <xsl:param name="pD" select="number(tokenize($pInput,'([.,&quot;\-])')[3])"/>
        <!--  <xsl:param name="pL" select="number(tokenize($pInput,'-')[1])"/>
        <xsl:param name="pS" select="number(tokenize($pInput,'-')[2])"/>
        <xsl:param name="pD" select="number(tokenize($pInput,'-')[3])"/> -->
        <xsl:param name="pCurInput" select="'Sterling'"/>
        <xsl:param name="pCurTarget" select="'Ottoman'"/>
        <xsl:param name="pRate" select="1"/>

        <!-- the base input -->
        <xsl:variable name="vInput">
            <xsl:variable name="vBaseD">
                <xsl:call-template name="funcCurBase">
                    <xsl:with-param name="pCurInput" select="$pCurInput"/>
                    <xsl:with-param name="pL" select="$pL"/>
                    <xsl:with-param name="pD" select="$pD"/>
                    <xsl:with-param name="pS" select="$pS"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$pCurInput='Sterling'">
                    <xsl:value-of select="number($vBaseD div 240)"/>
                </xsl:when>
                <xsl:when test="$pCurInput='Ottoman'">
                    <xsl:value-of select="number($vBaseD div 4000)"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- metric currencies -->
                    <!-- <xsl:value-of select="((($pL*100) + $pS) div 100) + ($pD div 100)"/> -->
                    <xsl:value-of select="number($vBaseD div 100)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="vOutput">
            <!-- vBase comes in lowest denomination of the input multiplied by the exchange rate -->
            <xsl:variable name="vBase" select="$vInput * $pRate"/>
            <xsl:choose>
                <xsl:when test="$pCurTarget='Ottoman'">
                    <!-- rates for ottoman are usually provided as piaster -->
                    <xsl:variable name="vOttoL" select="floor($vBase div 100)"/>
                    <xsl:variable name="vOttoS1" select="floor($vBase mod 100)"/>
                    <xsl:variable name="vOttoS" select="floor($vBase)"/>
                    <xsl:variable name="vOttoD"
                        select="format-number(40 * ($vBase - floor($vBase)),'00.0')"/>
                    <!-- <xsl:value-of select="concat($vOttoL,'&quot;',$vOttoS1,'&quot;',$vOttoD)"/> -->
                    <xsl:value-of select="concat($vOttoS,'-',$vOttoD)"/>
                </xsl:when>
                <xsl:when test="$pCurTarget='Sterling'">

                    <xsl:variable name="vBritL" select="floor($vBase)"/>
                    <xsl:variable name="vBritS" select="floor(($vBase - $vBritL)*20)"/>
                    <xsl:variable name="vBritD"
                        select="format-number((((($vBase - $vBritL)*20) - $vBritS)*12),'0.0')"/>
                    <xsl:value-of select="concat($vBritL,'-',$vBritS,'-',$vBritD)"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- metric currencies -->
                    <xsl:value-of select="$vBase"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$vOutput"/>
    </xsl:template>
    
    <!-- computes the exchange rate as a ration of the input1 value to the input2 value  -->
    <xsl:template name="funcCurRate">
        <xsl:param name="pInput1" select="'2-0-0'"/>
        <xsl:param name="pInput2" select="'2-3-0'"/>
        <xsl:param name="pL1" select="number(tokenize($pInput1,'([.,&quot;\-])')[1])"/>
        <xsl:param name="pS1" select="number(tokenize($pInput1,'([.,&quot;\-])')[2])"/>
        <xsl:param name="pD1" select="number(tokenize($pInput1,'([.,&quot;\-])')[3])"/>
        <xsl:param name="pL2" select="number(tokenize($pInput2,'([.,&quot;\-])')[1])"/>
        <xsl:param name="pS2" select="number(tokenize($pInput2,'([.,&quot;\-])')[2])"/>
        <xsl:param name="pD2" select="number(tokenize($pInput2,'([.,&quot;\-])')[3])"/>
        <xsl:param name="pCurInput1" select="'Sterling'"/>
        <xsl:param name="pCurInput2" select="'Ottoman'"/>

        <!-- rate -->
        <xsl:variable name="vRate">
            <xsl:variable name="vBaseD1">
                <xsl:call-template name="funcCurBase">
                    <xsl:with-param name="pCurInput" select="$pCurInput1"/>
                    <xsl:with-param name="pL" select="$pL1"/>
                    <xsl:with-param name="pS" select="$pS1"/>
                    <xsl:with-param name="pD" select="$pD1"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="vBaseD2">
                <xsl:call-template name="funcCurBase">
                    <xsl:with-param name="pCurInput" select="$pCurInput2"/>
                    <xsl:with-param name="pL" select="$pL2"/>
                    <xsl:with-param name="pS" select="$pS2"/>
                    <xsl:with-param name="pD" select="$pD2"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="$vBaseD2 div $vBaseD1"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$pCurInput1='Sterling' and $pCurInput2='Ottoman'">
                <!-- this computes the rate of £ to piaster -->
                <xsl:value-of select="$vRate*240 div 40"/>
            </xsl:when>
            <xsl:when test="$pCurInput1='Sterling' and $pCurInput2='Metric'">
                <!-- this computes the rate of £ to metric currencies -->
                <xsl:value-of select="$vRate*240 div 100"/>
            </xsl:when>
            <xsl:when test="$pCurInput1='Metric'  and $pCurInput2='Ottoman'">
                <!-- this computes the rate of metric currencies to piaster -->
                <xsl:value-of select="$vRate*100 div 40"/>
            </xsl:when>
            <xsl:when test="$pCurInput1='Metric'  and $pCurInput2='Sterling'">
                <!-- this computes the rate of metric currencies to £ -->
                <xsl:value-of select="$vRate*100"/>
            </xsl:when>
            <xsl:when test="$pCurInput1='Ottoman'  and $pCurInput2='Metric'">
                <!-- this computes the rate of piaster to metric currencies  -->
                <xsl:value-of select="$vRate*40 div 100"/>
            </xsl:when>
            <xsl:when test="$pCurInput1='Ottoman'  and $pCurInput2='Sterling'">
                <!-- this computes the rate of piaster to £ -->
                <xsl:value-of select="$vRate*40 div 240"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$vRate"/>
            </xsl:otherwise>
        </xsl:choose>


    </xsl:template>
    
    <!-- normalise non-metrical currencies to decimal values -->
    <xsl:template name="funcCurDecimal">
        <xsl:param name="pInput" select="'2-0-0'"/>
        <xsl:param name="pL" select="number(tokenize($pInput,'([.,&quot;\-])')[1])"/>
        <xsl:param name="pS" select="number(tokenize($pInput,'([.,&quot;\-])')[2])"/>
        <xsl:param name="pD" select="number(tokenize($pInput,'([.,&quot;\-])')[3])"/>
        <xsl:param name="pCurInput" select="'Ottoman'"/>
        <xsl:variable name="vCurBase">
            <xsl:call-template name="funcCurBase">
                <xsl:with-param name="pD" select="$pD"/>
                <xsl:with-param name="pL" select="$pL"/>
                <xsl:with-param name="pS" select="$pS"/>
                <xsl:with-param name="pCurInput" select="$pCurInput"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$pCurInput='Ottoman'">
                <xsl:value-of select="$vCurBase div 40"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pInput"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--  -->
    <xsl:template name="funcCurBase">
        <xsl:param name="pL"/>
        <xsl:param name="pS"/>
        <xsl:param name="pD"/>
        <xsl:param name="pCurInput" select="'Sterling'"/>
        <!-- British pence as base: £1 = 20s = 240d -->
        <xsl:variable name="vBritD1">
            <xsl:choose>
                <xsl:when test="$pL">
                    <xsl:value-of select="$pL*240"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vBritD2">
            <xsl:choose>
                <xsl:when test="$pS">
                    <xsl:value-of select="$pS*12"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vBritD3">
            <xsl:choose>
                <xsl:when test="$pD">
                    <xsl:value-of select="$pD"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Ottoman para base: £T1 = Ps 100 = 4000 para -->
        <xsl:variable name="vOttoD1">
            <xsl:choose>
                <xsl:when test="$pL">
                    <xsl:value-of select="$pL*4000"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vOttoD2">
            <xsl:choose>
                <xsl:when test="$pS">
                    <xsl:value-of select="$pS*40"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vOttoD3">
            <xsl:choose>
                <xsl:when test="$pD">
                    <xsl:value-of select="$pD"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$pCurInput='Sterling'">
                <xsl:value-of select="$vBritD1+$vBritD2+$vBritD3"/>
            </xsl:when>
            <xsl:when test="$pCurInput='Ottoman'">
                <xsl:value-of select="$vOttoD1+$vOttoD2+$vOttoD3"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- metric currencies -->
                <xsl:value-of select="(($pL*100) + $pS) + ($pD div 100)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>



</xsl:stylesheet>
