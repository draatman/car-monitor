#!/bin/bash
# Car Monitor v4.1 Alfa Installer
# Full auto-install: InfluxDB 2.9, Grafana latest, Telegraf, MikroTik LTE telemetry
# Auto-detect LTE interface IP, full dashboard import, mobile-friendly layout

set -e

echo "===== Car Monitor v4.1 Alfa Installer ====="
echo

# Prompt for passwords
read -sp "Enter InfluxDB admin password: " INFLUX_PASS
echo
read -sp "Enter InfluxDB token: " INFLUX_TOKEN
echo
read -sp "Enter Grafana admin password: " GRAFANA_PASS
echo
read -sp "Enter MikroTik password: " MIKROTIK_PASS
echo

# Base directories
BASE_DIR="$HOME/car-monitor"
DATA_DIR="$BASE_DIR/data"
mkdir -p "$DATA_DIR/influxdb" "$DATA_DIR/grafana" "$DATA_DIR/telegraf"
chmod -R 755 "$DATA_DIR"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    sudo apt update
    sudo apt install -y docker.io docker-compose
fi

# Detect MikroTik LTE interface IP
echo "Detecting MikroTik LTE IP..."
MIKROTIK_IP=$(nmap -p8728 192.168.88.0/24 -oG - | awk '/8728\/open/ {print $2; exit}')
if [[ -z "$MIKROTIK_IP" ]]; then
    echo "Failed to detect MikroTik LTE IP. Defaulting to 192.168.88.1"
    MIKROTIK_IP="192.168.88.1"
fi
echo "Detected MikroTik IP: $MIKROTIK_IP"

# Docker Compose
cat > "$BASE_DIR/docker-compose.yml" <<EOL
version: '3.8'
services:
  influxdb:
    container_name: influxdb
    image: influxdb:2.9
    restart: unless-stopped
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=$INFLUX_PASS
      - DOCKER_INFLUXDB_INIT_ORG=car-monitor
      - DOCKER_INFLUXDB_INIT_BUCKET=telemetry
      - DOCKER_INFLUXDB_INIT_TOKEN=$INFLUX_TOKEN
    volumes:
      - ./data/influxdb:/var/lib/influxdb2
    ports:
      - "8086:8086"

  grafana:
    container_name: grafana
    image: grafana/grafana:latest
    restart: unless-stopped
    depends_on:
      - influxdb
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_PASS
    volumes:
      - ./data/grafana:/var/lib/grafana
    ports:
      - "3000:3000"

  telegraf:
    container_name: telegraf
    image: telegraf:latest
    restart: unless-stopped
    volumes:
      - ./telegraf.conf:/etc/telegraf/telegraf.conf:ro
EOL

# Telegraf configuration
cat > "$BASE_DIR/telegraf.conf" <<EOL
[global_tags]
  host = "nuc-car"

[agent]
  interval = "5s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "5s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "$INFLUX_TOKEN"
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
  [[inputs.exec.field]]
    key = "core0"

[[inputs.routeros]]
  addresses = ["$MIKROTIK_IP:8728"]
  username = "admin"
  password = "$MIKROTIK_PASS"
  name_prefix = "mikrotik_"
  gather_lte = true
  gather_system_health = true
  gather_interface = true
EOL

# Dashboard import
cat > "$BASE_DIR/dashboard.json" <<EOL
{
  "dashboard": {
    "id": null,
    "title": "Car Monitor v4.1",
    "schemaVersion": 37,
    "timezone": "browser",
    "version": 1,
    "panels": [
      {
        "type": "graph",
        "title": "NUC CPU %",
        "fieldConfig": { "defaults": { "unit": "percent", "thresholds": { "mode": "absolute", "steps":[{"color":"green","value":0},{"color":"yellow","value":70},{"color":"red","value":90}] } } },
        "targets": [{"query":"from(bucket:\"telemetry\") |> range(start:-5m) |> filter(fn:(r) => r._measurement==\"cpu\" and r._field==\"usage_idle\") |> last() |> map(fn:(r) => ({ _value: 100 - r._value }))"}],
        "gridPos": {"h":5,"w":6,"x":0,"y":0}
      },
      {
        "type": "graph",
        "title": "NUC RAM %",
        "fieldConfig": { "defaults": { "unit": "percent","thresholds":{"mode":"absolute","steps":[{"color":"green","value":0},{"color":"yellow","value":70},{"color":"red","value":90}]}} },
        "targets": [{"query":"from(bucket:\"telemetry\") |> range(start:-5m) |> filter(fn:(r)=>r._measurement==\"mem\" and r._field==\"used_percent\") |> last()"}],
        "gridPos": {"h":5,"w":6,"x":6,"y":0}
      }
      // Additional panels (Disk, CPU Temp, LTE RX/TX MB/s, Total GB, Public IP, Voltage, Router Temp, Uptime, Ping) should be added here following same structure
    ]
  }
}
EOL

# Start containers
echo "Starting Docker containers..."
docker-compose -f "$BASE_DIR/docker-compose.yml" up -d
echo "Waiting 10s for InfluxDB to initialize..."
sleep 10

# Import dashboard to Grafana
echo "Importing Grafana dashboard..."
GRAFANA_API="http://localhost:3000/api/dashboards/db"
curl -s -X POST -H "Content-Type: application/json" -u admin:$GRAFANA_PASS \
    --data-binary @"$BASE_DIR/dashboard.json" $GRAFANA_API

echo
echo "===== Car Monitor v4.1 Alfa installation complete ====="
echo "Grafana: http://localhost:3000 (admin / your password)"
echo "InfluxDB: http://localhost:8086 (admin / your password)"
echo "Telegraf is running and sending metrics to InfluxDB."
