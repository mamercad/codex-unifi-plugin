---
name: unifi
description: Work with Ubiquiti UniFi Network controllers. Use when the user asks Codex to inspect UniFi sites, gateways, switches, access points, clients, WLANs, alerts, or controller health.
---

# UniFi

Use this skill to help with Ubiquiti UniFi Network controller tasks. This plugin is unofficial and should treat UniFi configuration changes as potentially disruptive network operations.

## Connection

Prefer the helper script at `scripts/unifi_api.sh` from the plugin root.

Required environment:

- `UNIFI_URL`: Base URL for the UniFi Network Application or UniFi OS console, for example `https://192.168.1.1`.
- `UNIFI_USERNAME`: Local UniFi username.
- `UNIFI_PASSWORD`: Local UniFi password.

Optional environment:

- `UNIFI_SITE`: UniFi site name, default `default`.
- `UNIFI_INSECURE`: Set to `1` for self-signed certificates.

Never print credentials. If credentials are missing, ask the user to set the environment variables.

## Safe Workflow

1. Start with read-only discovery unless the user explicitly asks for a change.
2. Identify whether the controller is UniFi OS or a classic Network Application.
3. Discover sites before site-scoped calls.
4. For writes, summarize the exact target object and intended effect before making changes.
5. After writes, read the changed object back and report the resulting state.

## Common Commands

Run these from the plugin root:

```bash
scripts/unifi_api.sh sites
scripts/unifi_api.sh devices
scripts/unifi_api.sh clients
scripts/unifi_api.sh health
scripts/unifi_api.sh raw /proxy/network/api/s/default/stat/device
```

The helper prints JSON. Prefer `jq` when available for inspection.

## API Notes

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
