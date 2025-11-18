#!/bin/bash

# ---- Config ----
VERSION="1.7.0"
EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz"
REMOTE_USER="root"
REMOTE_HOST="192.168.0.82" ##prometheus-ip
REMOTE_TARGET_FILE="/srv/grafana-monitoring/prometheus/linux-targets.json"

# ---- Step 1: Install Node Exporter ----
wget $EXPORTER_URL -O /tmp/node_exporter.tar.gz
tar -xzf /tmp/node_exporter.tar.gz -C /tmp
sudo mv /tmp/node_exporter-$VERSION.linux-amd64/node_exporter /usr/local/bin/

# ---- Step 2: Create systemd service ----
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=default.target
EOF

# ---- Step 3: Enable and start service ----
sudo systemctl daemon-reexec
sudo systemctl enable --now node_exporter

# ---- Step 4: Get IP and hostname ----
IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
TARGET="$IP:9100"

# ---- Step 5: Create a JSON snippet ----
TMP_NODE=$(mktemp)
/usr/bin/jq -n --arg target "$TARGET" --arg hn "$HOSTNAME" '[
  {
    targets: [$target],
    labels: {
      role: "linux",
      hostname: $hn,
      instance: $target
    }
  }
]' > "$TMP_NODE"

# ---- Step 6: Send JSON to Prometheus server ----
scp "$TMP_NODE" "$REMOTE_USER@$REMOTE_HOST:/tmp/node_$HOSTNAME.json"

# ---- Step 7: Remotely merge it into linux-targets.json ----
#ssh "$REMOTE_USER@$REMOTE_HOST" <<EOF
ssh -t "$REMOTE_USER@$REMOTE_HOST" <<EOF
  set -e
  TMP="/tmp/node_$HOSTNAME.json"
  FINAL="$REMOTE_TARGET_FILE"
  MERGED="/tmp/tmp_merged.json"
  
  if [ ! -f "\$FINAL" ]; then echo "[]" > "\$FINAL"; fi

  jq -s 'add | unique_by(.targets[0])' "\$FINAL" "\$TMP" > "\$MERGED" && \
  mv "\$MERGED" "\$FINAL" && \
  rm -f "\$TMP"
EOF

# ---- Cleanup ----
rm -f "$TMP_NODE"

echo "Node Exporter installed and registered to Prometheus."

