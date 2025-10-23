# app.py
from flask import Flask, jsonify
import os
import time
from prometheus_client import start_http_server, Summary, Gauge

app = Flask(__name__)

# Prometheus Metrics
REQUEST_TIME = Summary('request_processing_seconds', 'Time spent processing request')
HEALTH_STATUS = Gauge('app_health_status', 'Health status of the application (1 for healthy, 0 for unhealthy)')

# A simple "broken" feature for our debugging scenario
# Initially, this will be set to False to simulate a problem.
# We will "fix" it later by changing it to True.
IS_HEALTHY = True 

@app.route('/')
def home():
    return "Hello from the DevOps Project App!"

@app.route('/healthz')
@REQUEST_TIME.time()
def healthz():
    if IS_HEALTHY:
        HEALTH_STATUS.set(1)
        return jsonify(status="healthy"), 200
    else:
        HEALTH_STATUS.set(0)
        # This is the bug! The app reports unhealthy.
        return jsonify(status="unhealthy", reason="Simulated internal failure"), 503

# Expose metrics on port 8081
if __name__ == '__main__':
    start_http_server(8081)
    app.run(host='0.0.0.0', port=8080)
