#!/bin/bash
set -euo pipefail

mkdir -p /root/.config/opencode
mkdir -p /workspace

if [ ! -f /root/.config/opencode/opencode.json ] && [ ! -f /root/.config/opencode/opencode.jsonc ]; then
  cp /usr/local/share/opencode/opencode.json.example /root/.config/opencode/opencode.json
fi

exec opencode serve --hostname 0.0.0.0 --port 4096
