# Load testing benchmark

## Load Testing results
The results are delivered for Kong `v3.10` - Medium size (4 CPU / 8 GB RAM) and SOAP/XML plugins `v1.4.0`:
- There is no memory leak and no restart of Kong GW pod observed after 24h tests:
  - Tested for `libxml2`, `libxslt` and `saxon`
- A basic policy (Validation or Transformation or XPath Routing) done by a plugin (Request or Reponse) impacts in a negligible way the respone time and delivers the expected benefit
  - For instance, the `Kong proxy latency p95` (time taken by Kong itself) is similar to the reference measure:  0.96 ms (with plugins) vs 0.96 ms (without plugins)
- All the features (WSDL and SOAPAction validation, 2 x XSLT Transformations with `libxslt` and XPath Routing) applied simultaneously on both plugins reduce the throughput (rps) by 4 times and the `Kong proxy latency p95` is 0.99 ms compared to the reference measure without plugins 0.95 ms
  - Due to the complex nature of SOAP/XML, the plugin involves a high CPU usage than a simple proxyfication without plugin. So pay attention to correcly size the number of CPUs for the Kong node (vertical scaling) and/or the number of nodes (horizontal scaling)
- XSLT v1.0: `libxslt` is more efficient than `saxon` in terms of throughput (+35% rps) and the `Kong proxy latency p95` is similar: 0.96 ms for `libxslt` vs 0.98 ms for `saxon`
  - XSLT v2.0 or 3.0: only `saxon` supports them
- The `v1.4.0` optimizes the performance by compiling and parsing the XML defintions only once in comparison to the former releases where the XML defintions were compiled and parsed on each call, so:
  - The Kong memory usage is 4x lower
  - The throughput is ~2,4x higher

