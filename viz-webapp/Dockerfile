FROM python:3.11-slim

WORKDIR /app

# Install dependencies with compatible versions
RUN pip install --no-cache-dir \
    flask==3.0.0 \
    flask-socketio==5.3.5 \
    python-socketio==5.10.0 \
    docker==6.1.3 \
    requests==2.31.0 \
    urllib3==1.26.18

# Copy application files
COPY app.py /app/
COPY static/ /app/static/
COPY templates/ /app/templates/

# Expose port
EXPOSE 8080

# Run the application
CMD ["python", "app.py"]

