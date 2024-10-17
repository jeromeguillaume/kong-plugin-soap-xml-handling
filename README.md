# Kong plugins: SOAP/XML Handling for Request and Response
This repository concerns Kong plugins developed in Lua and uses the GNOME C libraries [libxml2](https://gitlab.gnome.org/GNOME/libxml2#libxml2) and [libxslt](https://gitlab.gnome.org/GNOME/libxslt#libxslt) (for XSLT 1.0). Part of the functions are bound in the [XMLua/libxml2](https://clear-code.github.io/xmlua/) library.
Both GNOME C and XMLua/libxml2 libraries are already included in [kong/kong-gateway](https://hub.docker.com/r/kong/kong-gateway) Enterprise Edition Docker image, so you don't need to rebuild a Kong image.

The XSLT Transformation can also be managed with the [saxon](https://www.saxonica.com/html/welcome/welcome.html) library, which supports XSLT 2.0 and 3.0. With XSLT 2.0+ there is a way for applying JSON <-> XML transformation with [fn:json-to-xml](https://www.w3.org/TR/xslt-30/#func-json-to-xml) and [fn:xml-to-json](https://www.w3.org/TR/xslt-30/#func-xml-to-json). The `saxon` library is not included in the Kong Docker image, see [SAXON.md](SAXON.md) for how to integrate saxon with Kong. It's optional, don't install `saxon` library if you don't need it.

These plugins don't apply to Kong OSS. They work for Kong EE and Konnect.

The plugins handle the SOAP/XML **Request** and/or the SOAP/XML **Response** in this order:

**soap-xml-request-handling** plugin to handle Request:

1) `XSLT TRANSFORMATION - BEFORE XSD`: Transform the XML request with XSLT (XSLTransformation) before step #2
2) `WSDL/XSD VALIDATION`: Validate XML request with its WSDL/XSD schema
3) `XSLT TRANSFORMATION - AFTER XSD`: Transform the XML request with XSLT (XSLTransformation) after step #2
4) `ROUTING BY XPATH`: change the Route of the request to a different hostname and path depending of XPath condition

**soap-xml-response-handling** plugin to handle Reponse:

5) `XSLT TRANSFORMATION - BEFORE XSD`: Transform the XML response before step #6
6) `WSDL/XSD VALIDATION`: Validate the XML response with its WSDL/XSD schema
7) `XSLT TRANSFORMATION - AFTER XSD`:  Transform the XML response after step #6

Each handling is optional. In case of misconfiguration the Plugin sends to the consumer an HTTP 500 Internal Server Error `<soap:Fault>` (with the error detailed message).

![Alt text](/images/Pipeline-Kong-soap-xml-handling.png?raw=true "Kong - SOAP/XML execution pipeline")

![Alt text](/images/Kong-Manager.png?raw=true "Kong - Manager")


