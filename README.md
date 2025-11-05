# Car Monitor Alfa v5.0

A plug-and-play telemetry monitoring system for **NUC + MikroTik LTE**, using **InfluxDB 2.9**, **Grafana latest**, and **Telegraf**. Fully automated installer, random passwords, and a complete importable Grafana dashboard.

---

## Table of Contents

1. [Prerequisites](#prerequisites)  
2. [Included Files](#included-files)  
3. [Installation](#installation)  
4. [Accessing the Services](#accessing-the-services)  
5. [Metrics Monitored](#metrics-monitored)  
6. [Passwords & Tokens](#passwords--tokens)  
7. [Configuration Files](#configuration-files)  
8. [Updating the System](#updating-the-system)  
9. [Troubleshooting](#troubleshooting)  
10. [Security Notes](#security-notes)  
11. [License](#license)

---

## Prerequisites

- **Operating System:** Ubuntu 22.04 LTS or Debian-based system  
- **Hardware:** NUC or x86 system  
- **Network:** MikroTik LTE router accessible on the LAN  
- **Dependencies:** The installer script will automatically install Docker & Docker Compose if missing  
- **Ports:**  
  - Grafana: `3000`  
  - InfluxDB: `8086`  

---

## Included Files

| File | Purpose |
|------|---------|
| `install.sh` | Full automated installer (v5.0) |
| `docker-compose.yml` | Defines all Docker services |
| `telegraf.conf` | NUC and MikroTik metrics config |
| `dashboard.json` | Full importable Grafana dashboard |
| `README.md` | GitHub documentation |
| `data/` | Persistent InfluxDB data |

---

## Installation

1. Clone the repository:

```bash
git clone https://github.com/draatman/car-monitor.git
cd car-monitor
Make the installer executable:

bash
Copy code
chmod +x install.sh
Run the installer:

bash
Copy code
./install.sh
Installer actions:

Installs Docker & Docker Compose if missing

Generates random passwords for InfluxDB, Grafana, MikroTik (printed at the end)

Creates persistent directories for InfluxDB

Deploys containers with docker-compose

Waits for InfluxDB to initialize

Automatically imports the Grafana dashboard

Accessing the Services
Grafana
URL: http://<NUC_IP>:3000

Username: admin

Password: printed by installer

InfluxDB
URL: http://<NUC_IP>:8086

Token: printed by installer

Organization: car-monitor

Bucket: telemetry

Metrics Monitored
Metric	Source	Details
LTE Signal	MikroTik	RSRP, RSRQ, SINR
LTE RX/TX	MikroTik	Real-time MB/s, total GB
LTE Public IP	MikroTik	LTE interface IP
Voltage	MikroTik	Battery/Power supply
Router Temp	MikroTik	System temperature
Router Uptime	MikroTik	Running time
NUC CPU	NUC	% usage
NUC RAM	NUC	% usage
NUC Disk	NUC	% usage
CPU Temp	NUC	°C
Ping	NUC	Connectivity to gateway or DNS

Additional Features:

Colored thresholds (red/yellow/green)

Mobile-friendly Grafana layout (w:6, h:5)

Auto-refresh every 5 seconds

Passwords & Tokens
Random credentials are generated during install. Example:

yaml
Copy code
InfluxDB Password: 9yF2dP8Qx7Lk
InfluxDB Token: 4a2f8b1e7d9c0f6a
Grafana Password: Gj8dL3kT2x
MikroTik Password: K9mT2p5R7v
Important: Save these credentials securely.

Configuration Files
docker-compose.yml
Docker Compose v2 format

Services: influxdb, grafana, telegraf

Persistent volumes for data

Restart policy: unless-stopped

Uses random passwords exported from installer

telegraf.conf
Collects NUC CPU, RAM, Disk, CPU Temp

Collects MikroTik LTE: RSRP, RSRQ, SINR, RX/TX, voltage, router temp, uptime, ping

Uses InfluxDB v2 output with auto-generated token

Global tag: host=nuc-car

dashboard.json
Importable Grafana dashboard

All metrics and panels

Colored thresholds & mobile-friendly layout

Automatically imported during installation

Updating the System
Pull latest images:

bash
Copy code
docker compose pull
Restart containers:

bash
Copy code
docker compose up -d
Dashboard and data remain persistent.

Troubleshooting
Grafana not starting: docker compose logs grafana

InfluxDB errors: Check data/influxdb permissions

Metrics not appearing: Ensure NUC & MikroTik reachable on network

Dashboard import failed: Re-import dashboard.json in Grafana

Security Notes
Random passwords are generated per install

Data persists in ./data directory

Protect Docker ports and Grafana web GUI

License
MIT License – free to use, modify, and distribute

Repository URL: https://github.com/draatman/car-monitor.git

This is **all-in-one**, ready for GitHub, fully detailed for anyone to run `install.sh` and get a plug-and-play telemetry dashboard.  
