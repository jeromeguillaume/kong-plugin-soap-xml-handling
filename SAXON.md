# Saxon and Kong

## Overview
[Saxonica](https://www.saxonica.com/html/welcome/welcome.html) company provides the `Saxon` processor for XSLT, XQuery, and XML Schema. The `Saxon` processor is available for Java, .NET, JavaScript, PHP, Python and C/C++. Several editions are available: 
- HE: Saxon Home Edition (open source)
- PE: Saxon Professional Edition
- EE: Saxon Enterprise Edition

The HE edition provides XSLT 2.0 and 3.0 support but the XML validation is only included in EE edition. See the [Feature Matrix](https://www.saxonica.com/html/products/feature-matrix-12.html).
So the purpose is to integrate `Saxon HE` to Kong for XSLT Transformation only. It enables JSON <-> XML transformation with [fn:json-to-xml](https://www.saxonica.com/html/documentation10/functions/fn/json-to-xml.html) and [fn:xml-to-json](https://www.saxonica.com/html/documentation12/functions/fn/xml-to-json.html) that [libxslt](https://gitlab.gnome.org/GNOME/libxslt#libxslt) doesn't provide. 

The `Saxon HE` for C/C++ (ie. [SaxonC-HE](https://www.saxonica.com/html/download/c.html)) library is not included in the [kong/kong-gateway](https://hub.docker.com/r/kong/kong-gateway) Enterprise Edition Docker image. For that: build your own Kong Docker images or use a Kubernetes initContainer.
The `SaxonC` documentation is [here](https://www.saxonica.com/saxon-c/documentation12/index.html).

Behind the scenes the `SaxonC-HE` library is developed in JAVA and it ships with a Java GraalVM Community Edition. So the library size is ~60MB.

## Prerequisite: download the `SaxonC-HE` Zip package
1) The `SaxonC-HE` v12.5.0 is used
- Linux AArch64:
[https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-aarch64-v12.5.0.zip](https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-aarch64-v12.5.0.zip)
- Linux Intel x86_64:
[https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-x86_64-v12.5.0.zip](https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-x86_64-v12.5.0.zip)
- General download page:
[here](https://www.saxonica.com/html/download/c.html)
2) Fork this repository
3) Go in the directory of the forked repository
```sh
cd kong-plugin-soap-xml-handling/kong/saxon
```
## Extract/Build the `Saxon` Shared Objects and the Docker images
- The `Saxon - Kong` integration requires 2 Shared Objects that are extracted and built with the `make` command:
  - `libsaxon-hec-12.5.0.so`: C++ shared object extracted from `libsaxon-HEC-linux-<arch>-v12.5.0.zip`
  - `libsaxon-4-kong.so`: C shared object compiled from `kong-adapter.cpp`
- Prerequisite
  - Copy `libsaxon-HEC` zip files
  - Copy inlude files (`.h`) for C/C++ syntax checking
```sh
cd ./kong-plugin-soap-xml-handling/kong/saxon
cp <Downloads>/libsaxon-HEC-linux-aarch64-v12.5.0.zip ./zip
cp <Downloads>/libsaxon-HEC-linux-x86_64-v12.5.0.zip ./zip
```
```sh
cp ./libsaxon-HEC-linux-aarch64-v12.5.0/Saxon.C.API/*.h ./include
cp ./libsaxon-HEC-linux-aarch64-v12.5.0/Saxon.C.API/graalvm/*.h ./include
rm ./include/php8*
```
- Adapt the version of Kong image (exemple: `kong/kong-gateway:3.9.0.0`) in the following files:
  - [Dockerfile_Kong_Saxon](/kong/saxon/Dockerfile_Kong_Saxon)
  - [Dockerfile_Local_Lib](/kong/saxon/Dockerfile_Local_Lib)
  - [Makefile](/kong/Makefile): replace `jeromeguillaume` by `<your_docker_account>`
- Adapt the version of the initContainer, Plugins or saxon (exemple: `kong-saxon-local-lib:1.0.5-1.2.4-12.5`) in the following file:
  - [Makefile](/kong/Makefile)
- Build all
```sh
cd ./kong-plugin-soap-xml-handling/kong
make
```
- Build and Push on Docker Hub a `<your_docker_account>/kong-saxon` image. It's based on `kong/kong-gateway` and it includes the `saxon` libraries
```sh
make kong_saxon_docker_hub
```
- Extract and Build the `saxon` libraries. The libaries are built in `./saxon/so/<arch>` depending of the architecture:
  - `arm64`
  ```sh
  make local_lib_arm64
  ```
  - `amd64`
  ```sh
  make local_lib_amd64
  ```
- Build and Push on Docker Hub a `<your_docker_account>/kong-saxon-initcontainer` image. It's based on `alpine` and it includes the `saxon` libraries
```sh
make kong_saxon_initcontainer_docker_hub
```

## Run `Kong` with `Saxon`
### Run `Kong` with `Saxon` in Docker with the standard image: `kong/kong-gateway`
- Include in your `docker run` command:
  ```sh
  docker run -d --name kong-gateway-soap-xml-handling \
  ...
  --mount type=bind,source="$(pwd)"/kong/saxon/conf,destination=/usr/local/lib/kongsaxon/conf \
  --mount type=bind,source="$(pwd)"/kong/saxon/so/$ARCHITECTURE,destination=/usr/local/lib/kongsaxon \
  -e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
  kong/kong-gateway:3.9.0.0
  ```
- Full example here: [start-kong.sh](start-kong.sh)

### Run `Kong` with `Saxon` in Docker or Kubernetes with the customized image: `jeromeguillaume/kong-saxon`
The image is based on `kong-gateway` and it includes the Lua SOAP/XML plugins, the `Saxon` libraries and defines the environment variables (`LD_LIBRARY_PATH` and `KONG_PLUGINS`)
- Docker
```sh
docker run -d --name kong-gateway-soap-xml-handling \
...
jeromeguillaume/kong-saxon:3.9.0.0-1.2.4-12.5
```
- Kubernetes:
  - Prerequisite: see [How to deploy SOAP/XML Handling plugins **schema** in Konnect (Control Plane) for Kong Gateway](https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling/tree/main?tab=readme-ov-file#Konnect_CP_for_Kong_Gateway)
  - Set in `values.yaml` the `image.repository` to `jeromeguillaume/kong-saxon:3.9.0.0-1.2.4-12.5`. See a complete `values.yaml` example for Konnect: [values-4-Konnect.yaml](kong/saxon/kubernetes/values-4-Konnect.yaml)

### Run `Kong` with `Saxon` in Kubernetes with an `initContainer` image: `jeromeguillaume/kong-saxon-initcontainer`
The image is based on `Alpine` and it includes the Lua SOAP/XML plugins, the `Saxon` libraries
- Prerequisite: see [How to deploy SOAP/XML Handling plugins **schema** in Konnect (Control Plane) for Kong Gateway](https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling/tree/main?tab=readme-ov-file#Konnect_CP_for_Kong_Gateway)
- Prepare a `values.yaml` and pay attention to:
  - `env.lua_package_path`
  - `env.plugins`
  - `customEnv.LD_LIBRARY_PATH`
  - `deployment.initContainers`
```yaml
image:
  repository: kong/kong-gateway
  tag: "3.9.0.0"
  ...
env:
  # *** Specific properties for SOAP/XML Request Handling plugins and Saxon ***
  lua_package_path: "/usr/local/lib/kongsaxon/?.lua;/opt/?.lua;/opt/?/init.lua;;"
  plugins: bundled,soap-xml-request-handling,soap-xml-response-handling
...
# *** Specific properties for Saxon ***
customEnv:
  LD_LIBRARY_PATH: /usr/local/lib/kongsaxon

# *** Specific properties for SOAP/XML Request Handling plugins and Saxon ***
deployment:
  initContainers:
  - name: kongsaxon
    image: jeromeguillaume/kong-saxon-initcontainer:1.0.5-1.2.4-12.5
    command: ["/bin/sh", "-c", "cp -r /kongsaxon/* /usr/local/lib/kongsaxon"]
    volumeMounts:
    - name: kongsaxon-vol
      mountPath: /usr/local/lib/kongsaxon
  userDefinedVolumes:
  - name: kongsaxon-vol
    emptyDir: {}
  userDefinedVolumeMounts:
  - name: kongsaxon-vol
    mountPath: /usr/local/lib/kongsaxon
```
- Execute the `helm` command
```sh
helm install kong kong/kong -n kong --values ./values.yaml
```
- See a complete `values.yaml` example for Konnect: [values-4-Konnect-w-initContainer.yaml](kong/saxon/kubernetes/values-4-Konnect-w-initContainer.yaml)
- For Kubernetes: **the `initContainer` is the preferred method** instead of using the customized image (`jeromeguillaume/kong-saxon`). Indeed the `initContainer` has no dependency to `kong/kong-gateway` and it doesn't require rebuilding for each new release of `kong/kong-gateway`

## Behind the scenes of `fn:json-to-xml` and `fn:xml-to-json` functions
The `fn:json-to-xml` function converts the `JSON` data types to corresponding `XML` tags. The `fn:xml-to-json` does the opposite. See the following `JSON` <-> `XML` conversion table mapping:
|JSON Data Type|XML Tag|
|:-|:-|
|`{}`|`<map>`|
|`[]`|`<array>`|
|`string`|`<string>`|
|`boolean`|`<boolean>`|
|`number`|`<number>`|
|`null`|`<null>`|

The `XML` attribute `key` is derivated from the `JSON` property name.

See `JSON` following example:
```json
{
  "companyName": "KongHQ",
  "offices": {
    "site": [
      "San Francisco (HQ)",
      "London"
    ]
  },
  "products": [
    {
      "Kong konnect": {
        "version": 2024,
        "saas": true
      }
    }
  ]
}
```
Result of `fn:json-to-xml` conversion:
```xml
<map>
   <string key="companyName">KongHQ</string>
   <map key="offices">
      <array key="site">
         <string>San Francisco (HQ)</string>
         <string>London</string>
      </array>
   </map>
   <array key="products">
      <map>
         <map key="Kong konnect">
            <number key="version">2024</number>
            <boolean key="saas">true</boolean>
         </map>
      </map>
   </array>
</map>
```
You can try it with an online XSLT tester (like [https://linangdata.com/xslt-tester/](https://linangdata.com/xslt-tester/)). Use the following `XSLT` to transform `JSON` data into `XML` document. As an input, encapsulate the `JSON` with a `<data>` fake tag (like `<data>{"companyName": "KongHQ"}</data>`)
```xml
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:map="http://www.w3.org/2005/xpath-functions/map" exclude-result-prefixes="#all" expand-text="yes">

  <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match=".">
    <xsl:copy-of select="json-to-xml(.)"/>
  </xsl:template>

</xsl:stylesheet>
```
## How to test XML Handling plugins with `Saxon`
### Example A: Request and Response | `XSLT 3.0 TRANSFORMATION`: JSON (client) to SOAP/XML (server)
Call the `calculator` web service by sending a `JSON` request.
The `soap-xml-request-handling` is in charge of transforming the JSON request to a SOAP/XML request by applying an XSLT 3.0 transformation. The `soap-xml-response-handling` is in charge of doing the opposite that's to say transforming the SOAP/XML response to JSON.
1) **The `saxon` library is not included in the Kong Docker image**. So, if it’s not done yet, add `saxon` library to the Kong gateway. See the [Prerequisite](#prerequisite-download-the-saxonc-he-zip-package) section

2) If the Kong Gateway Service called `calculator` exists, remove it

3) Create a Kong Gateway Service named `calculator` with this URL: http://www.dneonline.com:80/calculator.asmx

4) Create a Route on the Service `calculator` with the `path` value `/calculator`

5) Add `soap-xml-request-handling` plugin to `calculator` and configure the plugin with:
- `VerboseRequest` enabled
- `xsltLibrary` property with the value `saxon`
- `xsltTransformBefore` property with this `XSLT 3.0` definition:
```xml
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <xsl:variable name="json_var" select="fn:json-to-xml(.)"/>    
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <xsl:variable name="operation" select="$json_var/map/string[@key='operation']"/>    
        <xsl:element name="{$operation}" xmlns="http://tempuri.org/">
          <intA>
            <xsl:value-of select="$json_var/map/number[@key='intA']"/>
          </intA>
          <intB>
            <xsl:value-of select="$json_var/map/number[@key='intB']"/>
          </intB>              
        </xsl:element>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
</xsl:stylesheet>
```

6) Add `soap-xml-response-handling` plugin to `calculator` and configure the plugin with:
- `VerboseResponse` enabled
- `xsltLibrary` property with the value `saxon`
- `xsltTransformAfter` property with this `XSLT 3.0` definition:
```xml
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2005/xpath-functions" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xpath-default-namespace="http://tempuri.org/" exclude-result-prefixes="fn">
  <xsl:mode on-no-match="shallow-skip"/>
  <xsl:output method="text"/>
  
  <xsl:template match="/soap:Envelope/soap:Body/*[ends-with(name(), 'Response')]/*[ends-with(name(), 'Result')]">
    <xsl:variable name="json-result">
      <map xmlns="http://www.w3.org/2005/xpath-functions">
        <number key="result">
          <xsl:value-of select="text()"/>
        </number>
      </map>
    </xsl:variable>
    <xsl:value-of select="fn:xml-to-json($json-result)"/>
  </xsl:template>
</xsl:stylesheet>
```

7) Call the `calculator` through the Kong Gateway Route,  with a `JSON` request and by setting the operation to `Add`
```sh
http -v POST http://localhost:8000/calculator operation=Add intA:=50 intB:=10
```
```
Content-Type: application/json
...
```
```json
{
    "intA": 50,
    "intB": 10,
    "operation": "Add"
}
```
The expected `JSON` response is `60`:
```
HTTP/1.1 200 OK
Content-Type: application/json
...
```
```json
{
    "result": 60
}
```
You can change operation to the following values:
- `Subtract`
- `Divide`
- `Multiply`

### Example B: Request and Response | `XSLT 3.0 TRANSFORMATION`: XML (client) to JSON (server)
Call the `httpbin` REST API by sending an `XML` request.
The `soap-xml-request-handling` is in charge of transforming the XML request to a JSON request by applying an XSLT 3.0 transformation. The `soap-xml-response-handling` is in charge of doing the opposite that's to say transforming the XML response to JSON.
1) **The `saxon` library is not included in the Kong Docker image**. So, if it’s not done yet, add `saxon` library to the Kong gateway. See the [Prerequisite](#prerequisite-download-the-saxonc-he-zip-package) section

2) Create a Kong Gateway Service named `httpbin` with this URL: http://httpbin.apim.eu. A simple HTTP Request & Response REST API Service.

3) Create a Route on the Service `httpbin` with the `path` value `/httpbin`