## `soap-xml-request-handling` and `soap-xml-response-handling` configuration reference
|FORM PARAMETER                 |DEFAULT          |DESCRIPTION                                                 |
|:------------------------------|:----------------|:-----------------------------------------------------------|
|config.ExternalEntityLoader_Async|false|Download asynchronously the XSD schema from an external entity (i.e.: http(s)://)|
|config.ExternalEntityLoader_CacheTTL|3600|Keep the XSD schema in Kong memory cache during the time specified (in second). It applies for synchronous and asynchronous XSD download|
|config.ExternalEntityLoader_Timeout|1|Tiemout in second for XSD schema downloading. It applies for synchronous and asynchronous XSD download|
|config.RouteToPath|N/A|URI Path to change the route dynamically to the Web Service. Syntax is: `scheme://kong_upstream/path`|
|config.RouteXPath|N/A|XPath request to extract a value from the request body and to compare it with `RouteXPathCondition`|
|config.RouteXPathCondition|N/A|XPath value to compare with the value extracted by `RouteXPath`. If the condition is satisfied the route is changed to `RouteToPath`|
|config.RouteXPathRegisterNs|Pre-defined|Register Namespace to enable XPath request. The syntax is `name,namespace`. Mulitple entries are allowed (example: `name1,namespace1,name2,namespace2`)|
|config.VerboseRequest|false|`soap-xml-request-handling` only: enable a detailed error message sent to the consumer. The syntax is `<detail>...</detail>` in the `<soap:Fault>` message|
|config.VerboseResponse|false|`soap-xml-response-handling` only: see above|
|config.xsdApiSchema|false|WSDL/XSD schema used by `WSDL/XSD VALIDATION` for the Web Service tags|
|config.xsdApiSchemaInclude|false|XSD content included in the plugin configuration. It's related to `xsdApiSchema`. It avoids downloading content from external entity (i.e.: http(s)://). The include has priority over the download from external entity|
|config.xsdSoapSchema|Pre-defined|WSDL/XSD schema used by `WSDL/XSD VALIDATION` for the `<soap>` tags: `<soap:Envelope>`, `<soap:Header>`, `<soap:Body>`|
|config.xsltLibrary|libxslt|Library name for `XSLT TRANSFORMATION`. Select `saxon` for supporting XSLT 2.0 or 3.0
|config.xsltTransformAfter|N/A|`XSLT` definition used by `XSLT TRANSFORMATION - AFTER XSD`|
|config.xsltTransformBefore|N/A|`XSLT` definition used by `XSLT TRANSFORMATION - BEFORE XSD`|

## How to deploy SOAP/XML Handling plugins in Kong Gateway (standalone) | Docker
1) Do a Git Clone of this repo
```sh
git clone https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling.git
```
2) Create and prepare a PostgreDB called `kong-database-soap-xml-handling`.
[See documentation](https://docs.konghq.com/gateway/latest/install/docker/#prepare-the-database)
3) Provision a license of Kong Enterprise Edition and put the content in `KONG_LICENSE_DATA` environment variable. The following license is only an example. You must use the following format, but provide your own content
```sh
 export KONG_LICENSE_DATA='{"license":{"payload":{"admin_seats":"1","customer":"Example Company, Inc","dataplanes":"1","license_creation_date":"2023-04-07","license_expiration_date":"2023-04-07","license_key":"00141000017ODj3AAG_a1V41000004wT0OEAU","product_subscription":"Konnect Enterprise","support_plan":"None"},"signature":"6985968131533a967fcc721244a979948b1066967f1e9cd65dbd8eeabe060fc32d894a2945f5e4a03c1cd2198c74e058ac63d28b045c2f1fcec95877bd790e1b","version":"1"}}'
```
4) Start the standalone Kong Gateway
```sh
./start-kong.sh
```

## How to deploy SOAP/XML Handling plugins **schema** in Konnect (Control Plane) for Kong Gateway
1) Do a Git Clone of this repo (if it’s not done yet):
```sh
git clone https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling.git
```
2) Login to Konnect
3) Select the `Kong Gateway` in the Gateway Manager
4) Click on `Plugins`
5) Click on `+ New Plugin`
6) Click on `Custom Plugins`
7) Click on `Create` Custom Plugin
8) Click on `Select file` and open the [schema.lua](kong/plugins/soap-xml-request-handling/schema.lua) of `soap-xml-request-handling`
9) Click on `Save`

Repeat from step #6 and open the [schema.lua](kong/plugins/soap-xml-response-handling/schema.lua) of `soap-xml-response-handling`

## How to deploy SOAP/XML Handling plugins **schema** in Konnect (Control Plane) for Kong Ingress Controller (KIC)
1) Do a Git Clone of this repo (if it’s not done yet):
```sh
git clone https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling.git
```
2) Login to Konnect
3) Create a Personal Access Token (starting by `kpat_`) or System Account Access Token (starting by `spat_`). [See documentation](https://docs.konghq.com/konnect/gateway-manager/declarative-config/#generate-a-personal-access-token)
4) From the `Overview` page of KIC-Gateway manager page, get the KIC `id`
5) Upload the custom plugin schema of `soap-xml-request-handling` by using the Konnect API:
```sh
cd ./kong-plugin-soap-xml-handling/kong/plugins/soap-xml-request-handling
https -A bearer -a <**REPLACE_BY_ACCESS_TOKEN_VALUE**> eu.api.konghq.com/v2/control-planes/<**REPLACE_BY_KIC_ID**>/core-entities/plugin-schemas lua_schema=@schema.lua
```
The expected response is:
```
HTTP/1.1 201 Created
```
Repeat step #5 with the schema.lua of `soap-xml-response-handling` by changing the directory:
```sh 
cd -
cd ./kong-plugin-soap-xml-handling/kong/plugins/soap-xml-response-handling
```

