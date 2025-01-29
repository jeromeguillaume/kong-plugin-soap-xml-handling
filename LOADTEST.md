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
  - Those specific parameters are defined in:
    - [values.yaml](/loadtest/k6/0-init/cp-gke/values.yaml) without Saxon
    - [valuesSaxon.yaml](/loadtest/k6/0-init/cp-gke/valuesSaxon.yaml) with Saxon
  - The Kong entities (Service/Route/Plugin) are defined in [k6-kong.yaml](/loadtest/k6/0-init/k6-kong.yaml) deck file
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

## How to use K6
- Create a ConfigMap for each scenario
  - See [1-k6-configMap.sh](/loadtest/k6/1-k6-configMap.sh)
- Start a test
  - Configure [2-k6-TestRun.yaml](/loadtest/k6/2-k6-TestRun.yaml) with the right scenario (scen0, scen1, scen2, etc.)
  - Apply the configuration and start the test: `kubectl apply -f 2-k6-TestRun.yaml`
- Collect and check the results once the job has the `succeeded` status
  -  The command is for instance: `kubectl logs scen1-1-wxyz`
  - The expected result is:
```
    ✓ http response status code is 200
     ✓ Content-Type
     ✓ calculator Result
     checks.........................: 100.00% 14027889 out of 14027889
     data_received..................: 3.7 GB  3.7 MB/s
     data_sent......................: 2.5 GB  2.5 MB/s
     ...     
     ...
     http_reqs......................: 4675963 4723.14347/s
     iteration_duration.............: min=1.15ms  max=211.3ms  avg=4.01ms  p(90)=5.37ms  p(95)=7.54ms  p(99)=17.31ms
     iterations.....................: 4675963 4723.14347/s
     vus............................: 20      min=0                    max=20
     vus_max........................: 20      min=20                   max=20
```
- optional: if required stop a test
  - `kubectl delete testruns.k6.io scen1`

## Other information regarding load testing methodology
- The Body size of the request is ~345 bytes for both upstream services
- Protocol: HTTPS only
- The Performance test duration is 15 minutes
  - The K6 scripts are configured to reach the limit of the Kong node (CPU or Memory) and to use all the physical ressources allocated
- The Endurance test duration is 12 hours
- At the end of the K6 execution we collect the results and we verify that the checks are 100% successful
  
- Kong Node is restarted between each iteration of test

## Scenarios for `calculator` Web Service (SOAP/XML)
- [Scenario 0](/loadtest/k6/scen0.js): no plugin (need to set `replicas=2` instead of 1 to reach limit of `calculator`)
- [Scenario 1](/loadtest/k6/scen1.js): WSDL Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 2]
- [Scenario 3](/loadtest/k6/scen3.js): XSD Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 4](/loadtest/k6/scen4.js): XSLT Transformation (Before) with `libxslt` Request plugin
- [Scenario 5](/loadtest/k6/scen5.js): all options (with `libxslt`) for Request and Response plugins 
- [Scenario 6](/loadtest/k6/scen6.js): XSLT Transformation (Before) with `saxon` Request plugin
- [Scenario 7](/loadtest/k6/scen7.js): XSLT v3.0 - JSON to XML for Request and Response plugins

## Scenarios for `httpbin` REST API (JSON)
- [Scenario 0](/loadtest/k6/scenhttpbin0.js): no plugin
- [Scenario 1](/loadtest/k6/scenhttpbin1.js): OAS Validation plugin (only Request validation)
- [Scenario 2](/loadtest/k6/scenhttpbin2.js): OAS Validation plugin (Request and Response validation)

## Performance tests Results
|Service name|Scenario|Test type|XSLT Library|Requests per second|Avg|p95|p99 |Kong Linux Memory|Data Sent|Data Received
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|
|calculator|0|Kong proxy with no plugins|N/A|12441 rps||||||
|calculator|1|WSDL Validation (req only) plugin|libxslt|3848 rps|5 ms|8 ms|23 ms|2.4 Gib|2 GB|3 GB
|calculator|2|WSDL Validation and SOAPAction (req only) plugin|libxslt| rps| ms| ms| ms| Gib| GB| GB
|calculator|3|XSD Validation (req only) plugin|libxslt|4723 rps|4 ms|8 ms|17 ms|2.4 Gib|2.5 GB|3 GB
|calculator|4|XSLT Transformation (req only) plugin|libxslt|rps| ms| ms| ms| Gib| GB| GB
|calculator|5|All options for req and res plugins|libxslt|rps|ms|ms| ms| Gib| GB| GB
|calculator|6|XSLT Transformation (req only) plugin|saxon| rps| ms| ms| ms| Gib| GB| GB
|calculator|7|XSLT v3.0 - JSON to XML for req and res plugins|saxon|rps|ms|ms| ms| Gib| GB| GB
|httbin|0|Kong proxy with no plugins|N/A| rps| ms| ms| ms| Gib|
|httbin|1|OAS Validation (req only)|N/A|8691 rps|23 ms|63 ms|92 ms|0.9 Gib|
|httbin|2|OAS Validation (req and res)|N/A|6508 rps|31 ms|99 ms|144 ms|0.9 Gib|