See detailed results:
  - [Results of Performance Testing](#performance_testing_results): for measuring the performance of the SOAP/XML plugins in a context of high usage
  - [Results of Endurance Testing (24h)](#endurance_testing_results): for checking that there is no memory leak in the SOAP/XML plugins
  - [Results of Concurrent Testing with error](#concurrent_testing_with_error_results): for checking that there is no side effect of an error request on a query without error

## Deployment of the Architecture test
Deploy the stack **in this order** (for having `podAntiAffinity`):
1) Google Kubernetes Engine (GKE)
  - Use the `c2-standard-8` GKE cloud instance size:
    - 8 vCPUs and 32 GB ram per node
    - 3 nodes
2) Kong GW configuration:
  - Create a Control Plane on Konnect Management Plane
  - Create the custom plugins on Konnect Management Plane
  - Create the `kong` namespace
  - Create the configMap related to the plugins: [configMap-plugins.sh](/loadtesting/k6/0-init/cp-gke/configMap-plugins.sh)
  - Deploy the Kong Data Plane by using Helm with those parameters:
    - [values.yaml](/loadtesting/k6/0-init/cp-gke/values.yaml) without Saxon
    - [valuesSaxon.yaml](/loadtesting/k6/0-init/cp-gke/valuesSaxon.yaml) with Saxon
    - General Information:
      - Kong GW version: `kong/kong-gateway:3.10.0.1`
      - `saxon` version: `SaxonC-HE v12.5.0`
      - One Kong node with 4 Nginx workers (`nginx_worker_processes`: `4`)
      - Kong `Medium` size: the node is limited to 4 vCPU and 8 GB (`resources.requests` and `resources.limits`)
      - Disable `http2` on `proxy_listen` as it's the default protocol used by K6 and it's not supported by the Response plugin
  - Create a `kong-proxy` Kubernetes service (used by K6 scripts):
    - [kong-svc.yaml](/loadtesting/k6/0-init/kong-svc.yaml)
  - Import the Kong entities (Service/Route/Plugin) by executing: [deck_sync.sh](/loadtesting/k6/0-init/deck_sync.sh)
    - It includes the `Prometheus` plugin  
3) Prometheus / Grafana stack
  - Execute [monitoring.sh](/loadtesting/k6/0-init/cp-gke/monitoring.sh)
  - Open Grafana in the browser (see output of `monitoring.sh` for getting the URL and user/password)
  - Configure a `Prometheus` Data Source: menu Connections / Data Sources, add, select Prometheus and URL=`http://prometheus-server.monitoring`
  - Configure an `InfluxDB` Data Source: menu Connections / Data Sources, add, select influxdb and URL=`http://influxdb.monitoring:8086` and database=`k6`
  - Download JSON of the [Kong Dashboard for Grafana](https://grafana.com/grafana/dashboards/7424-kong-official/)
  - Import Kong Dashboard: menu Dahboards / New / Import and put the `Kong Dashboard Grafana` JSON
  - Download JSON of the [K6 Dashboard for Grafana](https://grafana.com/grafana/dashboards/14801-k6-dashboard/)
  - Import K6 Dashboard: menu Dahboards / New / Import and put the `K6 Dashboard Grafana` JSON
  - Download JSON of the [Kubernetes Dashboard for Grafana](https://grafana.com/grafana/dashboards/18283-kubernetes-dashboard/)
  - Import Kubernetes Dashboard: menu Dahboards / New / Import and select the `Prometheus` Data Source for cadvisor and Prometheus
4) K6: load testing tool
  - Helm installation
  ```bash
  curl https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml | kubectl apply -f -
  ```
  - See [Install k6 Operator](https://grafana.com/docs/k6/latest/set-up/set-up-distributed-k6/install-k6-operator/)
  
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
  - Configure [k6-TestRun.yaml](/loadtesting/k6/k6-TestRun.yaml) with the right scenario (scen0, scen1, scen2, etc.). For other types of tests like Endurance Testing or `httpbin` or `go-bench-suite` use:
    - Use [k6-TestRun-scenhttpbin.yaml](/loadtesting/k6/k6-TestRun-scenhttpbin.yaml)
    - Use [k6-TestRun-scengobench0.yaml](/loadtesting/k6/k6-TestRun-scengobench0.yaml)
    - Use [k6-TestRun-scen5endurance100.yaml](/loadtesting/k6/k6-TestRun-scen5endurance100.yaml)
    - Use [k6-TestRun-scen9endurance100.yaml](/loadtesting/k6/k6-TestRun-scen9endurance100.yaml)
    - Use [k6-TestRun-scen10endurance100.yaml](/loadtesting/k6/k6-TestRun-scen10endurance100.yaml)
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
  - Have `replicas: 3` in [ws-calculator.yaml](/loadtesting/k6/ws-calculator.yaml) for a better stability and endurance
  - Since this is not a performance testing there is a `sleep()` in the script for reducing the pace: the `sleep()` duration is subtracted from the performance duration metrics (`avg`, `p95`, `p99`)
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

## Endurance Testing scenarios for `calculator` Web Service (SOAP/XML) and 100 x Kong routes
Objective: check that there is no memory leak in the SOAP/XML plugins and check that the compiling/parsing of all XML definitions work well
- [Scenario 5 Endurance - 100 routes](/loadtesting/k6/scen5endurance100.js): all options (with `libxslt`) for **Request** and **Response** plugins
- [Scenario 9 Endurance - 100 routes](/loadtesting/k6/scen9saxonendurance100.js): XSLT v3.0 - JSON to SOAP/XML (with `saxon`) for **Request** and **Response** plugins
- [Scenario 10 Endurance - 100 routes](/loadtesting/k6/scen10saxonendurance100.js): XSLT v3.0 - XML to JSON with `saxon` for **Request** and **Response** plugins (including XSD Validation (custom schema))

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
|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|K6 Avg|K6 p95|K6 p99|Kong Linux Memory|Data Sent|Data Rcvd
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|0|Kong proxy with no plugins|N/A|12908 rps|0.96 ms|3.86 ms|8.95 ms|14.1 ms|1.1 GiB|6.5 GB|9.8 GB
|calculator|1|WSDL Validation (req plugin only)|N/A|9071 rps|0.95 ms|2.08 ms|4.55 ms|6.6 ms|1.3 GiB|4.7 GB|7.1 GB
|calculator|2|WSDL and SOAPAction Validation (req plugin only)|N/A|7988 rps|0.95 ms|2.36 ms|4.85 ms|7.09 ms|1.4 GiB|4.4 GB|6.3 GB
|calculator|3|XSD Validation (req plugin only)|N/A|9209 rps|0.96 ms|2.05 ms|4.48 ms|6.39 ms|1.3 GiB|4.8 GB|7.2 GB
|calculator|4|XSLT Transformation (req plugin only)|libxslt|6815 rps|0.96 ms|2.78 ms|5.77 ms|8.33 ms|1.2 GiB|3.61 GB|5.3 GB
|calculator|5|All options for req and res plugins|libxslt|3133 rps|0.99 ms|6.05 ms|11.15 ms|16.91 ms|1.7 GiB|1.8 GB|1.7 GB
|calculator|6|WSDL Validation (res plugin only)|N/A|8314 rps|0.95 ms|2.27 ms|4.66 ms|7 ms|1.3 GiB|4.3 GB|6.6 GB
|calculator|7|XSLT Transformation (res plugin only)|libxslt|7267 rps|0.95 ms|2.6 ms|5.34 ms|7.76 ms|1.4 GiB|3.8 GB| 5.7 GB
|calculator|8|XSLT Transformation (req plugin only)|saxon|5016 rps|0.98 ms|3.77 ms|6.64 ms|9.37 ms|1.2 GiB|2.7 GB|3.9 GB
|calculator|9|XSLT v3.0 - JSON to SOAP/XML for req and res plugins|saxon|3433 rps|0.98 ms|5.52 ms|8.87 ms|12.33 ms|1.4 GiB|0.68 GB|1.6 GB
|calculator|10|XSLT v3.0 - XML (client) to JSON (server) for req and res plugins|saxon|2853 rps|0.98 ms|6.64 ms|10.5 ms|15.41 ms|1.3 GiB|1.5 GB|2.1 GB
|httbin|0|Kong proxy with no plugins|N/A|10931 rps|0.96 ms|25.46 ms|46.6 ms|83.2 ms|1 GiB|5.6 GB|16.9 GB
|httbin|1|OAS Validation (req plugin only)|N/A|9311 rps|0.97 ms|29.94 ms|60.2 ms|99.23 ms|1.1 GiB|4.8 GB|14.4 GB
|httbin|2|OAS Validation (req and res plugins)|N/A|8173 rps|0.98 ms|34.08 ms|51.77 ms|105.12 ms|1 GiB|4.2 GB|12.7 GB
|go-bench-suite|0|Kong proxy with no plugins|N/A|18797 rps|0.96 ms|4.94 ms|10.54 ms|20.55 ms|1.2 GiB|2.2 GB GB|12.7 GB

Scenario 1 `calculator` - WSDL Validation (req plugin only): RPS per route/service by status code
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen1-rps.jpeg?raw=true "Scenario 4 - XSLT Transformation - libxslt")
Scenario 1 `calculator` - WSDL Validation (req plugin only): Kong Proxy Latency per Service
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen1-kong-proxy-latency.jpeg?raw=true "Scenario 4 - XSLT Transformation - libxslt")

<a id="endurance_testing_results"></a>

## Results of Endurance Testing (24h) and 100 x Kong routes
Here the performance is not the main objective, we check that:
  - There is no memory leak (see `Kong Linux Memory`)
  - No restart of Kong GW pod observed after 24h tests
  - No impact of re-compiling/re-parsing all XML definitions (every 1 hour) deployed on 100 x Kong Routes. The plugins are deployed on the route, so there are 200 instances plugin in total (1 req + 1 res plugin/route)

|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|K6 Avg|K6 p95|K6 p99|Kong Linux Memory|Data Sent|Data Rcvd
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|5|All options for req and res plugins|libxslt|2115 rps|0.98 ms|30.24 ms|178.35 ms|322.79 ms|2.4 GiB|105.4 GB|103.5 GB
|calculator|9|XSLT v3.0 - JSON to SOAP/XML for req and res plugins|saxon|2125 rps|0.98 ms|26.67 ms|153.12 ms|306.27 ms|2 GiB|37.8 GB|87.7  GB
|calculator|10|XSLT v3.0 - XML to JSON for req and res plugins|saxon|2118 rps|0.97 ms|38.13 ms|189.15 ms|332.46 ms|1.7 GiB|99.1 GB|137.7 GB

Scenario 5 `calculator` - All options for req and res plugins `libxslt`: RPS per route/service by status code
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen5endurance100-rps.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")
Scenario 5 `calculator` - All options for req and res plugins `libxslt`: Kong Proxy Latency per Service
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen5endurance100-kong-proxy-latency.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")
Scenario 5 `calculator` - All options for req and res plugins `libxslt`: Kong worker Lua VM usage
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen5endurance100-kong-worker-Lua-VM.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")
Scenario 5 `calculator` - All options for req and res plugins `libxslt`: Kong shared memory usage
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen5endurance100-kong-shared-memory-usage.jpeg?raw=true "Scenario 5 - All options for req and res plugins - libxslt")

