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
|---------|-------------|
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
Or clone and run manually:
bashgit clone https://github.com/draatman/car-monitor.git
cd car-monitor
chmod +x install.sh
./install.sh
What the script does

Installs Docker + Docker Compose plugin
Creates ~/car-monitor/ with persistent data folders
Prompts for:

InfluxDB password
Grafana password
MikroTik password
InfluxDB token


Writes docker-compose.yml, telegraf.conf, dashboard.json
Starts the three containers
Waits for InfluxDB to be ready
Auto-imports the full Grafana dashboard


Access Your Dashboard

ServiceURLLoginGrafanahttp://<NUC_IP>:3000admin / (your Grafana password)InfluxDBhttp://<NUC_IP>:8086admin / (your InfluxDB password)
The dashboard is imported automatically – just log in!

MikroTik Setup (One-Time)
On the router (Winbox or CLI):
bash/user add name=monitor group=read password="YOUR_MIKROTIK_PASSWORD"
/ip service set api disabled=no
Replace YOUR_MIKROTIK_PASSWORD with the password you entered during install.

Metrics Overview

PanelSourceUnitThresholdsVoltageMikroTikV<12 = red, 12–13 = yellow, >13 = greenRouter TempMikroTik°C>75 = red, 60–75 = yellowLTE RSRPMikroTikdBmGraphLTE RX/TXMikroTikMB/sLive rateTotal DataMikroTikGBAll-timePublic IPMikroTikTextAuto-updateNUC CPUNUC%>90 = red, 70–90 = yellowNUC RAMNUC%>90 = red, 70–90 = yellowNUC DiskNUC%>90 = red, 80–90 = yellowCPU TempNUC°C>80 = red, 65–80 = yellowPingNUCms>200 = red

File Structure
textcar-monitor/
├── install.sh              ← Run this
├── docker-compose.yml      ← Auto-generated
├── telegraf.conf           ← Auto-generated
├── dashboard.json          ← Full dashboard
├── data/
│   ├── influxdb/           ← Persistent DB
│   └── grafana/            ← Persistent settings
└── README.md               ← This file

Security Notes

Passwords are NOT hard-coded – you enter them at install time.
Data lives in ./data/ – back up this folder.
Grafana is not exposed to the internet by default.
For remote access, add a reverse proxy + HTTPS (e.g., Nginx).
To change passwords: docker compose down && ./install.sh


Updating the Stack
bashcd ~/car-monitor
docker compose pull
docker compose up -d
Your data and dashboard stay intact.

Troubleshooting
Quick Debug Commands
bashcd ~/car-monitor
docker compose ps          # Are containers running?
docker compose logs -f     # Live logs
docker compose restart     # Restart everything
Common Issues & Fixes

---

IssueFixdocker: command not foundThe script installs Docker automatically. If it fails: 
sudo apt install docker.ioPermission deniedAdd user to Docker group: 
sudo usermod -aG docker $USER → log out & back inContainers exit immediatelyCheck logs: 
docker compose logs 
Look for password mismatch or port 8086 conflictNo data in dashboard1. Wait 2 min (Telegraf collects every 5 s) 
2. docker compose logs -f telegraf 
3. Grafana → Data Sources → InfluxDB: 
 • URL: http://influxdb:8086 
 • Token: (your InfluxDB token)CPU Temp emptyInstall lm-sensors on the NUC: 
sudo apt install lm-sensors && sudo sensors-detectLTE panels empty1. Enable API on MikroTik: 
/ip service set api disabled=no 
2. Add user: /user add name=monitor group=read password="YOUR_MIKROTIK_PASS" 
3. Verify IP in telegraf.conf: 192.168.88.1:8728Script hangs on password promptsRun interactively (don’t pipe): 
Correct: ./install.sh 
Incorrect: `curl …
---
Screenshots (Mobile View)
text[ LTE Signal ]  [ Voltage: 13.4V ]
[ RX: 2.1 MB/s ] [ TX: 0.8 MB/s  ]
[ Total: 12.4 GB ] [ IP: 85.XXX.XX ]
[ CPU: 34% ] [ RAM: 62% ] [ Disk: 78% ]
[ CPU Temp: 58°C ] [ Ping: 42ms ]
Panels stack vertically on phones.
---
Repository
GitHub: https://github.com/draatman/car-monitor
