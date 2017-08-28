<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:bachf="http://www.sitzextase.de" 
    xmlns:functx="http://www.functx.com"
    xmlns:html="http://www.w3.org/1999/xhtml" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:till="http://www.sitzextase.de"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="till xs bachf functx"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">

    <xsl:output encoding="UTF-8" indent="yes" method="html" name="html" omit-xml-declaration="yes"/>
    <xsl:output encoding="UTF-8" indent="yes" method="xml" name="xml" omit-xml-declaration="no"
        version="1.0"/>

    <!-- this stylesheet provides various string functions to other stylesheets.-->

    <!-- Plans: funcStringNER should get a parameter to control the input language and reduce computing power -->

    <!-- ISSUE: Html is not particularly well-suited to use namespaces, thus they must be omitted -->
    <!-- v1e, v1f: improved the NER functions and added
        - funcStringToknize: tokenizes any input string into tei:w and tei:pc nodes. Whitespace is kept as text() in between the new nodes. -->
    <!-- v1d: new functions: 
        - funcStringCleanTranscription 
        - funcStringNER: provides NER for names based on an authority file of nyms.
        - funcStringExtractCurrencies: still experimental function that could be used inside the funcStringNER to identify and normalise currencies.
        - funcStringLanguageTest: this function takes an input string and tries to establish its language -->

    <xsl:param name="pgEnDash" select="'–'"/>
    <xsl:param name="pgEmDash" select="'—'"/>

    <!-- funcStringCaps
        PROBLEM: at the moment an "a" at the beginning of a string is not capitalised -->
    <!-- Chicago 16: 8.157: Principles of headline-style capitalization
        
The conventions of headline style are governed mainly by emphasis and grammar. The following rules, though occasionally arbitrary, are intended primarily to facilitate the consistent styling of titles mentioned or cited in text and notes:

    1. Capitalize the first and last words in titles and subtitles (but see rule 7), and capitalize all other major words (nouns, pronouns, verbs, adjectives, adverbs, and some conjunctions—but see rule 4).
    2. Lowercase the articles the, a, and an.
    3. Lowercase prepositions, regardless of length, except when they are used adverbially or adjectivally (up in Look Up, down in Turn Down, on in The On Button, to in Come To, etc.) or when they compose part of a Latin expression used adjectivally or adverbially (De Facto, In Vitro, etc.).
    4. Lowercase the conjunctions and, but, for, or, and nor.
    5. Lowercase to not only as a preposition (rule 3) but also as part of an infinitive (to Run, to Hide, etc.), and lowercase as in any grammatical function.
    6. Lowercase the part of a proper name that would be lowercased in text, such as de or von.
    7. Lowercase the second part of a species name, such as fulvescens in Acipenser fulvescens, even if it is the last word in a title or subtitle.
    
For examples, see 8.158. For hyphenated compounds in titles, see 8.159.  -->
    <!-- Chicago16: 11.3 Capitalization of foreign titles
        
