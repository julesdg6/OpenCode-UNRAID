# OpenCode-UNRAID

Unraid-compatible Docker image and template for running OpenCode as a persistent network service with MCP-ready config from first boot.

## Files

- `Dockerfile`
- `entrypoint.sh`
- `opencode.json.example`
- `unraid/opencode.xml`

## Build on Unraid

```bash
docker build -t opencode-unraid:local .
```

## Install the template in Unraid

1. Copy `unraid/opencode.xml` into your Unraid templates path.
   - Typical path: `/boot/config/plugins/dockerMan/templates-user/`
2. In the Unraid Docker UI, add/install the **OpenCode** container from this template.

Template defaults:

- Port: host `4096` -> container `4096`
- Config path: `/mnt/user/appdata/opencode/config` -> `/root/.config/opencode`
- Workspace path: `/mnt/user/appdata/opencode/workspace` -> `/workspace`
- Optional variables:
  - `OPENCODE_SERVER_PASSWORD`
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

Python is included because many MCP servers are distributed as Python packages.

## Runtime behavior

The container starts with:

```bash
opencode serve --hostname 0.0.0.0 --port 4096
```

On first boot, if no `opencode.json` or `opencode.jsonc` exists, it seeds `/root/.config/opencode/opencode.json` from `opencode.json.example` so MCP/provider config can be edited immediately without `opencode mcp add` surgery.

## Test

```bash
curl http://[IP]:4096
```

## Verify MCP

```bash
docker exec -it OpenCode bash -lc 'opencode mcp list'
```

## Update opencode.json

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
```
