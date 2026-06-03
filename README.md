# OpenCode-UNRAID

Unraid-compatible Docker image and template for running OpenCode as a persistent network service with MCP-ready config from first boot.

## Files

- `Dockerfile`
- `entrypoint.sh`
- `opencode.json.example`
- `unraid/opencode.xml`
- `.github/workflows/build.yml`

## Pull or Build

The pre-built image is published to GitHub Container Registry on every push to `main`:

```bash
docker pull ghcr.io/julesdg6/opencode-unraid:latest
```

To build locally instead:

```bash
docker build -t opencode-unraid:local .
```

## Install the template in Unraid

### Unraid 7 (recommended — curl method)

Run the following command from an Unraid terminal to download the template directly to the correct location:

```bash
curl -L -o /boot/config/plugins/dockerMan/templates-user/opencode.xml \
  https://raw.githubusercontent.com/julesdg6/OpenCode-UNRAID/main/unraid/opencode.xml
```

Then in the Unraid Docker UI, click **Add Container** and select the **OpenCode** template.

### Manual install

1. Copy `unraid/opencode.xml` into your Unraid templates path.
   - Typical path: `/boot/config/plugins/dockerMan/templates-user/`
2. In the Unraid Docker UI, add/install the **OpenCode** container from this template.

Template defaults:

- Port: host `4096` -> container `4096`
- Gateway MCP port: host `4097` -> container `4097`
- Config path: `/mnt/user/appdata/opencode/config` -> `/root/.config/opencode`
- Workspace path: `/mnt/user/appdata/opencode/workspace` -> `/workspace`
- Optional variables:
  - `OPENCODE_SERVER_PASSWORD`
  - `GATEWAY_MCP_ENABLED` (`true`/`false`)
  - `GATEWAY_MCP_PORT` (default `4097`)
  - `GATEWAY_MCP_ENDPOINT` (default `/mcp`)
  - `GATEWAY_MCP_API_KEY` (gateway `X-API-Key` auth)
  - `TZ`

## Included tools

The image bakes dependencies at build time (not startup):

- bash
- git
- curl
- jq
- python3
- python3-pip
- ripgrep
- ca-certificates
- less
- procps
- opencode-mcp
- mcp-proxy

Python is included because many MCP servers are distributed as Python packages.

## Runtime behavior

The container starts:

```bash
# OpenCode API/UI
opencode serve --hostname 0.0.0.0 --port 4096

# Dedicated MCP gateway (streamable HTTP)
mcp-proxy --port 4097 --server stream --streamEndpoint /mcp -- opencode-mcp
```

Entrypoint starts `opencode serve` first, waits until `http://127.0.0.1:4096` is reachable, then launches `opencode-mcp` on the gateway.

On first boot, if no `opencode.json` or `opencode.jsonc` exists, it seeds `/root/.config/opencode/opencode.json` from `opencode.json.example` so MCP/provider config can be edited immediately without needing to run `opencode mcp add` commands after deployment.

Gateway environment variables:

- `GATEWAY_MCP_ENABLED` (default `true`)
- `GATEWAY_MCP_PORT` (default `4097`)
- `GATEWAY_MCP_ENDPOINT` (default `/mcp`)
- `GATEWAY_MCP_API_KEY` (optional; mapped to `MCP_PROXY_API_KEY`)
- `OPENCODE_BASE_URL` (optional override, defaults to `http://127.0.0.1:${OPENCODE_PORT}`)

Hermes/OpenClaw streamable HTTP example:

```yaml
opencode:
  enabled: true
  transport: streamable_http
  url: http://OPENCODE_HOST:4097/mcp
```

Replace `OPENCODE_HOST` with your OpenCode host/IP (for example `192.168.1.100`).

If `GATEWAY_MCP_API_KEY` is set, configure your client to send `X-API-Key`.


## Security warning

`opencode serve --hostname 0.0.0.0` and the MCP gateway listen on container interfaces. If you publish ports `4096` and/or `4097` beyond localhost, treat `OPENCODE_SERVER_PASSWORD` and `GATEWAY_MCP_API_KEY` as required and keep network controls (firewall/reverse proxy) in place.

## Ollama endpoint note

The seeded `local_ollama` provider uses `http://127.0.0.1:11434/v1` as a local default (only valid when Ollama is reachable as localhost from this container). With Unraid bridge networking, localhost will not reach the host. If Ollama runs outside this container, update `opencode.json` to a reachable endpoint such as `http://192.168.1.100:11434/v1` (host IP), or `http://ollama:11434/v1` when both containers share the same Docker network.

## Test

```bash
curl http://[IP]:4096
curl -sS -X POST http://[IP]:4097/mcp \
  -H 'accept: application/json, text/event-stream' \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0.0.0"}}}'
```

## Verify MCP

```bash
docker exec -it OpenCode bash -lc 'opencode mcp list'
curl -sS -X POST http://[IP]:4097/mcp \
  -H 'accept: application/json, text/event-stream' \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"verify","version":"0.0.0"}}}'
```

## Update opencode.json

The example uses `{env:CONTEXT7_API_KEY}` in MCP headers; OpenCode resolves this from the matching container environment variable at runtime.

Edit your persisted config file at:

`/mnt/user/appdata/opencode/config/opencode.json`

Then restart the container.

## Restart

```bash
docker restart OpenCode
```

## Diagnostics

```bash
docker logs --tail 100 OpenCode
docker exec -it OpenCode bash -lc 'opencode mcp list'
docker exec -it OpenCode bash -lc 'cat /root/.config/opencode/opencode.json'
curl http://[IP]:4096
curl -i -X POST http://[IP]:4097/mcp \
  -H 'accept: application/json, text/event-stream' \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"diag","version":"0.0.0"}}}'
```
