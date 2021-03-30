FROM debian:buster as nginx-builder

ENV NGINX_VERSION=1.18.0 \
    NGINX_MODULE_VTS_VERSION=0.1.18 \
    HEADERS_MORE_NGINX_MODULE_VERSION=0.33 \
    JA3_NGINX_MODULE_VERSION=03.2021.1 \
    LUA_JSON_VERSION=1.2.3 \
    LUA_NGINX_MODULE_VERSION=0.10.19 \
    NGX_DEVEL_KIT_VERSION=0.3.1 \
    STREAM_LUA_NGINX_MODULE_VERSION=0.0.9 \
    LUAJIT_VERSION=2.1-20201229 \
    LUA_RESTY_SOCKPROC_VERSION=92aba736027bb5d96e190b71555857ac5bb6b2be \
    LUA_RESTY_SHELL_VERSION=955243d70506c21e7cc29f61d745d1a8a718994f

RUN apt-get -y update && apt-get install -y gnupg wget unzip ca-certificates curl openssl git
RUN echo "deb http://nginx.org/packages/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list && \
    echo "deb-src http://nginx.org/packages/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list  && \
    apt-key adv --fetch-keys "http://nginx.org/keys/nginx_signing.key"

RUN apt-get -y update && apt-get -y build-dep nginx

RUN apt-get install -y build-essential


RUN wget -O nginx-${NGINX_VERSION}.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz && \
    mv nginx-${NGINX_VERSION} nginx && \
    rm nginx-${NGINX_VERSION}.tar.gz

RUN mkdir -p /nginx-modules

RUN cd /nginx-modules && \
    wget -O nginx-module-ja3-${JA3_NGINX_MODULE_VERSION}.zip https://github.com/hasnat/nginx-ssl-ja3/archive/refs/tags/${JA3_NGINX_MODULE_VERSION}.zip && \
    unzip nginx-module-ja3-${JA3_NGINX_MODULE_VERSION}.zip  && \
    mv nginx-ssl-ja3-${JA3_NGINX_MODULE_VERSION} nginx-module-ja3 && \
    rm nginx-module-ja3-${JA3_NGINX_MODULE_VERSION}.zip && \
    cd nginx-module-ja3 && \
#    ls -lah /nginx-modules/nginx-module-ja3/patches/ && exit 1 && \
    git clone --depth 1 https://github.com/nginx/nginx-tests -b master && \
    git clone --depth 1 https://github.com/openssl/openssl -b OpenSSL_1_1_1e && \
    cd openssl && \
    patch -p1 < /nginx-modules/nginx-module-ja3/patches/openssl_1.1.1e.extensions.patch && \
    cd /nginx && patch -p1 < /nginx-modules/nginx-module-ja3/patches/nginx.latest.patch && \
    cd /nginx-modules/nginx-module-ja3/openssl && ./config -d && make && make install


RUN cd /nginx-modules && \
    wget -O luajit-${LUAJIT_VERSION}.zip https://github.com/openresty/luajit2/archive/refs/tags/v${LUAJIT_VERSION}.zip && \
    unzip luajit-${LUAJIT_VERSION}.zip  && \
    mv luajit2-${LUAJIT_VERSION} luajit && \
    cd luajit && make && make install && cd .. \
    rm luajit-${LUAJIT_VERSION}.zip


RUN mkdir -p /lua-modules /lua/lib
#RUN tail -f /dev/null


# for logger's jsonlines
RUN cd /lua-modules && \
    wget -O lua-json-${LUA_JSON_VERSION}.zip https://github.com/grafi-tt/lunajson/archive/refs/tags/${LUA_JSON_VERSION}.zip && \
    unzip lua-json-${LUA_JSON_VERSION}.zip  && \
    mv lunajson-${LUA_JSON_VERSION}/src /lua/lib/luajson && \
    rm lua-json-${LUA_JSON_VERSION}.zip

# for lua nginx module used by logger
RUN cd /nginx-modules && \
    wget -O ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.zip https://github.com/simplresty/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.zip && \
    unzip ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.zip && \
    mv ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} ngx_devel_kit && \
    rm ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.zip
#RUN tail -f /dev/null
# for lua nginx module used by logger
RUN cd /nginx-modules && \
    wget -O lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.zip https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE_VERSION}.zip &&\
    unzip lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.zip && \
    mv lua-nginx-module-${LUA_NGINX_MODULE_VERSION} lua-nginx-module && \
    rm lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.zip
RUN cd /nginx-modules && \
    wget -O stream-lua-nginx-module-${STREAM_LUA_NGINX_MODULE_VERSION}.zip https://github.com/openresty/stream-lua-nginx-module/archive/refs/tags/v${STREAM_LUA_NGINX_MODULE_VERSION}.zip &&\
    unzip stream-lua-nginx-module-${STREAM_LUA_NGINX_MODULE_VERSION}.zip && \
    mv stream-lua-nginx-module-${STREAM_LUA_NGINX_MODULE_VERSION} stream-lua-nginx-module && \
    rm stream-lua-nginx-module-${STREAM_LUA_NGINX_MODULE_VERSION}.zip

# for logger to use shell for making pretty dated directories in a non-blocking thread
RUN cd /lua-modules && \
    wget -O sockproc-${LUA_RESTY_SOCKPROC_VERSION}.zip https://github.com/juce/sockproc/archive/${LUA_RESTY_SOCKPROC_VERSION}.zip && \
    unzip sockproc-${LUA_RESTY_SOCKPROC_VERSION}.zip && \
