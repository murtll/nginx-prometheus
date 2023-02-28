FROM openresty/openresty:1.21.4.1-0-alpine

# maybe i can get it working with just apk install perl curl && opm install ...

# RUN apk add --no-cache curl make wget tar unzip build-base readline-dev outils-md5 && \
#     wget https://luarocks.org/releases/luarocks-3.9.0.tar.gz && \
#     tar -zxpf luarocks-3.9.0.tar.gz && \
#     cd luarocks-3.9.0 && \
#     ./configure --with-lua=/usr/local/openresty/luajit && \
#     make && \
#     make install && \
#     cd .. && \
#     rm -rf luarocks-3.9.0* && \
#     luarocks install nginx-lua-prometheus 0.20221218-1 && \
#     apk del outils-md5 unzip make build-base readline-dev

RUN apk add --no-cache perl curl && opm get knyar/nginx-lua-prometheus=0.20221218 && apk del perl curl

COPY conf.d/prometheus.conf conf.d/default.conf /etc/nginx/conf.d/
