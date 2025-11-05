#!/bin/bash
# Car Monitor v4.2 Installer
# Fully automated: Docker, Telegraf, InfluxDB, Grafana + Dashboard import

set -e

# -------------------------------
# Prompt for passwords
# -------------------------------
read -sp "Enter InfluxDB password: " INFLUX_PASS
echo
read -sp "Enter Grafana admin password: " GRAFANA_PASS
echo
read -sp "Enter MikroTik password: " MIKROTIK_PASS
echo
read -sp "Enter InfluxDB token: " INFLUX_TOKEN
echo

# -------------------------------
# Create directories
# -------------------------------
mkdir -p ~/car-monitor/data/influxdb
mkdir -p ~/car-monitor/data/grafana
mkdir -p ~/car-monitor/config
chmod -R 755 ~/car-monitor/data

# -------------------------------
# Write docker-compose.yml
# -------------------------------
cat > ~/car-monitor/docker-compose.yml <<EOF
version: '3.8'
services:
  influxdb:
    image: influxdb:2.9
    container_name: influxdb
    restart: unless-stopped
    environment:
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=${INFLUX_PASS}
      - DOCKER_INFLUXDB_INIT_TOKEN=${INFLUX_TOKEN}
      - DOCKER_INFLUXDB_INIT_ORG=car-monitor
      - DOCKER_INFLUXDB_INIT_BUCKET=telemetry
    volumes:
      - ./data/influxdb:/var/lib/influxdb2

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    depends_on:
      - influxdb
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASS}
    volumes:
      - ./data/grafana:/var/lib/grafana

  telegraf:
    image: telegraf:latest
    container_name: telegraf
    restart: unless-stopped
    depends_on:
      - influxdb
    volumes:
      - ./config/telegraf.conf:/etc/telegraf/telegraf.conf:ro
EOF

# -------------------------------
# Write telegraf.conf
# -------------------------------
cat > ~/car-monitor/config/telegraf.conf <<EOF
[global_tags]
  host = "nuc-car"

[agent]
  interval = "10s"
  round_interval = true

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "${INFLUX_TOKEN}"
  organization = "car-monitor"
  bucket = "telemetry"

[[inputs.cpu]]
  percpu = false
  totalcpu = true
  fielddrop = ["time_*"]

[[inputs.mem]]

[[inputs.disk]]
  ignore_fs = ["tmpfs","devtmpfs","overlay"]

[[inputs.exec]]
  commands = ["sensors | grep 'Core 0' | awk '{print \$3}' | tr -d '+°C' | cut -d. -f1"]
  data_format = "value"
  name_override = "nuc_cpu_temp"
  [inputs.exec.fields]
    core0 = "core0"

[[inputs.routeros]]
  addresses = ["192.168.88.1:8728"]
  username = "admin"
  password = "${MIKROTIK_PASS}"
  gather_lte = true
  gather_system_health = true
  gather_interface = true
  name_prefix = "mikrotik_"

[[inputs.ping]]
  urls = ["8.8.8.8","1.1.1.1"]
  timeout = 2.0
EOF

# -------------------------------
# Copy dashboard JSON
# -------------------------------
mkdir -p ~/car-monitor/dashboard
cat > ~/car-monitor/dashboard/car-monitor.json <<EOF
# [Insert the full dashboard JSON here from previous message]
EOF

# -------------------------------
# Start Docker stack
# -------------------------------
echo "Starting Docker containers..."
cd ~/car-monitor
docker-compose up -d

echo "Waiting 15 seconds for InfluxDB and Grafana to initialize..."
sleep 15

# -------------------------------
# Import dashboard automatically
# -------------------------------
echo "Importing Grafana dashboard..."
GRAFANA_URL="http://localhost:3000"
GRAFANA_API="admin:${GRAFANA_PASS}"
DASHBOARD_FILE="./dashboard/car-monitor.json"

curl -s -X POST -H "Content-Type: application/json" -u $GRAFANA_API \
  -d @"$DASHBOARD_FILE" \
  $GRAFANA_URL/api/dashboards/db || echo "Dashboard import failed. You can import manually."

echo "Installation complete! Grafana: http://localhost:3000"
echo "Use username 'admin' and the password you provided."
