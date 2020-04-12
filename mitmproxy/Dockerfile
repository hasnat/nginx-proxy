FROM mitmproxy/mitmproxy
RUN pip install requests pprint opentracing

COPY opentracing.py /home/mitmproxy/
CMD mitmweb -s /home/mitmproxy/opentracing.py --web-iface 0.0.0.0

