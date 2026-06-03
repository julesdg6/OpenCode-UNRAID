#!/bin/bash
set -euo pipefail

CONFIG_DIR=/root/.config/opencode
WORKSPACE_DIR=/workspace

mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"

if [ ! -f "$CONFIG_DIR/opencode.json" ] && [ ! -f "$CONFIG_DIR/opencode.jsonc" ]; then
  cp /usr/local/share/opencode/opencode.json.example "$CONFIG_DIR/opencode.json"
fi

OPENCODE_HOSTNAME="${OPENCODE_HOSTNAME:-0.0.0.0}"
OPENCODE_PORT="${OPENCODE_PORT:-4096}"
GATEWAY_MCP_ENABLED="${GATEWAY_MCP_ENABLED:-true}"
GATEWAY_MCP_PORT="${GATEWAY_MCP_PORT:-4097}"
GATEWAY_MCP_ENDPOINT="${GATEWAY_MCP_ENDPOINT:-/mcp}"

if [ "${GATEWAY_MCP_ENABLED,,}" = "false" ]; then
  exec opencode serve --hostname "$OPENCODE_HOSTNAME" --port "$OPENCODE_PORT"
fi

opencode serve --hostname "$OPENCODE_HOSTNAME" --port "$OPENCODE_PORT" &
opencode_pid=$!
mcp_proxy_pid=""

export OPENCODE_BASE_URL="${OPENCODE_BASE_URL:-http://127.0.0.1:${OPENCODE_PORT}}"
export OPENCODE_AUTO_SERVE=false

if [ -n "${GATEWAY_MCP_API_KEY:-}" ] && [ -z "${MCP_PROXY_API_KEY:-}" ]; then
  export MCP_PROXY_API_KEY="$GATEWAY_MCP_API_KEY"
fi

wait_for_opencode() {
  local retries=60
  while [ "$retries" -gt 0 ]; do
    if ! kill -0 "$opencode_pid" 2>/dev/null; then
      echo "opencode serve exited before becoming ready" >&2
      return 1
    fi
    if curl -s --max-time 1 -o /dev/null "http://127.0.0.1:${OPENCODE_PORT}" 2>/dev/null; then
      return 0
    fi
    retries=$((retries - 1))
    sleep 1
  done

  echo "Timed out waiting for opencode serve on 127.0.0.1:${OPENCODE_PORT}" >&2
  return 1
}

if ! wait_for_opencode; then
  kill "$opencode_pid" 2>/dev/null || true
  wait "$opencode_pid" 2>/dev/null || true
  exit 1
fi

mcp-proxy --port "$GATEWAY_MCP_PORT" --server stream --streamEndpoint "$GATEWAY_MCP_ENDPOINT" -- opencode-mcp &
mcp_proxy_pid=$!

cleanup() {
  for pid in "$opencode_pid" "${mcp_proxy_pid:-}"; do
    if [ -z "$pid" ]; then
      continue
    fi
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done
  if [ -n "${opencode_pid:-}" ]; then
    wait "$opencode_pid" 2>/dev/null || true
  fi
  if [ -n "${mcp_proxy_pid:-}" ]; then
    wait "$mcp_proxy_pid" 2>/dev/null || true
  fi
}

trap cleanup TERM INT

wait -n "$opencode_pid" "$mcp_proxy_pid"
exit_code=$?
cleanup
exit "$exit_code"
