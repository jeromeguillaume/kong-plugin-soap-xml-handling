local soap12_common = {}

soap12_common.calculator_soap12_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Add>
  </soap12:Body>
</soap12:Envelope>
]]

soap12_common.calculator_soap12_Subtract_Request = [[
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
		<Subtract xmlns="http://tempuri.org/">
			<intA>5</intA>
			<intB>1</intB>
		</Subtract>
  </soap12:Body>
</soap12:Envelope>
]]

soap12_common.soap12_XSD = [[
<!-- Schema defined in the SOAP Version 1.2 Part 1 specification
     Recommendation:
     http://www.w3.org/TR/2003/REC-soap12-part1-20030624/
     $Id: soap-envelope.xsd,v 1.2 2006/12/20 20:43:36 ylafon Exp $

     Copyright (C)2003 W3C(R) (MIT, ERCIM, Keio), All Rights Reserved.
     W3C viability, trademark, document use and software licensing rules
     apply.
     http://www.w3.org/Consortium/Legal/

     This document is governed by the W3C Software License [1] as
     described in the FAQ [2].

     [1] http://www.w3.org/Consortium/Legal/copyright-software-19980720
     [2] http://www.w3.org/Consortium/Legal/IPR-FAQ-20000620.html#DTD
-->

<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
           xmlns:tns="http://www.w3.org/2003/05/soap-envelope"
           targetNamespace="http://www.w3.org/2003/05/soap-envelope" 
             elementFormDefault="qualified" >

  <xs:import namespace="http://www.w3.org/XML/1998/namespace" 
             schemaLocation="http://www.w3.org/2001/xml.xsd"/>

  <!-- Envelope, header and body -->
  <xs:element name="Envelope" type="tns:Envelope" />
  <xs:complexType name="Envelope" >
    <xs:sequence>
      <xs:element ref="tns:Header" minOccurs="0" />
      <xs:element ref="tns:Body" minOccurs="1" />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" />
  </xs:complexType>

  <xs:element name="Header" type="tns:Header" />
  <xs:complexType name="Header" >
    <xs:annotation>
       <xs:documentation>
       Elements replacing the wildcard MUST be namespace qualified, but can be in the targetNamespace
       </xs:documentation>
     </xs:annotation>
    <xs:sequence>
      <xs:any namespace="##any" processContents="lax" minOccurs="0" maxOccurs="unbounded"  />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" />
  </xs:complexType>
  
  <xs:element name="Body" type="tns:Body" />
  <xs:complexType name="Body" >
    <xs:sequence>
      <xs:any namespace="##any" processContents="lax" minOccurs="0" maxOccurs="unbounded" />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" />
  </xs:complexType>

  <!-- Global Attributes.  The following attributes are intended to be
  usable via qualified attribute names on any complex type referencing
  them.  -->
  <xs:attribute name="mustUnderstand" type="xs:boolean" default="0" />
  <xs:attribute name="relay" type="xs:boolean" default="0" />
  <xs:attribute name="role" type="xs:anyURI" />

  <!-- 'encodingStyle' indicates any canonicalization conventions
  followed in the contents of the containing element.  For example, the
  value 'http://www.w3.org/2003/05/soap-encoding' indicates the pattern
  described in the SOAP Version 1.2 Part 2: Adjuncts Recommendation -->

  <xs:attribute name="encodingStyle" type="xs:anyURI" />

  <xs:element name="Fault" type="tns:Fault" />
  <xs:complexType name="Fault" final="extension" >
    <xs:annotation>
       <xs:documentation>
         Fault reporting structure
       </xs:documentation>
     </xs:annotation>
    <xs:sequence>
      <xs:element name="Code" type="tns:faultcode" />
      <xs:element name="Reason" type="tns:faultreason" />
      <xs:element name="Node" type="xs:anyURI" minOccurs="0" />
       <xs:element name="Role" type="xs:anyURI" minOccurs="0" />
      <xs:element name="Detail" type="tns:detail" minOccurs="0" />
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="faultreason" >
    <xs:sequence>
       <xs:element name="Text" type="tns:reasontext" 
                  minOccurs="1"  maxOccurs="unbounded" />
     </xs:sequence>
  </xs:complexType>

  <xs:complexType name="reasontext" >
    <xs:simpleContent>
       <xs:extension base="xs:string" >
         <xs:attribute ref="xml:lang" use="required" />
       </xs:extension>
     </xs:simpleContent>
  </xs:complexType>
  
  <xs:complexType name="faultcode">
    <xs:sequence>
      <xs:element name="Value"
                  type="tns:faultcodeEnum"/>
      <xs:element name="Subcode"
                  type="tns:subcode"
                  minOccurs="0"/>
    </xs:sequence>
  </xs:complexType>

  <xs:simpleType name="faultcodeEnum">
    <xs:restriction base="xs:QName">
      <xs:enumeration value="tns:DataEncodingUnknown"/>
      <xs:enumeration value="tns:MustUnderstand"/>
      <xs:enumeration value="tns:Receiver"/>
      <xs:enumeration value="tns:Sender"/>
      <xs:enumeration value="tns:VersionMismatch"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:complexType name="subcode">
    <xs:sequence>
      <xs:element name="Value"
                  type="xs:QName"/>
      <xs:element name="Subcode"
                  type="tns:subcode"
                  minOccurs="0"/>
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="detail">
    <xs:sequence>
      <xs:any namespace="##any" processContents="lax" minOccurs="0" maxOccurs="unbounded"  />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" /> 
  </xs:complexType>

  <!-- Global element declaration and complex type definition for header entry returned due to a mustUnderstand fault -->
  <xs:element name="NotUnderstood" type="tns:NotUnderstoodType" />
  <xs:complexType name="NotUnderstoodType" >
    <xs:attribute name="qname" type="xs:QName" use="required" />
  </xs:complexType>


  <!-- Global element and associated types for managing version transition as described in Appendix A of the SOAP Version 1.2 Part 1 Recommendation  -->  <xs:complexType name="SupportedEnvType" >
    <xs:attribute name="qname" type="xs:QName" use="required" />
  </xs:complexType>

  <xs:element name="Upgrade" type="tns:UpgradeType" />
  <xs:complexType name="UpgradeType" >
    <xs:sequence>
       <xs:element name="SupportedEnvelope" type="tns:SupportedEnvType" minOccurs="1" maxOccurs="unbounded" />
     </xs:sequence>
  </xs:complexType>


</xs:schema>
]]

