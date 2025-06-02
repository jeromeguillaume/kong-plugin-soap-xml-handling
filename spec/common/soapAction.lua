local soapAction_common = {}

soapAction_common.calculator_soap11_Add_Request= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Header>
    <auth:Authentication xmlns:auth="http://example.com/auth">
        <auth:Username>user123</auth:Username>
        <auth:Password>securepassword</auth:Password>
    </auth:Authentication>
    <trans:TransactionID xmlns:trans="http://example.com/transaction">12345</trans:TransactionID>
  </soap:Header>
  <soap:Body>
		<!-- My Comment -->
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
			<intB>7</intB>
    </Add>
  </soap:Body>
</soap:Envelope>
]]

soapAction_common.calculator_soap11_XSD_VALIDATION_Failed_XSD_Instead_of_WSDL= [[
<%?xml version="1.0" encoding="utf%-8"%?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request %- XSD validation failed</faultstring>
      <detail>
        <errorMessage>Validation of 'SOAPAction' header: Unable to find the 'wsdl:definitions' for WSDL 1.1 or 'wsdl2:description' for WSDL 2.0 in the WSDL definition</errorMessage>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>]]

----------------------------------------------------------------------------------------------------
-- This WSDL 1.1 provides:
--   The Namespace prefix of wsdl 1.1 is 'wsdl'
--   The Namespace prefix of soap 1.1 is 'soap'
--   Only HTTP transport
--   The XSD schema is imported
--
-- soap 1.1 -> 1 HTTP operation defined with transport="http://schemas.xmlsoap.org/soap/http"/
--    Add       with    soapActionRequired="true"
----------------------------------------------------------------------------------------------------
soapAction_common.calculatorWSDL11_soap_import_Ok= [[
<?xml version="1.0" encoding="utf-8"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <wsdl:types>
    <!-- XSD schema for Add (Request and Response) -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:9000/tempuri.org.req.res.add.xsd"/>
    </xsd:schema>
  </wsdl:types>
  <wsdl:message name="AddSoapIn">
    <wsdl:part name="parameters" element="tns:Add" />
  </wsdl:message>
  <wsdl:message name="AddSoapOut">
    <wsdl:part name="parameters" element="tns:AddResponse" />
  </wsdl:message>
  <wsdl:portType name="CalculatorSoap">
    <wsdl:operation name="Add">
      <wsdl:documentation xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">Adds two integers. This is a test WebService. ©DNE Online</wsdl:documentation>
      <wsdl:input message="tns:AddSoapIn" />
      <wsdl:output message="tns:AddSoapOut" />
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="CalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="Add">
      <soap:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="Calculator">
    <wsdl:port name="CalculatorSoap" binding="tns:CalculatorSoap">
      <soap:address location="http://www.dneonline.com/calculator.asmx" />
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
]]

