# Load testing benchmark

## Load Testing results
The results are delivered for Kong v3.9 - Medium size (4 CPU / 8 GB RAM):
- There is no memory leak and no restart of Kong GW pod observed after 24h tests:
  - Tested for `libxml2`, `libxslt` and `saxon`
- A basic policy (Validation or Transformation or XPath Routing) done by a plugin (Request or Reponse) impacts in a negligible way the respone time and delivers the expected benefit
  - For instance, the `Kong proxy latency p95` (time taken by Kong itself) is very close to the reference measure:  1.10 ms (with plugins) vs 0.95 ms (without plugins)
- All the features (WSDL and SOAPAction validation, 2 x XSLT Transformations with `libxslt` and XPath Routing) applied simultaneously on both plugins reduce the throughput (rps) by 10 times and the `Kong proxy latency p95` is ~4 ms compared to the reference measure without plugins 0.95 ms
  - Due to the complex nature of SOAP/XML, the plugin involves a high CPU usage than a simple proxyfication without plugin. So pay attention to correcly size the number of CPUs for the Kong node (vertical scaling) and/or the number of nodes (horizontal scaling)
- XSLT v1.0: `libxslt` is more efficient than `saxon` in terms of throughput (+50% rps) and `Kong proxy latency p95` (50% lower). 
  - XSLT v2.0 or 3.0: only `saxon` supports them

