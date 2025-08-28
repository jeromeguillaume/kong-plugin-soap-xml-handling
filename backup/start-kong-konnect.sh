# Delete the Kong Gateway container
docker rm -f kong-gateway-konnect-soap-xml-handling

export ARCHITECTURE=arm64

# Start Kong Gateway
docker run -d --name kong-gateway-konnect-soap-xml-handling \
--network=kong-net \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-request-handling,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-request-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-response-handling,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-response-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-handling-lib,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-handling-lib \
--mount type=bind,source="$(pwd)"/kong/saxon/so/$ARCHITECTURE,destination=/usr/local/lib/kongsaxon \
--mount type=bind,source="$(pwd)"/kong/saxon/conf,destination=/usr/local/lib/kongsaxon/conf \
-e "KONG_ROLE=data_plane" \
-e "KONG_DATABASE=off" \
-e "KONG_VITALS=off" \
-e "KONG_CLUSTER_MTLS=pki" \
-e "KONG_CLUSTER_CONTROL_PLANE=008b754df8.eu.cp0.konghq.com:443" \
-e "KONG_CLUSTER_SERVER_NAME=008b754df8.eu.cp0.konghq.com" \
-e "KONG_CLUSTER_TELEMETRY_ENDPOINT=008b754df8.eu.tp0.konghq.com:443" \
-e "KONG_CLUSTER_TELEMETRY_SERVER_NAME=008b754df8.eu.tp0.konghq.com" \
-e "KONG_CLUSTER_CERT=-----BEGIN CERTIFICATE-----
MIICGzCCAcCgAwIBAgIBATAKBggqhkjOPQQDBDA+MTwwCQYDVQQGEwJFVTAvBgNV
BAMeKABrAG8AbgBuAGUAYwB0AC0AYwBwAC0AcwBvAGEAcAAtAHQAZQBzAHQwHhcN
MjUwNTA1MTU0MzI3WhcNMzUwNTA1MTU0MzI3WjA+MTwwCQYDVQQGEwJFVTAvBgNV
BAMeKABrAG8AbgBuAGUAYwB0AC0AYwBwAC0AcwBvAGEAcAAtAHQAZQBzAHQwWTAT
BgcqhkjOPQIBBggqhkjOPQMBBwNCAAS5jXGbnDsXJBWsldvxpnIrNLdVMtmzllzG
ytCRcC52V94SC3vY/ojEPr5PuWSZEm6i48YfL4VqAAYqtg4LteJNo4GuMIGrMAwG
A1UdEwEB/wQCMAAwCwYDVR0PBAQDAgAGMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
BgEFBQcDAjAXBgkrBgEEAYI3FAIECgwIY2VydFR5cGUwIwYJKwYBBAGCNxUCBBYE
FAEBAQEBAQEBAQEBAQEBAQEBAQEBMBwGCSsGAQQBgjcVBwQPMA0GBSkBAQEBAgEK
AgEUMBMGCSsGAQQBgjcVAQQGAgQAFAAKMAoGCCqGSM49BAMEA0kAMEYCIQDrmv+3
hRm8IWyea5B2agEp2NmLRPBkz47Rz8MueedjVAIhAOtqU3CNtKU8P742+9meT2Sn
60RPrkO2dBLLFWRfQZXr
-----END CERTIFICATE-----" \
-e "KONG_CLUSTER_CERT_KEY=-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgwYEePNt3HV4aU+O4
SGlnF0j8oduCLBe9T/d33xfXzcqgCgYIKoZIzj0DAQehRANCAAS5jXGbnDsXJBWs
ldvxpnIrNLdVMtmzllzGytCRcC52V94SC3vY/ojEPr5PuWSZEm6i48YfL4VqAAYq
tg4LteJN
-----END PRIVATE KEY-----" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_PROXY_LISTEN=0.0.0.0:9000, 0.0.0.0:9443 ssl http2" \
-e "KONG_PLUGINS=bundled,soap-xml-request-handling,soap-xml-response-handling" \
-e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
-e "KONG_NGINX_WORKER_PROCESSES=1" \
-e "SOAP_USERNAME=KongUser" \
-e "SOAP_PASSWORD=KongP@sswOrd!" \
-e "KONG_LOG_LEVEL=debug" \
-e "KONG_INCREMENTAL_SYNC=on" \
-p 9000:9000 \
-p 9443:9443 \
-p 9001:9001 \
-p 9002:9002 \
-p 9444:9444 \
--platform linux/$ARCHITECTURE \
kong/kong-gateway:3.11.0.2

echo 'docker logs kong-gateway-konnect-soap-xml-handling -f'