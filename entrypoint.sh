#!/bin/bash
set -euo pipefail

CONFIG_DIR=/root/.config/opencode
WORKSPACE_DIR=/workspace

mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"

if [ ! -f "$CONFIG_DIR/opencode.json" ] && [ ! -f "$CONFIG_DIR/opencode.jsonc" ]; then
  cp /usr/local/share/opencode/opencode.json.example "$CONFIG_DIR/opencode.json"
fi

exec opencode serve --hostname 0.0.0.0 --port 4096
