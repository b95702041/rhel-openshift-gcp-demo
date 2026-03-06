"""
Demo REST API for OpenShift deployment.
A simple Flask app with health check, readiness probe, and metrics endpoint.
"""

import os
import time
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)

START_TIME = time.time()


@app.route("/")
def index():
    return jsonify({
        "app": "rhel-openshift-demo-api",
        "version": "1.0.0",
        "message": "Welcome to the RHEL & OpenShift Demo API",
        "endpoints": {
            "health": "/health",
            "ready": "/ready",
            "metrics": "/metrics",
            "info": "/info",
        },
    })


@app.route("/health")
def health():
    """Liveness probe - is the app process alive?"""
    return jsonify({"status": "healthy"}), 200


@app.route("/ready")
def ready():
    """Readiness probe - is the app ready to serve traffic?"""
    return jsonify({"status": "ready"}), 200


@app.route("/metrics")
def metrics():
    """Basic Prometheus-style metrics endpoint."""
    uptime = time.time() - START_TIME
    return (
        f"# HELP app_uptime_seconds Time since app started\n"
        f"# TYPE app_uptime_seconds gauge\n"
        f"app_uptime_seconds {uptime:.2f}\n"
        f"# HELP app_info Application info\n"
        f"# TYPE app_info gauge\n"
        f'app_info{{version="1.0.0"}} 1\n'
    ), 200, {"Content-Type": "text/plain; charset=utf-8"}


@app.route("/info")
def info():
    """Show runtime environment info - useful for demo."""
    return jsonify({
        "hostname": socket.gethostname(),
        "platform": os.uname().sysname,
        "python_version": os.popen("python3 --version").read().strip(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "uptime_seconds": round(time.time() - START_TIME, 2),
        "environment": {
            "POD_NAME": os.environ.get("POD_NAME", "N/A"),
            "POD_NAMESPACE": os.environ.get("POD_NAMESPACE", "N/A"),
            "NODE_NAME": os.environ.get("NODE_NAME", "N/A"),
        },
    })


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
