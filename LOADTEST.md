# Load testing results

## Architecture test
Deployment this stack in this order:
1) Google Kubernetes Engine (GKE)
  - Use the `c2-standard-8` GKE cloud instance size:
    - 8 vCPUs and 32 GB ram per node
    - 3 nodes
2) Kong node configuration:
  - Version: v3.9.0.1
  - One Kong node with 4 Nginx workers (with `nginx_worker_processes`: `4`)
  - Kong `Medium` size: the node is limited to 4 vCPU and 8 GB (with `resources.requests` and `resources.limits`)
  - Disable `http2` on `proxy_listen` as it's the default protocol used by K6
  - Those specific parameters are defined in [values.yaml](/loadtest/k6/0-init/cp-gke/values.yaml)
  - The Kong entities (Service/Route/Plugin) are defined in [k6-kong.yaml](/loadtest/k6/0-init/6-kong.yaml) deck file
3) Prometheus / Grafana stack
4) K6: load testing tool
  - See [Running distributed load tests on Kubernetes](https://grafana.com/blog/2022/06/23/running-distributed-load-tests-on-kubernetes/)
5) Upstream:
  - `calculator` Web Service (SOAP/XML)
    - Docker Image: [jeromeguillaume/ws-soap-calculator:1.0.4](https://hub.docker.com/r/jeromeguillaume/ws-soap-calculator)
    - Kubernetes deployment: [ws-calculator.yaml](loadtest/k6/ws-calculator.yaml)
  - `httpbin` REST API (JSON)
    - Docker Image: [kong/httpbin:0.2.3](https://hub.docker.com/r/kong/httpbin)
    - Kubernetes deployment: [httpbin.yaml](loadtest/k6/0-init/httpbin.yaml)

Body size ~345 bytes


## Scenarios for `calculator` Web Service (SOAP/XML)
- [Scenario 0](/loadtest/k6/scen0.js): no plugin
- [Scenario 1](/loadtest/k6/scen1.js): all options for Request and Response plugins
- [Scenario 2](/loadtest/k6/scen2.js): WSDL Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 3](/loadtest/k6/scen3.js): XSD Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 4](/loadtest/k6/scen4.js): XSLT Transformation (Before) Request plugin

## Scenarios for `httpbin` REST API (JSON)
- [Scenario 1](/loadtest/k6/scenhttpbin1.js): OAS Validation plugin (only Request validation)
- [Scenario 2](/loadtest/k6/scenhttpbin2.js): OAS Validation plugin (Request and Response validation)

|Service name|Test type|Requests per second|Avg|p95|p99 |Kong Linux Memory|Data Sent|Data Received
|:--------|:--------|------------------------:|-------:|-------:|-------:|-------:|-------:|-------:|
|calculator|Kong proxy with no plugins||||||||
|calculator|WSDL Validation plugin|3887 rps|5 ms|8 ms|18 ms|3.5 Gib|2.1 GB|3.0 GB
|calculator|XSD Validation (req only) plugin|4939 rps|4 ms|7 ms|17 ms|2.1 Gib|2.6 GB|3.9 GB
|calculator|XSLT Transformation plugin|526 rps|45 ms|47 ms|103 ms|7.7 Gib|0.3 GB|0.4 GB
|httbin|OAS Validation (req only)|8691 rps|23 ms|63 ms|92 ms|0.9 Gib|
|httbin|OAS Validation (req and res)|6508 rps|31 ms|99 ms|144 ms|0.9 Gib|