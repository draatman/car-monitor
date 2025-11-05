# Car Monitor Alfa v1.0.0

This is a plug-and-play car/NUC monitoring stack:
- Docker + Telegraf + InfluxDB + Grafana
- Automatically monitors:
  - MikroTik LTE interface: RSRP/RSRQ/SINR, RX/TX MB/s, total GB, public IP, voltage, router temp
  - NUC: CPU %, RAM %, Disk %, CPU Temp
  - Ping connectivity
- Colored thresholds for all critical values
- Mobile-friendly Grafana layout

## Installation

1. Clone repository:
   ```bash
   git clone https://github.com/yourusername/car-monitor-alfa-v1.0.0.git
   cd car-monitor-alfa-v1.0.0


   You place install.sh, docker-compose.yml, telegraf.conf, and dashboard.json in the same folder.

Run sudo bash install.sh.

The script:

Checks OS dependencies (curl, wget, openssl).

Installs Docker & Docker Compose if missing.

Creates data/ folders for persistence.

Generates secure random passwords and exports them.

Starts containers via Docker Compose.

Waits for services to be ready.

Imports the Grafana dashboard automatically.

After completion, you can log into Grafana with the generated password.
