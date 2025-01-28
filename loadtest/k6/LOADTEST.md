# Load testing results

The `c2-standard-8` GKE cloud instance size is used: 8 vCPUs and 32 GB ram per node
Kong nide configuration:
- 1 x Kong node with 4 Nginx workers (with `nginx_worker_processes`: `4`)
- Kong `Medium` size: Node limited to 4 vCPU and 8 GB (with `resources.requests` and `resources.limits`)

Body size ~345 bytes

## Scenarios for `calculator` Web Service (SOAP/XML )
- Scenario 0: no plugin
- Scenario 1: all options for Request and Response plugins
- Scenario 2: WSDL Validation (soap 1.1 and API) Request plugin
- Scenario 3: XSD Validation (soap 1.1 and API) Request plugin
- Scenario 4: XSLT Transformation (Before) Request plugin

## Scenarios for `httpbin` REST API (JSON)
- Scenario 1: OAS Valdiation plugin (only Request validation)
- Scenario 2: OAS Valdiation plugin (Request and Response validation)

|Service name|Test type|Requests per second|Avg|p95|p99 |Kong Linux Memory|Data Sent|Data Received
|:--------|:--------|------------------------:|-------:|-------:|-------:|-------:|-------:|-------:|
|calculator|Kong proxy with no plugins||||||||
|calculator|WSDL Validation plugin|3887 rps|5 ms|8 ms|18 ms|3.5 Gib|2.1 GB|3.0 GB
|calculator|XSD Validation (req only) plugin|4939 rps|4 ms|7 ms|17 ms|2.1 Gib|2.6 GB|3.9 GB
|calculator|XSLT Transformation plugin|526 rps|45 ms|47 ms|103 ms|7.7 Gib|0.3 GB|0.4 GB
|httbin|OAS Validation (req only)|8691 rps|23 ms|63 ms|92 ms|0.9 Gib|
|httbin|OAS Validation (req and res)|6508 rps|31 ms|99 ms|144 ms|0.9 Gib|