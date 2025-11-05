Or clone and run manually:

bashgit clone https://github.com/draatman/car-monitor.git
cd car-monitor
chmod +x install.sh
./install.sh

Installation Steps (What the Script Does)

Installs Docker + Docker Compose plugin
Creates ~/car-monitor/ with persistent data
Prompts you for:

InfluxDB password
Grafana password
MikroTik password
InfluxDB token


Writes docker-compose.yml, telegraf.conf, dashboard.json
Starts containers
Waits for InfluxDB to be ready
Auto-imports full Grafana dashboard


Access Your Dashboard




















ServiceURLLoginGrafanahttp://<NUC_IP>:3000admin / (your Grafana password)InfluxDBhttp://<NUC_IP>:8086admin / (your InfluxDB password)

Dashboard auto-imported — just log in!


MikroTik Setup (One-Time)
On your MikroTik router (via Winbox or CLI):
bash/user add name=monitor group=read password="YOUR_MIKROTIK_PASSWORD"
/ip service set api disabled=no

Replace YOUR_MIKROTIK_PASSWORD with the one you entered during install.


Metrics Overview













































































PanelSourceUnitThresholdsVoltageMikroTikV<12=red, 12–13=yellow, >13=greenRouter TempMikroTik°C>75=red, 60–75=yellowLTE RSRPMikroTikdBmGraphLTE RX/TXMikroTikMB/sLive rateTotal DataMikroTikGBAll-time (since start)Public IPMikroTikTextAuto-updateNUC CPUNUC%>90=red, 70–90=yellowNUC RAMNUC%>90=red, 70–90=yellowNUC DiskNUC%>90=red, 80–90=yellowCPU TempNUC°C>80=red, 65–80=yellowPingNUCms>200=red

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

Passwords are NOT hardcoded — you enter them at install time
Data stored in ./data/ — backup this folder
Grafana is not exposed to the internet by default
Use reverse proxy + HTTPS (e.g., Nginx) for remote access
Change passwords via docker compose down && ./install.sh


Updating the Stack
bashcd ~/car-monitor
docker compose pull
docker compose up -d

Your data and dashboard are preserved.


Troubleshooting





























IssueCommandContainers not startingdocker compose logs -fNo data in Grafanadocker logs telegrafInfluxDB not readydocker logs influxdbMikroTik not respondingPing 192.168.88.1Dashboard blankRe-import dashboard.json

Screenshots (Mobile View)
text[ LTE Signal ]  [ Voltage: 13.4V ]
[ RX: 2.1 MB/s ] [ TX: 0.8 MB/s  ]
[ Total: 12.4 GB ] [ IP: 85.XXX.XX ]
[ CPU: 34% ] [ RAM: 62% ] [ Disk: 78% ]
[ CPU Temp: 58°C ] [ Ping: 42ms ]
(Panels stack vertically on phones)

Repository
GitHub: https://github.com/draatman/car-monitor