#    git clone --depth 1 https://github.com/juce/sockproc -b local ${LUA_RESTY_SOCKPROC_VERSION} && \
    cd sockproc-${LUA_RESTY_SOCKPROC_VERSION}/ && \
    make && \
    mv sockproc /usr/local/bin/ && \
    rm ../sockproc-${LUA_RESTY_SOCKPROC_VERSION}.zip
RUN cd /lua-modules && \
    wget -O lua-resty-shell-${LUA_RESTY_SHELL_VERSION}.zip https://github.com/juce/lua-resty-shell/archive/${LUA_RESTY_SHELL_VERSION}.zip && \
    unzip lua-resty-shell-${LUA_RESTY_SHELL_VERSION}.zip && \
#    git clone --depth 1 https://github.com/juce/lua-resty-shell -b local ${LUA_RESTY_SHELL_VERSION} && \
    mkdir -p /lua/lib/resty && cp -r lua-resty-shell-${LUA_RESTY_SHELL_VERSION}/lib/resty/* /lua/lib/resty/ && \
    rm lua-resty-shell-${LUA_RESTY_SHELL_VERSION}.zip
ENV LUA_RESTY_CORE_VERSION=0.1.21
RUN cd /lua-modules && \
    wget -O lua-resty-core-${LUA_RESTY_CORE_VERSION}.zip https://github.com/openresty/lua-resty-core/archive/refs/tags/v${LUA_RESTY_CORE_VERSION}.zip && \
    unzip lua-resty-core-${LUA_RESTY_CORE_VERSION}.zip && \
    mkdir -p /lua/lib/resty && cp -r lua-resty-core-${LUA_RESTY_CORE_VERSION}/lib/resty/* /lua/lib/resty/ && \
    rm lua-resty-core-${LUA_RESTY_CORE_VERSION}.zip


ENV LUA_RESTY_LRUCACHE_VERSION=0.10

RUN cd /lua-modules && \
    wget -O lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION}.zip https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v${LUA_RESTY_LRUCACHE_VERSION}.zip && \
    unzip lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION}.zip && \
#    git clone --depth 1 https://github.com/juce/lua-resty-shell -b local ${LUA_RESTY_SHELL_VERSION} && \
    mkdir -p /lua/lib/resty && cp -r lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION}/lib/resty/* /lua/lib/resty/ && \
    rm lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION}.zip

RUN cd /nginx-modules && \
    wget -O nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_MODULE_VTS_VERSION}.zip && \
    unzip nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip  && \
    mv nginx-module-vts-${NGINX_MODULE_VTS_VERSION} nginx-module-vts && \
    rm nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip

RUN cd /nginx-modules && \
    wget -O headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_NGINX_MODULE_VERSION}.zip && \
    unzip headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip  && \
    mv headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION} headers-more-nginx-module && \
    rm headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip
#RUN tail -f /dev/null
ENV LUAJIT_LIB=/usr/local/lib \
    LUAJIT_INC=/usr/local/include/luajit-2.1

RUN cd nginx && \
    ./configure --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/dev/stdout \
    --http-log-path=/dev/stdout \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/tmp/client_body_temp \
    --http-proxy-temp-path=/tmp/proxy_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_auth_request_module \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-file-aio \
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -O -fno-omit-frame-pointer' \
    --with-ld-opt='-Wl,-z,relro -Wl,--as-needed -L/usr/local/lib -Wl,-E ' \
    --with-ipv6 \
    --add-dynamic-module=/nginx-modules/nginx-module-ja3  \
    --add-dynamic-module=/nginx-modules/headers-more-nginx-module \
    --add-dynamic-module=/nginx-modules/nginx-module-vts \
    --add-dynamic-module=/nginx-modules/ngx_devel_kit \
    --add-dynamic-module=/nginx-modules/stream-lua-nginx-module \
    --add-dynamic-module=/nginx-modules/lua-nginx-module && \
    make && make install

RUN    rm -rf /nginx*

#RUN tail -f /dev/null
# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod +x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.7.4

ADD https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz
RUN tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

#RUN tail -f /dev/null
#RUN nginx -V
#RUN exit 1
FROM debian:buster


RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH=/usr/local/lib
COPY --from=nginx-builder /etc/nginx/ /etc/nginx/
COPY --from=nginx-builder /lua /lua
COPY --from=nginx-builder /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib/

COPY --from=nginx-builder /usr/sbin/nginx \
    /usr/local/bin/openssl \
    /usr/local/bin/c_rehash \
    /usr/local/bin/forego \
    /usr/local/bin/sockproc \
    /usr/local/bin/docker-gen \
    /usr/local/bin/luajit \
    /usr/sbin/
RUN ln -s luajit /usr/local/bin/lua
#USER root
#RUN cat /etc/passwd
RUN groupadd nginx && useradd -g nginx nginx && usermod -s /bin/false nginx && \
    mkdir -p /etc/nginx/conf.d /var/cache/nginx /var/lib/nginx /etc/nginx/dhparam /var/log/nginx /tmp/client_body_temp /tmp/proxy_temp && \
    chown -R nginx:nginx /var/cache/nginx /etc/nginx/dhparam /var/lib/nginx /var/log/nginx && \
    chown nginx:nginx /etc/nginx /etc/nginx/nginx.conf && \
    chmod 774 /var/cache/nginx /var/lib/nginx /var/log/nginx /tmp/client_body_temp /tmp/proxy_temp


#USER nginx
# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf


COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/
COPY nginx.conf /etc/nginx/nginx.conf
COPY /lua/logger /lua/


ENV DOCKER_HOST unix:///tmp/docker.sock
ENV RESOLVERS="127.0.0.11 valid=5s"

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
