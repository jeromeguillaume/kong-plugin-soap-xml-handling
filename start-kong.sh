# remove the previous container
docker rm -f kong-gateway-soap-xml-handling >/dev/null

# Start Kong Gateway
docker run -d --name kong-gateway-soap-xml-handling \
--network=kong-net \
--link kong-database-soap-xml-handling:kong-database-soap-xml-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-request-handling,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-request-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-response-handling,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-response-handling \
--mount type=bind,source="$(pwd)"/kong/plugins/soap-xml-handling-lib,destination=/usr/local/share/lua/5.1/kong/plugins/soap-xml-handling-lib \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database-soap-xml-handling" \
-e "KONG_PG_USER=kong" \
-e "KONG_PG_PASSWORD=kongpass" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl http2" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl http2" \
-e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
-e "KONG_PLUGINS=bundled,soap-xml-request-handling,soap-xml-response-handling" \
-e "KONG_NGINX_WORKER_PROCESSES=1" \
-e KONG_LICENSE_DATA \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8002:8002 \
-p 8444:8444 \
kong/kong-gateway:3.3.1.0

# Disable gzip support
# -e "KONG_NGINX_PROXY_GZIP=off" \


echo 'docker logs kong-gateway-soap-xml-handling -f'