Scenario 9 `calculator` - XSLT v3.0 - XML to JSON for req and res plugins `saxon`: RPS per route/service by status code
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen9endurancesaxon100-rps.jpeg?raw=true "Scenario 9 - XSLT v3.0 - JSON to SOAP/XML for req and res plugins - saxon")
Scenario 9 `calculator` - XSLT v3.0 - XML to JSON for req and res plugins `saxon`: Kong worker Lua VM usage
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen9endurancesaxon100-kong-worker-Lua-VM.jpeg?raw=true "Scenario 9 - XSLT v3.0 - JSON to SOAP/XML for req and res plugins - saxon")

Scenario 10 `calculator` - XSLT v3.0 - JSON to SOAP/XML for req and res plugins `saxon`: RPS per route/service by status code
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen10endurancesaxon-rps.jpeg?raw=true "Scenario 10 - XSLT v3.0 - JSON to SOAP/XML for req and res plugins - saxon")
Scenario 10 `calculator` - XSLT v3.0 - JSON to SOAP/XML for req and res plugins `saxon`: Kong worker Lua VM usage
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen10endurancesaxon-kong-worker-Lua-VM.jpeg?raw=true "Scenario 10 - XSLT v3.0 - JSON to SOAP/XML for req and res plugins - saxon - saxon")

<a id="concurrent_testing_with_error_results"></a>

## Results of Concurrent Testing with error
Here the performance is not the main objective, we check in the K6 results that the "Ok" route leading to an expected 200 actually returns a 200 despite a high number of 500 errors implied concurently by the "Ko" route
|Service name|Scenario|Test type|XSLT Library|Requests per second|Kong Proxy Latency p95|K6 Avg|K6 p95|K6 p99|Kong Linux Memory|Data Sent|Data Rcvd
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|--:|
|calculator|1|WSDL Validation (req plugin only) with errors|N/A|8550 rps|0.96 ms|4.43 ms|9.37 ms|17.27 ms|1.3 GiB|4.5 GB|6.3 GB
|calculator|3|XSD Validation (req plugin only) with errors|N/A|7946 rps|0.96 ms|4.77 ms|9.95 ms|18.16 ms|1.5 GiB|4.3 GB|6.6 GB

Scenario 3 `calculator` - XSD Validation with Error: RPS per route/service by status code
![Alt text](/loadtesting/synthesis/images_v1.4.0/loadtesting-scen3concurrent-rps.jpeg?raw=true "Scenario 3 - XSD Validation with Error")