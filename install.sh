#!/bin/bash
# car-monitor-install.sh — FULLY FIXED & AUTOMATED
# Run: curl -fsSL https://raw.githubusercontent.com/your/repo/main/install.sh | bash

set -e

echo "=== CAR MONITOR FULL INSTALL (FIXED 401 & SETUP) ==="

# === 1. PREPARE ===
mkdir -p ~/car-monitor/data/{influxdb,grafana}
cd ~/car-monitor

# === 2. docker-compose.yml (FORCED SETUP) ===
cat > docker-compose.yml << 'EOF'
services:
  influxdb:
    image: influxdb:2.7
    container_name: influxdb
    restart: unless-stopped
    ports: ["8086:8086"]
    volumes:
      - influxdb_data:/var/lib/influxdb2
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: 2TRwGse81115
      DOCKER_INFLUXDB_INIT_ORG: car
      DOCKER_INFLUXDB_INIT_BUCKET: telemetry
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: xK9mP2vL8qW3rT5yU7zA0eC4fG6hJ1nB

  telegraf:
    image: telegraf:1.34
    container_name: telegraf
    restart: unless-stopped
    depends_on: [influxdb]
    volumes:
      - ./telegraf.conf:/etc/telegraf/telegraf.conf:ro

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    depends_on: [influxdb]
    ports: ["3000:3000"]
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: 2TRwGse81115
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  influxdb_data:
  grafana_data:
EOF

# === 3. telegraf.conf (CLEAN & SAFE) ===
cat > telegraf.conf << 'EOF'
[global_tags]
  host = "nuc-car"

[agent]
  interval = "10s"
  round_interval = true
  flush_interval = "10s"

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "xK9mP2vL8qW3rT5yU7zA0eC4fG6hJ1nB"
  organization = "car"
  bucket = "telemetry"

[[inputs.cpu]]
  percpu = false
  totalcpu = true
  fieldexclude = ["time_*"]

[[inputs.mem]]

[[inputs.disk]]
  ignore_fs = ["tmpfs","devtmpfs","overlay"]

[[inputs.ping]]
  urls = ["1.1.1.1","8.8.8.8"]
  count = 1
  timeout = 2.0

[[inputs.exec]]
  commands = ["sensors 2>/dev/null | grep 'Core 0' | awk '{print $3}' | tr -d '+°C' | head -1 || echo 0"]
  data_format = "value"
  name_override = "nuc_cpu_temp"

[[inputs.snmp]]
  agents = ["192.168.30.1:161"]
  version = 2
  community = "public"
  timeout = "3s"
  retries = 1
  [[inputs.snmp.field]]
    name = "voltage"
    oid = "1.3.6.1.4.1.14988.1.1.1.1.0"
  [[inputs.snmp.field]]
    name = "temperature"
    oid = "1.3.6.1.4.1.14988.1.1.1.2.0"
EOF

# === 4. INSTALL DEPENDENCIES ===
sudo apt update
sudo apt install -y docker.io docker-compose lm-sensors curl jq

# === 5. CLEAN ANY OLD VOLUMES ===
docker compose down 2>/dev/null || true
docker volume rm car-monitor_influxdb_data 2>/dev/null || true
docker volume rm car-monitor_grafana_data 2>/dev/null || true

# === 6. START INFLUXDB & WAIT FOR SETUP ===
docker compose up -d influxdb
echo "Waiting for InfluxDB setup..."
sleep 50

# === 7. VERIFY TOKEN & SETUP ===
echo "=== INFLUXDB SETUP LOG ==="
docker logs influxdb | grep "Generated admin token" || echo "ERROR: Setup failed!"

# === 8. START FULL STACK ===
docker compose up -d

# === 9. FINAL STATUS ===
sleep 30
echo "=== TELEGRAF LOGS (LOOK FOR 'Wrote batch') ==="
docker compose logs telegraf | tail -20

# === 10. DONE ===
echo ""
echo "DASHBOARD LIVE AT: http://$(hostname -I | awk '{print $1}'):3000"
echo "LOGIN: admin / 2TRwGse81115"
echo ""
echo "MIKROTIK SNMP (run once):"
echo "  /ip service set snmp enabled=yes"
echo "  /snmp community set [find name=public] addresses=192.168.30.0/24"