## How to deploy SOAP/XML Handling plugins in Kong Gateway (Data Plane) | Kubernetes
1) Do a Git Clone of this repo (if it’s not done yet):
```sh
git clone https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling.git
```
2) Create `configMaps`
- `configMaps` for the custom plugins (Request and Response)
```sh
cd ./kong-plugin-soap-xml-handling/kong/plugins
kubectl -n kong create configmap soap-xml-request-handling --from-file=./soap-xml-request-handling
kubectl -n kong create configmap soap-xml-response-handling --from-file=./soap-xml-response-handling
```
- Create a `configMap` for the shared library
```sh
kubectl -n kong create configmap soap-xml-handling-lib --from-file=./soap-xml-handling-lib
```
- Include `subdirectories` of the library
```sh
cd soap-xml-handling-lib

kubectl -n kong create configmap libxml2ex --from-file=./libxml2ex
kubectl -n kong create configmap libxslt --from-file=./libxslt
```
3) [See Kong Gateway on Kubernetes documentation](https://docs.konghq.com/gateway/latest/install/kubernetes/proxy/) and add the following properties to the helm `values.yaml`:
```yaml
image:
  repository: kong/kong-gateway
  ...
env:
  plugins: bundled,soap-xml-request-handling,soap-xml-response-handling
...
plugins:
  configMaps:
  - pluginName: soap-xml-request-handling
    name: soap-xml-request-handling
  - pluginName: soap-xml-response-handling
    name: soap-xml-response-handling
  - pluginName: soap-xml-handling-lib
    name: soap-xml-handling-lib
    subdirectories:
    - name: libxml2ex
      path: libxml2ex
    - name: libxslt
      path: libxslt
```
4) Execute the `helm` command:
```sh
helm install kong kong/kong -n kong --values ./values.yaml
```

## How to configure and test `calculator` Web Service in Kong Gateway
1) Create a Kong Gateway Service named `calculator` with this URL: http://www.dneonline.com:80/calculator.asmx.
This simple backend Web Service adds or subtracts 2 numbers.

2) Create a Route on the Service `calculator` with the `path` value `/calculator`

