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
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database-soap-xml-handling" \
-e "KONG_PG_USER=kong" \
-e "KONG_PG_PASSWORD=kongpass" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_PROXY_LISTEN=0.0.0.0:7000, 0.0.0.0:7443 ssl http2" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:7001, 0.0.0.0:7444 ssl http2" \
-e "KONG_ADMIN_GUI_LISTEN=0.0.0.0:7002, 0.0.0.0:7445 ssl" \
-e "KONG_ADMIN_GUI_URL=http://localhost:7002" \
-e "KONG_PLUGINS=bundled,soap-xml-request-handling,soap-xml-response-handling" \
-e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
-e "KONG_NGINX_WORKER_PROCESSES=1" \
-e KONG_LICENSE_DATA \
-p 7000:7000 \
-p 7443:7443 \
-p 7001:7001 \
-p 7002:7002 \
-p 7444:7444 \
--platform linux/$ARCHITECTURE \
kong/kong-gateway:3.8.0.0

#kong/kong-gateway:3.7.1.1
#-e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
#--mount type=bind,source="$(pwd)"/kong/saxon/so/$ARCHITECTURE,destination=/usr/local/lib/kongsaxon \

#jeromeguillaume/kong-saxon:3.7.1.1-12.5

#-e "KONG_NGINX_PROXY_GZIP=on" \
#-e "KONG_NGINX_PROXY_GZIP_VARY=on" \
#-e "KONG_NGINX_PROXY_GZIP_MIN_LENGTH=10" \
#-e "KONG_NGINX_PROXY_GZIP_TYPES=text/xml" \
#-e "KONG_NGINX_PROXY_GZIP_PROXIED=any" \


echo 'docker logs kong-gateway-soap-xml-handling -f'