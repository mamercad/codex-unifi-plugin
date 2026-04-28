---
name: unifi
description: Work with UniFi Site Manager and local Network controllers. Use when the user asks Codex to inspect UniFi sites, hosts, gateways, switches, access points, clients, WLANs, alerts, or controller health.
---

# UniFi

Use this skill to help with Ubiquiti UniFi Site Manager and Network controller tasks. This plugin is unofficial and should treat UniFi configuration changes as potentially disruptive network operations.

## Connection

Prefer the official Site Manager helper at `scripts/unifi_site_manager_api.sh` for cloud/account-wide read-only discovery. Use `scripts/unifi_api.sh` only when the user needs local Network Application details that are not exposed by Site Manager.

Site Manager environment:

- `UNIFI_API_TOKEN`: API token for `https://api.ui.com`.
- `UNIFI_API_BASE_URL`: Optional override, default `https://api.ui.com`.

Local controller environment:

- `UNIFI_URL`: Base URL for the UniFi Network Application or UniFi OS console, for example `https://192.168.1.1`.
- `UNIFI_USERNAME`: Local UniFi username.
- `UNIFI_PASSWORD`: Local UniFi password.

Optional environment:

- `UNIFI_SITE`: UniFi site name, default `default`.
- `UNIFI_INSECURE`: Set to `1` for self-signed certificates.

Never print credentials. If credentials are missing, ask the user to set the required environment variables.

## Safe Workflow

1. Start with read-only discovery unless the user explicitly asks for a change.
2. Use Site Manager first for hosts, sites, devices, and ISP metrics.
3. Use the local controller helper only when Site Manager lacks the needed detail.
4. Identify whether a local controller is UniFi OS or a classic Network Application before local calls.
5. For writes, summarize the exact target object and intended effect before making changes.
6. After writes, read the changed object back and report the resulting state.

## Common Commands

Run these from the plugin root:

```bash
scripts/unifi_site_manager_api.sh hosts
scripts/unifi_site_manager_api.sh sites
scripts/unifi_site_manager_api.sh devices
scripts/unifi_site_manager_api.sh isp-metrics 5m 24h
scripts/unifi_api.sh sites
scripts/unifi_api.sh devices
scripts/unifi_api.sh clients
scripts/unifi_api.sh health
scripts/unifi_api.sh raw /proxy/network/api/s/default/stat/device
```

The helper prints JSON. Prefer `jq` when available for inspection.

## API Notes

The official Site Manager API uses `https://api.ui.com` with an `X-API-Key` header. Stable endpoints live under `/v1/...`; Early Access endpoints live under `/ea/...` and may have optional or changing response fields. Site Manager response bodies commonly include `data`, `httpStatusCode`, `traceId`, and sometimes `nextToken`.

UniFi OS consoles commonly proxy Network API calls under:

```text
/proxy/network/api/s/<site>/<endpoint>
```

Classic Network Application controllers commonly use:

```text
/api/s/<site>/<endpoint>
```

The helper tries UniFi OS login first, then falls back to classic login.

## Change Safety

Configuration updates can disconnect users, disable Wi-Fi, restart devices, or affect firewall/routing behavior. For any request that modifies settings, pauses clients, reboots devices, upgrades firmware, changes WLANs, or changes firewall/routing, ask for explicit confirmation with a concise summary of the action.
