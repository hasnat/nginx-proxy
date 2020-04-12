FROM php:7.3-apache

RUN apt-get update && apt-get install -y wget unzip libcurl4-gnutls-dev
WORKDIR /usr/local/lib/

#RUN wget -O molten.zip https://github.com/chuan-yun/Molten/archive/9bf454c969c94feb33e6cd2461e3b2ee1726aa6e.zip && \
RUN wget -O molten.zip https://github.com/joy2fun/Molten/archive/b7af9bbaaa3096b051a1636d815995f7c61ca41f.zip && \
    unzip molten.zip
RUN cd Molten-* && \
    phpize && \
    ./configure --enable-zipkin-header=yes && \
    make && \
    make install
COPY molten.ini /usr/local/etc/php/conf.d

#    cp modules/molten.so /usr/local/lib/php/extensions/no-debug-non-zts-20170718/molten.so



#RUN wget -O dd-php-tracer.deb https://github.com/DataDog/dd-trace-php/releases/download/0.36.0/datadog-php-tracer_0.36.0_amd64.deb && \
#    dpkg -i dd-php-tracer.deb
#
#ENV DD_SERVICE_NAME=php-app-3 \
#    DD_AGENT_HOST=jaeger \
#    DD_TRACE_AGENT_PATH=/api/v2/spans \
#    DD_TRACE_AGENT_PORT=9411/api/v1/spans? \
#    DD_TRACE_CLI_ENABLED=true \
#    DD_TRACE_DEBUG=true \
#    DD_TRACE_GLOBAL_TAGS=lang:php,env:test \
#    DD_TRACE_NO_AUTOLOADER=true

#RUN wget -O signalfx-tracing.deb https://github.com/signalfx/signalfx-php-tracing/releases/download/0.30.2-beta-sfx1/signalfx-tracing_0.30.2-beta-sfx1_amd64.deb && \
#    dpkg -i signalfx-tracing.deb
#
#ENV SIGNALFX_SERVICE_NAME=php-app-2 \
#    SIGNALFX_ENDPOINT_URL=http://zipkin:9411/api/v2/spans \
#    SIGNALFX_TRACING_CLI_ENABLED=true \
#    SIGNALFX_TRACE_DEBUG=true

WORKDIR /var/www/html



