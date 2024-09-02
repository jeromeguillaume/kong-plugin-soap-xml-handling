# Saxon and Kong

## Prerequisite: download the SaxonC-HE v12 - Zip package
- Linux AArch64
https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-aarch64-v12.5.0.zip
- Linux Intel x86_64
https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-x86_64-v12.5.0.zip
- General download page
https://www.saxonica.com/html/download/c.html

## Build the C library (`libsaxon-4-kong.so`) and the Docker image
- Build all

It pushes on Docker Hub a `jeromeguillaume/kong-saxon` image. It's based on `kong/kong-gateway` and includes the `saxon` libraries.
```sh
cd saxon
make
```
- Build the libraries for local Docker test. The libaries are built in `./saxon/so/<arch>` depending of the architecture:
  - `arm64`
  ```sh
  make local_lib_arm64
  ```
  - `amd64`
  ```sh
  make local_lib_arm64
  ```

## Run Kong with Saxon
1) Run Saxon locally with Docker and the official image: `kong/kong-gateway`
    - Include in your `docker run` command:
      ```sh
      docker run -d --name kong-gateway-soap-xml-handling \
      ...
      --mount type=bind,source="$(pwd)"/kong/saxon/so/$ARCHITECTURE,destination=/usr/local/lib/kongsaxon \
      -e "LD_LIBRARY_PATH=/usr/local/lib/kongsaxon" \
      kong/kong-gateway:3.7.1.1
      ```
    - Full example here: [./start-kong.sh](start-kong.sh)

2) Run Saxon with the customized Docker image: `jeromeguillaume/kong-saxon`
  ```sh
  docker run -d --name kong-gateway-soap-xml-handling \
  ...
  jeromeguillaume/kong-saxon:3.7.1.1
  ```