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

It pushes on Docker Hub a `jeromeguillaume/kong-saxon` image; it's based on `kong/kong-gateway` and includes the `saxon` libraries.
```sh
cd saxon
make
```
- Build the libraries for local docker test. The libaries are built in `./saxon/so/<arch>` depending of the architecture:
  - arm64
  ```sh
  make local_lib_arm64
  ```
  - amd64
  ```sh
  make local_lib_arm64
  ```
