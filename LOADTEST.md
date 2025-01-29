# Load testing results

## Architecture test
Deploy this stack **in this order** (for having `podAntiAffinity`):
1) Google Kubernetes Engine (GKE)
  - Use the `c2-standard-8` GKE cloud instance size:
    - 8 vCPUs and 32 GB ram per node
    - 3 nodes
2) Kong GW configuration:
  - Version: v3.9.0.1
  - One Kong node with 4 Nginx workers (`nginx_worker_processes`: `4`)
  - Kong `Medium` size: the node is limited to 4 vCPU and 8 GB (`resources.requests` and `resources.limits`)
  - Disable `http2` on `proxy_listen` as it's the default protocol used by K6 and not supported by the Response plugin
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

Each deployment (Kong GW, K6, Upstream) has `podAntiAffinity` property for having a dedicated node for each deployment

## Other information regarding load testing methodology
- The Body size of the request is ~345 bytes for both upstream services
- The Performance test duration is 15 minutes
  - The K6 scripts are configured to reach the limit of the Kong node (CPU or Memory) and to use all the physical ressources allocated
- The Endurance test duration is 12 hours
- At the end of the K6 execution we checked that we have:
  - `checks....: 100.00%`
  -  The command is for instance: `kubectl logs scen1-1-wxyz`
- Kong Node is restarted between each iteration of test

## Scenarios for `calculator` Web Service (SOAP/XML)
- [Scenario 0](/loadtest/k6/scen0.js): no plugin
- [Scenario 1](/loadtest/k6/scen1.js): all options for Request and Response plugins
- [Scenario 2](/loadtest/k6/scen2.js): WSDL Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 3](/loadtest/k6/scen3.js): XSD Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 4](/loadtest/k6/scen4.js): XSLT Transformation (Before) Request plugin

## Scenarios for `httpbin` REST API (JSON)
- [Scenario 0](/loadtest/k6/scenhttpbin0.js): no plugin
- [Scenario 1](/loadtest/k6/scenhttpbin1.js): OAS Validation plugin (only Request validation)
- [Scenario 2](/loadtest/k6/scenhttpbin2.js): OAS Validation plugin (Request and Response validation)

## Results
|Service name|Scenario|Test type|Requests per second|Avg|p95|p99 |Kong Linux Memory|Data Sent|Data Received
|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|
|calculator|0|Kong proxy with no plugins||||||||
|calculator|1|WSDL Validation (req only) plugin|3848 rps|5 ms|8 ms|23 ms|2.4 Gib|2 GB|3 GB
|calculator|2|XSD Validation (req only) plugin| rps| ms| ms| ms| Gib| GB| GB
|calculator|3|XSLT Transformation plugin| rps| ms| ms| ms| Gib| GB| GB
|httbin|0|Kong proxy with no plugins| rps| ms| ms| ms| Gib|
|httbin|1|OAS Validation (req only)|8691 rps|23 ms|63 ms|92 ms|0.9 Gib|
|httbin|2|OAS Validation (req and res)|6508 rps|31 ms|99 ms|144 ms|0.9 Gib|