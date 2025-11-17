#!/bin/bash

# Output file paths
LINUX_FILE="./linux-targets.json"
WINDOWS_FILE="./windows-targets.json"
MAC_FILE="./macos-targets.json"

# Create Linux targets file
cat <<EOF > $LINUX_FILE
[
  {
    "targets": [],
    "labels": {
      "role": "linux"
    }
  }
]
EOF

# Create Windows targets file
cat <<EOF > $WINDOWS_FILE
[
  {
    "targets": [],
    "labels": {
      "role": "windows"
    }
  }
]
EOF

# Create macOS targets file
cat <<EOF > $MAC_FILE
[
  {
    "targets": [],
    "labels": {
      "role": "macos"
    }
  }
]
EOF

echo "Created empty target files:"
echo " - $LINUX_FILE"
echo " - $WINDOWS_FILE"
echo " - $MAC_FILE"

