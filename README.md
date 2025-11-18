# Grafana Monitoring Stack

"A lightweight, containerized observability stack built with Prometheus, Grafana, Alertmanager, and Loki — designed for centralized infrastructure, application, and log monitoring across Linux, Windows, and macOS systems."

---

## Prerequisites

Ensure the following are installed before running this setup:

- Docker v20.10+
- Docker Compose v2+
- Linux host with internet access



## 📂 Folder Structure
----

└── grafana-monitoring
    ├── client-scripts
    │   ├── linux-agent-setup.sh
    │   └── windows-agent-setup.ps1
    ├── docker-compose.yml
    ├── grafana
    │   ├── grafana.ini
    │   └── provisioning
    │       └── datasources
    │           └── datasource.yml
    ├── loki
    │   ├── data
    │   │      
    │   └── loki-config.yaml
    ├── nginx
    │   ├── conf.d
    │   │   └── monitoring.conf
    │   ├── nginx.conf
    │   └── ssl
    ├── prometheus
    │   ├── alertmanager.yml
    │   ├── blackbox
    │   │   └── blackbox.yml
    │   ├── generate_targets.sh
    │   ├── linux-targets.json
    │   ├── macos-targets.json
    │   ├── prometheus.yml
    │   ├── rules-url.yml
    │   ├── rules.yml
    │   ├── templates
    │   │   └── EmailTemplate.tmpl
    │   └── windows-targets.json
    └── README.md



⚙️ Setup Instructions
Clone this repository and start the stack:

git clone https://github.com/naveeng8731/grafana-monitoring.git
cd grafana-monitoring

sudo docker compose up -d
-------------------------
sudo docker ps
-----------------------
You should see containers like:
• prometheus
• grafana
• alertmanager
• loki
• nginx
🌐 Access URLs
Service	URL	Port	Description

| Service           | URL                                            | Port | Description                               |
| ----------------- | ---------------------------------------------- | ---- | ----------------------------------------- |
| **Grafana**       | [http://localhost:3000](http://localhost:3000) | 3000 | Dashboards and visualizations             |
| **Prometheus**    | [http://localhost:9090](http://localhost:9090) | 9090 | Metrics scraping and querying             |
| **Alertmanager**  | [http://localhost:9093](http://localhost:9093) | 9093 | Alert routing and notifications           |
| **Loki**          | [http://localhost:3100](http://localhost:3100) | 3100 | Log aggregation backend                   |
| **Nginx (Proxy)** | [http://localhost](http://localhost)           | 80   | Optional reverse proxy for unified access |




👤 Author
Naveen G
GitHub: https://github.com/naveeng8731


