----------------------------------------------------------------------------------------------------
-- This WSDL 1.1 provides:
--   The Namespace prefix of wsdl 1.1 is 'wsdl'
--   The Namespace prefix of soap 1.1 is 'soap'
--   The Namespace prefix of soap 1.2 is 'soap12'
--   JMS and HTTP transport and the plugin supports only HTTP Transport
--
-- soap 1.1 -> 5 HTTP operations defined with transport="http://schemas.xmlsoap.org/soap/http"/
--    Add       with    soapActionRequired="true"
--    Subtract  with    soapActionRequired="false"
--    Multiply  without soapActionRequired
--    Divide    with    soapAction=''           (which is not correctly defined as we would like to check its content)
--    Power     with    no soapAction attribute (which is not correctly defined as we would like to check its content)
--
-- soap 1.1 -> 2 JMS operations defined with transport="http://cxf.apache.org/transports/jms"/
--
-- soap 1.2 -> 5 HTTP operations + 2 JMS operations defined (like above)
----------------------------------------------------------------------------------------------------
soapAction_common.calculatorWSDL11_soap_soap12= [[
<?xml version="1.0" encoding="utf-8"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <wsdl:types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <s:element name="Add">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="AddResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="AddResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Subtract">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="SubtractResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="SubtractResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Multiply">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="MultiplyResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="MultiplyResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Divide">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="DivideResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="DivideResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Power">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="PowerResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="PowerResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
    </s:schema>
  </wsdl:types>
  <wsdl:message name="AddSoapIn">
    <wsdl:part name="parameters" element="tns:Add" />
  </wsdl:message>
  <wsdl:message name="AddSoapOut">
    <wsdl:part name="parameters" element="tns:AddResponse" />
  </wsdl:message>
  <wsdl:message name="SubtractSoapIn">
    <wsdl:part name="parameters" element="tns:Subtract" />
  </wsdl:message>
  <wsdl:message name="SubtractSoapOut">
    <wsdl:part name="parameters" element="tns:SubtractResponse" />
  </wsdl:message>
  <wsdl:message name="MultiplySoapIn">
    <wsdl:part name="parameters" element="tns:Multiply" />
  </wsdl:message>
  <wsdl:message name="MultiplySoapOut">
    <wsdl:part name="parameters" element="tns:MultiplyResponse" />
  </wsdl:message>
  <wsdl:message name="DivideSoapIn">
    <wsdl:part name="parameters" element="tns:Divide" />
  </wsdl:message>
  <wsdl:message name="DivideSoapOut">
    <wsdl:part name="parameters" element="tns:DivideResponse" />
  </wsdl:message>
  <wsdl:message name="PowerSoapIn">
    <wsdl:part name="parameters" element="tns:Power" />
  </wsdl:message>
  <wsdl:message name="PowerSoapOut">
    <wsdl:part name="parameters" element="tns:PowerResponse" />
  </wsdl:message>
  <wsdl:portType name="CalculatorSoap">
    <wsdl:operation name="Add">
      <wsdl:documentation xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">Adds two integers. This is a test WebService. ©DNE Online</wsdl:documentation>
      <wsdl:input message="tns:AddSoapIn" />
      <wsdl:output message="tns:AddSoapOut" />
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <wsdl:input message="tns:SubtractSoapIn" />
      <wsdl:output message="tns:SubtractSoapOut" />
    </wsdl:operation>
    <wsdl:operation name="Multiply">
      <wsdl:input message="tns:MultiplySoapIn" />
      <wsdl:output message="tns:MultiplySoapOut" />
    </wsdl:operation>
    <wsdl:operation name="Divide">
      <wsdl:input message="tns:DivideSoapIn" />
      <wsdl:output message="tns:DivideSoapOut" />
    </wsdl:operation>
        <wsdl:operation name="Power">
      <wsdl:input message="tns:PowerSoapIn" />
      <wsdl:output message="tns:PowerSoapOut" />
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="JMSCalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <wsdl:operation name="Add">
      <soap:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="CalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="Add">
      <soap:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Multiply">
      <soap:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Divide">
      <soap:operation soapAction="" style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
      <wsdl:operation name="Power">
      <soap:operation style="document" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="JMSCalculatorSoap12" type="tns:CalculatorSoap">
    <soap12:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <wsdl:operation name="Add">
      <soap12:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap12:operation soapAction="" style="rpc"/>
      <wsdl:input>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="CalculatorSoap12" type="tns:CalculatorSoap">
    <soap12:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="Add">
      <soap12:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Subtract">
      <soap12:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Multiply">
      <soap12:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Divide">
      <soap12:operation soapAction="" style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Power">
      <soap12:operation style="document" />
      <wsdl:input>
        <soap12:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="Calculator">
    <wsdl:port name="CalculatorSoap" binding="tns:CalculatorSoap">
      <soap:address location="http://www.dneonline.com/calculator.asmx" />
    </wsdl:port>
    <wsdl:port name="CalculatorSoap12" binding="tns:CalculatorSoap12">
      <soap12:address location="http://www.dneonline.com/calculator.asmx" />
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
]]

