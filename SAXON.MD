# Saxon and Kong

## Prerequisite: download the SaxonC-HE v12 - Zip package
- Linux AArch64:
[https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-aarch64-v12.5.0.zip](https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-aarch64-v12.5.0.zip)
- Linux Intel x86_64:
[https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-x86_64-v12.5.0.zip](https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-x86_64-v12.5.0.zip)
- General download page:
[https://www.saxonica.com/html/download/c.html](https://www.saxonica.com/html/download/c.html)

## Extract/Build the `Saxon` Shared Objects and the Docker images
- The `Saxon - Kong` integration requires 2 Shared Objects that are extracted and built with the `make` command:
  - `libsaxon-hec-12.5.0.so`: C++ shared object extracted from `libsaxon-HEC-linux-<arch>-v12.5.0.zip`
  - `libsaxon-4-kong.so`: C shared object compiled from `kong-adapter.cpp`
- Prerequisite
```sh
cd saxon
```
- Extract and Build the `saxon` libraries. The libaries are built in `./saxon/so/<arch>` depending of the architecture:
  - `arm64`
  ```sh
  make local_lib_arm64
  ```
  - `amd64`
  ```sh
  make local_lib_amd64
  ```
- Build and Push on Docker Hub a `jeromeguillaume/kong-saxon-initcontainer` image. It's based on `alpine` and it includes the `saxon` libraries
```sh
make kong_saxon_initcontainer_docker_hub
```
- Build and Push on Docker Hub a `jeromeguillaume/kong-saxon` image. It's based on `kong/kong-gateway` and it includes the `saxon` libraries
```sh
make kong_saxon_docker_hub
```
- Build all
```sh
cd saxon
make
```

## Run Kong with Saxon
1) Run `Kong` with `Saxon` in Docker with the standard image: `kong/kong-gateway`
- Include in your `docker run` command:
  ```sh
  docker run -d --name kong-gateway-soap-xml-handling \
  ...
  --mount type=bind,source="$(pwd)"/kong/saxon/so/$ARCHITECTURE,destination=/usr/local/lib/kongsaxon \
  -e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
  kong/kong-gateway:3.7.1.1
  ```
- Full example here: [start-kong.sh](start-kong.sh)

2) Run `Kong` with `Saxon` in Docker or Kubernetes with the customized image: `jeromeguillaume/kong-saxon`
- Docker
```sh
docker run -d --name kong-gateway-soap-xml-handling \
...
jeromeguillaume/kong-saxon:3.7.1.1
```
- Kubernetes: see [How to deploy SOAP/XML Handling plugins in Kong Gateway (Data Plane) | Kubernetes](https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling/tree/xslt-saxonc?tab=readme-ov-file#how-to-deploy-soapxml-handling-plugins-in-kong-gateway-data-plane--kubernetes). Set in `values.yaml` the `image.repository` to `jeromeguillaume/kong-saxon:3.7.1.1`

3) Run `Kong` with `Saxon` in Kubernetes with an `initContainer` image: `jeromeguillaume/kong-saxon-initcontainer`
- See [How to deploy SOAP/XML Handling plugins in Kong Gateway (Data Plane) | Kubernetes](https://github.com/jeromeguillaume/kong-plugin-soap-xml-handling/tree/xslt-saxonc?tab=readme-ov-file#how-to-deploy-soapxml-handling-plugins-in-kong-gateway-data-plane--kubernetes)
- Prepare a `values.yaml`. Pay attention to `customEnv.LD_LIBRARY_PATH` and `deployment.initContainers`
```yaml
image:
  repository: kong/kong-gateway
  ...
env:
  plugins: bundled,soap-xml-request-handling,soap-xml-response-handling
...
plugins:
  configMaps:
  - pluginName: soap-xml-request-handling
    name: soap-xml-request-handling
  - pluginName: soap-xml-response-handling
    name: soap-xml-response-handling
  - pluginName: soap-xml-handling-lib
    name: soap-xml-handling-lib
    subdirectories:
    - name: libxml2ex
      path: libxml2ex
    - name: libxslt
      path: libxslt
...
# *** Specific properties for Saxon ***
customEnv:
  LD_LIBRARY_PATH: /usr/local/lib/kongsaxon

deployment:
  initContainers:
  - name: kongsaxon
    image: jeromeguillaume/kong-saxon-initcontainer:1.0.0
    command: ["/bin/sh", "-c", "cp /kongsaxon/* /usr/local/lib/kongsaxon"]
    volumeMounts:
    - name: kongsaxon-vol
      mountPath: /usr/local/lib/kongsaxon
  userDefinedVolumes:
  - name: kongsaxon-vol
    emptyDir: {}
  userDefinedVolumeMounts:
  - name: kongsaxon-vol
    mountPath: /usr/local/lib/kongsaxon
```
- Execute the Helm command
```sh
helm install my-kong kong/kong -n kong --values ./values.yaml
```
- See a complete `values.yaml` example for Konnect: [values-4-Konnect.yaml](kong/saxon/kubernetes/values-4-Konnect.yaml)
- For Kubernetes: **the `initContainer` is the preferred method** instead of using the customized image (`jeromeguillaume/kong-saxon`). Indeed the `initContainer` has no dependency to `kong/kong-gateway` and it doesn't require rebuilding for each new release of `kong/kong-gateway`.
