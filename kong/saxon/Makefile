all: kong_saxon_all

kong_saxon_all: docker_hub arm64 amd64

docker_hub:
	# Build on multiplatform (arm64 and amd64) and push on Docker Hub registry
	docker buildx build --platform=linux/arm64,linux/amd64 -t jeromeguillaume/kong-saxon:3.7.1.1 --push .
	
arm64:
	# Build and Load image on (local) Docker for test
	docker buildx build --load --platform=linux/arm64 -t jeromeguillaume/kong-saxon:3.7.1.1-arm64 .

	# Create directories (and ignore the error if the directories exist)
	-mkdir so
	-mkdir so/arm64

	# Get libsaxon-hec and libsaxon-for-kong SO (ARM 64)
	docker rm -f kong-saxon-make-arm64
	docker create --name kong-saxon-make-arm64 jeromeguillaume/kong-saxon:3.7.1.1-arm64
	docker cp kong-saxon-make-arm64:/usr/local/lib/libsaxon-4-kong.so ./so/arm64/.
	docker cp kong-saxon-make-arm64:/usr/local/lib/libsaxon-hec-12.5.0.so ./so/arm64/.

amd64:
	# Build and Load image on (local) Docker for test
	docker buildx build --load --platform=linux/amd64 -t jeromeguillaume/kong-saxon:3.7.1.1-amd64 .
	
	# Create directories (and ignore the error if the directories exist)
	-mkdir so
	-mkdir so/amd64
	
	# Get libsaxon-hec and libsaxon-for-kong SO (AMD 64)
	docker rm -f kong-saxon-make-amd64
	docker create --name kong-saxon-make-amd64 jeromeguillaume/kong-saxon:3.7.1.1-amd64
	docker cp kong-saxon-make-amd64:/usr/local/lib/libsaxon-4-kong.so ./so/amd64/.
	docker cp kong-saxon-make-amd64:/usr/local/lib/libsaxon-hec-12.5.0.so ./so/amd64/.

