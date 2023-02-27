FROM openresty/openresty:1.21.4.1-0-alpine

RUN apk add --no-cache curl make wget tar unzip build-base readline-dev && \
    wget https://luarocks.org/releases/luarocks-3.8.0.tar.gz && \
    tar -zxpf luarocks-3.8.0.tar.gz && \
    cd luarocks-3.8.0 && \
    ./configure --with-lua=/usr/local/openresty/luajit && \
    make && \
    make install && \
    cd .. && \
    rm -rf luarocks-3.8.0* && \
    luarocks install nginx-lua-prometheus 0.20221218-1 && \
    apk del openssl unzip make build-base readline-dev

COPY conf.d/prometheus.conf conf.d/default.conf /etc/nginx/conf.d/