--------------------------------------------------------------------------------------------------------
-- This WSDL 1.1 provides:
--   The Namespace prefix of wsdl 1.1 is 'kong_w_s_d_l'
--   The Namespace prefix of soap 1.1 is 'kong11'
--   The Namespace prefix of soap 1.2 is 'kong12'
--   JMS and HTTP transport and the plugin supports only HTTP Transport
--
-- soap 1.1 (kong11) -> 4 HTTP operations defined with transport="http://schemas.xmlsoap.org/soap/http"/
--    Add       with    soapActionRequired="true"
--    Subtract  with    soapActionRequired="false"
--    Multiply  without soapActionRequired
--    Divide    without soapActionRequired
--
-- soap 1.1 (kong11) -> 2 JMS operations defined with transport="http://cxf.apache.org/transports/jms"/
--
-- soap 1.2 (kong12) -> 4 HTTP operations + 2 JMS operations defined (like above)
--------------------------------------------------------------------------------------------------------
soapAction_common.calculatorWSDL11_kong_wsdl_kong11_kong12= [[
<?xml version="1.0" encoding="utf-8"?>
<kong_w_s_d_l:definitions xmlns:kong11="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:kong12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:kong_w_s_d_l="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <kong_w_s_d_l:types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <s:element name="Add">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="AddResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="AddResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Subtract">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="SubtractResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="SubtractResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Multiply">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="MultiplyResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="MultiplyResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Divide">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="DivideResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="DivideResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
    </s:schema>
  </kong_w_s_d_l:types>
  <kong_w_s_d_l:message name="AddSoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Add" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="AddSoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:AddResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="SubtractSoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Subtract" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="SubtractSoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:SubtractResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="MultiplySoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Multiply" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="MultiplySoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:MultiplyResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="DivideSoapIn">
    <kong_w_s_d_l:part name="parameters" element="tns:Divide" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:message name="DivideSoapOut">
    <kong_w_s_d_l:part name="parameters" element="tns:DivideResponse" />
  </kong_w_s_d_l:message>
  <kong_w_s_d_l:portType name="CalculatorSoap">
    <kong_w_s_d_l:operation name="Add">
      <kong_w_s_d_l:documentation xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">Adds two integers. This is a test WebService. ©DNE Online</kong_w_s_d_l:documentation>
      <kong_w_s_d_l:input message="tns:AddSoapIn" />
      <kong_w_s_d_l:output message="tns:AddSoapOut" />
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong_w_s_d_l:input message="tns:SubtractSoapIn" />
      <kong_w_s_d_l:output message="tns:SubtractSoapOut" />
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Multiply">
      <kong_w_s_d_l:input message="tns:MultiplySoapIn" />
      <kong_w_s_d_l:output message="tns:MultiplySoapOut" />
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Divide">
      <kong_w_s_d_l:input message="tns:DivideSoapIn" />
      <kong_w_s_d_l:output message="tns:DivideSoapOut" />
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:portType>
  <kong_w_s_d_l:binding name="JMSCalculatorSoap" type="tns:CalculatorSoap">
    <kong11:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <kong_w_s_d_l:operation name="Add">
      <kong11:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong11:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:binding name="CalculatorSoap" type="tns:CalculatorSoap">
    <kong11:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <kong_w_s_d_l:operation name="Add">
      <kong11:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong11:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Multiply">
      <kong11:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Divide">
      <kong11:operation soapAction="http://tempuri.org/Divide" style="document" />
      <kong_w_s_d_l:input>
        <kong11:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong11:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:binding name="JMSCalculatorSoap12" type="tns:CalculatorSoap">
    <kong12:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <kong_w_s_d_l:operation name="Add">
      <kong12:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong12:operation soapAction="" style="rpc"/>
      <kong_w_s_d_l:input>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:binding name="CalculatorSoap12" type="tns:CalculatorSoap">
    <kong12:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <kong_w_s_d_l:operation name="Add">
      <kong12:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Subtract">
      <kong12:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Multiply">
      <kong12:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
    <kong_w_s_d_l:operation name="Divide">
      <kong12:operation soapAction="http://tempuri.org/Divide" style="document" />
      <kong_w_s_d_l:input>
        <kong12:body use="literal" />
      </kong_w_s_d_l:input>
      <kong_w_s_d_l:output>
        <kong12:body use="literal" />
      </kong_w_s_d_l:output>
    </kong_w_s_d_l:operation>
  </kong_w_s_d_l:binding>
  <kong_w_s_d_l:service name="Calculator">
    <kong_w_s_d_l:port name="CalculatorSoap" binding="tns:CalculatorSoap">
      <kong11:address location="http://www.dneonline.com/calculator.asmx" />
    </kong_w_s_d_l:port>
    <kong_w_s_d_l:port name="CalculatorSoap12" binding="tns:CalculatorSoap12">
      <kong12:address location="http://www.dneonline.com/calculator.asmx" />
    </kong_w_s_d_l:port>
  </kong_w_s_d_l:service>
</kong_w_s_d_l:definitions>
]]

