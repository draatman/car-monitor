# Car Monitor Alfa v5.0  
**Live Telemetry Dashboard for NUC + MikroTik LTE Router**

A **plug-and-play**, **secure**, and **mobile-friendly** monitoring stack using:

- **Telegraf** → Collects metrics  
- **InfluxDB 2.9** → Stores time-series data  
- **Grafana** → Beautiful dashboard with alerts  

Automatically installs Docker, configures everything, and **prompts for your custom passwords**.

---

## Features

| Feature | Description |
|-------|-----------|
| **LTE Signal** | RSRP, RSRQ, SINR (real-time graphs) |
| **Data Usage** | RX/TX in **MB/s** + **Total GB (all-time)** |
| **Public IP** | Auto-updates on LTE change |
| **NUC Health** | CPU %, RAM %, Disk %, CPU Temp |
| **Router Health** | Voltage, Temperature, Uptime |
| **Connectivity** | Ping to 1.1.1.1 & 8.8.8.8 |
| **Mobile Ready** | Stacked layout for phone/tablet |
| **Auto-Refresh** | 5-second live updates |
| **Color Alerts** | Red/Yellow/Green thresholds |

---

## Prerequisites

- **OS**: Ubuntu 20.04/22.04/24.04 (or Debian-based)  
- **Hardware**: Intel NUC (or x86 PC)  
- **Network**: MikroTik LTE router at `192.168.88.1`  
- **Internet**: Required for Docker images  
- **Ports Open**: `3000` (Grafana), `8086` (InfluxDB)

---

## Quick Install (One Command)

```bash
curl -fsSL https://raw.githubusercontent.com/draatman/car-monitor/main/install.sh | bash