soap12_common.soap12_import_XML_XSD =[[
<?xml version='1.0'?>
<!DOCTYPE xs:schema PUBLIC "-//W3C//DTD XMLSCHEMA 200102//EN" "XMLSchema.dtd" >
<xs:schema targetNamespace="http://www.w3.org/XML/1998/namespace" xmlns:xs="http://www.w3.org/2001/XMLSchema" xml:lang="en">

 <xs:annotation>
  <xs:documentation>   
  </xs:documentation>
 </xs:annotation>

 <xs:annotation>
  <xs:documentation>This schema defines attributes and an attribute group...
  </xs:documentation>
 </xs:annotation>

 <xs:annotation>
  <xs:documentation>In keeping with the XML Schema WG's standard versioning...
  </xs:documentation>
 </xs:annotation>

 <xs:attribute name="lang" type="xs:language">
  <xs:annotation>
   <xs:documentation>In due course, we should install the relevant ISO 2- and 3-letter
         codes as the enumerated possible values . . .</xs:documentation>
  </xs:annotation>
 </xs:attribute>

 <xs:attribute name="space" default="preserve">
  <xs:simpleType>
   <xs:restriction base="xs:NCName">
    <xs:enumeration value="default"/>
    <xs:enumeration value="preserve"/>
   </xs:restriction>
  </xs:simpleType>
 </xs:attribute>

 <xs:attribute name="base" type="xs:anyURI">
  <xs:annotation>
   <xs:documentation>See http://www.w3.org/TR/xmlbase/ for
                     information about this attribute.</xs:documentation>
  </xs:annotation>
 </xs:attribute>

 <xs:attributeGroup name="specialAttrs">
  <xs:attribute ref="xml:base"/>
  <xs:attribute ref="xml:lang"/>
  <xs:attribute ref="xml:space"/>
 </xs:attributeGroup>

</xs:schema>
]]

return soap12_common