For foreign titles of works, whether these appear in text, notes, or bibliographies, Chicago recommends a simple rule: capitalize only the words that would be capitalized in normal prose—first word of title and subtitle and all proper nouns. That is, use sentence style (see 8.156). This rule applies equally to titles using the Latin alphabet and to transliterated titles. For examples, see 14.107. For exceptions, see 14.193, 11.24, 11.42. For variations in French, see 11.30.  -->
    <xsl:template name="funcStringCaps">
        <xsl:param name="pString"/>
        <xsl:param name="pLang"/>
        <xsl:param name="pLowerCaseStrings">
            <xsl:choose>
                <xsl:when test="$pLang='ar'">
                    <xsl:value-of select="',bi,fī,fīhi,fīhā,wa,aw,ilā,min,maʿa,ʿan,ʿalā,alā'"/>
                </xsl:when>
                <xsl:when test="$pLang='fr'">
                    <xsl:value-of select="',a,à,á,d,de,du,des,en,et,ou,un,une,la,le,les,sur'"/>
                </xsl:when>
                <xsl:when test="$pLang='en'">
                    <xsl:value-of
                        select="',a,an,and,as,at,by,but,during,from,for,in,is,it,its,of,on,or,nor,the,to,under,was,were'"
                    />
                </xsl:when>
                <xsl:when test="$pLang='de'">
                    <xsl:value-of
                        select="',auf,als,bei,der,die,das,des,den,dem,einer,eine,eines,einem,einen,für,im,ist,oder,und,unter,über,von,vom,zu,zur,zum'"
                    />
                </xsl:when>
                <!-- this is somewhat redundant, but safe -->
                <xsl:otherwise>
                    <xsl:value-of
                        select="',a,à,d,de,du,des,en,et,ou,un,une,la,le,les,sur,
                        ,an,and,as,at,by,but,during,from,for,in,is,it,its,of,on,or,nor,the,to,under,was,were,
                        ,auf,als,bei,der,die,das,den,dem,einer,eine,eines,einem,einen,für,im,ist,oder,und,unter,über,von,vom,zu,zur,zum,
                        ,bi,fī,fīhi,fīhā,wa,aw,ilā,min,maʿa,ʿan,ʿalā,alā,ve'"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="pProtectedStrings"
            select="'i,ii,iii,iv,v,vi,vii,viii,ix,x,ier,iie,iiie,ive,ve,vie,vii,viii,ixe,xe,xie,xii,xiie,xiii,xiiie,xiv,xive,xv,xve,xvi,xvie,xvii,xviie,xviii,xviiie,xix,xixe,xx,xxe,bss,yi,yı,ı,up,ddr,ei2'"/>

        <xsl:choose>
            <!-- the first xsl:when conditions split the input string at common punctuation marks -->
            <xsl:when test="contains($pString,':')">
                <xsl:analyze-string regex="(:\s*)" select="$pString">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:call-template name="funcStringCaps">
                            <xsl:with-param name="pString" select="normalize-space(.)"/>
                        </xsl:call-template>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:when test="contains($pString,'.')">
                <xsl:analyze-string regex="(\.\s*)" select="$pString">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:call-template name="funcStringCaps">
                            <xsl:with-param name="pString" select="normalize-space(.)"/>
                        </xsl:call-template>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:when test="contains($pString,'/')">
                <xsl:analyze-string regex="(/\s*)" select="$pString">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:call-template name="funcStringCaps">
                            <xsl:with-param name="pString" select="normalize-space(.)"/>
                        </xsl:call-template>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- Strings are split into words at spaces -->
            <xsl:otherwise>
                <xsl:for-each select="tokenize($pString,'(\s)')">
                    <xsl:variable name="vWord" select="lower-case(.)"/>
                    <!-- (\W) -->
                    <xsl:choose>
                        <!-- test for particles in transcriptions of Arabic -->
                        <xsl:when test="contains($vWord,'-')">
                            <xsl:analyze-string regex="(.*)\-(.*)" select=".">
                                <xsl:matching-substring>
                                    <xsl:call-template name="funcStringCaps">
                                        <xsl:with-param name="pString" select="regex-group(1)"/>
                                    </xsl:call-template>
                                    <xsl:text>-</xsl:text>
                                    <xsl:call-template name="funcStringCaps">
                                        <xsl:with-param name="pString" select="regex-group(2)"/>
                                    </xsl:call-template>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:when>
                        <xsl:when test="$vWord='al'">
                            <xsl:value-of select="'al'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='li'">
                            <xsl:value-of select="'li'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='wa'">
                            <xsl:value-of select="'wa'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='bi'">
                            <xsl:value-of select="'bi'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='l'">
                            <xsl:value-of select="'l'"/>
                        </xsl:when>
                        <!--<!-\- the following would cause all words beginning with ʿayn to be capitalised -\->
                        <xsl:when test="starts-with($vWord,'ʿ')">
                            <xsl:value-of select="'ʿ'"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>-->

                        <!-- test for particles in French -->
                        <xsl:when test="starts-with($vWord,'l''')">
                            <xsl:value-of select="'l'''"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,3)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'l’')">
                            <xsl:value-of select="'l'''"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,3)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- in case of d'un or d'une, this produces erroneous caps -->
                        <xsl:when test="starts-with($vWord,'d''')">
                            <xsl:value-of select="'d'''"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,3)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- test for brackets -->
                        <xsl:when test="starts-with($vWord,'(')">
                            <xsl:value-of select="'('"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'[')">
                            <xsl:value-of select="'['"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- this is done in the funcStringCleanTranscription -->
                        <!-- I change double quotation marks into singles for better readability -->
                        <xsl:when test="starts-with($vWord,'&quot;')">
                            <xsl:value-of select="'&quot;'"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'''')">
                            <xsl:value-of select="''''"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- Roman numerals should be protected from small-caps -->
                        <xsl:when test="contains($pProtectedStrings,$vWord)">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <!--  list of terms not to be capitalised, if they are not at the first position -->
                        <xsl:when test="contains($pLowerCaseStrings,$vWord)">
                            <xsl:choose>
                                <!-- this condition is always true for loops of single words -->
                                <xsl:when test="position()=1">
                                    <xsl:choose>
                                        <xsl:when test="starts-with($vWord,'ʿ')">
                                            <xsl:value-of select="'ʿ'"/>
                                            <xsl:value-of select="upper-case(substring($vWord,2,1))"/>
                                            <xsl:value-of select="lower-case(substring($vWord,3))"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="upper-case(substring($vWord,1,1))"/>
                                            <xsl:value-of select="lower-case(substring($vWord,2))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="lower-case($vWord)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!-- single letters not being part of $pLowerCaseStrings should be capitalised. This must come after the previous condition, as otherwise the letter "A" at the beginning of a string is not capitalised. -->
                        <xsl:when test="string-length($vWord)=1">
                            <xsl:choose>
                                <xsl:when
                                    test="not(contains($pLowerCaseStrings,concat(',',$vWord,',')))">
                                    <xsl:value-of select="upper-case($vWord)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="lower-case($vWord)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!-- the following would cause all words beginning with ʿayn to be capitalised -->
                        <xsl:when test="starts-with($vWord,'ʿ')">
                            <xsl:value-of select="'ʿ'"/>
                            <xsl:call-template name="funcStringCaps">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="upper-case(substring($vWord,1,1))"/>
                            <xsl:value-of select="lower-case(substring($vWord,2))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="not(position()=last())">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="funcStringCleanTranscription">
        <xsl:param name="pString"/>
        <!-- ar-Latn-x-ijmes: for Arabic in Latin transcription following IJMES conventions -->
        <xsl:param name="pLang" select="'ar-Latn-x-ijmes'"/>
        <xsl:choose>
            <xsl:when test="$pLang='ar-Latn-x-ijmes'">
                <xsl:choose>
                    <xsl:when test="contains(lower-case($pString),'wa al-')">
                        <xsl:call-template name="funcStringCleanTranscription">
                            <xsl:with-param name="pString"
                                select="replace($pString,'wa al-','wa-l-')"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'wa ')">
                        <xsl:call-template name="funcStringCleanTranscription">
                            <xsl:with-param name="pString" select="replace($pString,'wa ','wa-')"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'ilá')">
                        <xsl:call-template name="funcStringCleanTranscription">
                            <xsl:with-param name="pString" select="replace($pString,'ilá','ilā')"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'īya')">
                        <xsl:call-template name="funcStringCleanTranscription">
                            <xsl:with-param name="pString" select="replace($pString,'īya','iyya')"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'lil-')">
                        <xsl:call-template name="funcStringCleanTranscription">
                            <xsl:with-param name="pString" select="replace($pString,'lil-','li-l-')"
                            />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$pString"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="translate($pString,'‘’&quot;','''''''')"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
    <xsl:function name="till:funcStringCleanTranscription">
        <xsl:param name="pString"/>
        <!-- ar-Latn-x-ijmes: for Arabic in Latin transcription following IJMES conventions -->
        <xsl:param name="pLang"/>
        <xsl:choose>
            <xsl:when test="$pLang='ar-Latn-x-ijmes'">
                <xsl:choose>
                    <xsl:when test="contains(lower-case($pString),'wa al-')">
                        <xsl:value-of select="till:funcStringCleanTranscription(replace($pString,'wa al-','wa-l-'),'ar-Latn-x-ijmes')"/>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'wa ')">
                        <xsl:value-of select="till:funcStringCleanTranscription(replace($pString,'wa ','wa-'),'ar-Latn-x-ijmes')"/>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'ilá')">
                        <xsl:value-of select="till:funcStringCleanTranscription(replace($pString,'ilá','ilā'),'ar-Latn-x-ijmes')"/>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'īya')">
                        <xsl:value-of select="till:funcStringCleanTranscription(replace($pString,'īya','iyya'),'ar-Latn-x-ijmes')"/>
                    </xsl:when>
                    <xsl:when test="contains(lower-case($pString),'lil-')">
                        <xsl:value-of select="till:funcStringCleanTranscription(replace($pString,'lil-','li-l-'),'ar-Latn-x-ijmes')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$pString"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="translate($pString,'‘’&quot;','''''''')"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>

    <xsl:template name="funcStringRemoveTrailing">
        <xsl:param name="pString"/>
        <xsl:param name="pCharacters" select="'.'"/>
        <xsl:variable name="vString" select="normalize-space($pString)"/>
        <xsl:choose>
            <xsl:when test="substring($vString,string-length($vString),1)=$pCharacters">
                <xsl:value-of select="substring($vString,1,string-length($vString)-1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$vString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="funcStringTextDecoration">
        <xsl:param name="pInputString"/>
        <!-- mmd, html, docx, and tei -->
        <xsl:param name="pOutputFormat" select="'mmd'"/>
        <xsl:param name="pDecoration" select="'italics'"/>
        <xsl:choose>
            <xsl:when test="$pOutputFormat = 'mmd'">
                <xsl:choose>
                    <xsl:when test="$pDecoration = 'italics'">
                        <xsl:value-of select="concat('*',$pInputString,'*')"/>
                    </xsl:when>
                    <xsl:when test="$pDecoration = 'bold'">
                        <xsl:value-of select="concat('**',$pInputString,'**')"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$pOutputFormat = 'html'">
                <xsl:choose>
                    <xsl:when test="$pDecoration = 'italics'">
                        <em style="font-style:italic">
                            <xsl:value-of select="$pInputString"/>
                        </em>
                    </xsl:when>
                    <xsl:when test="$pDecoration = 'bold'">
                        <strong>
                            <xsl:value-of select="$pInputString"/>
                        </strong>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$pOutputFormat = 'tei'">
                <xsl:choose>
                    <xsl:when test="$pDecoration = 'italics'">
                        <tei:emph style="font-style:italic">
                            <xsl:value-of select="$pInputString"/>
                        </tei:emph>
                    </xsl:when>
                    <xsl:when test="$pDecoration = 'bold'">
                        <tei:emph style="font-weight:bold">
                            <xsl:value-of select="$pInputString"/>
                        </tei:emph>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$pOutputFormat = 'docx'">
                <xsl:choose>
                    <xsl:when test="$pDecoration = 'italics'">
                        <w:r w:rsidRPr="00F9512">
                            <w:rPr>
                                <w:rFonts w:ascii="Gentium Plus" w:hAnsi="Gentium Plus"/>
                                <w:i/>
                                <w:noProof/>
                                <w:sz w:val="18"/>
                                <w:szCs w:val="18"/>
                            </w:rPr>
                            <w:t>
                                <xsl:value-of select="$pInputString"/>
                            </w:t>
                        </w:r>
                    </xsl:when>
                    <xsl:when test="$pDecoration = 'bold'">
                        <w:r w:rsidRPr="00F9512">
                            <w:rPr>
                                <w:rFonts w:ascii="Gentium Plus" w:hAnsi="Gentium Plus"/>
                                <w:b/>
                                <w:noProof/>
                                <w:sz w:val="18"/>
                                <w:szCs w:val="18"/>
                            </w:rPr>
                            <w:t>
                                <xsl:value-of select="$pInputString"/>
                            </w:t>
                        </w:r>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="funcStringOxfordComma">
        <!-- needs nodes as input <till:li/> -->
        <xsl:param name="pLiInput"/>
        <xsl:for-each select="$pLiInput/till:li">
            <xsl:if test="position()&gt;=2">
                <xsl:if test="position()=last()">
                    <xsl:text> and </xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:value-of select="."/>
            <xsl:if test="not(position()=last())">
                <xsl:if test="count($pLiInput/till:li)&gt;2">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:function as="xs:string" name="functx:ordinal-number-en">
        <xsl:param name="num"/>

        <xsl:sequence
            select="
            concat(xs:string($num),
            if (matches(xs:string($num),'[04-9]$|1[1-3]$')) then 'th'
            else if (ends-with(xs:string($num),'1')) then 'st'
            else if (ends-with(xs:string($num),'2')) then 'nd'
            else if (ends-with(xs:string($num),'3')) then 'rd'
            else '')
            "/>

    </xsl:function>

    <!-- funcStringNER breaks an input string into words and checks an authority file for known canonical names. Positive hits are wrapped in a tei:name element with corresponding @nymRef attributes -->
    <!-- To do:
        - tei:form[lower-case(.)=lower-case($vWord)] is extremely slow
        - The function should break up strings containing variants of the Arabic definite article -->
    <xsl:template name="funcStringNER">
        <xsl:param name="pInput"/>
        <xsl:param name="pNymFile"
            select="document('/BachUni/projekte/XML/TEI XML/masterFiles/NymMaster.TEIP5.xml')"/>
        <!-- first we need to strip out possible plain text XML tags, e.g. &lt;persName&gt; -->
        <xsl:variable name="vInputClean">
            <xsl:analyze-string regex="&lt;//*\w+&gt;" select="$pInput">
                <xsl:matching-substring>
                    <xsl:value-of select="concat(' ',.,' ')"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>

        <!-- start by tokenizing the $vInputClean into words -->
        <xsl:variable name="vInputTokenized">
            <xsl:call-template name="funcStringTokenize">
                <xsl:with-param name="pInput" select="$vInputClean"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- the issue of trailing points cannot be solved in the regex, as they should be included in some but not all cases, i.e. in the case of "Dr.", "Ef." or "Moh.d" the point should be included, in the case of a name at the end of the sentence, such as "Muṣṭafā.", it should not. -->
        <!-- regex="(al\-)*([\w.]+)(\W*)" -->

        <xsl:apply-templates mode="mNER" select="$vInputTokenized/tei:w[1]">
            <xsl:with-param name="pNymFile" select="$pNymFile"/>
        </xsl:apply-templates>
    </xsl:template>
    
    

    <!-- mNER: adding natural entity recognition for names for mixed-content nodes containing tei:w and tei:pc nodes. It should only be run on the first tei:w child node, as it then iterates through all following. This is necessary, as it also tries to catch nyms for compound names, such as "Badr al-Dīn" -->
    <xsl:template match="tei:w" mode="mNER">
        <xsl:param name="pNymFile"
            select="document('/BachUni/projekte/XML/TEI XML/masterFiles/NymMaster.TEIP5.xml')"/>

        <xsl:variable name="vWord1" select="."/>
        <xsl:variable name="vWord2" select="following::tei:w[1]"/>
        <xsl:variable name="vWord1and2" select="concat($vWord1,' ',$vWord2)"/>
        <xsl:choose>
            <!-- check if the current word and the immediately following word form a known compound name -->
            <xsl:when
                test="$pNymFile//tei:listNym[not(@type='entity')][not(@type='location')]//tei:form[.=$vWord1and2]">
                <xsl:element name="tei:name">
                    <xsl:variable name="vNymRef"
                        select="till:funcNymRefLookup($vWord1and2, $pNymFile)"/>
                    <xsl:attribute name="nymRef" select="$vNymRef"/>
                    <xsl:value-of select="$vWord1and2"/>
                </xsl:element>
                <xsl:if test="$vWord2/following::node()[1][self::tei:pc]">
                    <xsl:value-of select="$vWord2/following::node()[1]"/>
                </xsl:if>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="mNER" select="following::tei:w[2]">
                    <xsl:with-param name="pNymFile" select="$pNymFile"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- check if the current word and the immediately following word form a known compound name that ends with a period -->
            <xsl:when
                test="ends-with($vWord1and2,'.') and $pNymFile//tei:listNym[not(@type='entity')][not(@type='location')]//tei:form[.=substring($vWord1and2,1,(string-length($vWord1and2)-1))]">
                <xsl:element name="tei:name">
                    <xsl:variable name="vNymRef"
                        select="till:funcNymRefLookup(substring($vWord1and2,1,(string-length($vWord1and2)-1)), $pNymFile)"/>
                    <xsl:attribute name="nymRef" select="$vNymRef"/>
                    <xsl:value-of select="substring($vWord1and2,1,(string-length($vWord1and2)-1))"/>
                </xsl:element>
                <xsl:text>.</xsl:text>
                <xsl:if test="$vWord2/following::node()[1][self::tei:pc]">
                    <xsl:value-of select="$vWord2/following::node()[1]"/>
                </xsl:if>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="mNER" select="following::tei:w[2]">
                    <xsl:with-param name="pNymFile" select="$pNymFile"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- check if the current word is a known nym -->
            <xsl:when
                test="$pNymFile//tei:listNym[not(@type='entity')][not(@type='location')]//tei:form[.=$vWord1]">
                <xsl:element name="tei:name">
                    <xsl:variable name="vNymRef" select="till:funcNymRefLookup($vWord1, $pNymFile)"/>
                    <xsl:attribute name="nymRef" select="$vNymRef"/>
                    <xsl:value-of select="$vWord1"/>
                </xsl:element>
                <xsl:apply-templates mode="mNER" select="following::node()[1]">
                    <xsl:with-param name="pNymFile" select="$pNymFile"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- check if a word, which was not caught by the earlier conditions, ends with a period and check for a known nym without the period -->
            <xsl:when test="ends-with($vWord1,'.')">
                <xsl:variable name="vWord-1"
                    select="substring($vWord1,1,(string-length($vWord1)-1))"/>
                <xsl:choose>
                    <xsl:when
                        test="$pNymFile//tei:listNym[not(@type='entity')][not(@type='location')]//tei:form[.=$vWord-1]">
                        <xsl:element name="tei:name">
                            <xsl:variable name="vNymRef"
                                select="till:funcNymRefLookup($vWord-1, $pNymFile)"/>
                            <xsl:attribute name="nymRef" select="$vNymRef"/>
                            <xsl:value-of select="$vWord-1"/>
                        </xsl:element>
                        <xsl:text>.</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$vWord1"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates mode="mNER" select="following::node()[1]">
                    <xsl:with-param name="pNymFile" select="$pNymFile"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- check if a word, which was not caught by the earlier conditions, ends with a dash and check for a known nym without the dash -->
            <xsl:when test="ends-with($vWord1,'-')">
                <xsl:variable name="vWord-1"
                    select="substring($vWord1,1,(string-length($vWord1)-1))"/>
                <xsl:choose>
                    <xsl:when
                        test="$pNymFile//tei:listNym[not(@type='entity')][not(@type='location')]//tei:form[.=$vWord-1]">
                        <xsl:element name="tei:name">
                            <xsl:variable name="vNymRef"
                                select="till:funcNymRefLookup($vWord-1, $pNymFile)"/>
                            <xsl:attribute name="nymRef" select="$vNymRef"/>
                            <xsl:value-of select="$vWord-1"/>
                        </xsl:element>
                        <xsl:text> -</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$vWord1"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates mode="mNER" select="following::node()[1]">
                    <xsl:with-param name="pNymFile" select="$pNymFile"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$vWord1"/>
                <!-- <xsl:if test="following::node()[1][self::text()] and following::node()[2][self::tei:pc]">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="following::node()[2]"/>
                </xsl:if>-->
                <!--<xsl:if test="following::node()[1][not(self::tei:w)]">
                    <xsl:value-of select="following::node()[1]"/>
                </xsl:if>-->
                <xsl:apply-templates mode="mNER" select="following::node()[1]">
                    <xsl:with-param name="pNymFile" select="$pNymFile"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="node()" mode="mNER">
        <xsl:param name="pNymFile"/>
        <xsl:value-of select="."/>
        <xsl:apply-templates mode="mNER" select="following::node()[1]">
            <xsl:with-param name="pNymFile" select="$pNymFile"/>
        </xsl:apply-templates>
    </xsl:template>


    <!-- this template is a rather early draft -->
    <xsl:template name="funcNymRefLookup">
        <xsl:param name="pInput"/>
        <xsl:param name="pNymFile"
            select="document('/BachUni/projekte/XML/TEI XML/master files/NymMasterTEI.xml')"/>
        <xsl:for-each
            select="$pNymFile/descendant::tei:listNym[not(@type='entity')][not(@type='location')]/descendant::tei:form[.=$pInput]">
            <xsl:value-of select="'#'"/>
            <xsl:value-of select="parent::node()/@xml:id"/>
            <xsl:if test="position()!=last()">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:function name="till:funcNymRefLookup">
        <xsl:param name="pInput"/>
        <xsl:param name="pNymFile"/>
        <xsl:for-each
            select="$pNymFile/descendant::tei:listNym[not(@type='entity')][not(@type='location')]/descendant::tei:form[.=$pInput]">
            <xsl:value-of select="concat('#',parent::node()/@xml:id)"/>
            <xsl:if test="position()!=last()">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>
    
    
    <!-- this function corrects Sente's faulty escaping in text nodes:
        - linebreaks: Sente escapes them without a closing tag, i.e. "&lt;br&gt;"
        - tags within text nodes: Sente double-escapes the ampersand, i.e. "&amp;lt;" instead of "&lt;"-->
    <xsl:function name="till:funcStringCorrectSenteEscaping">
        <xsl:param name="pInput"/>
        <xsl:choose>
            <!-- correct smart quotes -->
            <xsl:when test="contains($pInput,'“')">
                <xsl:value-of select="till:funcStringCorrectSenteEscaping(replace($pInput,'“','&quot;'))"/>
            </xsl:when>
            <xsl:when test="contains($pInput,'”')">
                <xsl:value-of select="till:funcStringCorrectSenteEscaping(replace($pInput,'”','&quot;'))"/>
            </xsl:when>
            <!-- correct Sente's unclosed <br> tags -->
            <xsl:when test="contains($pInput,'&lt;br&gt;')">
                <xsl:value-of select="till:funcStringCorrectSenteEscaping(replace($pInput,'&lt;br&gt;','&lt;br/&gt;'))"/>
            </xsl:when>
            <!-- correct my faulty encoding of unclosed <pb> tags -->
            <xsl:when test="contains($pInput,'&lt;pb&gt;')">
                <xsl:value-of select="till:funcStringCorrectSenteEscaping(replace($pInput,'&lt;pb&gt;','&lt;pb/&gt;'))"/>
            </xsl:when>
            <xsl:when test="contains($pInput,'&amp;lt;')">
                <xsl:value-of select="till:funcStringCorrectSenteEscaping(replace($pInput,'&amp;lt;','&lt;'))"/>
            </xsl:when>
            <xsl:when test="contains($pInput,'&amp;gt;')">
                <xsl:value-of  select="till:funcStringCorrectSenteEscaping(replace($pInput,'&amp;gt;','&gt;'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$pInput"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- v1d: this template capitalises only the first word of a string. It is far too bloated for this simple task -->
    <xsl:template name="funcStringCapsFirst">
        <xsl:param name="pString"/>
        <xsl:param name="pLang"/>
        <xsl:param name="pPos" select="1"/>
        <xsl:param name="pLowerCaseStrings">
            <xsl:choose>
                <xsl:when test="$pLang='ar'">
                    <xsl:value-of select="',bi,fī,fīhi,fīhā,wa,aw,ilā,min,maʿa,ʿan,ʿalā,alā'"/>
                </xsl:when>
                <xsl:when test="$pLang='fr'">
                    <xsl:value-of select="',a,à,á,d,de,du,des,en,et,ou,un,une,la,le,les,sur'"/>
                </xsl:when>
                <xsl:when test="$pLang='en'">
                    <xsl:value-of
                        select="',a,an,and,as,at,by,but,during,from,for,in,is,it,its,of,on,or,nor,the,to,under,was,were'"
                    />
                </xsl:when>
                <xsl:when test="$pLang='de'">
                    <xsl:value-of
                        select="',auf,als,bei,der,die,das,den,dem,einer,eine,eines,einem,einen,für,im,ist,oder,und,unter,über,von,vom,zu,zur,zum'"
                    />
                </xsl:when>
                <!-- this is somewhat redundant, but safe -->
                <xsl:otherwise>
                    <xsl:value-of
                        select="',a,à,d,de,du,des,en,et,ou,un,une,la,le,les,sur,
                        ,an,and,as,at,by,but,during,from,for,in,is,it,its,of,on,or,nor,the,to,under,was,were,
                        ,auf,als,bei,der,die,das,den,dem,einer,eine,eines,einem,einen,für,im,ist,oder,und,unter,über,von,vom,zu,zur,zum,
                        ,bi,fī,fīhi,fīhā,wa,aw,ilā,min,maʿa,ʿan,ʿalā,alā,ve'"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="pProtectedStrings"
            select="'i,ii,iii,iv,v,vi,vii,viii,ix,x,ier,iie,iiie,ive,ve,vie,vii,viii,ixe,xe,xie,xii,xiie,xiii,xiiie,xiv,xive,xv,xve,xvi,xvie,xvii,xviie,xviii,xviiie,xix,xixe,xx,xxe,bss,yi,yı,ı,up,ddr,ei2'"/>

        <xsl:choose>
            <!-- the first xsl:when conditions split the input string at common punctuation marks -->
            <xsl:when test="contains($pString,':')">
                <xsl:analyze-string regex="(:\s*)" select="$pString">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:call-template name="funcStringCapsFirst">
                            <xsl:with-param name="pString" select="normalize-space(.)"/>
                        </xsl:call-template>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:when test="contains($pString,'.')">
                <xsl:analyze-string regex="(\.\s*)" select="$pString">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:call-template name="funcStringCapsFirst">
                            <xsl:with-param name="pString" select="normalize-space(.)"/>
                        </xsl:call-template>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:when test="contains($pString,'/')">
                <xsl:analyze-string regex="(/\s*)" select="$pString">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:call-template name="funcStringCapsFirst">
                            <xsl:with-param name="pString" select="normalize-space(.)"/>
                        </xsl:call-template>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>

            <!-- Strings are split into words at spaces -->
            <xsl:otherwise>
                <xsl:for-each select="tokenize($pString,'(\s+)')[position()=$pPos]">
                    <xsl:variable name="vWord" select="lower-case(.)"/>
                    <!--                    <xsl:message select="$vWord"/>-->
                    <!-- (\W) -->
                    <xsl:choose>
                        <xsl:when test="contains($vWord,'-')">
                            <xsl:analyze-string regex="(.*)\-(.*)" select=".">
                                <xsl:matching-substring>
                                    <xsl:call-template name="funcStringCapsFirst">
                                        <xsl:with-param name="pString" select="regex-group(1)"/>
                                    </xsl:call-template>
                                    <xsl:text>-</xsl:text>
                                    <xsl:call-template name="funcStringCapsFirst">
                                        <xsl:with-param name="pString" select="regex-group(2)"/>
                                    </xsl:call-template>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:when>
                        <xsl:when test="$vWord='al'">
                            <xsl:value-of select="'al'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='li'">
                            <xsl:value-of select="'li'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='wa'">
                            <xsl:value-of select="'wa'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='bi'">
                            <xsl:value-of select="'bi'"/>
                        </xsl:when>
                        <xsl:when test="$vWord='l'">
                            <xsl:value-of select="'l'"/>
                        </xsl:when>
                        <!-- the following would cause words beginning with ʿayn to be capitalised -->
                        <xsl:when test="starts-with($vWord,'ʿ')">
                            <xsl:value-of select="'ʿ'"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'l''')">
                            <xsl:value-of select="'l'''"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,3)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'l’')">
                            <xsl:value-of select="'l'''"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,3)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- in case of d'un or d'une, this produces erroneous caps -->
                        <xsl:when test="starts-with($vWord,'d''')">
                            <xsl:value-of select="'d'''"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,3)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'(')">
                            <xsl:value-of select="'('"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'[')">
                            <xsl:value-of select="'['"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- this is done in the funcStringCleanTranscription -->
                        <!-- I change double quotation marks into singles for better readability -->
                        <xsl:when test="starts-with($vWord,'&quot;')">

                            <xsl:value-of select="'&quot;'"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="starts-with($vWord,'''')">
                            <xsl:value-of select="''''"/>
                            <xsl:call-template name="funcStringCapsFirst">
                                <xsl:with-param name="pString" select="substring($vWord,2)"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- Roman numerals should be protected from small-caps -->
                        <xsl:when test="contains($pProtectedStrings,$vWord)">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <!-- single letters not being part of $pLowerCaseStrings should be capitalised -->
                        <xsl:when test="string-length($vWord)=1">
                            <xsl:choose>
                                <xsl:when
                                    test="not(contains($pLowerCaseStrings,concat(',',$vWord,',')))">
                                    <xsl:value-of select="upper-case($vWord)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="lower-case($vWord)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!--  list of terms not to be capitalised, if they are not at the first position -->
                        <xsl:when test="contains($pLowerCaseStrings,$vWord)">
                            <xsl:choose>
                                <!-- this condition is always true for loops of single words -->
                                <xsl:when test="position()=1">
                                    <xsl:choose>
                                        <xsl:when test="starts-with($vWord,'ʿ')">
                                            <xsl:value-of select="'ʿ'"/>
                                            <xsl:value-of select="upper-case(substring($vWord,2,1))"/>
                                            <xsl:value-of select="lower-case(substring($vWord,3))"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="upper-case(substring($vWord,1,1))"/>
                                            <xsl:value-of select="lower-case(substring($vWord,2))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="lower-case($vWord)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="upper-case(substring($vWord,1,1))"/>
                            <xsl:value-of select="lower-case(substring($vWord,2))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="not(position()=last())">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="tokenize($pString,'(\s+)')[not(position()=$pPos)]">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="lower-case(.)"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!-- v1d: testing -->
    <xsl:template name="funcStringExtractCurrencies">
        <xsl:param name="pInput"/>
        <xsl:variable name="vOutput">
            <xsl:analyze-string regex="(\d+)\s+(para)" select="$pInput">
                <xsl:matching-substring>
                    <xsl:variable name="vAmount" select="number(regex-group(1))"/>
                    <xsl:text>Ps </xsl:text>
                    <xsl:call-template name="funcCurExchange">
                        <xsl:with-param name="pD" select="$vAmount"/>
                        <xsl:with-param name="pCurInput" select="'Ottoman'"/>
                        <xsl:with-param name="pCurTarget" select="'Ottoman'"/>
                        <xsl:with-param name="pRate" select="100"/>
                    </xsl:call-template>
                    <xsl:text>; </xsl:text>
                </xsl:matching-substring>
            </xsl:analyze-string>
            <xsl:analyze-string regex="(\d+)\s+(piast\w+)" select="$pInput">
                <xsl:matching-substring>
                    <xsl:variable name="vAmount" select="number(regex-group(1))"/>
                    <xsl:text>Ps </xsl:text>
                    <xsl:call-template name="funcCurExchange">
                        <xsl:with-param name="pS" select="$vAmount"/>
                        <xsl:with-param name="pCurInput" select="'Ottoman'"/>
                        <xsl:with-param name="pCurTarget" select="'Ottoman'"/>
                        <xsl:with-param name="pRate" select="100"/>
                    </xsl:call-template>
                    <xsl:text>; </xsl:text>
                </xsl:matching-substring>
            </xsl:analyze-string>
            <xsl:analyze-string regex="(£T)\s+(\d+)" select="$pInput">
                <xsl:matching-substring>
                    <xsl:variable name="vAmount" select="number(regex-group(2))"/>
                    <xsl:text>Ps </xsl:text>
                    <xsl:call-template name="funcCurExchange">
                        <xsl:with-param name="pL" select="$vAmount"/>
                        <xsl:with-param name="pCurInput" select="'Ottoman'"/>
                        <xsl:with-param name="pCurTarget" select="'Ottoman'"/>
                        <xsl:with-param name="pRate" select="100"/>
                    </xsl:call-template>
                    <xsl:text>; </xsl:text>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>

        <xsl:analyze-string regex="(Ps)\s+(\d+)\-(\d+)" select="$vOutput">
            <xsl:matching-substring>
                <xsl:element name="tei:measure">
                    <xsl:attribute name="type" select="'currency'"/>
                    <xsl:attribute name="unit">
                        <!-- this should contain a nummerical decimal, i.e. normalised, value  -->
                    </xsl:attribute>
                    <xsl:value-of select="regex-group(1)"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="regex-group(2)"/>
                    <xsl:text>&quot;</xsl:text>
                    <xsl:value-of select="regex-group(3)"/>
                </xsl:element>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <!-- try to recognise prices and mark them up in TEI -->
    <xsl:function name="till:funcStringNERCurrency">
        <xsl:param name="pInput" as="xs:string"/>
        <xsl:analyze-string select="$pInput" regex="(\w+)\s*(\d+&quot;*\d*)">
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="lower-case(regex-group(1))=('ps', 'piaster', 'pias')">
                        <xsl:variable name="vQuantity" select="regex-group(2)"/>
                        <xsl:variable name="vQuantityDecimal">
                            <xsl:call-template name="funcCurDecimal">
                                <xsl:with-param name="pCurInput" select="'Ottoman'"/>
                                <xsl:with-param name="pInput" select="concat('0-',$vQuantity)"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:element name="measure">
                            <xsl:attribute name="commodity" select="'currency'"/>
                            <xsl:attribute name="unit" select="'ops'"/>
                            <xsl:attribute name="quantity" select="$vQuantityDecimal"/>
                            <xsl:value-of select="."/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="lower-case(regex-group(1))=('£t','ltq')">
                        <xsl:variable name="vQuantity" select="regex-group(2)"/>
                        <!-- probably this computation is unnecessary -->
                        <xsl:variable name="vQuantityDecimal">
                            <xsl:call-template name="funcCurDecimal">
                                <xsl:with-param name="pCurInput" select="'Ottoman'"/>
                                <xsl:with-param name="pInput" select="$vQuantity"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:element name="measure">
                            <xsl:attribute name="commodity" select="'currency'"/>
                            <xsl:attribute name="unit" select="'ops'"/>
                            <xsl:attribute name="quantity" select="$vQuantityDecimal"/>
                            <xsl:value-of select="."/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    

    <xsl:template name="funcStringLanguageTest">
        <xsl:param name="pInput"/>
        <!-- This can take the values "short" and "long" -->
        <xsl:param name="pOutputFormat" select="'short'"/>
        <xsl:variable name="vInput" select="lower-case($pInput)"/>
        <xsl:variable name="vArabic"
            select="'bi','fī','fīhi','fīhā','wa','aw','ilā','min','maʿa','ʿan','ʿalā','alā','li-','wa-'"/>
        <xsl:variable name="vFrench"
            select="'à','á','d','dans','de','du','en','et','ou','un','une','la','le','les','sur'"/>
        <xsl:variable name="vGerman"
            select="'auf','als','bei','bis','der','die','das','den','dem','einer','eine','eines','einem','einen','für','im','ist','oder','und','unter','über','von','vom','zu','zur','zum'"/>
        <xsl:variable name="vOttoman" select="'-yi','-i','-ı'"/>
        <xsl:variable name="vTurkish" select="'ve'"/>
        <xsl:variable name="vEnglish"
            select="'an','and','as','at','by','but','during','from','for','in','is','it','its','of','on','or','nor','the','to','under','was','with','were'"/>

        <!-- the template should look at every word and test if it is part of a language variable -->
        <xsl:variable name="vLangAuto">
            <xsl:choose>
                <xsl:when test="tokenize($vInput,'\W')=($vArabic)">
                    <xsl:text>ar</xsl:text>
                </xsl:when>
                <xsl:when test="tokenize($vInput,'\W')=($vFrench)">
                    <xsl:text>fr</xsl:text>
                </xsl:when>
                <xsl:when test="tokenize($vInput,'\W')=($vGerman)">
                    <xsl:text>de</xsl:text>
                </xsl:when>
                <xsl:when test="tokenize($vInput,'\W')=($vOttoman)">
                    <xsl:text>ota</xsl:text>
                </xsl:when>
                <xsl:when test="tokenize($vInput,'\W')=($vTurkish)">
                    <xsl:text>tr</xsl:text>
                </xsl:when>
                <xsl:when test="tokenize($vInput,'\W')=($vEnglish)">
                    <xsl:text>en</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$pOutputFormat = 'short'">
                <xsl:value-of select="$vLangAuto"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$vLangAuto='ar'">
                        <xsl:text>Arabic</xsl:text>
                    </xsl:when>
                    <xsl:when test="$vLangAuto='de'">
                        <xsl:text>German</xsl:text>
                    </xsl:when>
                    <xsl:when test="$vLangAuto='fr'">
                        <xsl:text>French</xsl:text>
                    </xsl:when>
                    <xsl:when test="$vLangAuto='tr'">
                        <xsl:text>Turkish</xsl:text>
                    </xsl:when>
                    <xsl:when test="$vLangAuto='ota'">
                        <xsl:text>Ottoman Turkish</xsl:text>
                    </xsl:when>
                    <xsl:when test="$vLangAuto='en'">
                        <xsl:text>English</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="funcStringTokenize">
        <xsl:param name="pInput"/>
        <!-- periods and dashes are included in the word tokens, as they could mark abbreviations or the Arabic article "al-" -->
        <!-- ([\w]+[\.&apos;\-]*[\w]+[\.]*) -->
        <xsl:analyze-string regex="([\w\.&apos;:\-]+)" select="$pInput">
            <!-- consider the first group to be a word -->
            <xsl:matching-substring>
                <xsl:analyze-string regex="(.+)([&apos;:\-])(\w?)$" select="regex-group(1)">
                    <xsl:matching-substring>
                        <xsl:element name="tei:w">
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:element>
                        <xsl:element name="tei:pc">
                            <xsl:value-of select="regex-group(2)"/>
                        </xsl:element>
                        <xsl:if test="regex-group(3)!=''">
                            <xsl:element name="tei:w">
                                <xsl:value-of select="regex-group(3)"/>
                            </xsl:element>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:element name="tei:w">
                            <xsl:value-of select="."/>
                        </xsl:element>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!-- consider the first group to be a punctuation mark -->
                <xsl:analyze-string regex="([,;\.–—\(\)&apos;:\[\]&lt;&gt;])" select=".">
                    <xsl:matching-substring>
                        <xsl:element name="tei:pc">
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <!-- the remnants should be whitespaces only -->
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

    <!-- v1f: testing -->
    <xsl:template name="funcStringNERDates">
        <xsl:param name="pInput"/>
        <!-- 1. round: test for yyyy-mm-dd, d.m.yyyy,  4(.) Apr(.) 1887, July 4(th), 2005. The alternative regex are separated by the pipe character -->
        <xsl:analyze-string select="$pInput" regex="(\d{{4}}\-\d{{2}}\-\d{{2}})|(\d{{1,2}})\.\s*(\d{{1,2}})\.\s*(\d{{4}})|(\d{{1,2}})(\.|\s+|\.\s+)(\w[\D\s]+)\.*\s+(\d{{4}})|(\w+)\.*\s+(\d{{1,2}})(\.|st|nd|rd|th)*,\s+(\d{{4}})">
            <xsl:matching-substring>
                    <!-- content of the @when must either be computed or can be parsed straight away -->
                        <xsl:choose>
                            <!-- test for yyyy-mm-dd -->
                            <xsl:when test="matches(.,'\d{4}\-\d{2}\-\d{2}')">
                                <xsl:element name="tei:date">
                                <xsl:attribute name="when" select="."/>
                                    <xsl:value-of select="."/>
                                </xsl:element>
                            </xsl:when>
                            <!-- test for d.m.yyyy -->
                            <xsl:when test="matches(.,'(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})')">
                                <xsl:element name="tei:date">
                                <xsl:attribute name="when">
                                <xsl:value-of select="regex-group(4)"/>
                                <xsl:text>-</xsl:text>
                                    <!-- format-number(number(regex-group(5)),'00') -->
                                    <xsl:value-of select="format-number(number(regex-group(3)),'00')"/>
                                <xsl:text>-</xsl:text>
                                    <xsl:value-of select="format-number(number(regex-group(2)),'00')"/>
                                </xsl:attribute>
                                    <xsl:value-of select="."/>
                                </xsl:element>
                            </xsl:when>
                            <!-- test for 4(.) Apr(.) 1887 -->
                            <xsl:when test="matches(.,'(\d{1,2})(\.|\s+|\.\s+)(\w[\D\s]+)\s+(\d{4})')">
                                <!-- we have to call a function identifying the month. This function is language independent -->
                                <xsl:variable name="vMonth">
                                    <xsl:value-of select="till:funcStringNERDateMN(regex-group(7))"/>
                                </xsl:variable>
                                <!-- if the word is not a month, $vMonth won't return a number -->
                                <xsl:choose>
                                    <xsl:when test="matches($vMonth,'\d+')">
                                        <xsl:element name="tei:date">
                                        <xsl:attribute name="when">
                                            <xsl:value-of select="regex-group(8)"/>
                                            <xsl:text>-</xsl:text>
                                            <xsl:value-of select="format-number($vMonth,'00')"/>
                                            <xsl:text>-</xsl:text>
                                            <xsl:value-of select="format-number(number(regex-group(5)),'00')"/>
                                        </xsl:attribute>
                                            <xsl:value-of select="."/>
                                        </xsl:element>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="."/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <!-- test for Apr(.) 4(th), 1887  -->
                            <xsl:when test="matches(.,'(\w+)\.*\s+(\d{1,2})(\.|st|nd|rd|th)*,\s+(\d{4})')">
                                <xsl:variable name="vMonth">
                                    <xsl:value-of select="till:funcStringNERDateMN(regex-group(9))"/>
                                </xsl:variable>
                                <!-- if the word is not a month, $vMonth won't return a number -->
                                <xsl:choose>
                                    <xsl:when test="matches($vMonth,'\d+')">
                                        <xsl:element name="tei:date">
                                            <xsl:attribute name="when">
                                                <xsl:value-of select="regex-group(12)"/>
                                                <xsl:text>-</xsl:text>
                                                <xsl:value-of select="format-number($vMonth,'00')"/>
                                                <xsl:text>-</xsl:text>
                                                <xsl:value-of select="format-number(number(regex-group(10)),'00')"/>
                                            </xsl:attribute>
                                            <xsl:value-of select="."/>
                                        </xsl:element>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="."/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                        </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:analyze-string select="." regex="(سنة)\s+(\d{{3,4}})">
                    <xsl:matching-substring>
                        <xsl:element name="tei:date">
                            <xsl:attribute name="when" select="regex-group(2)"/>
                            <xsl:value-of select="."/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
   
    <!--  XPath function  to establish months -->
    <xsl:function name="till:funcStringNERDateMN">
        <!-- this function returns a number -->
        <xsl:param name="pInput"/>
        <xsl:variable name="vInputLC" select="lower-case($pInput)"/>
        <xsl:variable name="vMonthNyms">
            <!-- Hijri: Muḥarram,Ṣafār,Rabīʿ al-awwal,Rabīʿ al-thānī,Jumāda al-ulā,Jumāda al-tāniya,Rajab,Shaʿbān,Ramaḍān,Shawwāl,Dhū al-qaʿda,Dhū al-ḥijja -->
            <!-- Hijri abb: Muḥ,Ṣaf,Rab I,Rab II,Jum I,Jum II,Raj,Shaʿ,Ram,Shaw,Dhu I,Dhu II -->
            <!-- Turk: Ocak,Şubat,Mart,Nisan,Mayıs,Haziran,Temmuz,Ağustos,Eylül,Ekim,Kasım,Aralık -->
            <tei:nymList n="cal_gregorian">
                <tei:nym n="1">
                <tei:form xml:lang="en">january</tei:form>
                <tei:form xml:lang="fr">janvier</tei:form>
                <tei:form xml:lang="tr">ocak</tei:form>
                    <tei:form xml:lang="ar">يناير</tei:form>
            </tei:nym>
            <tei:nym n="2">
                <tei:form xml:lang="en">february</tei:form>
                <tei:form xml:lang="fr">février</tei:form>
                <tei:form xml:lang="tr">şubat</tei:form>
                <tei:form xml:lang="ar">فبراير</tei:form>
            </tei:nym>
            <tei:nym n="3">
                <tei:form xml:lang="de">märz</tei:form>
                <tei:form xml:lang="en">march</tei:form>
                <tei:form xml:lang="fr">mars</tei:form>
                <tei:form xml:lang="tr">mart</tei:form>
                <tei:form xml:lang="ar">مارس</tei:form>
            </tei:nym>
            <tei:nym n="4">
                <tei:form xml:lang="en de">april</tei:form>
                <tei:form xml:lang="fr">avril</tei:form>
                <tei:form xml:lang="tr">nisan</tei:form>
                <tei:form xml:lang="ar">ابريل</tei:form>
            </tei:nym>
            <tei:nym n="5">
                <tei:form xml:lang="en">may</tei:form>
                <tei:form xml:lang="de fr">mai</tei:form>
                <tei:form xml:lang="tr">mayıs</tei:form>
                <tei:form xml:lang="ar">مايو</tei:form>
            </tei:nym>
            <tei:nym n="6">
                <tei:form xml:lang="de">juni</tei:form>
                <tei:form xml:lang="en">june</tei:form>
                <tei:form xml:lang="fr">juin</tei:form>
                <tei:form xml:lang="tr">haziran</tei:form>
                <tei:form xml:lang="ar">يونيو</tei:form>
            </tei:nym>
            <tei:nym n="7">
                <tei:form xml:lang="en">july</tei:form>
                <tei:form xml:lang="de">juli</tei:form>
                <tei:form xml:lang="fr">juillet</tei:form>
                <tei:form xml:lang="tr">temmuz</tei:form>
                <tei:form xml:lang="ar">يوليو</tei:form>
            </tei:nym>
            <tei:nym n="8">
                <tei:form xml:lang="en de">august</tei:form>
                <tei:form xml:lang="fr">août</tei:form>
                <tei:form xml:lang="tr">ağustos</tei:form>
                <tei:form xml:lang="ar"></tei:form>
            </tei:nym>
            <tei:nym n="9">
                <tei:form xml:lang="en de">september</tei:form>
                <tei:form xml:lang="fr">septembre</tei:form>
                <tei:form xml:lang="tr">eylül</tei:form>
                <tei:form xml:lang="ar"></tei:form>
            </tei:nym>
            <tei:nym n="10">
                <tei:form xml:lang="de">oktober</tei:form>
                <tei:form xml:lang="en">october</tei:form>
                <tei:form xml:lang="fr">octobre</tei:form>
                <tei:form xml:lang="tr">ekim</tei:form>
                <tei:form xml:lang="ar">اكتوبر</tei:form>
            </tei:nym>
            <tei:nym n="11">
                <tei:form xml:lang="en de">november</tei:form>
                <tei:form xml:lang="fr">novembre</tei:form>
                <tei:form xml:lang="tr">kasım</tei:form>
                <tei:form xml:lang="ar">نوفمبر</tei:form>
            </tei:nym>
            <tei:nym n="12">
                <tei:form xml:lang="de">dezember</tei:form>
                <tei:form xml:lang="en">december</tei:form>
                <tei:form xml:lang="fr">décembre</tei:form>
                <tei:form xml:lang="tr">aralık</tei:form>
                <tei:form xml:lang="ar">ديسمبر</tei:form>
            </tei:nym>
            </tei:nymList>
            <!--<tei:nymList n="cal_Muslim">
                <tei:nym n="1">
                    <tei:form xml:lang="ar-Latn-x-ijmes">muḥarram</tei:form>
                </tei:nym>
                <tei:nym n="2">
                    <tei:form xml:lang="ar-Latn-x-ijmes">ṣafār</tei:form>
                </tei:nym>
                <tei:nym n="3">
                    <tei:form xml:lang="ar-Latn-x-ijmes">rabīʿ al-awwal</tei:form>
                    <tei:form>rab i</tei:form>
                </tei:nym>
                <tei:nym n="4">
                    <tei:form xml:lang="ar-Latn-x-ijmes">rabīʿ al-thānī</tei:form>
                    <tei:form>rab ii</tei:form>
                </tei:nym>
                <tei:nym n="5">
                   <tei:form xml:lang="ar-Latn-x-ijmes">jumāda al-ulā</tei:form>
                    <tei:form>jum i</tei:form>
                </tei:nym>
                <tei:nym n="6">
                    <tei:form xml:lang="ar-Latn-x-ijmes">jumāda al-thāniyya</tei:form>
                    <tei:form>jum ii</tei:form>
                </tei:nym>
                <tei:nym n="7">
                    <tei:form xml:lang="ar-Latn-x-ijmes">rajab</tei:form>
                </tei:nym>
                <tei:nym n="8">
                    <tei:form xml:lang="ar-Latn-x-ijmes">shaʿbān</tei:form>
                </tei:nym>
                <tei:nym n="9">
                    <tei:form xml:lang="ar-Latn-x-ijmes">ramaḍān</tei:form>
                </tei:nym>
                <tei:nym n="10">
                    <tei:form xml:lang="ar-Latn-x-ijmes">shawwāl</tei:form>
                </tei:nym>
                <tei:nym n="11">
                    <tei:form xml:lang="ar-Latn-x-ijmes">dhū al-qaʿda</tei:form>
                    <tei:form>dhu i</tei:form>
                </tei:nym>
                <tei:nym n="12">
                    <tei:form xml:lang="ar-Latn-x-ijmes">dhū al-ḥijja</tei:form>
                    <tei:form>dhu ii</tei:form>
                </tei:nym>
            </tei:nymList>-->
        </xsl:variable>
        <!-- this way of doing it will return multiple possitive hits for abbreviations of many months. -->
        <xsl:for-each select="$vMonthNyms//tei:form">
            <xsl:if test="starts-with(.,$vInputLC)">
                <!-- prevent to test following siblings -->
                <xsl:if test="not(starts-with(preceding-sibling::node()[1],$vInputLC))">
                    <xsl:value-of select="ancestor::tei:nym/@n"/>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>
