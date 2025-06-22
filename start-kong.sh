# Delete the Kong Gateway container
docker rm -f kong-gateway-soap-xml-handling

export ARCHITECTURE=arm64

# Start Kong Gateway
docker run -d --name kong-gateway-soap-xml-handling \
--network=kong-net \
--link kong-database-soap-xml-handling:kong-database-soap-xml-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-request-handling,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-request-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-response-handling,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-response-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-handling-lib,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-handling-lib \
--mount type=bind,source="$(pwd)"/kong/saxon/so/$ARCHITECTURE,destination=/usr/local/lib/kongsaxon \
--mount type=bind,source="$(pwd)"/kong/saxon/conf,destination=/usr/local/lib/kongsaxon/conf \
--mount type=bind,source="$(pwd)"/spec/fixtures/,destination=/kong-plugin/spec/fixtures \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database-soap-xml-handling" \
-e "KONG_PG_USER=kong" \
-e "KONG_PG_PASSWORD=kongpass" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_PROXY_LISTEN=0.0.0.0:9000, 0.0.0.0:9443 ssl http2" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:9001, 0.0.0.0:9444 ssl http2" \
-e "KONG_ADMIN_GUI_LISTEN=0.0.0.0:9002, 0.0.0.0:9445 ssl" \
-e "KONG_ADMIN_GUI_URL=http://localhost:9002" \
-e "KONG_PLUGINS=bundled,soap-xml-request-handling,soap-xml-response-handling" \
-e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
-e "KONG_NGINX_WORKER_PROCESSES=1" \
-e "SOAP_USERNAME=KongUser" \
-e "SOAP_PASSWORD=KongP@sswOrd!" \
-e "KONG_LOG_LEVEL=debug" \
-e KONG_LICENSE_DATA \
-p 9000:9000 \
-p 9443:9443 \
-p 9001:9001 \
-p 9002:9002 \
-p 9444:9444 \
--platform linux/$ARCHITECTURE \
kong/kong-gateway:3.10.0.1

#kong/kong-gateway:3.4.3.13
#kong/kong-gateway:3.5.0.7
#kong/kong-gateway:3.6.1.8

# -e "KONG_STREAM_LISTEN= 0.0.0.0:9099" \


#kong/kong-gateway:3.8.0.0
#kong/kong-gateway:3.7.1.1
#-e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
#--mount type=bind,source="$(pwd)"/kong/saxon/so/$ARCHITECTURE,destination=/usr/local/lib/kongsaxon \

#jeromeguillaume/kong-soap-xml:3.7.1.1-12.5

#-e "KONG_NGINX_PROXY_GZIP=on" \
#-e "KONG_NGINX_PROXY_GZIP_VARY=on" \
#-e "KONG_NGINX_PROXY_GZIP_MIN_LENGTH=10" \
#-e "KONG_NGINX_PROXY_GZIP_TYPES=text/xml" \
#-e "KONG_NGINX_PROXY_GZIP_PROXIED=any" \


echo 'docker logs kong-gateway-soap-xml-handling -f'