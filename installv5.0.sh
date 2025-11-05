#!/bin/bash
set -e

# -------------------------------
# Car Monitoring Stack Installer v5.0
# Fully automated, plug-and-play
# -------------------------------

# Function to check for a command
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -------------------------------
# Install dependencies if missing
# -------------------------------
echo "[INFO] Checking for required dependencies..."

for cmd in curl wget openssl jq; do
    if ! command_exists "$cmd"; then
        echo "[INFO] Installing $cmd..."
        apt-get update
        apt-get install -y "$cmd"
    fi
done

# -------------------------------
# Install Docker if missing
# -------------------------------
if ! command_exists docker; then
    echo "[INFO] Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
fi

# -------------------------------
# Install Docker Compose v2 if missing
# -------------------------------
if ! command_exists docker-compose; then
    echo "[INFO] Installing Docker Compose v2..."
    DOCKER_COMPOSE_VERSION="v2.25.0"
    curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# -------------------------------
# Create data directories
# -------------------------------
echo "[INFO] Creating persistent data directories..."
mkdir -p ./data/influxdb ./data/grafana

# -------------------------------
# Generate random passwords
# -------------------------------
echo "[INFO] Generating random passwords..."
export INFLUX_PASS=$(openssl rand -base64 16)
export INFLUX_TOKEN=$(openssl rand -hex 16)
export GRAFANA_PASS=$(openssl rand -base64 12)
export MIKROTIK_PASS=$(openssl rand -base64 12)

echo "[INFO] Passwords generated:"
echo "  InfluxDB: $INFLUX_PASS"
echo "  InfluxDB Token: $INFLUX_TOKEN"
echo "  Grafana: $GRAFANA_PASS"
echo "  MikroTik: $MIKROTIK_PASS"

# -------------------------------
# Copy config files (if needed)
# -------------------------------
echo "[INFO] Ensuring config files exist..."
if [[ ! -f docker-compose.yml ]]; then
    echo "[ERROR] docker-compose.yml not found!"
    exit 1
fi
if [[ ! -f telegraf.conf ]]; then
    echo "[ERROR] telegraf.conf not found!"
    exit 1
fi
if [[ ! -f dashboard.json ]]; then
    echo "[ERROR] dashboard.json not found!"
    exit 1
fi

# -------------------------------
# Start Docker containers
# -------------------------------
echo "[INFO] Starting Docker containers..."
docker-compose up -d

echo "[INFO] Waiting 15 seconds for InfluxDB and Grafana to initialize..."
sleep 15

# -------------------------------
# Import Grafana dashboard
# -------------------------------
echo "[INFO] Importing Grafana dashboard..."
GRAFANA_API="http://localhost:3000/api/dashboards/db"
DASHBOARD_JSON=$(cat dashboard.json)

curl -s -X POST "$GRAFANA_API" \
    -H "Content-Type: application/json" \
    -u "admin:$GRAFANA_PASS" \
    -d "$DASHBOARD_JSON"

echo "[INFO] Grafana dashboard imported."

# -------------------------------
# Permissions & Security
# -------------------------------
echo "[INFO] Setting permissions..."
chmod -R 755 ./data
chmod 600 ./telegraf.conf

# -------------------------------
# Done
# -------------------------------
echo "-------------------------------------------"
echo "✅ Car Monitoring Stack Installed v5.0"
echo "Grafana URL: http://localhost:3000"
echo "Grafana admin password: $GRAFANA_PASS"
echo "InfluxDB password: $INFLUX_PASS"
echo "InfluxDB token: $INFLUX_TOKEN"
echo "MikroTik password: $MIKROTIK_PASS"
echo "Run 'docker-compose logs -f' to view logs."
echo "-------------------------------------------"
