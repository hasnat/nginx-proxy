from mitmproxy import http
import requests
import time
from pprint import pprint
import sys
from urllib.parse import urlparse
import uuid
def get_nano():
  if sys.version_info >= (3, 7):
    return time.time_ns()
  else:
    return int(time.time() * 1000000000)

def response(flow: http.HTTPFlow) -> None:
  # flow.response.headers["newheader"] = "foo"
  pprint(flow.response)
  pprint(flow.request.method)
  pprint(flow.request.headers)
  new_span_id = str(uuid.uuid4()).replace('-','')[:16]
  if "x-b3-spanid" in flow.request.headers:
    url = 'http://jaeger:9411/api/v1/spans'
    myobj = [
      {
        "annotations": [
          {
            "endpoint": {
              "port": urlparse(flow.request.url).port,
              "serviceName": urlparse(flow.request.url).hostname
            },
            "timestamp": int(flow.request.timestamp_start * 100000),
            "value": "sr"
          },
          {
            "endpoint": {
              "port": urlparse(flow.request.url).port,
              "serviceName": urlparse(flow.request.url).hostname
            },
            "timestamp": int(flow.request.timestamp_end  * 100000),
            "value": "ss"
          }
        ],
        "duration": int((flow.request.timestamp_end  * 100000) - (flow.request.timestamp_start * 100000)),
        # "id": flow.request.headers["x-b3-spanid"],
        "id": new_span_id,
        "name": flow.request.method,
        "parentId": flow.request.headers["x-b3-spanid"],
        "timestamp": get_nano(),
        "traceId": flow.request.headers["x-b3-traceid"],
        "version": "mitmproxy"
      }
    ]
    pprint(myobj)
    requests.post(url, json=myobj, headers={'Content-Type': 'application/json', 'Accept':'*/*'})


