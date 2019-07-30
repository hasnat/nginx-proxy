FROM debian:buster as nginx-builder

ENV NGINX_VERSION=1.16.0 \
    NGINX_MODULE_VTS_VERSION=0.1.18 \
    HEADERS_MORE_NGINX_MODULE_VERSION=0.33
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

RUN wget -O nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_MODULE_VTS_VERSION}.zip && \
    unzip nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip  && \
    mv nginx-module-vts-${NGINX_MODULE_VTS_VERSION} nginx-module-vts && \
    rm nginx-module-vts-${NGINX_MODULE_VTS_VERSION}.zip

RUN wget -O headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.zip https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_NGINX_MODULE_VERSION}.zip && \
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
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-file-aio \
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
    --with-ipv6 \
    --add-module=/headers-more-nginx-module \
    --add-module=/nginx-module-vts && \
    make && make install && \
    rm -rf /nginx*
#RUN nginx -V
#RUN exit 1
FROM debian:buster

RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

COPY --from=nginx-builder /etc/nginx/ /etc/nginx/
COPY --from=nginx-builder /usr/sbin/nginx /usr/sbin/nginx
RUN groupadd nginx && useradd -g nginx nginx && usermod -s /bin/false nginx && \
    mkdir -p /var/cache/nginx /var/lib/nginx /var/log/nginx && \
    chown nginx:nginx /var/cache/nginx /var/lib/nginx /var/log/nginx && \
    chmod 774 /var/cache/nginx /var/lib/nginx /var/log/nginx
# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.7.4

ADD https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz
RUN tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/
COPY nginx.conf /etc/nginx/nginx.conf
RUN touch /app/htpasswd_generator.sh && chmod +x /app/htpasswd_generator.sh

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV RESOLVERS="127.0.0.11 valid=5s"

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
