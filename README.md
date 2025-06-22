# Kong plugins: SOAP/XML Handling for Request and Response
This repository concerns Kong plugins developed in Lua, which use the GNOME C libraries [libxml2](https://gitlab.gnome.org/GNOME/libxml2#libxml2) and [libxslt](https://gitlab.gnome.org/GNOME/libxslt#libxslt) (for XSLT 1.0). Part of the functions are bound in the [XMLua/libxml2](https://clear-code.github.io/xmlua/) library.
Both GNOME C and XMLua/libxml2 libraries are already included in [kong/kong-gateway](https://hub.docker.com/r/kong/kong-gateway) Enterprise Edition Docker image, so you don't need to rebuild a Kong image.

The XSLT Transformation can also be managed with the [saxon](https://www.saxonica.com/html/welcome/welcome.html) library, which supports XSLT 2.0 and 3.0. With XSLT 2.0+ there is a way for applying JSON <-> XML transformation with [fn:json-to-xml](https://www.w3.org/TR/xslt-30/#func-json-to-xml) and [fn:xml-to-json](https://www.w3.org/TR/xslt-30/#func-xml-to-json). The `saxon` library is not included in the Kong Docker image, see [SAXON.md](SAXON.md) for how to integrate saxon with Kong. It's optional, don't install the `saxon` library if you don't need it.

These plugins don't apply to Kong OSS. They work for Kong EE and Konnect.

The plugins handle the SOAP/XML **Request** and/or the SOAP/XML **Response** in this order:

**soap-xml-request-handling** plugin to handle Request:

1) `XSLT TRANSFORMATION - BEFORE XSD`: Transform the XML request with XSLT (XSLTransformation) before step #2
2) `WSDL/XSD VALIDATION`: Validate XML request with its WSDL/XSD schema (and optionnaly validate the `SOAPAction` header)
3) `XSLT TRANSFORMATION - AFTER XSD`: Transform the XML request with XSLT (XSLTransformation) after step #2
4) `ROUTING BY XPATH`: change the Route of the request to a different hostname and path depending of XPath condition

**soap-xml-response-handling** plugin to handle Reponse:

5) `XSLT TRANSFORMATION - BEFORE XSD`: Transform the XML response before step #6
6) `WSDL/XSD VALIDATION`: Validate the XML response with its WSDL/XSD schema
7) `XSLT TRANSFORMATION - AFTER XSD`:  Transform the XML response after step #6

Each handling is optional (except for `WSDL/XSD VALIDATION` for SOAP schema, due to the default value of the schema config)

---