4) Add `soap-xml-request-handling` plugin to `httpbin` and configure the plugin with:
- `VerboseRequest` enabled
- `xsltLibrary` property with the value `saxon`
- `xsdSoapSchema` property with the value [kong.xsd](_tmp.xslt.transformation/kong.xsd) for XSD validation
- `xsltTransformAfter` property with this `XSLT 3.0` definition:
```xml
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2005/xpath-functions" xmlns:fn="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:mode on-no-match="shallow-skip"/>
  <xsl:output method="text"/>
  
  <xsl:template match="/root">
    <xsl:variable name="json-result">
      <map xmlns="http://www.w3.org/2005/xpath-functions">
        <string key="companyName"><xsl:value-of select="companyName"/></string>
        <string key="city"><xsl:value-of select="city"/></string>
        <string key="state"><xsl:value-of select="state"/></string>
        <string key="country"><xsl:value-of select="country"/></string>
        <map key="offices">
          <array key="site">
            <xsl:for-each select="offices/site">
              <string><xsl:value-of select="."/></string>
            </xsl:for-each>
          </array>
        </map>
        <array key="products">
          <xsl:for-each select="products/product">
            <map>
              <xsl:element name="map">
              <xsl:attribute name="key"><xsl:value-of select="@name"/></xsl:attribute>
                <number key="version"><xsl:value-of select="./version"/></number>
                <boolean key="saas"><xsl:value-of select="./saas"/></boolean>
              </xsl:element>
            </map>
          </xsl:for-each>
        </array>
      </map>
    </xsl:variable>
    <xsl:value-of select="fn:xml-to-json($json-result)"/>
  </xsl:template>
</xsl:stylesheet>
```