----------------------------------------------------------------------------------------------------
-- This WSDL 1.1 provides:
--   No  Namespace prefix for wsdl 1.1
--   The Namespace prefix of soap 1.1 is 'soap'
--   The Namespace prefix of soap 1.2 is 'soap12'
--   JMS and HTTP transport and the plugin supports only HTTP Transport
--
-- soap 1.1 -> 5 HTTP operations defined with transport="http://schemas.xmlsoap.org/soap/http"/
--    Add       with    soapActionRequired="true"
--    Subtract  with    soapActionRequired="false"
--    Multiply  without soapActionRequired
--    Divide    with    soapAction=''           (which is not correctly defined as we would like to check its content)
--    Power     with    no soapAction attribute (which is not correctly defined as we would like to check its content)
--
-- soap 1.1 -> 2 JMS operations defined with transport="http://cxf.apache.org/transports/jms"/
--
-- soap 1.2 -> 5 HTTP operations + 2 JMS operations defined (like above)
----------------------------------------------------------------------------------------------------
soapAction_common.calculatorWSDL11_defaultNS_wsdl_kong11_kong12= [[
<?xml version="1.0" encoding="utf-8"?>
<definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/wsdl/" xmlns:jms="http://cxf.apache.org/transports/jms">
  <types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <s:element name="Add">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="AddResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="AddResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Subtract">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="SubtractResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="SubtractResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Multiply">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="MultiplyResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="MultiplyResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Divide">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="DivideResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="DivideResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="Power">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
            <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="PowerResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="1" maxOccurs="1" name="PowerResult" type="s:int" />
          </s:sequence>
        </s:complexType>
      </s:element>
    </s:schema>
  </types>
  <message name="AddSoapIn">
    <part name="parameters" element="tns:Add" />
  </message>
  <message name="AddSoapOut">
    <part name="parameters" element="tns:AddResponse" />
  </message>
  <message name="SubtractSoapIn">
    <part name="parameters" element="tns:Subtract" />
  </message>
  <message name="SubtractSoapOut">
    <part name="parameters" element="tns:SubtractResponse" />
  </message>
  <message name="MultiplySoapIn">
    <part name="parameters" element="tns:Multiply" />
  </message>
  <message name="MultiplySoapOut">
    <part name="parameters" element="tns:MultiplyResponse" />
  </message>
  <message name="DivideSoapIn">
    <part name="parameters" element="tns:Divide" />
  </message>
  <message name="DivideSoapOut">
    <part name="parameters" element="tns:DivideResponse" />
  </message>
  <message name="PowerSoapIn">
    <part name="parameters" element="tns:Power" />
  </message>
  <message name="PowerSoapOut">
    <part name="parameters" element="tns:PowerResponse" />
  </message>
  <portType name="CalculatorSoap">
    <operation name="Add">
      <documentation xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">Adds two integers. This is a test WebService. ©DNE Online</documentation>
      <input message="tns:AddSoapIn" />
      <output message="tns:AddSoapOut" />
    </operation>
    <operation name="Subtract">
      <input message="tns:SubtractSoapIn" />
      <output message="tns:SubtractSoapOut" />
    </operation>
    <operation name="Multiply">
      <input message="tns:MultiplySoapIn" />
      <output message="tns:MultiplySoapOut" />
    </operation>
    <operation name="Divide">
      <input message="tns:DivideSoapIn" />
      <output message="tns:DivideSoapOut" />
    </operation>
        <operation name="Power">
      <input message="tns:PowerSoapIn" />
      <output message="tns:PowerSoapOut" />
    </operation>
  </portType>
  <binding name="JMSCalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <operation name="Add">
      <soap:operation soapAction="" style="rpc"/>
      <input>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </input>
      <output>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </output>
    </operation>
    <operation name="Subtract">
      <soap:operation soapAction="" style="rpc"/>
      <input>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </input>
      <output>
        <soap:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </output>
    </operation>
  </binding>
  <binding name="CalculatorSoap" type="tns:CalculatorSoap">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <operation name="Add">
      <soap:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <input>
        <soap:body use="literal" />
      </input>
      <output>
        <soap:body use="literal" />
      </output>
    </operation>
    <operation name="Subtract">
      <soap:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <input>
        <soap:body use="literal" />
      </input>
      <output>
        <soap:body use="literal" />
      </output>
    </operation>
    <operation name="Multiply">
      <soap:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <input>
        <soap:body use="literal" />
      </input>
      <output>
        <soap:body use="literal" />
      </output>
    </operation>
    <operation name="Divide">
      <soap:operation soapAction="" style="document" />
      <input>
        <soap:body use="literal" />
      </input>
      <output>
        <soap:body use="literal" />
      </output>
    </operation>
      <operation name="Power">
      <soap:operation style="document" />
      <input>
        <soap:body use="literal" />
      </input>
      <output>
        <soap:body use="literal" />
      </output>
    </operation>
  </binding>
  <binding name="JMSCalculatorSoap12" type="tns:CalculatorSoap">
    <soap12:binding style="rpc" transport="http://cxf.apache.org/transports/jms"/>
    <operation name="Add">
      <soap12:operation soapAction="" style="rpc"/>
      <input>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </input>
      <output>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </output>
    </operation>
    <operation name="Subtract">
      <soap12:operation soapAction="" style="rpc"/>
      <input>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </input>
      <output>
        <soap12:body namespace="http://org.jboss.ws/samples/jmstransport" use="literal"/>
      </output>
    </operation>
  </binding>
  <binding name="CalculatorSoap12" type="tns:CalculatorSoap">
    <soap12:binding transport="http://schemas.xmlsoap.org/soap/http" />
    <operation name="Add">
      <soap12:operation soapAction="http://tempuri.org/Add" soapActionRequired="true" style="document" />
      <input>
        <soap12:body use="literal" />
      </input>
      <output>
        <soap12:body use="literal" />
      </output>
    </operation>
    <operation name="Subtract">
      <soap12:operation soapAction="http://tempuri.org/Subtract" soapActionRequired="false" style="document" />
      <input>
        <soap12:body use="literal" />
      </input>
      <output>
        <soap12:body use="literal" />
      </output>
    </operation>
    <operation name="Multiply">
      <soap12:operation soapAction="http://tempuri.org/Multiply" style="document" />
      <input>
        <soap12:body use="literal" />
      </input>
      <output>
        <soap12:body use="literal" />
      </output>
    </operation>
    <operation name="Divide">
      <soap12:operation soapAction="" style="document" />
      <input>
        <soap12:body use="literal" />
      </input>
      <output>
        <soap12:body use="literal" />
      </output>
    </operation>
    <operation name="Power">
      <soap12:operation style="document" />
      <input>
        <soap12:body use="literal" />
      </input>
      <output>
        <soap12:body use="literal" />
      </output>
    </operation>
  </binding>
  <service name="Calculator">
    <port name="CalculatorSoap" binding="tns:CalculatorSoap">
      <soap:address location="http://www.dneonline.com/calculator.asmx" />
    </port>
    <port name="CalculatorSoap12" binding="tns:CalculatorSoap12">
      <soap12:address location="http://www.dneonline.com/calculator.asmx" />
    </port>
  </service>
</definitions>
]]

