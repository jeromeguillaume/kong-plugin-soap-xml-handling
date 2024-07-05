FROM kong/kong-gateway:3.6.1.3

USER root
RUN apt-get update && apt-get install -y build-essential zsh unzip
COPY libsaxon-HEC-linux-aarch64-v12.5.0.zip /
RUN unzip libsaxon-HEC-linux-aarch64-v12.5.0.zip
RUN rm /libsaxon-HEC-linux-aarch64-v12.5.0.zip
RUN mv /libsaxon-HEC-linux-aarch64-v12.5.0/libs/nix/libsaxon-hec-12.5.0.so /usr/local/lib/
COPY kong-adapter-makefile libsaxon-HEC-linux-aarch64-v12.5.0/Saxon.C.API/Makefile
COPY kong-adapter.cpp libsaxon-HEC-linux-aarch64-v12.5.0/Saxon.C.API/
RUN cd libsaxon-HEC-linux-aarch64-v12.5.0/Saxon.C.API && make
RUN cp libsaxon-HEC-linux-aarch64-v12.5.0/Saxon.C.API/libsaxon-4-kong.so /usr/local/lib

RUN echo /usr/local/lib > /etc/ld.so.conf.d/local.conf && ldconfig