3) Call the `calculator` through the Kong Gateway Route by using [httpie](https://httpie.io/) tool
```
http POST http://localhost:8000/calculator \
Content-Type:"text/xml; charset=utf-8" \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Add>
  </soap:Body>
</soap:Envelope>'
```

The expected result is `12`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>12</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```

## How to configure and test `calculator` Web Service in Kong Ingress Controller (KIC)
1) Configure a Kubernetes `External Service` (to http://www.dneonline.com:80/calculator.asmx) with [kic/extService-Calculator-Ingress.yaml](kic/extService-Calculator-Ingress.yaml) and a related `Ingress` kind:
```sh
kubectl apply -f kic/extService-Calculator-Ingress.yaml
```
2) Call the `calculator` through the Kong Ingress. See example in topic above (How to configure and test `calculator` Web Service in Kong Gateway). Replace `localhost:8000` by the `hostname:port` of the Kong gateway in Kurbenetes

## How to test XML Handling plugins with `calculator`
### Example #1: Request | `XSLT TRANSFORMATION - BEFORE XSD`: adding a Tag in XML request by using XSLT 

The plugin applies a XSLT Transformation on XML request **before** the XSD Validation.
In this example the XSLT **adds the value ```<intB>8</intB>```** which will not be present in the request.

Add `soap-xml-request-handling` plugin and configure the plugin with:
- `xsltTransformBefore` property with this XSLT definition:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output version="1.0" method="xml" encoding="utf-8" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='intA']">
    <xsl:copy-of select="."/>
      <intB>8</intB>
  </xsl:template>
</xsl:stylesheet>
```
Use command defined at step #3, **remove `<intB>7</intB>`**, the expected result is no longer `12` but `13`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```
### Example #2: Request | `XSD VALIDATION`: calling incorrectly `calculator` and detecting issue on the Request with XSD schema
Calling incorrectly `calculator` and detecting issue in the Request with XSD schema. 
We call incorrectly the Service by injecting a SOAP error; the plugin detects it, sends an error message to the Consumer and Kong doesn't call the SOAP backend API.

Open `soap-xml-request-handling` plugin and configure the plugin with:
- `VerboseRequest` enabled
- `XsdApiSchema` property with this value:
```xml
<s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema">
  <s:element name="Add">
    <s:complexType>
      <s:sequence>
        <s:element minOccurs="1" maxOccurs="1" name="intA" type="s:int" />
        <s:element minOccurs="1" maxOccurs="1" name="intB" type="s:int" />
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
</s:schema>
```

Use command defined at step #3, **change** `<soap:Envelope>` by **`<soap:EnvelopeKong>`**  and **change** `</soap:Envelope>` by **`</soap:EnvelopeKong>`** => Kong says: 
```xml
HTTP/1.1 500 Internal Server Error
...
<faultstring>Request - XSD validation failed</faultstring>
<detail>Error Node: EnvelopeKong, Error code: 1845, Line: 2, Message: Element '{http://schemas.xmlsoap.org/soap/envelope/}EnvelopeKong': No matching global declaration available for the validation root.<detail/>
</soap:Fault>
```
Use command defined at step #3, **remove ```<intA>5</intA>```** => there is an error because the ```<intA>``` tag has the ```minOccurs="1"``` XSD property and Kong says: 
```xml
HTTP/1.1 500 Internal Server Error
...
<faultstring>Request - XSD validation failed</faultstring>
<detail>Error Node: Add, Error code: 1871, Line: 1, Message: Element '{http://tempuri.org/}Add': Missing child element(s). Expected is ( {http://tempuri.org/}intA ).<detail/>
```
### Example #3: Request | `XSLT TRANSFORMATION - AFTER XSD`:  renaming a Tag in XML request by using XSLT
The plugin applies a XSLT Transformation on XML request **after** the XSD Validation.
In this example we **change the Tag name from `<Subtract>...</Subtract>`** (present in the request) **to `<Add>...</Add>`**.

**Without XSLT**: Use command defined at step #3, rename the Tag `<Add>...</Add>`, to `<Subtract>...</Subtract>`, remove `<b>7</b>`, so the new command is:
```
http POST http://localhost:8000/calculator \
Content-Type:"text/xml; charset=utf-8" \
--raw "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
  <soap:Body>
    <Subtract xmlns=\"http://tempuri.org/\">
      <intA>5</intA>
    </Subtract>
  </soap:Body>
</soap:Envelope>"
```

The expected result is `-3`
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <SubtractResponse xmlns="http://tempuri.org/">
      <SubtractResult>-3</SubtractResult>
    </SubtractResponse>
  </soap:Body>
</soap:Envelope>
```

Open `soap-xml-request-handling` plugin and configure the plugin with:
- `xsltTransformAfter` property with this XSLT definition:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='Subtract']">
    <Add xmlns="http://tempuri.org/"><xsl:apply-templates select="@*|node()" /></Add>
  </xsl:template>
</xsl:stylesheet>
```
**With XSLT**: Use command defined at Example #3, the expected result is `13`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```
### Example #4: Request | `ROUTING BY XPATH`: change the Route of the request to a different hostname and path depending of XPath condition
The plugin searches the XPath entry and compares it to a Condition value. If this is the right Condition value, the plugin changes the host and the path of the Route.

This example uses a new backend Web Service (https://ecs.syr.edu/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx), which provides the same capabilities as `calculator` Service (http://www.dneonline.com) defined at step #1. 

Add a Kong `Upstream` named `ecs.syr.edu` and defines a `target` with `ecs.syr.edu:443` value. 
Open `soap-xml-request-handling` plugin and configure the plugin with:
- `RouteToPath` property with the value `https://ecs.syr.edu/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx`
- `RouteXPath` property with the value `/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'a']`
- `RouteXPathCondition` property with the value `5`
- `RouteXPathRegisterNs` leave the default value; we can also register specific NameSpace with the syntax `prefix,uri`
- `xsltTransformAfter` property with the following XSLT definition (the `ecs.syr.edu` uses `a` and `b` parameters instead of `ìntA` and `intB` so we have to change the XSLT transformation to make the proper call):

```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">   
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
  <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//*[local-name()='Subtract']">
    <Add xmlns="http://tempuri.org/"><xsl:apply-templates select="@*|node()" /></Add>
  </xsl:template>
  <xsl:template match="//*[local-name()='intA']">
    <a><xsl:apply-templates select="@*|node()" /></a>
  </xsl:template>
  <xsl:template match="//*[local-name()='intB']">
    <b><xsl:apply-templates select="@*|node()" /></b>
  </xsl:template>
</xsl:stylesheet>
```
Use command defined at Example #3, the expected result is `13`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```
For testing purposes only: one can play with the `RouteToPath` to raise a 503 error by temporarily replacing `ecs.syr.edu` by `ecs.syr.edu.WXYZ`
### Example #5: Response | `XSLT TRANSFORMATION - BEFORE XSD`: changing a Tag name in XML response by using XSLT
The plugin applies a XSLT Transformation on XML response **before** the XSD Validation.
In this example the XSLT **changes the Tag names**:
-  from `<AddResult>...</AddResult>` (present in the response) to **`<KongResult>...</KongResult>`**

Add `soap-xml-response-handling` plugin and configure the plugin with:
- `VerboseResponse` enabled
- `xsltTransformBefore` property with this XSLT definition:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//*[local-name()='AddResult']">
    <KongResult><xsl:apply-templates select="@*|node()" /></KongResult>
  </xsl:template>
</xsl:stylesheet>
```
Use command defined at Example #3, the expected result is `<KongResult>13</KongResult>`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <KongResult>13</KongResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```
### Example #6: Response | `XSD VALIDATION`: checking validity of XML response with its XSD schema
Open `soap-xml-response-handling` plugin and configure the plugin with:
- `XsdApiSchema` property with this value:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="KongResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```
For testing purposes only: one can play with the XSD schema to raise error by temporarily replacing `KongResult` by `KongResult2`

### Example #7: Response | `XSLT TRANSFORMATION - AFTER XSD`:  transforming the SOAP response to a XML response
In this example the XSLT removes all <soap> tags and **converts the response from SOAP to XML**.

Open `soap-xml-response-handling` plugin and configure the plugin with:
- `xsltTransformAfter` property with this value:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" exclude-result-prefixes="soapenv">
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <!-- remove all elements in the soapenv namespace -->
  <xsl:template match="soapenv:*">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  <!-- for the remaining elements (i.e. elements in the default namespace) ... -->
  <xsl:template match="*">
      <!-- ... create a new element with similar name in no-namespace -->
      <xsl:element name="{local-name()}">
          <xsl:apply-templates select="@*|node()"/>
      </xsl:element>
  </xsl:template>
  <!-- convert attributes to elements -->
  <xsl:template match="@*">
      <xsl:element name="{local-name()}">
          <xsl:value-of select="." />
      </xsl:element>
  </xsl:template>
</xsl:stylesheet>
```
Use command defined at Example #3, the expected result is:
```xml
<?xml version="1.0" encoding="utf-8"?>
<addResponse>
  <KongResult>13</KongResult>
</addResponse>
```

### Example #8: Response | Use a SOAP/XML WebService with a `Content-Encondig: gzip`
With `Content-Encondig: gzip` the SOAP/XML Response body is zipped. So the `soap-xml-response-handling` has to unzip the SOAP/XML Response body, apply XSD and XSLT handling and re-zip the SOAP/XML Response body.

In this example the XSLT **changes the Tag names**:
-  from `<m:NumberToWordsResult>...</m:NumberToWordsResult>` (present in the response) to **`<KongResult>...</KongResult>`**

1) Create a Kong Service named `dataAccess` with this URL: https://www.dataaccess.com/webservicesserver/NumberConversion.wso. This simple backend Web Service converts a digit number to a number in full

2) Create a Route on the Service `dataAccess` with the `path` value `/dataAccess`

3) Call the `dataAccess` through the Kong Gateway Route by using [httpie](https://httpie.io/) tool
```
http 'http://localhost:8000/dataAccess' \
Content-Type:'text/xml; charset=utf-8' \
Accept-Encoding:'gzip' \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <NumberToWords xmlns="http://www.dataaccess.com/webservicesserver/">
      <ubiNum>500</ubiNum>
    </NumberToWords>
  </soap:Body>
</soap:Envelope>'
```

The expected result is zipped with `Content-Encoding: gzip` header and we get `<m:NumberToWordsResult>five hundred </m:NumberToWordsResult>`
```xml
...
Connection: keep-alive
Content-Encoding: gzip
Content-Length: 213
...
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <m:NumberToWordsResponse xmlns:m="http://www.dataaccess.com/webservicesserver/">
      <m:NumberToWordsResult>five hundred </m:NumberToWordsResult>
    </m:NumberToWordsResponse>
  </soap:Body>
</soap:Envelope>
```
4) Add `soap-xml-response-handling` plugin and and configure the plugin with:
- `xsltTransformBefore` property with this value:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
   <xsl:template match="//*[local-name()='NumberToWordsResult']">
    <KongResult>
      <xsl:apply-templates select="@*|node()" />
    </KongResult>
  </xsl:template>
</xsl:stylesheet>
```
Use command defined at step #3, the expected result is zipped with `Content-Encoding: gzip` header and we get `<KongResult>five hundred </KongResult>`
```xml
Connection: keep-alive
Content-Encoding: gzip
Content-Length: 185
...
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <m:NumberToWordsResponse xmlns:m="http://www.dataaccess.com/webservicesserver/">
      <KongResult>five hundred </KongResult>
    </m:NumberToWordsResponse>
  </soap:Body>
</soap:Envelope>
```

### Example #9: Request | `WSDL VALIDATION`: use a WSDL definition, which imports an XSD schema from an external entity (i.e.: http(s)://)
Call correctly `calculator` and detect issue in the Request with a WSDL definition. The XSD schema content is not configured in the plugin itself but it's downloaded from an external entity. 
In this example we use the Kong Gateway itself to serve the XSD schema (through the WSDL definition), see the import in `wsdl`
```xml
<xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:8000/tempuri.org.request-response.xsd"/>
```

1) Create a Kong Route named `tempuri.org.request-response.xsd` with the `path` value `/tempuri.org.request-response.xsd`

2) Add `Request Termination` plugin to this Route and configure the plugin with:
- `body` property with this `XSD` value:
```xml
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Add" type="tem:AddType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="Subtract" type="tem:SubtractType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="SubtractType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="AddResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```
- `content_type` property with the value `text/xml`
- `status_code` property with the value `200`

3) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins 

4) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `ExternalEntityLoader_CacheTTL` property with the value `15` seconds
- `VerboseRequest` enabled
- `XsdApiSchema` property with this `WSDL` value:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                  xmlns:tns="http://tempuri.org/"
                  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                  name="Tempuri.org"
                  targetNamespace="http://tempuri.org/">
  <wsdl:documentation>Tempuri.org - Add and Subtract calculation
  </wsdl:documentation>
  <wsdl:types>
    <!-- XSD schema for the Request and the Response -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:8000/tempuri.org.request-response.xsd"/>
    </xsd:schema>
  </wsdl:types>
</wsdl:definitions>
```

5) check prerequisite: **have at least 2 Nginx worker processes** because the External Entity loader uses the `socket.http` library which is a blocking library.
```
KONG_NGINX_WORKER_PROCESSES=2
```
Note: 
  - The non-blocking `resty.http` library cannot be used because it raises a conflict issue with `libxml2`: `attempt to yield across C-call boundary` 
  - To avoid this limitation please enable the experimental `ExternalEntityLoader_Async` property (which uses `resty.http`)

6) Call the `calculator` through the Kong Gateway Route
```
http POST http://localhost:8000/calculator \
Content-Type:"text/xml; charset=utf-8" \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Add>
  </soap:Body>