See detailed results:
  - [Results of Performance Testing](#performance_testing_results): for measuring the performance of the SOAP/XML plugins in a context of high usage
  - [Results of Endurance Testing (24h)](#endurance_testing_results): for checking that there is no memory leak in the SOAP/XML plugins
  - [Results of Concurrent Testing with error](#concurrent_testing_with_error_results): for checking that there is no side effect of an error request on a query without error

## Architecture test
Deploy the stack **in this order** (for having `podAntiAffinity`):
1) Google Kubernetes Engine (GKE)
  - Use the `c2-standard-8` GKE cloud instance size:
    - 8 vCPUs and 32 GB ram per node
    - 3 nodes
2) Kong GW configuration:
  - Kong GW version: `kong/kong-gateway:3.9.0.1`
  - `saxon` version: `SaxonC-HE v12.5.0`
  - One Kong node with 4 Nginx workers (`nginx_worker_processes`: `4`)
  - Kong `Medium` size: the node is limited to 4 vCPU and 8 GB (`resources.requests` and `resources.limits`)
  - Disable `http2` on `proxy_listen` as it's the default protocol used by K6 and it's not supported by the Response plugin
  - Create a `kong-proxy` Kubernetes service
  - Those specific parameters are defined in:
    - [values.yaml](/loadtesting/k6/0-init/cp-gke/values.yaml) without Saxon
    - [valuesSaxon.yaml](/loadtesting/k6/0-init/cp-gke/valuesSaxon.yaml) with Saxon
    - [kong-svc.yaml](/loadtesting/k6/0-init/kong-svc.yaml) 
  - The Kong entities (Service/Route/Plugin) are defined in [k6-kong.yaml](/loadtesting/k6/0-init/k6-kong.yaml) deck file. It includes the `Prometheus` plugin
3) Prometheus / Grafana stack
4) K6: load testing tool
  - See [Running distributed load tests on Kubernetes](https://grafana.com/blog/2022/06/23/running-distributed-load-tests-on-kubernetes/)
  - `make deploy`
5) Upstream:
  - `calculator` Web Service (SOAP/XML)
    - Docker Image: [jeromeguillaume/ws-soap-calculator:1.0.4](https://hub.docker.com/r/jeromeguillaume/ws-soap-calculator)
    - Kubernetes deployment: [ws-calculator.yaml](loadtesting/k6/ws-calculator.yaml)
  - `httpbin` REST API (JSON)
    - Docker Image: [kong/httpbin:0.2.3](https://hub.docker.com/r/kong/httpbin)
    - Kubernetes deployment: [httpbin.yaml](loadtesting/k6/0-init/httpbin.yaml)
  - `go-bench-suite` REST API (JSON)
    - Docker Image: [mangomm/go-bench-suite:latest](https://hub.docker.com/r/mangomm/go-bench-suite)
    - Kubernetes deployment: [go-bench-suite.yaml](loadtesting/k6/0-init/go-bench-suite.yaml)

Each deployment (Kong GW, K6, Upstream) has `podAntiAffinity` property for having a dedicated node for each deployment. Exception: in case of Scenario 0 (tests with no plugins) and Endurance testing the number of `replicas` for the Upstream and `K6` deployment are deployed on all Kubernetes nodes

## How to use K6
- Create a ConfigMap for each scenario
  - See [k6-configMap.sh](/loadtesting/k6/k6-configMap.sh)
- Start a scenario on your Laptop
  - Configure `executor: per-vu-iterations` and `iterations: 1` in the `scenX.js`
  - `k6 run scen1.js`
- Start a Load testing on Kubernetes
  - Configure `executor: 'ramping-vus` and `{ duration: '900s', target: 20 }` in the `scenX.js`
  - Configure [k6-TestRun.yaml](/loadtesting/k6/k6-TestRun.yaml) with the right scenario (scen0, scen1, scen2, etc.)
  - Apply the configuration and start the test: `kubectl apply -f k6-TestRun.yaml`
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
- Performance testing
  - Duration = 15 minutes
  - The K6 scripts are configured to reach the limit of the Kong node (CPU or Memory) and to use all the physical ressources allocated
  - Have `spec.parallelism: 1` in [k6-TestRun.yaml](/loadtesting/k6/k6-TestRun.yaml)
  - There is a ramp up phase of 90 s then the 15 min test
- Endurance testing
  - Duration = 24 hours
  - Have `spec.parallelism: 10` in [k6-TestRun.yaml](/loadtesting/k6/k6-TestRun.yaml) for stability and avoid the K6 `failed` status
  - Have `replicas: 5` in [ws-calculator.yaml](/loadtesting/k6/ws-calculator.yaml) for a better stability and endurance
  - Since this is not a performance testing there is a `sleep()` in the script for reducing the pace: the `sleep()` duration is subtracted from the performance duration metrics (`avg`, `p95`, `p99`)
- Performance and Endurance Testing: for `calculator` scenario 5  the  Kong node consumes 8 GB of memory at peak so it may be necessary to allocate a little bit more memory (~8.5 GB)
- At the end of the K6 execution:
  - Collect the K6 results for `Requests per second`, `Avg`, `p95`, `p99`, `Data Sent`, `Data Rcvd` metrics
  - Collect the `Kong Linux Memory` (observed at the end of the test)
  - Collect the `Kong Proxy Latency p95` in Grafana 
  - Verify that **the checks are 100% successful**
- Kong Node is restarted between each iteration of test

## Performance Testing scenarios for `calculator` Web Service (SOAP/XML)
Objective: measure the performance of the SOAP/XML plugins in a context of high usage
- [Scenario 0](/loadtesting/k6/scen0.js): no plugin (needs to set `replicas: 2` for `calculator` instead of 1 to reach its limit)
- [Scenario 1](/loadtesting/k6/scen1.js): WSDL Validation (soap 1.1 and API schemas) **Request** plugin
- [Scenario 2](/loadtesting/k6/scen2.js): WSDL and SOAPAction Validation (soap 1.1 and API schemas) **Request** plugin
- [Scenario 3](/loadtesting/k6/scen3.js): XSD Validation (soap 1.1 and API schemas) **Request** plugin
- [Scenario 4](/loadtesting/k6/scen4.js): XSLT Transformation (Before) with `libxslt` **Request** plugin (including XSD Validation (soap 1.1))
- [Scenario 5](/loadtesting/k6/scen5.js): all options (with `libxslt`) for **Request** and **Response** plugins
- [Scenario 6](/loadtesting/k6/scen6.js): WSDL Validation (soap 1.1 and API schemas) **Response** plugin
- [Scenario 7](/loadtesting/k6/scen7.js): XSLT Transformation (Before) with `libxslt` **Response plugin** (including XSD Validation (soap 1.1))
- [Scenario 8](/loadtesting/k6/scen8saxon.js): XSLT Transformation (Before) with `saxon` **Request** plugin
- [Scenario 9](/loadtesting/k6/scen9saxon.js): XSLT v3.0 - JSON (client) to SOAP/XML (server) with `saxon` for **Request** and **Response** plugins (including XSD Validation (soap 1.1))
- [Scenario 10](/loadtesting/k6/scen10saxon.js): XSLT v3.0 - XML (client) to JSON (server) with `saxon` for **Request** and **Response** plugins (including XSD Validation (custom schema))

## Performance Testing scenarios for `httpbin` REST API (JSON)
Objective: have a reference measure of a REST API to compare to the SOAP/XML API. This reference measure is also used in the context of scenario 10 (XSLT v3.0 - XML (client) to JSON (server) with `saxon`) using `httpbin`
- [Scenario 0](/loadtesting/k6/scenhttpbin0.js): no plugin
- [Scenario 1](/loadtesting/k6/scenhttpbin1.js): OAS Validation plugin (**Request** validation only)
- [Scenario 2](/loadtesting/k6/scenhttpbin2.js): OAS Validation plugin (**Request** and **Response** validation): needs to be reviewed as there is no response schema defined in the OAS

## Performance Testing scenarios for `go-bench-suite` REST API (JSON)
Objective: have another reference measure of a REST API to compare to the SOAP/XML API. The `go-bench-suite` is used for the benchmark of Kong Gateway : see the [performance testing benchmarks](https://docs.konghq.com/gateway/latest/production/performance/performance-testing/) and the [public test suite](https://github.com/Kong/kong-gateway-performance-benchmark/)
- [Scenario 0](/loadtesting/k6/scengobench0.js): no plugin

## Endurance Testing scenarios for `calculator` Web Service (SOAP/XML)
Objective: check that there is no memory leak in the SOAP/XML plugins
- [Scenario 5 Endurance](/loadtesting/k6/scen5endurance.js): all options (with `libxslt`) for **Request** and **Response** plugins
- [Scenario 9 Endurance](/loadtesting/k6/scen9saxonendurance.js): XSLT v3.0 - JSON to SOAP/XML (with `saxon`) for **Request** and **Response** plugins
- [Scenario 10 Endurance](/loadtesting/k6/scen10saxonendurance.js): XSLT v3.0 - XML to JSON with `saxon` for **Request** and **Response** plugins (including XSD Validation (custom schema))

## Concurrent Testing scenarios with error for `calculator` Web Service (SOAP/XML)
Objective: check that there is no side effect of an error request on a query without error. Keep in mind that the `libxml2` and `libxslt` libraries have global functions to detect error
- [Scenario 1 with Error](/loadtesting/k6/scen1concurrent.js): WSDL Validation **Request** plugin, 2 sub-scenarios are concurently executed:
  - A sub-scenario without error (http 200)
  - A sub-scenario with error (http 500) due to an invalid WSDL schema (in the plugin configuration)
- [Scenario 3 with Error](/loadtesting/k6/scen3concurrent.js): XSD Validation **Request** plugin, 2 sub-scenarios are concurently executed: 
  - A sub-scenario without error (http 200)
  - A sub-scenario with error (http 500) due to an invalid SOAP body request

<a id="performance_testing_results"></a>

## Results of Performance Testing
|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|Avg|p95|p99|Kong Linux Memory|Data Sent|Data Rcvd
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|0|Kong proxy with no plugins|N/A|13177 rps|0.95 ms|4.5 ms|11.3 ms|21.2 ms|0.9 Gib|6.8 GB|10 GB
|calculator|1|WSDL Validation (req plugin only)|N/A|3780 rps|1.10 ms|5 ms|8.4 ms|26.8 ms|3.9 Gib|2 GB|3 GB
|calculator|2|WSDL and SOAPAction Validation (req plugin only)|N/A|3806 rps|0.99 ms|4.9 ms|8.3 ms|24.5 ms|3.8 Gib|2 GB|3 GB
|calculator|3|XSD Validation (req plugin only)|N/A|4561 rps|0.98 ms|4.2 ms|7.5 ms|17.3 ms|2.7 Gib|2.4 GB|3.6 GB
|calculator|4|XSLT Transformation (req plugin only)|libxslt|5949 rps|0.97 ms|3.18 ms|5.9 ms|13.1 ms|2.1 Gib|3.2 GB|4.7 GB
|calculator|5|All options for req and res plugins|libxslt|1299 rps|4.27 ms|14.6 ms|35.1 ms|70.9 ms|6.7 Gib|0.75 GB|0.72 GB
|calculator|6|WSDL Validation (res plugin only)|N/A|3663 rps|0.97 ms|5.2 ms|8.2 ms|23 ms|2.9 Gib|1.9 GB|2.9 GB
|calculator|7|XSLT Transformation (res plugin only)|libxslt|3881 rps|0.96 ms|4.9 ms|8.8 ms|20.2 ms|1.4 Gib|2.1 GB|3.1 GB
|calculator|8|XSLT Transformation (req plugin only)|saxon|2587 rps|1.92 ms|7.3ms|10.7 ms|29.4 ms|2.1 Gib|1.4 GB|2 GB
|calculator|9|XSLT v3.0 - JSON to SOAP/XML for req and res plugins|saxon|1652 rps|1.91 ms|11.5 ms|15 ms|38.2 ms|2.7 Gib|0.3 GB|0.8 GB
|calculator|10|XSLT v3.0 - XML (client) to JSON (server) for req and res plugins|saxon|1079 rps|2.94 ms|17.6 ms|26.5 ms|39 ms|2.1 Gib|0.59 GB| 0.8 GB
|httbin|0|Kong proxy with no plugins|N/A|10290 rps|0.96 ms|26.97 ms|43.4 ms|82.3 ms|0.9 Gib|5.5 GB|16 GB
|httbin|1|OAS Validation (req plugin only)|N/A|8905 rps|0.96 ms|31.2 ms|59.8 ms|95 ms|0.9 Gib|4.7 GB|14 GB
|httbin|2|OAS Validation (req and res plugins)|N/A|6712 rps|0.97 ms|41.4 ms|61.1 ms|116.7 ms|0.9 Gib|3.5 GB|11 GB
|go-bench-suite|0|Kong proxy with no plugins|N/A|19511 rps|0.97 ms|4.75 ms|11 ms|19.9 ms|0.9 Gib|2.5 GB GB|13 GB

Scenario 4 `calculator` - XSLT Transformation `libxslt`: RPS per route/service by status code
![Alt text](/images/loadtesting-scen4-rps.jpeg?raw=true "Scenario 4 - XSLT Transformation - libxslt")
Scenario 4 `calculator` - XSLT Transformation `libxslt`: Kong Proxy Latency per Service
![Alt text](/images/loadtesting-scen4-kong-proxy-latency.jpeg?raw=true "Scenario 4 - XSLT Transformation - libxslt")

<a id="endurance_testing_results"></a>

## Results of Endurance Testing (24h)
The main objective is to check that is no memory leak (see `Kong Linux Memory`) and no restart of Kong GW pod observed after 24h tests
|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|K6 Avg|K6 p95|K6 p99|Kong Linux Memory|Data Sent|Data Rcvd
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|5|All options for req and res plugins|libxslt|611 rps|4.56 ms|7.7 ms|24 ms|71.3 ms|4.7 Gib|31 GB|29.4 GB
|calculator|9|XSLT v3.0 - JSON to SOAP/XML for req and res plugins|saxon|632 rps|2.97 ms|6.6 ms|7.6 ms|86.4 ms|8.2 Gib|12 GB| 26 GB
|calculator|10|XSLT v3.0 - XML to JSON for req and res plugins|saxon| rps| ms| ms| ms| ms| Gib| GB| GB

Scenario 5 `calculator` - All options for req and res plugins `libxslt`: RPS per route/service by status code
![Alt text](/images/loadtesting-scen5endurance-rps.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")
Scenario 5 `calculator` - All options for req and res plugins `libxslt`: Kong Proxy Latency per Service
![Alt text](/images/loadtesting-scen5endurance-kong-proxy-latency.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")
Scenario 5 `calculator` - All options for req and res plugins `libxslt`: Kong worker Lua VM usage
![Alt text](/images/loadtesting-scen5endurance-kong-worker-Lua-VM.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")
Scenario 5 `calculator` - All options for req and res plugins `libxslt`: Kong shared memory usage
![Alt text](/images/loadtesting-scen5endurance-kong-shared-memory-usage.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")

Scenario 9 `calculator` - XSLT v3.0 - JSON to SOAP/XML for req and res plugins `saxon`: RPS per route/service by status code
![Alt text](/images/loadtesting-scen9endurancesaxon-rps.jpeg?raw=true "Scenario 9 - XSLT v3.0 - JSON to SOAP/XML for req and res plugins - saxon")
Scenario 9 `calculator` - XSLT v3.0 - JSON to SOAP/XML for req and res plugins `saxon`: Kong worker Lua VM usage
![Alt text](/images/loadtesting-scen9endurancesaxon-kong-worker-Lua-VM.jpeg?raw=true "Scenario 9 - XSLT v3.0 - JSON to SOAP/XML for req and res plugins - saxon")

<a id="concurrent_testing_with_error_results"></a>

## Results of Concurrent Testing with error
Here the performance is not the main objective: we just check in the K6 results that the "Ok" route leading to an expected 200 actually returns a 200 despite a high number of 500 errors implied concurently by the "Ko" route
|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|K6 Avg|K6 p95|K6 p99|Kong Linux Memory|Data Sent|Data Rcvd
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|1|WSDL Validation (req plugin only) with errors|N/A|4277 rps|0.99 ms|8.9 ms|16 ms|58.4 ms|2.7 Gib|2.3 GB|3.3 GB
|calculator|3|XSD Validation (req plugin only) with errors|N/A|4479 rps|1 ms|8.5 ms|17.5 ms|45.1 ms|2.2 Gib|2.5 GB|3.9 GB

Scenario 3 `calculator` - XSD Validation with Error: RPS per route/service by status code
![Alt text](/images/loadtesting-scen3concurrent-rps.jpeg?raw=true "Scenario 3 - XSD Validation with Error")