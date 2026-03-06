# Use Red Hat Universal Base Image (UBI) - standard for OpenShift deployments
FROM registry.access.redhat.com/ubi9/python-311:latest

# Labels following OpenShift conventions
LABEL app.kubernetes.io/name="demo-api" \
      app.kubernetes.io/version="1.0.0" \
      maintainer="your-name"

# Set working directory
WORKDIR /opt/app-root/src

# Copy dependency file first (layer caching optimization)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Expose port
EXPOSE 8080

# Run with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--access-logfile", "-", "main:app"]
