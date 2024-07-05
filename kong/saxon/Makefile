
all:
	docker build -t kong-saxon:3.6.1.3 .
	docker rm -f kong-saxon-make
	docker create --name kong-saxon-make kong-saxon:3.6.1.3
	docker cp kong-saxon-make:/usr/local/lib/libsaxon-4-kong.so ./so/.
	docker cp kong-saxon-make:/usr/local/lib/libsaxon-hec-12.5.0.so ./so/.