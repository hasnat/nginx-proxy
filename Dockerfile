FROM debian:buster as nginx-builder

ENV NGINX_VERSION=1.18.0 \
    NGINX_MODULE_VTS_VERSION=0.1.18 \
    HEADERS_MORE_NGINX_MODULE_VERSION=0.33 \
    JA3_NGINX_MODULE_VERSION=03.2021.1 \
    NGX_DEVEL_KIT_VERSION=0.3.1 \
    NJS_NGINX_MODULE_VERSION=0.5.2

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
    wget -O nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_MODULE_VTS_VERSION}.zip && \
    unzip nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip  && \
    mv nginx-module-vts-${NGINX_MODULE_VTS_VERSION} nginx-module-vts && \
    rm nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip

RUN cd /nginx-modules && \
    wget -O nginx-module-njs-${NJS_NGINX_MODULE_VERSION}.zip https://github.com/nginx/njs/archive/refs/tags/${NJS_NGINX_MODULE_VERSION}.zip && \
    unzip nginx-module-njs-${NJS_NGINX_MODULE_VERSION}.zip  && \
    mv njs-${NJS_NGINX_MODULE_VERSION} nginx-module-njs && \
    rm nginx-module-njs-${NJS_NGINX_MODULE_VERSION}.zip

RUN cd /nginx-modules && \
    wget -O headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_NGINX_MODULE_VERSION}.zip && \
    unzip headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip  && \
    mv headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION} headers-more-nginx-module && \
    rm headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip



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
    --add-dynamic-module=/nginx-modules/nginx-module-njs/nginx && \
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

COPY --from=nginx-builder /usr/sbin/nginx \
    /usr/local/bin/openssl \
    /usr/local/bin/c_rehash \
    /usr/local/bin/forego \
    /usr/local/bin/docker-gen \
    /usr/sbin/

#USER root
#RUN cat /etc/passwd
RUN groupadd nginx && useradd -g nginx nginx && usermod -s /bin/false nginx && \
    mkdir -p /etc/nginx/conf.d /var/cache/nginx /var/lib/nginx /etc/nginx/dhparam /var/log/nginx /tmp/client_body_temp /tmp/proxy_temp && \
    chown -R nginx:nginx /var/cache/nginx /etc/nginx/dhparam /var/lib/nginx /var/log/nginx && \
    chown nginx:nginx /etc/nginx /etc/nginx/nginx.conf && \
    chmod 774 /var/cache/nginx /var/lib/nginx /var/log/nginx /tmp/client_body_temp /tmp/proxy_temp


#USER nginx
# Configure Nginx and apply fix for very long server names
#RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
# && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf


COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/
COPY nginx.placeholder.conf /etc/nginx/nginx.conf
COPY /njs/ /njs/


ENV DOCKER_HOST unix:///tmp/docker.sock
ENV RESOLVERS="127.0.0.11 ipv6=off valid=30s"

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