----------------------------------------------------------------------------------------------------
-- This WSDL 2.0 provides:
--   The Namespace prefix of wsdl 2.0 is 'wsdl2'
--   No  Namespace prefix for xsd (this is the default Namespace)
-- <wsdl:interface> -> 3 HTTP operation defined
--    Add       with    wsam:Action="http://tempuri.org/Add"
--    Subtract  has no 'wsam:Action'
--    Multiply  has no 'wsam:Action' and invalid pattern URL

----------------------------------------------------------------------------------------------------
soapAction_common.calculatorWSDL20_wsdl2= [[
<wsdl2:description
    xmlns:wsdl2=     "http://www.w3.org/ns/wsdl"
    targetNamespace= "http://tempuri.org/"
    xmlns:tns=       "http://tempuri.org/"
    xmlns:wsoap=     "http://www.w3.org/ns/wsdl/soap"
    xmlns:soap=      "http://www.w3.org/2003/05/soap-envelope"
    xmlns:wsdlx=     "http://www.w3.org/ns/wsdl-extensions"
    xmlns=           "http://www.w3.org/2001/XMLSchema"
    xmlns:wsam=      "http://www.w3.org/2007/05/addressing/metadata">

  <wsdl2:documentation>
    This is the web service documentation.
  </wsdl2:documentation>

  <wsdl2:types>
    <schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <element name="Add" type="tempuri:typeAdd" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeAdd">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="intA" type="int" />
          <element minOccurs="1" maxOccurs="1" name="intB" type="int" />
        </sequence>
      </complexType> 
      <element name="AddResponse" type="tempuri:typeAddResponse" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeAddResponse">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="AddResult" type="int" />
        </sequence>
      </complexType>
      <element name="Subtract" type="tempuri:typeSubtract" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeSubtract">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="intA" type="int" />
          <element minOccurs="1" maxOccurs="1" name="intB" type="int" />
        </sequence>
      </complexType> 
      <element name="SubtractResponse" type="tempuri:typeSubtractResponse" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeSubtractResponse">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="SubtractResult" type="int" />
        </sequence>
      </complexType>
      <element name="Multiply" type="tempuri:typeMultiply" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeMultiply">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="intA" type="int" />
          <element minOccurs="1" maxOccurs="1" name="intB" type="int" />
        </sequence>
      </complexType> 
      <element name="MultiplyResponse" type="tempuri:typeMultiplyResponse" xmlns:tempuri="http://tempuri.org/"/>
      <complexType name="typeMultiplyResponse">
        <sequence>
          <element minOccurs="1" maxOccurs="1" name="MultiplyResult" type="int" />
        </sequence>
      </complexType>
    </schema>
  </wsdl2:types>
  
    <wsdl2:interface  name = "AddInterface" >
    <wsdl2:fault name = "invalidAddFault"  element = "tns:invalidAddError"/>
    <wsdl2:operation name="Add"
            pattern="http://www.w3.org/ns/wsdl/in-out"
            style="http://www.w3.org/ns/wsdl/style/iri"
            wsdlx:safe = "true">
      <wsdl2:input    messageLabel="In"  element="tns:AddSoapIn"  wsam:Action="http://tempuri.org/Add" />
      <wsdl2:output   messageLabel="Out" element="tns:AddSoapOut" wsam:Action="http://tempuri.org/AddResponse"/>
      <wsdl2:outfault messageLabel="Out" ref    ="tns:invalidAddFault" />    
    </wsdl2:operation>
  </wsdl2:interface>
  
  <wsdl2:interface  name = "SubtractInterface" >
    <wsdl2:fault name = "invalidSubtractFault"  element = "tns:invalidSubtractError"/>
    <wsdl2:operation name="Subtract"
            pattern="http://www.w3.org/ns/wsdl/in-out"
            style="http://www.w3.org/ns/wsdl/style/iri"
            wsdlx:safe = "true">
      <wsdl2:input    messageLabel="In"  element="tns:SubtractSoapIn"/>
      <wsdl2:output   messageLabel="Out" element="tns:SubtractSoapOut"/>
      <wsdl2:outfault messageLabel="Out" ref    ="tns:invalidSubtractFault" />    
    </wsdl2:operation>
  </wsdl2:interface>

  <wsdl2:interface  name = "MultiplytInterface" >
    <wsdl2:fault name = "invalidMultiplyFault"  element = "tns:invalidMultiplyError"/>
    <wsdl2:operation name="Multiply"
            pattern="http://www.w3.org/ns/wsdl/in-out-INVALID-URL-FOR-TEST-ONLY"
            style="http://www.w3.org/ns/wsdl/style/iri"
            wsdlx:safe = "true">
      <wsdl2:input    messageLabel="In"  element="tns:MultiplySoapIn"/>
      <wsdl2:output   messageLabel="Out" element="tns:MultiplySoapOut"/>
      <wsdl2:outfault messageLabel="Out" ref    ="tns:invalidMultiplyFault" />    
    </wsdl2:operation>
  </wsdl2:interface>

  <wsdl2:binding name="AddSOAPBinding"
          interface="tns:AddInterface"
          type="http://www.w3.org/ns/wsdl/soap"
          wsoap:protocol="http://www.w3.org/2003/05/soap/bindings/HTTP/">
    <wsdl2:fault ref="tns:invalidAddFault" wsoap:code="soap:Sender"/>
    <wsdl2:operation ref="tns:Add"
      wsoap:mep="http://www.w3.org/2003/05/soap/mep/soap-response"/>
  </wsdl2:binding>

  <wsdl2:binding name="SubtractSOAPBinding"
          interface="tns:SubtractInterface"
          type="http://www.w3.org/ns/wsdl/soap"
          wsoap:protocol="http://www.w3.org/2003/05/soap/bindings/HTTP/">
    <wsdl2:fault ref="tns:invalidSubtractFault" wsoap:code="soap:Sender"/>
    <wsdl2:operation ref="tns:Subtract"
      wsoap:mep="http://www.w3.org/2003/05/soap/mep/soap-response"/>
  </wsdl2:binding>

  <wsdl2:service
       name     ="AddCalculatorService"
       interface="tns:AddInterface">
     <wsdl2:endpoint name ="AddCalculatorEndpoint"
            binding ="tns:AddSOAPBinding"
            address ="http://localhost:8080/ws"/>
  </wsdl2:service>

  <wsdl2:service
       name     ="SubtractCalculatorService"
       interface="tns:SubtractInterface">
     <wsdl2:endpoint name ="SubtractCalculatorEndpoint"
            binding ="tns:SubtractSOAPBinding"
            address ="http://localhost:8080/ws"/>
  </wsdl2:service>

</wsdl2:description>
]]

