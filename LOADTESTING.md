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
  - Disable `http2` on `proxy_listen` as it's the default protocol used by K6 and it's not supported by the Response plugin
  - Those specific parameters are defined in:
    - [values.yaml]( /loadTesting/k6/0-init/cp-gke/values.yaml) without Saxon
    - [valuesSaxon.yaml]( /loadTesting/k6/0-init/cp-gke/valuesSaxon.yaml) with Saxon
  - The Kong entities (Service/Route/Plugin) are defined in [k6-kong.yaml]( /loadTesting/k6/0-init/k6-kong.yaml) deck file. It includes the `Prometheus` plugin
3) Prometheus / Grafana stack
4) K6: load testing tool
  - See [Running distributed load tests on Kubernetes](https://grafana.com/blog/2022/06/23/running-distributed-load-tests-on-kubernetes/)
5) Upstream:
  - `calculator` Web Service (SOAP/XML)
    - Docker Image: [jeromeguillaume/ws-soap-calculator:1.0.4](https://hub.docker.com/r/jeromeguillaume/ws-soap-calculator)
    - Kubernetes deployment: [ws-calculator.yaml](loadtesting/k6/ws-calculator.yaml)    
  - `httpbin` REST API (JSON)
    - Docker Image: [kong/httpbin:0.2.3](https://hub.docker.com/r/kong/httpbin)
    - Kubernetes deployment: [httpbin.yaml](loadtesting/k6/0-init/httpbin.yaml)

Each deployment (Kong GW, K6, Upstream) has `podAntiAffinity` property for having a dedicated node for each deployment. Exception: in case of Endurance tests the number of `replicas` for the `K6` deployment are deployed on all Kubernetes nodes

## How to use K6
- Create a ConfigMap for each scenario
  - See [1-k6-configMap.sh]( /loadTesting/k6/1-k6-configMap.sh)
- Start a scenario on your Laptop
  - Configure `executor: per-vu-iterations` and `iterations: 1` in the `scenX.js`
  - `k6 run scen1.js`
- Start a Load testing on Kubernetes
  - Configure `executor: 'ramping-vus` and `{ duration: '900s', target: 20 }` in the `scenX.js`
  - Configure [2-k6-TestRun.yaml]( /loadTesting/k6/2-k6-TestRun.yaml) with the right scenario (scen0, scen1, scen2, etc.)
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
- Delete the test (for starting a new test)
  - `kubectl delete testruns.k6.io scen1`

## Other information regarding load testing methodology
- The Body size of the request is ~350 bytes for both upstream services
- Protocol: HTTPS only
- The reponse is deflated with `Content-Encoding: gzip` for `calculator` upstream only (but not for `httpbin` upstream)
- As `XsdSoapSchema` has a default value (related to soap 1.1 schema) we can't put a null value. So the `XSLT Transformation` (only) also includes `XSD Validation (soap 1.1)`
- The Performance test duration is 15 minutes
  - The K6 scripts are configured to reach the limit of the Kong node (CPU or Memory) and to use all the physical ressources allocated
  - Have `spec.parallelism: 1` in [2-k6-TestRun.yaml]( /loadTesting/k6/2-k6-TestRun.yaml)
- The Endurance test duration is 24 hours
  - Have `spec.parallelism: 10` in [2-k6-TestRun.yaml]( /loadTesting/k6/2-k6-TestRun.yaml) for stability and avoid the K6 `failed` status
- At the end of the K6 execution we:
  - Collect the K6 results
  - Collect the `Kong Linux Memory` observed (at the end of the test)
  - Collect the `Kong Proxy Latency p95` in Grafana 
  - Verify that **the checks are 100% successful**
- Kong Node is restarted between each iteration of test

## Performance Tests Scenarios for `calculator` Web Service (SOAP/XML)
- [Scenario 0]( /loadTesting/k6/scen0.js): no plugin (needs to set `replicas=2` instead of 1 to reach limit of `calculator`)
- [Scenario 1]( /loadTesting/k6/scen1.js): WSDL Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 2]( /loadTesting/k6/scen2.js): WSDL and SOAPAction Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 3]( /loadTesting/k6/scen3.js): XSD Validation (soap 1.1 and API schemas) Request plugin
- [Scenario 4]( /loadTesting/k6/scen4.js): XSLT Transformation (Before) with `libxslt` Request plugin (including XSD Validation (soap 1.1))
- [Scenario 5]( /loadTesting/k6/scen5.js): all options (with `libxslt`) for Request and Response plugins
- [Scenario 6]( /loadTesting/k6/scen6.js): WSDL Validation (soap 1.1 and API schemas) Response plugin
- [Scenario 7]( /loadTesting/k6/scen7.js): XSLT Transformation (Before) with `libxslt` Response plugin (including XSD Validation (soap 1.1))
- [Scenario 8]( /loadTesting/k6/scen8saxon.js): XSLT Transformation (Before) with `saxon` Request plugin
- [Scenario 9]( /loadTesting/k6/scen9saxon.js): XSLT v3.0 - JSON (client) to SOAP/XML (server) with `saxon` for Request and Response plugins (including XSD Validation (soap 1.1))
- [Scenario 10]( /loadTesting/k6/scen10saxon.js): XSLT v3.0 - XML (client) to JSON (server) with `saxon` for Request and Response plugins (including XSD Validation (custom schema))

