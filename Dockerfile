FROM debian:jessie as nginx-plus-modules-base

ENV NGINX_VERSION=1.17.3 \
    NGX_DEVEL_KIT_VERSION=0.3.0 \
    DOCKER_GEN_VERSION=0.7.4 \
    FOREGO_VERSION=0.16.1 \
    SET_MISC_NGINX_MODULE_VERSION=0.32 \
    LUA_NGINX_MODULE_VERSION=0.10.13 \
    NGINX_MODULE_VTS_VERSION=0.1.18 \
    HEADERS_MORE_NGINX_MODULE_VERSION=0.33 \
    OPENTRACING_NGINX_MODULE_VERSION=0.9.0 \
    ZIPKIN_NGINX_MODULE_VERSION=0.5.2 \
    JAEGER_NGINX_MODULE_VERSION=0.4.2

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV RESOLVERS="127.0.0.11 valid=5s"
ENV ZIPKIN_CONFIG="" \
    JAEGER_CONFIG=""

RUN echo "deb http://nginx.org/packages/debian/ jessie nginx" >> /etc/apt/sources.list.d/nginx.list && \
    echo "deb-src http://nginx.org/packages/debian/ jessie nginx" >> /etc/apt/sources.list.d/nginx.list  && \
    apt-key adv --fetch-keys "http://nginx.org/keys/nginx_signing.key"

RUN apt-get -y update && apt-get -y build-dep nginx && apt-get -y install wget unzip ca-certificates curl

RUN apt-get install -y lua5.1 liblua5.1-0 liblua5.1-0-dev luarocks build-essential openssl git && \
    ln -s /usr/lib/x86_64-linux-gnu/liblua5.1.so /usr/lib/liblua.so

RUN wget -O /usr/local/bin/forego https://github.com/jwilder/forego/releases/download/v${FOREGO_VERSION}/forego && \
    chmod u+x /usr/local/bin/forego

RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

RUN wget -O nginx-${NGINX_VERSION}.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz && \
    mv nginx-${NGINX_VERSION} nginx && \
    rm nginx-${NGINX_VERSION}.tar.gz

RUN wget -O ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.zip https://github.com/simplresty/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.zip && \
    unzip ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.zip && \
    mv ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} ngx_devel_kit && \
    rm ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.zip

RUN wget -O lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.zip https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE_VERSION}.zip &&\
    unzip lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.zip && \
    mv lua-nginx-module-${LUA_NGINX_MODULE_VERSION} lua-nginx-module && \
    rm lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.zip

RUN wget -O set-misc-nginx-module-${SET_MISC_NGINX_MODULE_VERSION}.zip https://github.com/openresty/set-misc-nginx-module/archive/v${SET_MISC_NGINX_MODULE_VERSION}.zip && \
    unzip set-misc-nginx-module-${SET_MISC_NGINX_MODULE_VERSION}.zip && \
    mv set-misc-nginx-module-${SET_MISC_NGINX_MODULE_VERSION} set-misc-nginx-module && \
    rm set-misc-nginx-module-${SET_MISC_NGINX_MODULE_VERSION}.zip

RUN wget -O nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_MODULE_VTS_VERSION}.zip && \
    unzip nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip  && \
    mv nginx-module-vts-${NGINX_MODULE_VTS_VERSION} nginx-module-vts && \
    rm nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip

RUN wget -O headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_NGINX_MODULE_VERSION}.zip && \
    unzip headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip  && \
    mv headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION} headers-more-nginx-module && \
    rm headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip

# opentracing
RUN cd /usr/local/lib/ && \
    wget -O - https://github.com/opentracing-contrib/nginx-opentracing/releases/download/v${OPENTRACING_NGINX_MODULE_VERSION}/linux-amd64-nginx-${NGINX_VERSION}-ngx_http_module.so.tgz \
    | tar zxf -
# Zipkin
RUN wget -O - https://github.com/rnburn/zipkin-cpp-opentracing/releases/download/v${ZIPKIN_NGINX_MODULE_VERSION}/linux-amd64-libzipkin_opentracing_plugin.so.gz \
    | gunzip -c > /usr/local/lib/libzipkin_opentracing_plugin.so
# Jaeger
RUN wget https://github.com/jaegertracing/jaeger-client-cpp/releases/download/v${JAEGER_NGINX_MODULE_VERSION}/libjaegertracing_plugin.linux_amd64.so \
    -O /usr/local/lib/libjaegertracing_plugin.so

RUN cd nginx && \
    ./configure --prefix=/etc/nginx \
    --with-compat \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/dev/stdout \
    --http-log-path=/dev/stdout \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-file-aio \
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
    --with-ipv6 \
    --add-module=/lua-nginx-module \
    --add-module=/ngx_devel_kit \
    --add-module=/set-misc-nginx-module \
    --add-module=/headers-more-nginx-module \
    --add-module=/nginx-module-vts && \
    make && make install && \
    rm -rf /nginx*

RUN groupadd nginx && useradd -g nginx nginx && usermod -s /bin/false nginx && \
    mkdir -p /var/cache/nginx/temp /var/lib/nginx /var/log/nginx /etc/nginx/conf.d/ && \
    chown nginx:nginx /var/cache/nginx /var/cache/nginx/temp /var/lib/nginx /var/log/nginx && \
    chmod 774 /var/cache/nginx /var/lib/nginx /var/log/nginx /etc/nginx/conf.d/

EXPOSE 80
# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]


# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf && \
    sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf
# uncomment following to
# make sure when updating NGINX_VERSION
# your nginx.tmpl has appropriate http block config
# RUN cat /etc/nginx/nginx.conf
# RUN exit 1
#COPY /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf

WORKDIR /app/
RUN touch /app/htpasswd_generator.sh && chmod +x /app/htpasswd_generator.sh
COPY network_internal.conf /etc/nginx/
COPY . .