5) Call the `httpbin` through the Kong Gateway Route,  with an `XML` request
```xml
http POST http://localhost:8000/httpbin/anything \
Content-Type:'text/xml; charset=utf-8' \
--raw '<?xml version="1.0" encoding="utf-8"?>
<root>
  <companyName>KongHQ</companyName>
  <city>SAN FRANCISCO</city>
  <state>CA</state>
  <country>USA</country>
  <offices>
    <site>San Francisco (HQ)</site>
    <site>Chicago</site>
    <site>London</site>
    <site>Bangalore</site>
    <site>Singapore</site>
    <site>Shangai</site>
    <site>Japan</site>
  </offices>
  <products>
    <product name="Kong konnect">
      <version>2024</version>
      <saas>true</saas>
    </product>
    <product name="Kong AI Gateway">
      <version>3.8</version>
      <saas>false</saas>
    </product>
    <product name="Kong Ingress Controller">
      <version>3.3</version>
      <saas>false</saas>
    </product>
    <product name="Kong Mesh">
      <version>2.8</version>
      <saas>false</saas>
    </product>
    <product name="Insomnia">
      <version>10</version>
      <saas>false</saas>
    </product>
  </products>
</root>'
```
The expected `JSON` response is as following. Pay attention to the `json` property: it contains the whole converted request XML.
```
HTTP/1.1 200 OK
Content-Type: application/json
...
```
```json
{
  "args": {},
  "data": "{\"companyName\":\"KongHQ\",\"...\":\"...\"}",
  "json": {
    "city": "SAN FRANCISCO",
    "companyName": "KongHQ",
    "state": "CA",
    "country": "USA",
    "offices": {
      "site": [
        "San Francisco (HQ)",
        "Chicago",
        "London",
        "Bangalore",
        "Singapore",
        "Shangai",
        "Japan"
      ]
    },
    "products": [
      {
        "Kong konnect": {
          "saas": true,
          "version": 2024
          }
      },
      {
        "Kong AI Gateway": {
          "saas": false,
          "version": 3.8
        }
      },
      {
        "Kong Ingress Controller": {
          "saas": false,
          "version": 3.3
        }
      },
      {
        "Kong Mesh": {
          "saas": false,
          "version": 2.8
        }
      },
      {
        "Insomnia": {
          "saas": false,
          "version": 10
        }
      }
    ],
  },
}
```
Now, let's convert the `JSON` response (sent by `httpbin` server) to an XML response by using `soap-xml-response-handling` plugin:

6) Add `soap-xml-response-handling` plugin to `httpbin` and configure the plugin with:
- `VerboseResponse` enabled
- `xsltLibrary` property with the value `saxon`
- `xsdSoapSchema` property with the value [kong.xsd](_tmp.xslt.transformation/kong.xsd) for XSD validation
- `xsltTransformBefore` property with this `XSLT 3.0` definition:
```xml
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <xsl:variable name="json_var" select="fn:json-to-xml(.)"/>
    <root>
      <companyName><xsl:value-of select="$json_var/map/map/string[@key='companyName']"/></companyName>
      <city><xsl:value-of select="$json_var/map/map/string[@key='city']"/></city>
      <state><xsl:value-of select="$json_var/map/map/string[@key='state']"/></state>
      <country><xsl:value-of select="$json_var/map/map/string[@key='country']"/></country>
      <offices>
        <xsl:for-each select="$json_var/map/map/map[@key='offices']/array[@key='site']/string">
          <site><xsl:value-of select="."/></site>
        </xsl:for-each>
      </offices>
      <products>
        <xsl:for-each select="$json_var/map/map/array[@key='products']/map/map">
          <product>
            <xsl:attribute name="name"><xsl:value-of select="@key"/></xsl:attribute>
              <version><xsl:value-of select="number[@key='version']"/></version>
              <saas><xsl:value-of select="boolean[@key='saas']"/></saas>
          </product>
        </xsl:for-each>
      </products>
    </root>
  </xsl:template>
</xsl:stylesheet>
```
7) Call the `httpbin` through the Kong Gateway Route,  with an `XML` request. Use command defined at step #5. The expected `XML` response is as following. So For demoing purposes only, we get in the response the **same** xml sent.
```
HTTP/1.1 200 OK
Content-Type: text/xml; charset=utf-8
...
```
```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <companyName>KongHQ</companyName>
  <city>SAN FRANCISCO</city>
  <state>CA</state>
  <country>USA</country>
  <offices>
    <site>San Francisco (HQ)</site>
    <site>Chicago</site>
    <site>London</site>
    <site>Bangalore</site>
    <site>Singapore</site>
    <site>Shangai</site>
    <site>Japan</site>
  </offices>
  <products>
    <product name="Kong konnect">
      <version>2024</version>
      <saas>true</saas>
    </product>
    <product name="Kong AI Gateway">
      <version>3.8</version>
      <saas>false</saas>
    </product>
    <product name="Kong Ingress Controller">
      <version>3.3</version>
      <saas>false</saas>
    </product>
    <product name="Kong Mesh">
      <version>2.8</version>
      <saas>false</saas>
    </product>
    <product name="Insomnia">
      <version>10</version>
      <saas>false</saas>
    </product>
  </products>
</root>
```