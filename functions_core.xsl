<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:till="http://www.sitzextase.de"
    exclude-result-prefixes="till xs"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    
    <xsl:output name="html" method="html" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
    <xsl:output name="xml" method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
    
    <!-- this stylesheet provides various functions to other stylesheets.-->
    <xsl:include href="functions_strings.xsl"/>
    <xsl:include href="functions_dates.xsl"/>
    <xsl:include href="functions_currencies.xsl"/>
    <xsl:include href="functions_arabic-transcription.xsl"/>
    <!-- local paths work much better! -->
    <xsl:include href="../Sente/tss_tools/tss_core-functions.xsl"/>
    <xsl:include href="../Sente/tss_tools/tss_citation-functions.xsl"/>
<!--    <xsl:include href="https://rawgit.com/tillgrallert/tss_tools/master/tss_citation-functions.xsl"/>-->
    
    
    <!--<xsl:include href="TeiMarkUpFunctions%20v1.xsl"/>
    <xsl:include href="SearchFunctions%20v1.xsl"/>
    <xsl:include href="SenteFunctions%20v1.xsl"/>
    <xsl:include href="Html2Mmd.xsl"/>-->
    
    <!-- toggle debugging mode -->
<!--    <xsl:param name="p_debug" select="true()"/>-->
    
    <!-- links to master files -->
    <!-- select a folder with Sente XML files. As per other transformations they are already unescaped -->
    <xsl:param name="pgSecondary" select="collection('/BachUni/BachBibliothek/GitHub/Sente/tss_data/BachSecondary?select=*.TSS.xml')"/>
    <xsl:param name="pgSources" select="collection('/BachUni/BachBibliothek/GitHub/Sente/tss_data/BachSources?select=*.TSS.xml')"/>
    <!--    <xsl:param name="pgSourcesUnescaped" select="document('/BachUni/projekte/XML/Sente XML exports/all/SourcesClean 151005 unescaped.TSS.xml')"/>-->
    <xsl:param name="pgNyms" select="document('/BachUni/programming/XML/TEI XML/masterFiles/NymMaster.TEIP5.xml')"/>
    
    <!-- this variable specifies the sort order according to the IJMES transliteration of Arabic -->
    <!-- it is called as collation="http://saxon.sf.net/collation?rules={encode-for-uri($sortIjmes)}" -->
    <xsl:variable name="sortIjmes"
        select="'&lt; ʾ,ʿ &lt; a,A &lt; ā, Ā &lt; b,B &lt; c,C &lt; d,D &lt; ḍ, Ḍ &lt; e,é,è,E,É,È &lt; f,F &lt; g,G &lt; ġ, Ġ &lt; h,H &lt; ḥ, Ḥ &lt; ḫ, Ḫ &lt; i,I &lt; ī, Ī  &lt; j,J &lt; k,K &lt; ḳ, Ḳ &lt; l,L &lt; m,M &lt; n,N &lt; o,O &lt; p,P &lt; q,Q &lt; r,R &lt; s,S &lt; ṣ, Ṣ &lt; t,T &lt; ṭ, Ṭ &lt; ṯ, Ṯ &lt; u,U &lt; ū, Ū &lt; v,V &lt; w,W &lt; x,X &lt; y,Y &lt; z, Z &lt; ẓ, Ẓ'"/>
    
    <!-- this variable specifies a sort order for reference whether they are archival sources, periodicals, or secondary literatur -->
    <!-- '&lt; Archival Book Chapter, Archival File, Archival Journal Entry, Archival Letter, Archival Material, Bill, Photograph, Maps &lt; Archival Periodical, Archival Periodical Article, Newspaper article &lt; Book, Book Chapter, Edited Book, Journal Article, Thesis, Manuscript, Other' -->
    <!-- it is called as collation="http://saxon.sf.net/collation?rules={encode-for-uri($sortIjmes)}" -->
    <xsl:variable name="sortLiterature" select="'&lt; A, P, M &lt; N &lt; B, E, J, T, O'"/>
    
    <!-- this variable provides a collation to normalize the IJMES transliteration -->
    <xsl:variable name="normIjmes"
        select="'&lt; ʾ,ʿ &lt; a,A, ā, Ā &lt; b,B &lt; c,C, ç, Ç &lt; d,D, ḍ, Ḍ &lt; e,é,è,E,É,È &lt; f,F &lt; g,G , ġ, Ġ, ğ, Ğ &lt; h,H , ḥ, Ḥ , ḫ, Ḫ &lt; i,I , ī, Ī  &lt; j,J &lt; k,K , ḳ, Ḳ, q, Q &lt; l,L &lt; m,M &lt; n,N &lt; o,O &lt; p,P &lt; r,R &lt; s,S , ṣ, Ṣ, š, Š, ş, Ş &lt; t,T , ṭ, Ṭ , ṯ, Ṯ &lt; u,U , ū, Ū &lt; v,V &lt; w,W &lt; x,X &lt; y,Y &lt; z, Z , ẓ, Ẓ, ż, Ż, ẕ, Ẕ'"/>
    <!-- these variables can be used to down-mark transliterations -->
    <xsl:variable name="vIjmesDiac">
        <xsl:text>ĀāĪīŪūḌḍḤḥḪḫḲḳṢṣṬṭṮṯẒẓʾʿ</xsl:text>
    </xsl:variable>
    <xsl:variable name="vIjmesNormal">
        <xsl:text>AaIiUuDdHhHhQqSsTtTtZz''</xsl:text>
    </xsl:variable>
    <xsl:variable name="vGeoNamesDiac" select="'’‘áḨḨḩŞşŢţz̧'"/>
    <xsl:variable name="vGeoNamesIjmes" select="'ʾʿāḤḤḥṢṣṬṭẓ'"/>
    
    <xsl:variable name="vArabicPossessive" select="'uhu,uhā,uhumā,uhum,uhun,ihi,ihā,ihimā,ihim,ihin,ahu,ahā,ahumā,ahum,ahun'"/>
</xsl:stylesheet>
