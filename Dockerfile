FROM alpine:3.15.4

ARG NGINX_VERSION=1.21.6
ARG HEADERS_MORE_VERSION=0.34
ARG LUA_NGINX_VERSION=0.10.23
ARG LUA_PROMETHEUS_VERSION=0.20221218
ARG LUAJIT_VERSION=2.1-20230119
ARG NGX_DEVEL_VERSION=0.3.2
ARG RESTY_CORE_VERSION=0.1.25
ARG RESTY_LRUCACHE_VERSION=0.13

WORKDIR /tmp/build/nginx

# install dependencies and dev-dependencies
RUN apk add --no-cache gzip \
                       pcre \
                       zlib \
                       openssl \
                       curl \
                       libaio \
                       libgcc && \
    apk add --no-cache \
            --virtual .build \
                      linux-headers \
                      gnupg \
                      wget \
                      g++ \
                      pcre-dev \
                      zlib-dev \
                      make \
                      openssl-dev \
                      libaio-dev && \
#  create nginx user and group
    addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -s /sbin/nologin -G nginx -g nginx nginx && \
# get nginx, luajit and required modules and libs
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    wget https://github.com/openresty/luajit2/archive/v${LUAJIT_VERSION}.tar.gz \
        -O luajit2-${LUAJIT_VERSION}.tar.gz && \
    wget https://github.com/knyar/nginx-lua-prometheus/archive/${LUA_PROMETHEUS_VERSION}.tar.gz \
        -O nginx-lua-prometheus-${LUA_PROMETHEUS_VERSION}.tar.gz && \
    wget https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_VERSION}.tar.gz \
        -O lua-nginx-module-${LUA_NGINX_VERSION}.tar.gz && \
    wget https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v${HEADERS_MORE_VERSION}.tar.gz \
        -O headers-more-nginx-module-${HEADERS_MORE_VERSION}.tar.gz && \
    wget https://github.com/vision5/ngx_devel_kit/archive/v${NGX_DEVEL_VERSION}.tar.gz \
        -O ngx_devel_kit-${NGX_DEVEL_VERSION}.tar.gz && \
    wget https://github.com/openresty/lua-resty-core/archive/v${RESTY_CORE_VERSION}.tar.gz \
        -O lua-resty-core-${RESTY_CORE_VERSION}.tar.gz && \
    wget https://github.com/openresty/lua-resty-lrucache/archive/v${RESTY_LRUCACHE_VERSION}.tar.gz \
        -O lua-resty-lrucache-${RESTY_LRUCACHE_VERSION}.tar.gz && \
# unpack 'em all
    tar -xvf nginx-${NGINX_VERSION}.tar.gz && \
    tar -xvf luajit2-${LUAJIT_VERSION}.tar.gz && \
    tar -xvf nginx-lua-prometheus-${LUA_PROMETHEUS_VERSION}.tar.gz && \
    tar -xvf lua-nginx-module-${LUA_NGINX_VERSION}.tar.gz && \
    tar -xvf headers-more-nginx-module-${HEADERS_MORE_VERSION}.tar.gz && \
    tar -xvf ngx_devel_kit-${NGX_DEVEL_VERSION}.tar.gz && \
    tar -xvf lua-resty-core-${RESTY_CORE_VERSION}.tar.gz && \
    tar -xvf lua-resty-lrucache-${RESTY_LRUCACHE_VERSION}.tar.gz && \
# install luajit
    cd luajit2-${LUAJIT_VERSION} && make install && cd .. && \
# install nginx with modules
    cd nginx-${NGINX_VERSION} && \
    LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.1 \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/dev/stdout \
        --http-log-path=/dev/stdout \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-cc-opt='-Os -fomit-frame-pointer -g' \
        --with-ld-opt=-Wl,--as-needed,-O1,--sort-common \
        --add-module=$(cd .. && pwd)/ngx_devel_kit-${NGX_DEVEL_VERSION} \
        --add-module=$(cd .. && pwd)/lua-nginx-module-${LUA_NGINX_VERSION} \
        --add-module=$(cd .. && pwd)/headers-more-nginx-module-${HEADERS_MORE_VERSION} && \
    make && make install && cd .. && \
# install lua resty core lib
    cd lua-resty-core-${RESTY_CORE_VERSION} && \
    make install PREFIX=/etc/nginx && cd .. && \
# install lua resty lrucache lib
    cd lua-resty-lrucache-${RESTY_LRUCACHE_VERSION} && \
    make install PREFIX=/etc/nginx && cd .. && \
# add lua prometheus files to nginx lua libs directory
    rm nginx-lua-prometheus-${LUA_PROMETHEUS_VERSION}/prometheus_test.lua && \
    cp nginx-lua-prometheus-${LUA_PROMETHEUS_VERSION}/prometheus*.lua /etc/nginx/lib/lua/ && \
# clean build files
    apk del --no-cache .build && \
    rm -rf /tmp/build/nginx && \
# set correct permissions
    mkdir -p /usr/share/nginx /var/log/nginx /var/cache/nginx /usr/lib/nginx/modules && \
    ln -s /usr/lib/nginx/modules /etc/nginx/modules && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /usr/share/nginx /etc/nginx /var/run/nginx.pid /var/cache/nginx /var/log/nginx /usr/lib/nginx && \
    chmod -R 744 /usr/share/nginx /var/log/nginx /var/cache/nginx /var/run/nginx.pid

ENV LUA_PATH=/etc/nginx/lib/lua/?.lua;;

USER nginx

EXPOSE 8080
EXPOSE 9145

WORKDIR /etc/nginx

STOPSIGNAL SIGQUIT

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/prometheus.conf conf.d/default.conf /etc/nginx/conf.d/

CMD ["nginx", "-g", "daemon off;"]