</soap:Envelope>'
```

The expected result is: 
```xml
...
<AddResult>12</AddResult>
...
```
Use previous command defined, **remove ```<intA>5</intA>```** => there is an error because the ```<intA>``` tag has the ```minOccurs="1"``` XSD property and Kong says: 
```xml
HTTP/1.1 500 Internal Server Error
...
<faultstring>Request - XSD validation failed</faultstring>
<detail>Error Node: intB, Error code: 1871, Line: 5, Message: Element '{http://tempuri.org/}intB': This element is not expected. Expected is ( {http://tempuri.org/}intA ).<detail/>
```

### Example #10-a: Request | `WSDL VALIDATION`: use a WSDL definition, which imports an XSD schema from the plugin configuration (no download)
Call incorrectly `calculator` and detect issue in the Request with a WSDL definition. The XSD schema content is configured in the plugin itself and it isn't downloaded from an external entity. 
1) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins 

2) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `VerboseRequest` enabled
- `XsdApiSchema` property with this `WSDL` value:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                  xmlns:tns="http://tempuri.org/"
                  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                  name="Tempuri.org"
                  targetNamespace="http://tempuri.org/">
  <wsdl:documentation>Tempuri.org - Add and Subtract calculation
  </wsdl:documentation>
  <wsdl:types>
    <!-- XSD schema for the Request and the Response -->
      <xsd:schema
        xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
        targetNamespace="http://schemas.xmlsoap.org/soap/envelope/"
        attributeFormDefault="qualified"
        elementFormDefault="qualified">
      <xsd:import namespace="http://tempuri.org/" schemaLocation="http://localhost:8000/tempuri.org.request-response.xsd"/>
    </xsd:schema>
  </wsdl:types>
</wsdl:definitions>
```
- `xsdApiSchemaInclude` property with this value:
  - key: `http://localhost:8000/tempuri.org.request-response.xsd`
  - value: 
```xml
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Add" type="tem:AddType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="Subtract" type="tem:SubtractType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="SubtractType">
    <xs:sequence>
      <xs:element type="xs:integer" name="intA" minOccurs="1"/>
      <xs:element type="xs:integer" name="intB" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="AddResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```
  - Note: `xsdApiSchemaInclude` is type of `map`. You can add all the `XSD` entries required. There is no limit of XSD files.

3) Call the `calculator` through the Kong Gateway Route. Use command defined at step #6 of Use case #9

### Example #10-b: Request | `WSDL VALIDATION`: use a WSDL definition, which imports an XSD schema with Kong Ingress Controller (KIC)
1) If it’s not done yet, create the Kubernetes External Service and the related Ingress kind (see topic: `How to configure and test calculator Web Service in Kong Ingress Controller (KIC)`)
2) Create the Kubernetes `KongPlugin` of `soap-xml-request-handling`. The yaml file ([kic/kongPlugin-SOAP-XML-request.yaml](kic/kongPlugin-SOAP-XML-request.yaml)) is already configured in regards of `example #10-a`: `wsdl` in `XsdApiSchema` and `XSD` import in `xsdApiSchemaInclude`
```sh
kubectl apply -f kic/kongPlugin-SOAP-XML-request.yaml
```
3) Annotate the Ingress with `KongPlugin`
```sh
kubectl annotate ingress calculator-ingress konghq.com/plugins=calculator-soap-xml-request-handling
```
4) Call the `calculator` through the Kong Ingress. Use command defined at step #6 of Use case #9. Replace `localhost:8000` by the `hostname:port` of the Kong gateway in Kurbenetes

