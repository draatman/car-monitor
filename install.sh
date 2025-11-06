#!/bin/bash
set -euo pipefail

echo "Car Monitor Alfa v5.0 Installer"
echo "================================"

# === 1. Prompt for passwords (always) ===
read -sp "Enter InfluxDB admin password: " INFLUX_PASS; echo
read -sp "Enter Grafana admin password: " GRAFANA_PASS; echo
read -sp "Enter MikroTik API password: " MIKROTIK_PASS; echo
read -sp "Enter InfluxDB token (any strong string): " INFLUX_TOKEN; echo

# === 2. Install Docker if missing ===
if ! command -v docker >/dev/null 2>&1; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
fi

# === 3. Install Docker Compose plugin if missing ===
if ! docker compose version >/dev/null 2>&1; then
    echo "Installing Docker Compose plugin..."
    sudo apt-get update && sudo apt-get install -y docker-compose-plugin
fi

# === 4. Create project structure ===
PROJECT_DIR="$HOME/car-monitor"
mkdir -p "$PROJECT_DIR/data/influxdb" "$PROJECT_DIR/data/grafana"
cd "$PROJECT_DIR"

# === 5. Fix Grafana volume permissions (user 472) ===
sudo chown -R 472:472 "$PROJECT_DIR/data/grafana"

# === 6. Write docker-compose.yml ===
cat > docker-compose.yml <<EOF
services:
  influxdb:
    image: influxdb:2.7
    container_name: influxdb
    restart: unless-stopped
    ports: ["8086:8086"]
    volumes: [./data/influxdb:/var/lib/influxdb2]
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: $INFLUX_PASS
      DOCKER_INFLUXDB_INIT_ORG: car
      DOCKER_INFLUXDB_INIT_BUCKET: telemetry
      DOCKER_INFLUXDB_INIT_TOKEN: $INFLUX_TOKEN

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    depends_on: [influxdb]
    ports: ["3000:3000"]
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: $GRAFANA_PASS
    volumes: [./data/grafana:/var/lib/grafana]

  telegraf:
    image: telegraf:1.34
    container_name: telegraf
    restart: unless-stopped
    depends_on: [influxdb]
    volumes:
      - ./telegraf.conf:/etc/telegraf/telegraf.conf:ro
EOF

# === 7. Write telegraf.conf (fixed for 1.34) ===
cat > telegraf.conf <<'EOF'
[global_tags]
  host = "nuc-car"

[agent]
  interval = "5s"
  round_interval = true
  flush_interval = "5s"

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "$INFLUX_TOKEN"
  organization = "car"
  bucket = "telemetry"

[[inputs.cpu]]
  percpu = false
  totalcpu = true
  fieldexclude = ["time_*"]

[[inputs.mem]]

[[inputs.disk]]
  ignore_fs = ["tmpfs","devtmpfs","overlay"]

[[inputs.exec]]
  commands = ["sensors | grep 'Core 0' | awk '{print $3}' | tr -d '+°C' | cut -d. -f1"]
  data_format = "value"
  name_override = "nuc_cpu_temp"
  tagpass = { core0 = ["true"] }

[[inputs.ping]]
  urls = ["1.1.1.1","8.8.8.8"]
  count = 1
  timeout = 2.0

[[inputs.snmp]]
  agents = ["192.168.88.1:161"]
  version = 2
  community = "public"
  [[inputs.snmp.field]]
    name = "voltage"
    oid = "1.3.6.1.4.1.14988.1.1.1.1.0"
  [[inputs.snmp.field]]
    name = "temperature"
    oid = "1.3.6.1.4.1.14988.1.1.1.2.0"
EOF

# === 8. Start stack ===
echo "Starting containers..."
docker compose up -d

# === 9. Wait for InfluxDB ===
echo "Waiting for InfluxDB to be ready..."
until curl -s http://localhost:8086/ping >/dev/null 2>&1; do
    sleep 2
done

# === 10. Final message ===
IP=$(hostname -I | awk '{print $1}')
echo "Installation complete!"
echo "Grafana: http://$IP:3000 | admin / $GRAFANA_PASS"
echo "InfluxDB Token: $INFLUX_TOKEN"
echo "MikroTik SNMP: Enable on router → /ip service set snmp enabled=yes"
