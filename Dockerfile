FROM debian:sid

# Build arguments
ARG DEBIAN_REPO_HOST=httpredir.debian.org
ENV DEBIAN_FRONTEND=noninteractive
# Mirror to my location
RUN echo "deb http://${DEBIAN_REPO_HOST}/debian sid main" > /etc/apt/sources.list
RUN echo "deb-src http://${DEBIAN_REPO_HOST}/debian sid main" >> /etc/apt/sources.list

# Update
RUN  apt-get update || true

# Install build dependencies
RUN apt-get install -y --fix-missing \
    apt-utils \
    autoconf \
    automake \
    bind9-host \
    build-essential \
    dh-autoreconf \
    cpanminus \
    curl \
    devscripts \
    exuberant-ctags \
    git-core \
    jq \
    llvm \
    libgeoip1 \
    libgeoip-dev \
    libpcre3 \
    libpcre3-dbg \
    libpcre3-dev \
    libperl-dev \
    libmagic-dev \
    libtool \
    lsof \
    make \
    mercurial \
    ngrep \
    procps \
    python2 \
    telnet \
    tcpflow \
    valgrind \
    vim \
    wget \
    zlib1g \
    zlib1g-dev

WORKDIR /build
RUN git clone https://github.com/nginx/nginx-tests
RUN git clone https://github.com/openssl/openssl

# Build and install openssl
WORKDIR /build/openssl

RUN git checkout OpenSSL_1_1_1 -b patched
COPY patches/openssl.extensions.patch /build/openssl
RUN patch -p1 < openssl.extensions.patch
RUN ./config -d
RUN make
RUN make install

# Clone from nginx
WORKDIR /build
RUN hg clone http://hg.nginx.org/nginx -u release-1.17.1

# Patch nginx for fetching ssl client extensions
WORKDIR /build/nginx
COPY patches/nginx.1.17.1.ssl.extensions.patch patches/nginx.1.17.1-no_pool.patch /build/nginx/
RUN patch -p1 < nginx.1.17.1.ssl.extensions.patch
RUN patch -p1 < nginx.1.17.1-no_pool.patch

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.7.4

RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib \
    PATH=$PATH:/usr/local/bin:/usr/local/nginx/sbin \
    ASAN_SYMBOLIZER_PATH=/usr/bin/llvm-symbolizer \
    ASAN_OPTIONS="symbolize=1:detect_leaks=0"
# fast_unwind_on_malloc=0:halt_on_error=0
WORKDIR /build

ENV SSL_JA3_NGINX_MODULE_VERSION=0.0.2

RUN wget -O nginx-ssl-ja3-${SSL_JA3_NGINX_MODULE_VERSION}.zip https://github.com/fooinha/nginx-ssl-ja3/archive/v${SSL_JA3_NGINX_MODULE_VERSION}.zip && \
    unzip nginx-ssl-ja3-${SSL_JA3_NGINX_MODULE_VERSION}.zip  && \
    mv nginx-ssl-ja3-${SSL_JA3_NGINX_MODULE_VERSION} nginx-ssl-ja3 && \
    rm nginx-ssl-ja3-${SSL_JA3_NGINX_MODULE_VERSION}.zip

RUN cd nginx && \
    ./auto/configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/bin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/dev/stdout \
        --http-log-path=/dev/stdout \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
#        --add-module=/build/lua-nginx-module \
#        --add-module=/build/ngx_devel_kit \
#        --add-module=/build/set-misc-nginx-module \
#        --add-module=/build/headers-more-nginx-module \
#        --add-module=/build/nginx-module-vts \
        --add-module=/build/nginx-ssl-ja3 \
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
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
        --with-cc-opt="-fsanitize=address -fsanitize-recover=address -O -fno-omit-frame-pointer" \
        --with-ld-opt="-L/usr/local/lib -Wl,-E -lasan" \
#        --with-cc-opt="-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wno-cast-function-type -Wp,-D_FORTIFY_SOURCE=2 -fsanitize=address -O -fno-omit-frame-pointer" \
#        --with-ld-opt="-L/usr/local/lib -Wl,-E -lasan -Wl,-z,relro -Wl,--as-needed" && \
        && \
        make && make install


COPY network_internal.conf /etc/nginx/
RUN mkdir -p /var/cache/nginx/main_cache
COPY . /app/
WORKDIR /app/
RUN touch /app/htpasswd_generator.sh && chmod +x /app/htpasswd_generator.sh

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV RESOLVERS="127.0.0.11 valid=5s"

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