### Example #11: Request and Response | `XSLT 3.0 TRANSFORMATION` with the `saxon` library
See [SAXON.md](SAXON.md)

## Plugins Testing
The plugins testing is available through [pongo](https://github.com/Kong/kong-pongo)
1) Download pongo
2) Initialize pongo
3) Run tests with [pongo.sh](pongo.sh) and **adapt the `KONG_IMAGE` value** according to expectations

Note: If the Kong Docker image with `saxon` has been rebuilt, run a `pongo clean` for rebuilding the Pongo image

## Changelog
- v1.0.0:
  - Initial Release
- v1.0.1:
  - Improve the behavior of SOAP/XML Handling plugins in conjunction with the Kong System plugins: Rate Limiting, Auth (OIDC, basic-auth, etc.)
  - Reformat the JSON Error messages (of Kong System plugins) to a SOAP/XML `<soap:Fault>` error
- v1.0.2:
  - Add the capacity to provide `wsdl` content to `xsdApiSchema`. The raw `<xs:schema>` is still valid
- v1.0.3:
  - When `VerboseRequest` or  `VerboseResponse` are disabled, the plugins no longer send the detailed error to the logs
- v1.0.4:
  - Improve the log error management by initializing it in the `init_worker` phase
- v1.0.5:
  - Add an external loader (http)