## Performance Tests for `httpbin` REST API (JSON)
- [Scenario 0]( /loadTesting/k6/scenhttpbin0.js): no plugin (needs to set `replicas=8` instead of 1 to reach limit of `httpbin`)
- [Scenario 1]( /loadTesting/k6/scenhttpbin1.js): OAS Validation plugin (only Request validation)
- [Scenario 2]( /loadTesting/k6/scenhttpbin2.js): OAS Validation plugin (Request and Response validation)

## Endurance Tests Scenarios for `calculator` Web Service (SOAP/XML)
- [Scenario 5]( /loadTesting/k6/scen5endurance.js): all options (with `libxslt`) for Request and Response plugins

For `calculator` scenario 5 (Performmance and Endurance tests) the  Kong node consumes 8 GB of memory at peak so it may be necessary to allocate a little bit more memory (~8.5 GB)

## Performance Tests Result
|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|K6 Avg|K6 p95|K6 p99|Kong Linux Memory|Data Sent|Data Rcv
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|0|Kong proxy with no plugins|N/A|13177 rps|0.95 ms|4.5 ms|11.3 ms|21.2 ms|0.9 Gib|6.8 GB|10 GB
|calculator|1|WSDL Validation (req only) plugin|N/A|3780 rps|1.10 ms|5 ms|8.4 ms|26.8 ms|3.9 Gib|2 GB|3 GB
|calculator|2|WSDL and SOAPAction Validation (req only) plugin|N/A|3806 rps|0.99 ms|4.9 ms|8.3 ms|24.5 ms|3.8 Gib|2 GB|3 GB
|calculator|3|XSD Validation (req only) plugin|N/A| rps|ms| ms| ms| ms| Gib| GB| GB
|calculator|4|XSLT Transformation (req only) plugin|libxslt|5869 rps|0.97 ms|3.2 ms|5.9 ms|13.2 ms|1.9 Gib|3.2 GB|4.6 GB
|calculator|5|All options for req and res plugins|libxslt|1299 rps|4.27 ms|14.6 ms|35.1 ms|70.89 ms|6.7 Gib|0.75 GB|0.72 GB
|calculator|6|WSDL Validation (res only) plugin|N/A|3663 rps|0.97 ms|5.2 ms|8.25 ms|23 ms|2.9 Gib|1.9 GB|2.9 GB
|calculator|7|XSLT Transformation (res only) plugin|libxslt|3881 rps|0.96 ms|4.88 ms|8.77 ms|20.2 ms|1.4 Gib|2.1 GB|3.1 GB
|calculator|8|XSLT Transformation (req only) plugin|saxon|2587 rps|1.92 ms|7.3ms|10.7 ms|29.4 ms|2.1 Gib|1.4 GB|2 GB
|calculator|9|XSLT v3.0 - JSON to SOAP/XML for req and res plugins|saxon|1652 rps|1.91 ms|11.5 ms|15 ms|38.2 ms|2.7 Gib|0.3 GB|0.8 GB
|calculator|10|XSLT v3.0 - XML (client) to JSON (server) for req and res plugins|saxon|1108 rps|3.2 ms|17.1 ms|28.2 ms|40.1 ms|2.1 Gib|1.3 GB|1.5 GB
|httbin|0|Kong proxy with no plugins|N/A| rps|ms|ms| ms| ms| Gib| GB| GB
|httbin|1|OAS Validation (req only)|N/A|8691 rps|ms|23 ms|63 ms|92 ms|0.9 Gib| GB| GB
|httbin|2|OAS Validation (req and res)|N/A|6508 rps|ms|31 ms|99 ms|144 ms|0.9 Gib| GB| GB

## Endurance Tests Result (24h)
|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|K6 Avg|K6 p95|K6 p99|Kong Linux Memory|Data Sent|Data Rcv
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|5|All options for req and res plugins|libxslt| rps| ms| ms| ms| ms| Gib| GB| GB
