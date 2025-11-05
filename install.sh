#!/bin/bash
# Install Docker & Compose if missing
if ! command -v docker &> /dev/null; then
  echo "Docker not found, installing..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
  echo "Docker Compose not found, installing..."
  DOCKER_COMPOSE_VERSION=2.20.2
  curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Generate random passwords
INFLUX_PASS=$(openssl rand -base64 16)
INFLUX_TOKEN=$(openssl rand -hex 16)
GRAFANA_PASS=$(openssl rand -base64 12)
MIKROTIK_PASS=$(openssl rand -base64 12)
export INFLUX_PASS INFLUX_TOKEN GRAFANA_PASS MIKROTIK_PASS

# Create data folders
mkdir -p data/influxdb data/grafana

# Run Docker Compose
echo "Starting containers..."
docker-compose up -d
sleep 10
echo "Car Monitoring Stack is now running! Access Grafana on port 3000."