- v1.0.6: 
  - Add `Timeout` and `Cache_TTL` parameters related to the External Entity Loader (http(s))
  - Put the detailed error message in `<detail>` of `<soap:Fault>` message in case `VerboseRequest` or `VerboseResponse` is enabled
  - Adapt the `schema.lua` to be Konnect compatible
- v1.0.7: 
  - Change example material from `https://ecs.syr.edu` (no longer available) to `http://www.dneonline.com`
  - Improve `Routing By XPath` by putting in one plugin property the complete routing URL and by enabling the usage of a Host (not only a Kong Upstream)
  - Add experimental `ExternalEntityLoader_Async` capacity for downloading Asynchronously the XSD External Entities
- v1.0.8: 
  - Add https support to Synchronous external loader (https)
  - `WSDL validation`: Get the Namespace definitons found in `<wsdl:definitions>` and add them in `<xsd:schema>` (if they don't exist)
- v1.0.9: 
  - In case of `request-termination` plugin there is no longer SOAP/XML - 200 error
  - `xsdApiSchemaInclude`: support the inclusion of multiple XSD schemas in the plugin configuration (without download external entity)
  - Enhance the documentation for Kubernetes, Konnect and KIC
- v1.0.10:
  - Due to Kong v3.7+, update the Kong's library used for gzip compression (from `kong.tools.utils` to `kong.tools.gzip`)
- v1.0.11:
  - Add `pongo` tests
- v1.1.0:
  - Add `saxon` Home Edition (v12.5) library for supporting XSLT 2.0 or 3.0
  - Fix a free memory issue for `libxslt` (and avoid `[alert] 1#0: worker process **** exited on signal 11` error during Nginx shutdown)
  - Add an `Error Handler` for `libxslt` to detect correctly the unsupported XLST 2.0 or 3.0
  - Add `jit.off()` for `libxml` to avoid `nginx: lua atpanic: Lua VM crashed, reason: bad callback` error
- v1.1.1:
  - Add the `saxon` notices files (related to the Saxon license distribution)
  - Add support for `XML` to `JSON` transformation
  - Rename the `kong-saxon-initcontainer` and `kong-saxon` docker images
- v1.1.2:
  - `saxon` library: remove the `xsltSaxonTemplate` and `xsltSaxonTemplateParam` parameters and use `XSLT` without `<xsl:template name="main">`
  - Add `conf/saxonConf.xml` for `saxon` configuration file 
  - Add nginx `pid` for `saxon` logs
- v1.1.3:
  - Load `saxon` library during the `configure` nginx phase only if necessary
- v1.1.4:
  - `ExternalEntityLoader_Async`: replace `nginx.timer.at` by `kong.tools.queue`
- v1.1.5:
  - Remove the `require("kong.plugins.soap-xml-handling-lib.xmlgeneral")` declared on each phase to a global definition
  - `ExternalEntityLoader_Async`: replace the `kong.xmlSoapAsync.entityLoader.urls` to a LRU cache
  - Replace `plugin.PRIORITY` by `plugin.__plugin_id` regarding the Error management
- v1.1.6:
  - `ExternalEntityLoader_Async`: use a `kong.tools.queue` to execute a WSDL/XSD validation prefetch on the `configure` nginx phase (for downloading the `ìmport`ed XSD)
