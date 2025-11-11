#!/bin/bash

LINUX_PORT=9100
WIN_PORT=9182
MAC_PORT=9300

LINUX_FILE="./linux-targets.json"
WINDOWS_FILE="./windows-targets.json"
MAC_FILE="./macos-targets.json"

scan_ips() {
  local PORT=$1
  local SUBNETS=("192.168.1")
  local TARGETS=()

  for SUBNET in "${SUBNETS[@]}"; do
    for HOST in {1..254}; do
      IP="$SUBNET.$HOST"
      (echo > /dev/tcp/$IP/$PORT) >/dev/null 2>&1 && TARGETS+=("\"$IP:$PORT\"")
    done
  done

  echo "${TARGETS[@]}"
}

# Generate Linux targets
LINUX_IPS=($(scan_ips $LINUX_PORT))
cat <<EOF > $LINUX_FILE
[
  {
    "targets": [
      $(IFS=, ; echo "${LINUX_IPS[*]}")
    ],
    "labels": {
      "role": "linux"
    }
  }
]
EOF

# Generate Windows targets
WIN_IPS=($(scan_ips $WIN_PORT))
cat <<EOF > $WINDOWS_FILE
[
  {
    "targets": [
      $(IFS=, ; echo "${WIN_IPS[*]}")
    ],
    "labels": {
      "role": "windows"
    }
  }
]
EOF

# Generate macOS targets
MAC_IPS=($(scan_ips $MAC_PORT))
cat <<EOF > $MAC_FILE
[
  {
    "targets": [
      $(IFS=, ; echo "${MAC_IPS[*]}")
    ],
    "labels": {
      "role": "macos"
    }
  }
]
EOF

echo "✅ Updated targets: Linux (${#LINUX_IPS[@]} hosts), Windows (${#WIN_IPS[@]} hosts), macOS (${#MAC_IPS[@]} hosts)"