----------------------------------------------------------------------------------------------------
-- This WSDL 2.0 provides:
--   No  Namespace prefix for wsdl 2.0 (this is the default Namespace)
--   The Namespace prefix of xsd is 'xs'
-- <wsdl:interface> -> 3 HTTP operation defined
--    Add       with    wsam:Action="http://tempuri.org/Add"
--    Subtract  has no 'wsam:Action'
--    Multiply  has no 'wsam:Action' and invalid pattern URL

----------------------------------------------------------------------------------------------------
soapAction_common.calculatorWSDL20_defaultNS_wsdl= [[
<description
    xmlns=           "http://www.w3.org/ns/wsdl"
    targetNamespace= "http://tempuri.org/"
    xmlns:tns=       "http://tempuri.org/"
    xmlns:wsoap=     "http://www.w3.org/ns/wsdl/soap"
    xmlns:soap=      "http://www.w3.org/2003/05/soap-envelope"
    xmlns:wsdlx=     "http://www.w3.org/ns/wsdl-extensions"
    xmlns:xs=        "http://www.w3.org/2001/XMLSchema"
    xmlns:wsam=		   "http://www.w3.org/2007/05/addressing/metadata">

  <documentation>
    This is the web service documentation.
  </documentation>

  <types>
    <xs:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <xs:element name="Add" type="typeAdd" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeAdd">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="intA" type="xs:int" />
          <xs:element minOccurs="1" maxOccurs="1" name="intB" type="xs:int" />
        </xs:sequence>
      </xs:complexType>
      <xs:element name="AddResponse" type="typeAddResponse" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeAddResponse">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="AddResult" type="xs:int" />
        </xs:sequence>
      </xs:complexType>
      <xs:element name="Subtract" type="typeSubtract" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeSubtract">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="intA" type="xs:int" />
          <xs:element minOccurs="1" maxOccurs="1" name="intB" type="xs:int" />
        </xs:sequence>
      </xs:complexType>
      <xs:element name="SubtractResponse" type="typeSubtractResponse" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeSubtractResponse">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="SubtractResult" type="xs:int" />
        </xs:sequence>
      </xs:complexType>
      <xs:element name="Multiply" type="typeSubtract" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeMultiply">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="intA" type="xs:int" />
          <xs:element minOccurs="1" maxOccurs="1" name="intB" type="xs:int" />
        </xs:sequence>
      </xs:complexType>
      <xs:element name="MultiplyResponse" type="typeMultiplyResponse" xmlns="http://tempuri.org/"/>
      <xs:complexType name="typeMultiplyResponse">
        <xs:sequence>
          <xs:element minOccurs="1" maxOccurs="1" name="MultiplyResult" type="xs:int" />
        </xs:sequence>
      </xs:complexType>
    </xs:schema>
  </types>

  <interface  name = "AddInterface" >
    <fault name = "invalidAddFault"  element = "tns:invalidAddError"/>
    <operation name="Add"
            pattern="http://www.w3.org/ns/wsdl/in-out"
            style="http://www.w3.org/ns/wsdl/style/iri"
            wsdlx:safe = "true">
      <input    messageLabel="In"  element="tns:AddSoapIn"  wsam:Action="http://tempuri.org/Add"/>
      <output   messageLabel="Out" element="tns:AddSoapOut" wsam:Action="http://tempuri.org/AddResponse"/>
      <outfault messageLabel="Out" ref    ="tns:invalidAddFault" />
    </operation>
  </interface>

  <interface  name = "SubtractInterface" >
    <fault name = "invalidSubtractFault"  element = "tns:invalidSubtractError"/>
    <operation name="Subtract"
            pattern="http://www.w3.org/ns/wsdl/in-out"
            style="http://www.w3.org/ns/wsdl/style/iri"
            wsdlx:safe = "true">
      <input    messageLabel="In"  element="tns:SubtractSoapIn"/>
      <output   messageLabel="Out" element="tns:SubtractSoapOut"/>
      <outfault messageLabel="Out" ref    ="tns:invalidSubtractFault" />
    </operation>
  </interface>

  <interface  name = "MultiplyInterface" >
    <fault name = "invalidMultiplyFault"  element = "tns:invalidMultiplyError"/>
    <operation name="Multiply"
            pattern="http://www.w3.org/ns/wsdl/in-out-INVALID-URL-FOR-TEST-ONLY"
            style="http://www.w3.org/ns/wsdl/style/iri"
            wsdlx:safe = "true">
      <input    messageLabel="In"  element="tns:MultiplySoapIn"/>
      <output   messageLabel="Out" element="tns:MultiplySoapOut"/>
      <outfault messageLabel="Out" ref    ="tns:invalidMultiplyFault" />
    </operation>
  </interface>

  <binding name="AddSOAPBinding"
          interface="tns:AddInterface"
          type="http://www.w3.org/ns/wsdl/soap"
          wsoap:protocol="http://www.w3.org/2003/05/soap/bindings/HTTP/">
    <fault ref="tns:invalidAddFault" wsoap:code="soap:Sender"/>
    <operation ref="tns:Add"
      wsoap:mep="http://www.w3.org/2003/05/soap/mep/soap-response"/>
  </binding>

  <binding name="SubtractSOAPBinding"
          interface="tns:SubtractInterface"
          type="http://www.w3.org/ns/wsdl/soap"
          wsoap:protocol="http://www.w3.org/2003/05/soap/bindings/HTTP/">
    <fault ref="tns:invalidSubtractFault" wsoap:code="soap:Sender"/>
    <operation ref="tns:Subtract"
      wsoap:mep="http://www.w3.org/2003/05/soap/mep/soap-response"/>
  </binding>

  <service
       name     ="AddCalculatorService"
       interface="tns:AddInterface">
     <endpoint name ="AddCalculatorEndpoint"
            binding ="tns:AddSOAPBinding"
            address ="http://localhost:8080/ws"/>
  </service>

  <service
       name     ="SubtractCalculatorService"
       interface="tns:SubtractInterface">
     <endpoint name ="SubtractCalculatorEndpoint"
            binding ="tns:SubtractSOAPBinding"
            address ="http://localhost:8080/ws"/>
  </service>

</description>
]]

return soapAction_common