1. [Information and Recommendation](#information_recommendation)
2. [Configuration Reference](#configuration_reference)
3. [How to deploy SOAP/XML Handling plugins](#deployment)
    1. [Docker](#docker)
    2. [Schema plugins in Konnect (Control Plane) for Kong Gateway](#Konnect_CP_for_Kong_Gateway)
    3. [Schema plugins in Konnect (Control Plane) for Kong Ingress Controller (KIC)](#Konnect_CP_for_KIC)
    4. [Kong Gateway (Data Plane) | Kubernetes](#Konnect_DP_for_K8S)
4. [Quick Test: How to test an XML calculator Web Service without the plugins](#Quick_Test)
    1. [Kong Gateway - online calculator](#Quick_Test_Kong_Gateway_online)
    2. [Kong Gateway - local Docker calculator](#Quick_Test_Kong_Gateway_local_Docker)
    3. [Kong Ingress Controller (KIC) - online calculator](#Quick_Test_KIC_online)
5. [Main Example: How to test XML Handling plugins with calculator](#Main_Example)
    1. [Example #1: Request | XSLT TRANSFORMATION - BEFORE XSD](#Main_Example_1)
    2. [Example #2: Request | XSD VALIDATION](#Main_Example_2)
    3. [Example #3: Request | XSLT TRANSFORMATION - AFTER XSD](#Main_Example_3)
    4. [Example #4: Request | ROUTING BY XPATH](#Main_Example_4)
    5. [Example #5: Response | XSLT TRANSFORMATION - BEFORE XSD](#Main_Example_5)
    6. [Example #6: Response | XSD VALIDATION](#Main_Example_6)
    7. [Example #7: Response | XSLT TRANSFORMATION - AFTER XSD](#Main_Example_7)
6. [Miscellaneous examples](#Miscellaneous_examples)
    1. [Example (A) : Response | Use a SOAP/XML WebService with gzip](#Miscellaneous_example_A)
    2. [Example (B) : Request | Use a WSDL definition, which imports XSD schemas from external entity FILE](#Miscellaneous_example_B)
    3. [Example (C1): Request | Use a WSDL definition, which imports an XSD schema from the plugin configuration](#Miscellaneous_example_C1)
    4. [Example (C2): Request | Use a WSDL definition, which imports an XSD schema from the plugin configuration for KIC](#Miscellaneous_example_C2)
    5. [Example (D) : Request | Use a WSDL definition, which imports an XSD schema from an external entity URL](#Miscellaneous_example_D)
    6. [Example (E) : Request and Response | XSLT 3.0 with the saxon library](#Miscellaneous_example_E)
    7. [Example (F) : Request and Response | use a SOAP 1.2 XSD definition and the calculator API XSD definition](#Miscellaneous_example_F)
    8. [Example (G) : Request | validate the SOAPAction Http header](#Miscellaneous_example_G)
    9. [Example (H): Request | XSLT with parameters applied by  libxslt (or saxon) library](#Miscellaneous_example_H)
7. [W3C Compatibility Matrix](#w3c-compatibility-matrix)
8. [Plugins Testing](#Plugins_Testing)
9. [Known Limitations](#Known_Limitations)
10. [Changelog](#Changelog)

![Alt text](/images/Pipeline-Kong-soap-xml-handling.jpeg?raw=true "Kong - SOAP/XML execution pipeline")

![Alt text](/images/Kong-Manager.jpeg?raw=true "Kong - Manager")

<a id="information_recommendation"></a>

## Information and Recommendation
### XML Definitions in files
The XML definitions (for WSDL/XSD/XSLT) can be put on the Kong Gateway file system rather using a raw definition. 
Example for `config.xsdApiSchema`:
- WSDL raw definition: `<wsdl:definitions> ... </wsdl:definitions>`
- WSDL file definition: `/usr/local/apiclient.wsdl`

The user is in charge of putting the definition files on the Kong Gateway file system.

### Import and External entities
WSDL and XSD definitions can import other definitions by using `<import>` tag:
- URL (`http(s)://`), example: `<import schemaLocation ="https://client.net/FaultMessage.xsd"/>`
- File, example: `<import schemaLocation ="/usr/local/FaultMessage.xsd"/>`

The plugins manage both types of import:
- URL (`http(s)://`): the plugins synchronously or asynchronously download the definition
- File: the plugins read the definition from the Kong Gateway file system

### Caching
- The plugins compile/parse the WSDL/XSD/XSLT definitions and keep them in a Kong memory cache for improving performance
- WSDL/XSD: in case of error due to incorrect definition (e.g. missing a leading "<"), the plugins compile/parse the definition again on each call
- XSLT: the error message is kept in the cache
- WSDL/XSD: when the TTL is reached the plugins compile/parse once more
- The difference in behavior (WSDL/XSD vs XSLT) comes from the external entities URL that can be downloaded without any guarantee of the result (and the download of external entities URL is only provided by WSDL/XSD)
- If the plugin configuration changes, the cache is refreshed for all plugins (even if there is a change in only one plugin)
- The caching is not compatible with Asynchronous download of External Entities URL (`config.ExternalEntityLoader_Async`=`true`)

### Recommendation
1) When defining a large number of `soap-xml-handling` plugins (let's say +100), prefer using WSDL/XSD/XSLT definition in files rather than raw definitions. It drastically decreases the memory size of the Kong Gateway configuration sent by the Control Plane.

2) When importing definitions, it is recommended to configure the plugins preferably in this order:
    1) Use the File definition (in case of high number of `soap-xml-handling` plugins)
    2) Put the content in `config.xsdSoapSchemaInclude` or `config.xsdApiSchemaInclude`
    3) Use URL External Entities (and choose the type of download: synchronous or asynchronous)

### Error management
In case of misconfiguration the Plugins send to the consumer a SOAP Fault (HTTP 500 Internal Server Error) following the W3C specification:
- [SOAP Fault 1.1](https://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383507):
  - `<faultstring>`: name of the handling process of the plugin
  - `<faultcode>`: the values are `Client` (for a Consumer error) and `Server` (for a Server error: Kong or Web Service)
- [SOAP Fault 1.2](https://www.w3.org/TR/soap12-part1/#soapfault):
  - `<Reason><Text>`: name of the handling process of the plugin
  - `<Code><Value>`: the values are `Sender` (for a Consumer error) and `Receiver` (for a Server error: Kong or Web Service)

If `Verbose` is enabled:
- the `<errorMessage>` contains the detail of the error
- the `soap-xml-response-handling` adds a `<backendHttpCode>` with the Http status code of the Web Service

<a id="configuration_reference"></a>

## `soap-xml-request-handling` and `soap-xml-response-handling` configuration reference
|FORM PARAMETER                 |DEFAULT          |DESCRIPTION                                                 |
|:------------------------------|:----------------|:-----------------------------------------------------------|
|config.ExternalEntityLoader_Async|`false`|Asynchronously download the XSD schema from an external entity (i.e.: http(s)://). It executes a WSDL/XSD validation prefetch on the `configure` phase (for downloading the ìmported XSD ahead of the 1st request)|
|config.ExternalEntityLoader_CacheTTL|`3600`|Keep the XSD schema in Kong memory cache during the time specified (in second). It applies for synchronous and asynchronous XSD download|
|config.ExternalEntityLoader_Timeout|`1`|Timeout in second for XSD schema downloading. It applies for synchronous and asynchronous XSD download|
|config.RouteXPathTargets|N/A|Array of targets for routing by XPath. The plugin executes all the XPath expressions until the condition is satisfied. If no condition is satisfied the plugin keeps the original Route without error|
|config.RouteXPathTargets.URL|N/A|URL to dynamically change the route to the Web Service. Syntax is: `scheme://kong_upstream/path` or `scheme://hostname[:port]/path`|
|config.RouteXPathTargets.XPath|N/A|XPath expression to extract a value from the request body and to compare it with `XPathCondition`|
|config.RouteXPathTargets.XPathCondition|N/A|XPath condition value to compare with the value extracted by `XPath` expression. If the condition is satisfied the route is changed to `URL`|
|config.RouteXPathRegisterNs|Pre-defined|Array of NameSpaces to be registered for applying XPath expression. The syntax is `prefix,namespace`. If this is the defauft Namespace without a prefix (like `xmlns=http://...` instead of `xmlns:xsd=http://...`) set a a fake prefix like `myprefix,http://...`|
|config.SOAPAction_Header|`no`|`soap-xml-request-handling` only: validate the value of the `SOAPAction` Http header in conjonction with `WSDL/XSD VALIDATION`. If `yes` is set, the `xsdSoapSchema` must be defined with a WSDL 1.1 (including `<wsdl:binding>` and `soapAction` attributes) or with a WSDL 2.0 (including `<wsdl2:interface>` and `Action` attribute). For WSDL 1.1 the optional `soapActionRequired` attribute is considered and for WSDL 2.0 the default action pattern is used if no `Action` is set (as defined by the [W3C](https://www.w3.org/TR/2007/REC-ws-addr-metadata-20070904/#defactionwsdl20)). If `yes_null_allowed` is set, the plugin works as defined with `yes` configuration and top of that it allows the request even if the `SOAPAction` is not present. The `SOAPAction` = `''` is not considered a valid value|
|config.VerboseRequest|`false`|`soap-xml-request-handling` only: enable a detailed error message sent to the consumer. The syntax is `<detail>...</detail>` in the `<soap:Fault>` message|
|config.VerboseResponse|`false`|`soap-xml-response-handling` only: see above|
|config.xsdApiSchema|`false`|WSDL/XSD schema used by `WSDL/XSD VALIDATION` for the Web Service tags|
|config.xsdApiSchemaInclude|`false`|XSD content included in the plugin configuration. It's related to `xsdApiSchema`. It avoids downloading content from external entity (i.e.: http(s)://). The include has priority over the download from external entity. It's the **recommended** option instead of using `ExternalEntityLoader_Async`|
|config.xsdSoapSchema|Pre-defined with `SOAP` v1.1|WSDL/XSD schema used by `WSDL/XSD VALIDATION` for the `<soap>` tags: `<soap:Envelope>`, `<soap:Header>`, `<soap:Body>`|
|config.xsdSoapSchemaInclude|`false`|XSD content included in the plugin configuration. It's related to `xsdSoapSchema`. It avoids downloading content from external entity (i.e.: http(s)://). The include has priority over the download from external entity|
|config.xsltLibrary|`libxslt`|Library name for `XSLT TRANSFORMATION`. Select `saxon` for supporting XSLT 2.0 or 3.0
|config.xsltParams|N/A|Named parameter (`<xsl:param>`) to use in XSL schema. Used by `XSLT TRANSFORMATION` `BEFORE XSD` and `AFTER XSD`
|config.xsltTransformAfter|N/A|`XSLT` definition used by `XSLT TRANSFORMATION - AFTER XSD`|
|config.xsltTransformBefore|N/A|`XSLT` definition used by `XSLT TRANSFORMATION - BEFORE XSD`|

<a id="deployment"></a>

## How to deploy SOAP/XML Handling plugins

<a id="docker"></a>

###  How to deploy SOAP/XML Handling plugins in Kong Gateway (standalone) | Docker
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
<a id="Konnect_CP_for_Kong_Gateway"></a>

### How to deploy SOAP/XML Handling plugins **schema** in Konnect (Control Plane) for Kong Gateway
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

<a id="Konnect_CP_for_KIC"></a>

### How to deploy SOAP/XML Handling plugins **schema** in Konnect (Control Plane) for Kong Ingress Controller (KIC)
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
<a id="Konnect_DP_for_K8S"></a>

### How to deploy SOAP/XML Handling plugins in Kong Gateway (Data Plane) | Kubernetes
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
3) [See Kong Gateway in Kubernetes documentation](https://docs.konghq.com/gateway/latest/install/kubernetes/proxy/) and add the following properties to the helm `values.yaml`:
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
<a id="Quick_Test"></a>

## Quick Test: How to test an XML `calculator` Web Service without the plugins

<a id="Quick_Test_Kong_Gateway_online"></a>

### How to configure and test online `calculator` Web Service in Kong Gateway
1) Create a Kong Gateway Service named `calculator` with this URL: http://www.dneonline.com:80/calculator.asmx.
This simple backend Web Service adds or subtracts 2 numbers.

2) Create a Route on the `calculator` Service with the `path` value `/calculator`

3) Call the `calculator` through the Kong Gateway Route by using [httpie](https://httpie.io/) tool
```
http POST http://localhost:8000/calculator \
Content-Type:'text/xml; charset=utf-8' \
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

<a id="Quick_Test_Kong_Gateway_local_Docker"></a>

### How to configure and test local Docker `calculator` Docker Web Service in Kong Gateway
If you prefer to use the `calculator` Web Service deployed locally in Docker:
1) Create a `calculator` container
```shell
docker run --network=kong-net -d --name ws-soap-calulator --env X_SOAP_REGION=soap1 -p 8080:8080 jeromeguillaume/ws-soap-calculator
```
2) Create a Kong Gateway Service named `calculator` with this URL: http://ws-soap-calulator:8080/ws
3) Create a Route on the Service `calculator` with the `path` value `/calculator`
4) Call the `calculator` by seeing example in topic above (How to configure and test online `calculator` Web Service in Kong Gateway)

<a id="Quick_Test_KIC_online"></a>

### How to configure and test online `calculator` Web Service in Kong Ingress Controller (KIC)
1) Configure a Kubernetes `External Service` (to http://www.dneonline.com:80/calculator.asmx) with [kic/extService-Calculator-Ingress.yaml](kic/extService-Calculator-Ingress.yaml) and a related `Ingress` kind:
```sh
kubectl apply -f kic/extService-Calculator-Ingress.yaml
```
2) Call the `calculator` through the Kong Ingress. See example in topic above (How to configure and test online `calculator` Web Service in Kong Gateway). Replace `localhost:8000` by the `hostname:port` of the Kong gateway in Kurbenetes

<a id="Main_Example"></a>

## Main Example: How to test XML Handling plugins with `calculator`
Apply the following examples for testing all capabilities of both plugins. The examples (from Example #1 to Example #7) are related. So apply Example #1 first, then Example #2 (by keeping the configuration of Example #1), etc.

<a id="Main_Example_1"></a>

### Example #1: Request | `XSLT TRANSFORMATION - BEFORE XSD`: adding a Tag in XML request by using XSLT 

The plugin applies an XSLT Transformation on XML request **before** the XSD Validation.
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

<a id="Main_Example_2"></a>

### Example #2: Request | `XSD VALIDATION`: calling incorrectly `calculator` and detecting issue on the Request with XSD schema
Calling incorrectly `calculator` and detecting issue in the Request with XSD schema. 
We call incorrectly the Service by injecting a SOAP error; the plugin detects it, sends an error message to the Consumer and Kong doesn't call the SOAP backend API.

Open `soap-xml-request-handling` plugin and configure the plugin with:
- `VerboseRequest` enabled
- `xsdApiSchema` property with this value:
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
<detail>
  <errorMessage>Error Node: EnvelopeKong, Error code: 1845, Line: 2, Message: Element '{http://schemas.xmlsoap.org/soap/envelope/}EnvelopeKong': No matching global declaration available for the validation root.</errorMessage>
<detail/>
</soap:Fault>
```
Use command defined at step #3, **remove ```<intA>5</intA>```** => there is an error because the ```<intA>``` tag has the ```minOccurs="1"``` XSD property and Kong says: 
```xml
HTTP/1.1 500 Internal Server Error
...
<faultstring>Request - XSD validation failed</faultstring>
<detail>
  <errorMessage>Error Node: Add, Error code: 1871, Line: 1, Message: Element '{http://tempuri.org/}Add': Missing child element(s). Expected is ( {http://tempuri.org/}intA ).</errorMessage>
<detail/>
```

<a id="Main_Example_3"></a>

### Example #3: Request | `XSLT TRANSFORMATION - AFTER XSD`:  renaming a Tag in XML request by using XSLT
The plugin applies an XSLT Transformation on XML request **after** the XSD Validation.
In this example we **change the Tag name from `<Subtract>...</Subtract>`** (present in the request) **to `<Add>...</Add>`**.

**Without XSLT**: Use command defined at step #3, rename the Tag `<Add>...</Add>`, to `<Subtract>...</Subtract>`, remove `<b>7</b>`, so the new command is:
```
http POST http://localhost:8000/calculator \
Content-Type:'text/xml; charset=utf-8' \
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
**With XSLT**: Use previous command, the expected result is `13`:
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

<a id="Main_Example_4"></a>

### Example #4: Request | `ROUTING BY XPATH`: change the Route of the request to a different hostname and path depending of XPath condition
The plugin executes an XPath expression and compares it to a Condition value. If this is the right Condition value, the plugin changes the host and the path of the Route. The plugin executes all the XPath expressions until the condition is satisfied. If no condition is satisfied the plugin keeps the original Route.

This example uses a new backend Web Service (https://calculator.apim.eu:443/ws), which provides the same capabilities as `calculator` Service (http://www.dneonline.com) defined at step #1. 

Add a Kong `Upstream` named `calculator.apim.eu` and defines a `target` with `calculator.apim.eu:443` value. 

Open `soap-xml-request-handling` plugin and configure it with:
- `RouteXPathRegisterNs` leave the default value and add `tempuri_kong,http://tempuri.org/`
- `RouteXPathTargets` add a new (target) item with:
  - `URL` property with the value `https://calculator.apim.eu:443/ws`
  - `XPath` property with the value `/soap:Envelope/soap:Body/*[local-name() = 'Add']/*[local-name() = 'intA']` or `/soap:Envelope/soap:Body/tempuri_kong:Add/tempuri_kong:intA`
  - `XPathCondition` property with the value `5`
Use command defined at Example #3, the expected result is `13`. Pay attention to the `X-SOAP-Region` (http header in the response) added by `calculator.apim.eu`
```xml
HTTP/1.1 200 
X-SOAP-Region: soap1.apim.eu
...
<?xml version="1.0" encoding="utf-8" ?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```
For testing purposes only: one can play with the `RouteToPath` to raise a 503 error by temporarily replacing `calculator.apim.eu` by `calculator.apim.eu.WXYZ`

<a id="Main_Example_5"></a>

### Example #5: Response | `XSLT TRANSFORMATION - BEFORE XSD`: changing a Tag name in XML response by using XSLT
The plugin applies an XSLT Transformation on XML response **before** the XSD Validation.
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

<a id="Main_Example_6"></a>

### Example #6: Response | `XSD VALIDATION`: checking validity of XML response with its XSD schema
Open `soap-xml-response-handling` plugin and configure the plugin with:
- `xsdApiSchema` property with this value:
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
For testing purposes only: one can play with the XSD schema to raise an error by temporarily replacing `KongResult` by `KongResult2`

<a id="Main_Example_7"></a>

### Example #7: Response | `XSLT TRANSFORMATION - AFTER XSD`:  transforming the SOAP response to an XML response
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
---

<a id="Miscellaneous_examples"></a>

## Miscellaneous examples

<a id="Miscellaneous_example_A"></a>

### Example (A): Response | Use a SOAP/XML WebService with a `Content-Encondig: gzip`
With `Content-Encondig: gzip` the SOAP/XML Response body is zipped. So the `soap-xml-response-handling` has to unzip the SOAP/XML Response body, applies XSD and XSLT handling and re-zips the SOAP/XML Response body.

In this example the XSLT converts the response from SOAP to XML

1) Create a new Kong Service named `apim.eu.calculator` with this URL: https://calculator.apim.eu:443/ws, which provides the `gzip` support and the same capabilities as `calculator` Service (http://www.dneonline.com) defined at step #1

2) Create a Route on the Service `apim.eu.calculator` with the `path` value `/apim.eu.calculator`

3) Add `soap-xml-response-handling` plugin and configure the plugin with:
- `xsltTransformAfter` property with this XSLT definition:
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
4) Call the `apim.eu.calculator` through the Kong Gateway Route by using [httpie](https://httpie.io/) tool
```
http POST http://localhost:8000/apim.eu.calculator \
Content-Type:'text/xml; charset=utf-8' \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Multiply xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Multiply>
  </soap:Body>
</soap:Envelope>'
```

The expected result is zipped with `Content-Encoding: gzip` header and we get an XML response (without SOAP tags)
```xml
...
HTTP/1.1 200 OK
Content-Encoding: gzip
...
<?xml version="1.0" encoding="utf-8"?>
<MultiplyResponse>
  <MultiplyResult>35</MultiplyResult>
</MultiplyResponse>
```

<a id="Miscellaneous_example_B"></a>

### Example (B): Request and Response | `WSDL VALIDATION`: use a WSDL definition, which imports XSD schemas from  external entity FILE (Example: `/usr/local/my.wsdl`)
Call correctly `calculator`. The XSD schema content is read from the Kong file system

0) Place the following files on the Kong Gateway file system following the directory name :
  - [`/kong-plugin/spec/fixtures/calculator/2_6_soap11.xsd`](/spec/fixtures/calculator/2_6_soap11.xsd)
  - [`/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import_relative_path.wsdl`](/spec/fixtures/calculator/2_6_soap11.xsd))
  - [`/kong-plugin/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import_relative_path.wsdl`](/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import_relative_path.wsdl)

1) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins 

2) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `VerboseRequest` enabled
- `filePathPrefix` property with this value: `/kong-plugin/spec/fixtures/calculator`
- `xsdSoapSchema` = [`2_6_soap11.xsd`](/spec/fixtures/calculator/2_6_soap11.xsd)
- `xsdApiSchema` = [`2_6_WSDL11_soap12_file_import_relative_path.wsdl`](/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import_relative_path.wsdl)

3) Add `soap-xml-response-handling` plugin to `calculator` and configure the plugin with:
- `VerboseResponse` enabled
- `filePathPrefix` property with this value: `/kong-plugin/spec/fixtures/calculator`
- `xsdSoapSchema` = [`2_6_soap11.xsd`](/spec/fixtures/calculator/2_6_soap11.xsd)
- `xsdApiSchema` = [`2_6_WSDL11_soap12_file_import_relative_path.wsdl`](/spec/fixtures/calculator/2_6_WSDL11_soap12_file_import_relative_path.wsdl)

4) Call the `calculator` through the Kong Gateway Route
```
http POST http://localhost:8000/calculator \
Content-Type:'text/xml; charset=utf-8' \
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

<a id="Miscellaneous_example_C1"></a>

### Example (C1): Request | `WSDL VALIDATION`: use a WSDL definition, which imports an XSD schema from the plugin configuration (no download)
Call incorrectly `calculator` and detect issue in the Request with a WSDL definition. The XSD schema content is configured in the plugin itself and it isn't downloaded from an external entity. 
1) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins 

2) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `VerboseRequest` enabled
- `xsdApiSchema` property with this `WSDL` value:
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
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="AddResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```
  - Note: `xsdApiSchemaInclude` is type of `map`. You can add all the `XSD` entries required. There is no limit of XSD files.

3) Call the `calculator` through the Kong Gateway Route. Use command defined at step #4 of Example (B)

<a id="Miscellaneous_example_C2"></a>

### Example (C2): Request | `WSDL VALIDATION`: use a WSDL definition, which imports an XSD schema from the plugin configuration (no download) for Kong Ingress Controller (KIC)
1) If it’s not done yet, create the Kubernetes External Service and the related Ingress kind (see topic: `How to configure and test calculator Web Service in Kong Ingress Controller (KIC)`)
2) Create the Kubernetes `KongPlugin` of `soap-xml-request-handling`. The yaml file ([kic/kongPlugin-SOAP-XML-request.yaml](kic/kongPlugin-SOAP-XML-request.yaml)) is already configured in regards of `example #10-a`: `wsdl` in `xsdApiSchema` and `XSD` import in `xsdApiSchemaInclude`
```sh
kubectl apply -f kic/kongPlugin-SOAP-XML-request.yaml
```
3) Annotate the Ingress with `KongPlugin`
```sh
kubectl annotate ingress calculator-ingress konghq.com/plugins=calculator-soap-xml-request-handling
```
4) Call the `calculator` through the Kong Ingress. Use command defined at step #4 of Example (B). Replace `localhost:8000` by the `hostname:port` of the Kong gateway in Kurbenetes

<a id="Miscellaneous_example_D"></a>

### Example (D): Request | `WSDL VALIDATION`: use a WSDL definition, which imports an XSD schema from an external entity URL (i.e.: http(s)://)
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
- `ExternalEntityLoader_CacheTTL` property with the value `3600` seconds
- `VerboseRequest` enabled
- `xsdApiSchema` property with this `WSDL` value:
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
  - To avoid this limitation please enable the experimental `ExternalEntityLoader_Async` property (which uses `resty.http`) or use `config.xsdApiSchemaInclude` and `config.xsdSoapSchemaInclude`

6) Call the `calculator` through the Kong Gateway Route
```
http POST http://localhost:8000/calculator \
Content-Type:'text/xml; charset=utf-8' \
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
<detail>
   <errorMessage>Error Node: intB, Error code: 1871, Line: 5, Message: Element '{http://tempuri.org/}intB': This element is not expected. Expected is ( {http://tempuri.org/}intA ). </errorMessage>
<detail/>
```

<a id="Miscellaneous_example_E"></a>

### Example (E): Request and Response | `XSLT 3.0 TRANSFORMATION` with the `saxon` library
See [SAXON.md](SAXON.md)
- Request and Response | `XSLT 3.0 TRANSFORMATION`: JSON (client) to SOAP/XML (server): [here](SAXON.md#example-a-request-and-response--xslt-30-transformation-json-client-to-soapxml-server)
- Request and Response | `XSLT 3.0 TRANSFORMATION`: XML (client) to JSON (server): [here](SAXON.md#example-b-request-and-response--xslt-30-transformation-xml-client-to-json-server)

<a id="Miscellaneous_example_F"></a>

### Example (F): Request and Response | `SOAP 1.2` `XSD VALIDATION`: use a `SOAP 1.2` `XSD` definition and the `calculator` API `XSD` definition
Call correctly `calculator` by using a `SOAP 1.2` enveloppe. The `SOAP 1.2` XSD imports `http://www.w3.org/2001/xml.xsd` schema. This XSD schema content is configured in the plugin itself and it isn't downloaded from an external entity
1) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins

2) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `VerboseRequest` enabled
- `xsdSoapSchema` property: replace the default value by [www.w3.org/2003/05/soap-envelope.xsd](./_tmp.w3.org/www.w3.org|2003|05|soap-envelope.xsd)
- `xsdSoapSchemaInclude` property with this value:
  - key: `http://www.w3.org/2001/xml.xsd`
  - value: see value in [http://www.w3.org/2001/xml.xsd](_tmp.w3.org/www.w3.org|2001|xml.xsd)
- `xsdApiSchema` property with this `XSD` value:
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
</s:schema>
```
3) Add `soap-xml-response-handling` plugin to `calculator` and configure the plugin with:
- `VerboseResponse` enabled
- `xsdSoapSchema` property:  replace the default value by [www.w3.org/2003/05/soap-envelope.xsd](./_tmp.w3.org/www.w3.org|2003|05|soap-envelope.xsd)
- `xsdSoapSchemaInclude` property with this value:
  - key: `http://www.w3.org/2001/xml.xsd`
  - value: see value in [http://www.w3.org/2001/xml.xsd](_tmp.w3.org/www.w3.org|2001|xml.xsd)
- `xsdApiSchema` property with this `XSD` value:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="AddResponse" type="tem:AddResponseType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddResponseType">
    <xs:sequence>
      <xs:element type="xs:string" name="AddResult"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```

4) Call the `calculator` through the Kong Gateway Route
```
http POST http://localhost:8000/calculator \
Content-Type:'application/soap+xml; charset=utf-8' \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Add>
  </soap12:Body>
</soap12:Envelope>'
```

The expected result is: 
```xml
...
<AddResult>12</AddResult>
...
```

<a id="Miscellaneous_example_G"></a>

### Example (G): Request | `WSDL VALIDATION`: validate the `SOAPAction` Http header
Call correctly `calculator` by setting the expected `SOAPAction` Http header. The header name depends of the SOAP version:
- SOAP 1.1: `SOAPAction` Http header
- SOAP 1.2: `action` in `Content-Type` Http header

The WSDL v1.1 and WSDL v2.0 differ in how they define the `SOAPAction`:
- WSDL 1.1: `soapAction` attribute
- WSDL 2.0: `Action` attribute

#### For WSDL 1.1 | SOAP 1.1:
1) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins

2) Change the URL of `calculator` Gateway Service: https://calculator.apim.eu:443/ws

3) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `SOAPAction_Header` property with the value `yes`
- `VerboseRequest` enabled
- `xsdApiSchema` property with this `WSDL 1.1` value: [dneonline.com.wsdl (v1.1)](/_tmp.dneonline.com/dneonline.com.binding_soap1.1_soap1.2.wsdl)

4) Call the `calculator` through the Kong Gateway Route. As the `Àdd` operation name is requested (see `soapActionRequired="true"` in WSDL), the `SOAPAction` has the `http://tempuri.org/Add` value as defined in the WSDL
```
http POST http://localhost:8000/calculator \
Content-Type:'text/xml; charset=utf-8' \
SOAPAction:"http://tempuri.org/Add" \
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
5) If the `SOAPAction` is not set correctly regarding the `WSDL`, the plugin detects it and sends an error message
- Use previous command defined, **remove ```SOAPAction```** and Kong says: 
```xml
HTTP/1.1 500 Internal Server Error
...
<faultstring>Request - XSD validation failed</faultstring>
<detail>
   <errorMessage>Validation of 'SOAPAction' header: The 'SOAPAction' header is not set but according to the WSDL this value is 'Required</errorMessage>
</detail>
```
- Use previous command defined, **set ```SOAPAction:"http://tempuri.org/Subtract"```** and Kong says: 
```xml
HTTP/1.1 500 Internal Server Error
...
<faultstring>Request - XSD validation failed</faultstring>
<detail>
   <errorMessage>Validation of 'SOAPAction' header: The Operation Name found in 'soap:Body' is 'Add'. According to the WSDL the 'SOAPAction' should be 'http://tempuri.org/Add' and not 'http://tempuri.org/Subtract'</errorMessage>
</detail>
```

6) If the `SOAPAction` is not set but there is `soapActionRequired="false"` (in the WSDL) for `Subtract` operation, the plugin allows the request
```
http POST http://localhost:8000/calculator \
Content-Type:'text/xml; charset=utf-8' \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Subtract xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Subtract>
  </soap:Body>
</soap:Envelope>'
```
The expected result is: 
```xml
...
<SubtractResult>-2</SubtractResult>
...
```

#### For WSDL 1.1 | SOAP 1.2:
1) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins

2) Change the URL of `calculator` GW Service: https://calculator.apim.eu:443/ws

3) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `SOAPAction_Header` property with the value `yes`
- `VerboseRequest` enabled
- `xsdApiSchema` property with this `WSDL 1.1` value: [dneonline.com.wsdl (v1.1)](/_tmp.dneonline.com/dneonline.com.binding_soap1.1_soap1.2.wsdl)
- `xsdSoapSchema` property: replace the default value by [www.w3.org/2003/05/soap-envelope.xsd](./_tmp.w3.org/www.w3.org|2003|05|soap-envelope.xsd)
- `xsdSoapSchemaInclude` property with this value:
  - key: `http://www.w3.org/2001/xml.xsd`
  - value: see value in [http://www.w3.org/2001/xml.xsd](_tmp.w3.org/www.w3.org|2001|xml.xsd)

4) Call the `calculator` through the Kong Gateway Route. As the `Àdd` operation name is requested (see `soapActionRequired="true"` in WSDL), the `action` has the `http://tempuri.org/Add` value as defined in the WSDL
```
http POST http://localhost:8000/calculator \
Content-Type:'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"' \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Add>
  </soap12:Body>
</soap12:Envelope>'
```
The expected result is: 
```xml
...
<AddResult>12</AddResult>
...
```

#### For WSDL 2.0 | SOAP 1.1:
Follow the steps defined for WSDL 1.1 | SOAP 1.1 and specifically configure the plugin with: 
- `xsdApiSchema` property with this `WSDL 2.0` value: [dneonline.com.wsdl (v2.0)](/_tmp.dneonline.com/dneonline.com.wsdlv2_defaultNS_xsd_NSPrefix.wsdl)

##### Add operation
Call the `Add` operation with a SOAP 1.1 envelope and `SOAPAction:"http://tempuri.org/Add"` as there is a defined value for the `Action` attribute

##### Subtract operation
Call the `Subtract` operation with a SOAP 1.1 envelope and `SOAPAction:"http://tempuri.org/SubtractInterface/SubtractRequest"` as there is not defined value for the `Action` attribute. So the default action pattern is used as defined by the [W3C](https://www.w3.org/TR/2007/REC-ws-addr-metadata-20070904/#defactionwsdl20)

#### For WSDL 2.0 | SOAP 1.2:
Follow the steps defined for WSDL 1.1 | SOAP 1.2 and specifically configure the plugin with: 
- `xsdApiSchema` property with this `WSDL 2.0` value: [dneonline.com.wsdl (v2.0)](/_tmp.dneonline.com/dneonline.com.wsdlv2_defaultNS_xsd_NSPrefix.wsdl)

##### Add operation
Call the `Add` operation with a SOAP 1.2 envelope and `Content-Type:'application/soap+xml; charset=utf-8; action="http://tempuri.org/Add"'` as there is a defined value for the `Action` attribute

##### Subtract operation
Call the `Subtract` operation with a SOAP 1.2 envelope `Content-Type:'application/soap+xml; charset=utf-8; action="http://tempuri.org/SubtractInterface/SubtractRequest"'` as there is not defined value for the `Action` attribute. So the default action pattern is used as defined by the [W3C](https://www.w3.org/TR/2007/REC-ws-addr-metadata-20070904/#defactionwsdl20)

<a id="Miscellaneous_example_H"></a>

### Example (H): Request | `XSLT TRANSFORMATION` with Parameters applied by the `libxslt` (or `saxon`) library
The plugin applies an XSLT Transformation on XML request by using `<xsl:param>` defined in the plugin `config`. The transformations are:
- `<intA>` value transformed to `1111`
- `<intB>` value transformed to `3333`
- `<Username>` value transformed to `KongUser` referenced in a Vault `{vault://env/soap-username}`
- `<Password>` value transformed to `KongP@sswOrd!` referenced in a Vault `{vault://env/soap-password}`
0) Add the following environment variables at the Kong Linux level, for instance for a Docker deployment (see [start-kong.sh](start-kong.sh)):
```sh
-e "SOAP_USERNAME=KongUser" \
-e "SOAP_PASSWORD=KongP@sswOrd!" \
-e "KONG_LOG_LEVEL=debug" \
```
Restart the Kong node and pay attention to the `KONG_LOG_LEVEL=debug` as it will be useful later
1) Create 2 x Vault environment variables
- Go on `Vaults`
- Create the 1st Vault with:
  - `Environment Variables` selected
  - `Environment Variable Prefix` with `env` value
  - `Prefix` with `soap-username` value
- Create the 2nd Vault with:
  - `Environment Variables` selected
  - `Environment Variable Prefix` with `env` value
  - `Prefix` with `soap-password` value
2) 'Reset' the configuration of `calculator`: remove the `soap-xml-request-handling` and `soap-xml-response-handling` plugins 
3) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `VerboseRequest` enabled
- `xsltLibrary` property with `libxslt` or `saxon` value
- `xsltTransformBefore` property with this XSLT definition:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:param name="intA_param" select="1"/>
   <xsl:param name="intB_param" select="2"/>
   <xsl:param name="SOAP_USERNAME" select="MyUser"/>
   <xsl:param name="SOAP_PASSWORD" select="MyPassword"/>
  <xsl:output version="1.0" method="xml" encoding="utf-8" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>   
  <xsl:template match="//*[local-name()='Username']">
      <Username><xsl:value-of select="$SOAP_USERNAME"/></Username>
  </xsl:template>
  <xsl:template match="//*[local-name()='Password']">
      <Password><xsl:value-of select="$SOAP_PASSWORD"/></Password>
  </xsl:template>
  <xsl:template match="//*[local-name()='intA']">
      <intA><xsl:value-of select="$intA_param"/></intA>
  </xsl:template>
  <xsl:template match="//*[local-name()='intB']">
      <intB><xsl:value-of select="$intB_param"/></intB>
  </xsl:template>
</xsl:stylesheet>
```
- `XsltParams` property with these values:
  - key: `intA_param`
  - value: `1111`
  - key: `intB_param`
  - value: `3333`
  - key: `SOAP_USERNAME`
  - value: `{vault://env/soap-username}`
  - key: `SOAP_PASSWORD`
  - value: `{vault://env/soap-password}`
4) Call the `calculator` through the Kong Gateway Route
```
http POST http://localhost:8000/calculator \
Content-Type:'text/xml; charset=utf-8' \
--raw '<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Header xmlns:auth="http://wwww.example.com">
    <auth:Authentication xmlns:auth="http://example.com/auth">
      <Username>**TO_BE_CHANGED**</Username>
      <Password>**TO_BE_CHANGED**</Password>
    </auth:Authentication>
  </soapenv:Header>
  <soapenv:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>5</intA>
      <intB>7</intB>
    </Add>
  </soapenv:Body>
</soapenv:Envelope>'
```
The expected result is no longer `12` but `4444`:
```xml
...
<AddResult>4444</AddResult>
...
```
As the `calculator` service doesn't check the `<Username>` and `<Password>` values open the Kong Log and look for `XSLT transformation, END` debug and see the transformation applied by using the Vault referenced values.
The expected result is:
- `<Username>` value is transformed to `KongUser` referenced in the Vault
- `<Password>` value is transformed to `KongP@sswOrd!` referenced in the Vault
```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soapenv:Header xmlns:auth="http://wwww.example.com">
    <auth:Authentication xmlns:auth="http://example.com/auth">
      <Username>KongUser</Username>
      <Password>KongP@sswOrd!</Password>
    </auth:Authentication>
  </soapenv:Header>
  <soapenv:Body>
    <Add xmlns="http://tempuri.org/">
      <intA>1111</intA>
      <intB>3333</intB>
    </Add>
  </soapenv:Body>
</soapenv:Envelope>
```
<a id="W3C_Compatibility_Matrix"></a>

## W3C Compatibility Matrix
|SOAP/XML       |Plugin         |libxml2        |libxlt         |saxon HE       |W3C URL        |Comment        |
|:--------------|:--------------|:--------------|:--------------|:--------------|:--------------|:--------------|
|SOAP 1.1 Envelope|All (except for plugin features not supported by the library)|✅|✅|✅|http://schemas.xmlsoap.org/soap/envelope/|The `Content-Type` is `text/xml` for SOAP 1.1|
|SOAP 1.2 Envelope|All (except for plugin features not supported by the library)|✅|✅|✅|http://www.w3.org/2003/05/soap-envelope|The `Content-Type` is `application/soap+xml` for SOAP 1.2|
|XSLT 1.0|`XSLT TRANSFORMATION`|N/A|✅|✅|http://www.w3.org/1999/XSL/Transform|See `version=1.0` attribute in XSLT|
|XSLT 2.0/3.0|`XSLT TRANSFORMATION`|N/A|❌|✅|http://www.w3.org/1999/XSL/Transform|See `version=2.0` or `version=3.0` attribute in XSLT|
|Schema XML 1.0|`WSDL/XSD VALIDATION`|✅|N/A|⬛|http://www.w3.org/2001/XMLSchema|
|WSDL 1.1|`WSDL/XSD VALIDATION`|✅|N/A|⬛|http://schemas.xmlsoap.org/wsdl/|See `<definitions>` in WSDL 1.0|
|WSDL 2.0|`WSDL/XSD VALIDATION`|✅|N/A|⬛|http://www.w3.org/ns/wsdl|See `<description>` in WSDL 2.0|
|SOAPAction|`WSDL/XSD VALIDATION`|✅|N/A|⬛|http://schemas.xmlsoap.org/wsdl/ (WSDL 1.1) and http://www.w3.org/ns/wsdl (WSDL 2.0)|`SOAPAction` Http header for SOAP 1.1 and `action` in `Content-Type` Http header for SOAP 1.2|
|XPath 1.0|`ROUTING BY XPATH`|✅|N/A|⬛|https://www.w3.org/TR/xpath-10/||
1) Table legend
- ✅: supported by the library
- ❌: not supported by the library
- ⬛: supported by the library but not available due to license restiction (it only concerns `saxon HE` that stands for Home Edition)
- N/A: not applicable

2) Libraries availability
- The `libxml2` and `libxlt` libraries are already included in [kong/kong-gateway](https://hub.docker.com/r/kong/kong-gateway) Enterprise Edition Docker image
- The `saxon HE` library is not included in the Kong Docker image, see [SAXON.md](SAXON.md) for how to integrate saxon with Kong

<a id="Plugins_Testing"></a>

## Plugins Testing
### Functional testing
The functional testing is available through [pongo](https://github.com/Kong/kong-pongo)
1) Download `pongo`
2) Initialize `pongo`
3) Run tests with [pongo.sh](pongo.sh) and **adapt the `KONG_IMAGE` value** according to expectations

Note: If the Kong Docker image with `saxon` has been rebuilt, run a `pongo clean` for rebuilding the Pongo image

### Load testing benchmark
The Load testing benchmark is performed with K6. See [LOADTESTING.md](LOADTESTING.md)

<a id="Known_Limitations"></a>

## Known Limitations
1) The `soap-xml-response-handling` plugin doesn't work for HTTP/2
- It's due to the current Nginx limitation. See [Kong Gateway doc](https://docs.konghq.com/gateway/latest/plugin-development/custom-logic/#available-contexts)
2) The `WSDL/XSD VALIDATION` has following limitations:
- If the WSDL/XSD schema imports an XSD from external entity, it uses a callback function (i.e. `libxml2ex.xmlMyExternalEntityLoader` called by `libxml2`). As it's a non-yield function it must use the `socket.http` (blocking library). To avoid this limitation please:
  - Have at least 2 Nginx worker processes or enable the experimental `ExternalEntityLoader_Async` property (which uses `resty.http`) or 
  - Use `config.xsdApiSchemaInclude` and `config.xsdSoapSchemaInclude`
- If [`stream_listen`](https://docs.konghq.com/gateway/latest/reference/configuration/#stream_listen) is enabled, the `kong.ctx.shared` is not set correctly in `libxml2ex.xmlMyExternalEntityLoader`. It impacts the WSDL/XSD validation which can perform imports: the `config.xsdApiSchemaInclude`, `config.xsdSoapSchemaInclude` and `config.ExternalEntityLoader_Async` are ignored; and the `import` is only done through `socket.http` (blocking library). The recommendation is to disable `stream_listen` with the SOAP/XML plugins and have a dedicated Kong GW that enables `stream_listen`
- The Asynchronous download of the XSD schemas (with `config.ExternalEntityLoader_Async`) uses a LRU cache (Least Recently Used) for storing the content of XSD schema. The default size is `2000` entries. When the limit has been reached there is a warning message in the Kong log
4) `WSDL/XSD VALIDATION` applies for SOAP 1.1 or SOAP 1.2 but not both simultaneously
- It's related to `config.xsdSoapSchema` and `config.xsdSoapSchemaInclude`. To avoid this limitation please create one Kong route per SOAP version

<a id="Changelog"></a>

## Changelog
- v1.0.0:
  - Initial Release
- v1.0.1:
  - Improved the behavior of SOAP/XML Handling plugins in conjunction with the Kong System plugins: Rate Limiting, Auth (OIDC, basic-auth, etc.)
  - Reformated the JSON Error messages (of Kong System plugins) to a SOAP/XML `<soap:Fault>` error
- v1.0.2:
  - Added the capacity to provide `wsdl` content to `xsdApiSchema`. The raw `<xs:schema>` is still valid
- v1.0.3:
  - When `VerboseRequest` or  `VerboseResponse` are disabled, the plugins no longer send the detailed error to the logs
- v1.0.4:
  - Improved the log error management by initializing it in the `init_worker` phase
- v1.0.5:
  - Added an external loader (http)
- v1.0.6: 
  - Added `Timeout` and `Cache_TTL` parameters related to the External Entity Loader (http(s))
  - Put the detailed error message in `<detail>` of `<soap:Fault>` message in case `VerboseRequest` or `VerboseResponse` is enabled
  - Adapted the `schema.lua` to be Konnect compatible
- v1.0.7: 
  - Changed example material from `https://ecs.syr.edu` (no longer available) to `http://www.dneonline.com`
  - Improved `Routing By XPath` by putting in one plugin property the complete routing URL and by enabling the usage of a Host (not only a Kong Upstream)
  - Added experimental `ExternalEntityLoader_Async` capacity for downloading Asynchronously the XSD External Entities
- v1.0.8: 
  - Added https support to Synchronous external loader (https)
  - `WSDL validation`: Get the Namespace definitons found in `<wsdl:definitions>` and add them in `<xsd:schema>` (if they don't exist)
- v1.0.9: 
  - In case of `request-termination` plugin there is no longer SOAP/XML - 200 error
  - `xsdApiSchemaInclude`: support the inclusion of multiple XSD schemas in the plugin configuration (without download external entity)
  - Enhanced the documentation for Kubernetes, Konnect and KIC
- v1.0.10:
  - Due to Kong v3.6+, updated the Kong's library used for gzip compression (from `kong.tools.utils` to `kong.tools.gzip`)
- v1.0.11:
  - Added `pongo` tests
- v1.1.0:
  - Added `saxon` Home Edition (v12.5) library for supporting XSLT 2.0 or 3.0
  - Fixed a free memory issue for `libxslt` (and avoid `[alert] 1#0: worker process **** exited on signal 11` error during Nginx shutdown)
  - Added an `Error Handler` for `libxslt` to detect correctly the unsupported XLST 2.0 or 3.0
  - Added `jit.off()` for `libxml` to avoid `nginx: lua atpanic: Lua VM crashed, reason: bad callback` error
- v1.1.1:
  - Added the `saxon` notices files (related to the Saxon license distribution)
  - Added support for `XML` to `JSON` transformation
  - Renamed the `kong-saxon-initcontainer` and `kong-saxon` docker images
- v1.1.2:
  - `saxon` library: removed the `xsltSaxonTemplate` and `xsltSaxonTemplateParam` parameters and use `XSLT` without `<xsl:template name="main">`
  - Added `conf/saxonConf.xml` for `saxon` configuration file 
  - Added nginx `pid` for `saxon` logs
- v1.1.3:
  - Loaded `saxon` library during the `configure` nginx phase only if necessary
- v1.1.4:
  - `ExternalEntityLoader_Async`: replaced `nginx.timer.at` by `kong.tools.queue`
- v1.1.5:
  - Removed the `require("kong.plugins.soap-xml-handling-lib.xmlgeneral")` declared on each phase to a global definition
  - `ExternalEntityLoader_Async`: replace the `kong.xmlSoapAsync.entityLoader.urls` to a LRU cache
  - Replaced `plugin.PRIORITY` by `plugin.__plugin_id` regarding the Error management
- v1.1.6:
  - `ExternalEntityLoader_Async`: used a `kong.tools.queue` to execute a WSDL/XSD validation prefetch on the `configure` nginx phase (for downloading the `ìmport`ed XSD)
- v1.2.0:
  - Improved support for `SOAP` v1.1 and v1.2, which does an `ìmport` (that can be included in a new property: `xsdSoapSchemaInclude`)
  - Added the validation of the `SOAPAction` Http header
  - `xmlgeneral.pluginConfigure`: enabled the `XSD_Validation_Prefetch` for `saxon` library (not only `libxslt`)
  - Added a `Known Limitations` section in the README.md
  - If `stream_listen` is enabled, send an error message in the log and forces the synchronous download by using `socket.http` (blocking library)
- v1.2.1
  - Added a table of contents in the README.md
  - Added support of `WSDL` 2.0 (for `WSDL/XSD Validation`)
  - `WSDL/XSD Validation`: Handle correctly the case where the Namespace (associated with `http://www.w3.org/ns/wsdl` or `http://www.w3.org/2001/XMLSchema`) has no prefix
  - `xmlgeneral.addNamespaces`: fixed a memory issue when the prefix is NULL (example: `xmlns="http://www.w3.org/ns/wsdl"` instead of `xmlns:wsdl="http://www.w3.org/ns/wsdl"`)
  - Send the correct detailed error message (instead `Ko`) in case there is no Operation in `<soap:Body>`  
  - Optimized the `WSDL` validation (in case of multiple `<xs:schema>`): match the Operation in `<soap:Body>` with its associated `<xs:element name=` in `<xs:schema>`
  - Have a dynamic loading of the Kong's library used for gzip compression regarding the Kong version: `kong.tools.utils` for version < 3.6 and `kong.tools.gzip`for version >= 3.6
  - Replaced the usage of `https://ecs.syr.edu` by a local calculator
  - Included the Kong version in the docker image related to `saxon` (example: `jeromeguillaume/kong-soap-xml:3.8.1.0-1.2.1-12.5`)
  - Included the Lua code SOAP/XML plugins in the docker images related to `saxon`
  - Pongo (Tests): removed the external dependencies (from `http://www.dneonline.com:80/calculator.asmx` to `jeromeguillaume/ws-soap-calculator` Docker image and from `http://httpbin.apim.eu` to `svenwal/httpbin` Docker image)
- v1.2.2
  - `saxon` - `XSLT Transformation`: removed empty Namespace (example: `xmlns=""`)
  - `XSLT Transformation`: Improved error message in case XSLT definition or XML input is not correct
  - `WSDL/XSD Validation`: Improved error message in case WSDL/XSD schema or XML input is not correct
  - `WSDL/XSD Validation`: Improved the validation mechanism in case of multiple schemas to have a better match between the XML ad its WSDL/XSD schema (by leveraging the error code `1845` - `No matching global declaration available for the validation root` on `xmlSchemaValidateOneElement` call)
  - `soap-xml-response-handling`: removed the call of `xmlgeneral.sleepForPrefetchEnd` due to `ngx.sleep` that is not allowed in `header` phase
- v1.2.3
  - Validation of `SOAPAction` Http header: fixed the header name detection for SOAP 1.2 (from `SOAPAction` to `action` in `Content-Type`)
  - Validation of `SOAPAction` Http header: handled the default namespace for `soap`, `soap12`, `wsdl` (example: `xmlns="http://www.w3.org/ns/wsdl"` instead of `xmlns:wsdl="http://www.w3.org/ns/wsdl"`) 
- v1.2.4
  - Validation of `SOAPAction` Http header: added WSDL 2.0 support
  - Added the Lua code checking that the pointer passed to `ffi.string` is not `ffi.NULL` (and avoid a crash: `[alert] 1#0: worker process XXXX exited on signal 11`)
  - Added a `W3C Compatibility Matrix` section in the README.md
  - `pongo` tests: removed `it()` from `lazy_setup()` and removed `teardown()` and put `helpers.stop_kong()` in `lazy_teardown()`
- v1.2.5
  - Fixed a memory leak in XSLT Transformation due to the `libxslt` taking ownership of the pointer returned by `xmlReadMemory` (see comments in `libxml2ex.lua` for `xmlReadMemory`)
  - Added Load testing benchmark. See [LOADTESTING.md](/LOADTESTING.md)
- v1.2.6
  - Added `xsltParams`: named parameter (`<xsl:param>`) to use in `XSLT Transformation`
- v1.2.7
  - Added `pongo` tests for `xsltParams`
  - Added the detection of non existing symbols in `libsaxon4kong.lua`
- v1.3.0
  - `ROUTING BY XPATH`: added multiple targets in the plugin configuration. Breaking change: former parameters `RouteToPath`, `RouteXPath` and `RouteXPathCondition` have been replaced by `RouteXPathTargets[].URL`, `RouteXPathTargets[].XPath` and `RouteXPathTargets[].XPathCondition`
- v1.3.1
  - Changed the `SOAP Fault` message format following the W3C specification for [SOAP 1.1](https://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383507) and [SOAP 1.2](https://www.w3.org/TR/soap12-part1/#soapfault)
  - Added a MIME type detection of the request for answering with the same type of MIME on error (For SOAP 1.1: `Content-Type: text/xml` and for SOAP 1.2: `Content-Type: application/soap+xml`)
  - Renamed the docker image to `jeromeguillaume/kong-soap-xml` (former name: `jeromeguillaume/kong-saxon`) and `jeromeguillaume/kong-soap-xml-initcontainer` (former name: `jeromeguillaume/kong-saxon-initcontainer`)
- v1.4.0-beta.0
  - Added the file support for WSDL, XSD and XSLT definitions. The raw WSDL content (example: `<wsdl:definitions...</wsdl:definitions>`) can be replaced by a file path (example: `/usr/local/kongxml-files/mycontent.wsdl`) put on the Kong Gateway file system
  - Improved the performance by compiling and parsing WSDL, XSD and XSLT definitions only once per plugin (managed by a new `kong.xmlSoapPtrCache.plugins[plugin_id]` table)
  - Fixed a bug by replacing `plugin.__plugin_id` (that doesn't exist except for `configure` phase) by `kong.plugin.get_id()`
  - Removed useless `formatCerr` in `libsaxon-4-kong`