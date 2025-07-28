# If there is an Auth: "ERROR: failed to solve: failed to push jeromeguillaume/kong-soap-xml..." re-create the buildx
# docker buildx create --use --name newbuilder --driver docker-container

all: kong_saxon_all

kong_saxon_all: local_lib_arm64 local_lib_amd64 kong_saxon_docker_hub kong_saxon_initcontainer_docker_hub

# All architectures: Build the Kong image (based on 'kong/kong-gateway') with the Saxon libraries and push it on Docker Hub
kong_saxon_docker_hub:
	# Build on multiplatform (arm64 and amd64) and push on Docker Hub registry
	docker buildx build --platform=linux/arm64,linux/amd64 --file=./saxon/Dockerfile_Kong_Saxon -t jeromeguillaume/kong-soap-xml:3.10.0.1-1.4.0-12.5 --push .

# All architectures: Build an initContainer image (based on 'alpine') with the Saxon libraries and push it on Docker Hub
kong_saxon_initcontainer_docker_hub:
	# Build on multiplatform (arm64 and amd64) and push on Docker Hub registry
	docker buildx build --platform=linux/arm64,linux/amd64 --file=./saxon/Dockerfile_Kong_Saxon_InitContainer -t jeromeguillaume/kong-soap-xml-initcontainer:1.0.5-1.4.0-12.5 --push .

# ARM64: Build the Saxon libraries and copy them locally
local_lib_arm64:
	# Build and Load image on (local) Docker for test
	docker buildx build --load --platform=linux/arm64 --file=./saxon/Dockerfile_Local_Lib -t kong-saxon-local-lib:1.0.5-1.4.0-12.5-arm64 .

	# Create directories (and ignore the error if the directories exist)
	-mkdir saxon/so
	-mkdir saxon/so/arm64

	# Get libsaxon-hec and libsaxon-for-kong SO (ARM 64)
	docker rm -f kong-saxon-make-arm64
	docker create --name kong-saxon-make-arm64 kong-saxon-local-lib:1.0.5-1.4.0-12.5-arm64
	docker cp kong-saxon-make-arm64:/usr/local/lib/libsaxon-4-kong.so ./saxon/so/arm64/.
	docker cp kong-saxon-make-arm64:/usr/local/lib/libsaxon-hec-12.5.0.so ./saxon/so/arm64/.

# AMD64: Build the Saxon libraries and copy them locally
local_lib_amd64:
	# Build and Load image on (local) Docker for test
	docker buildx build --load --platform=linux/amd64 --file=./saxon/Dockerfile_Local_Lib -t kong-saxon-local-lib:1.0.5-1.4.0-12.5-amd64 .
	
	# Create directories (and ignore the error if the directories exist)
	-mkdir saxon/so
	-mkdir saxon/so/amd64
	
	# Get libsaxon-hec and libsaxon-for-kong SO (AMD 64)
	docker rm -f kong-saxon-make-amd64
	docker create --name kong-saxon-make-amd64 kong-saxon-local-lib:1.0.5-1.4.0-12.5-amd64
	docker cp kong-saxon-make-amd64:/usr/local/lib/libsaxon-4-kong.so ./saxon/so/amd64/.
	docker cp kong-saxon-make-amd64:/usr/local/lib/libsaxon-hec-12.5.0.so ./saxon/so/amd64/.

