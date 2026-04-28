# UniFi Codex Plugin

Unofficial Codex plugin for working with Ubiquiti UniFi Network controllers.

It adds a UniFi skill that helps Codex safely discover sites, inspect devices and clients, and reason about potentially disruptive network changes before making them.

## Contents

- `.codex-plugin/plugin.json`: Codex plugin manifest.
- `skills/unifi/SKILL.md`: UniFi operating guidance for Codex.
- `scripts/unifi_api.sh`: Small curl-based helper for UniFi Network API reads.

## Configuration

Set these environment variables before asking Codex to inspect a controller:

```bash
export UNIFI_URL="https://192.168.1.1"
export UNIFI_USERNAME="your-local-user"
export UNIFI_PASSWORD="your-password"
export UNIFI_SITE="default"
```

For self-signed controller certificates:

```bash
export UNIFI_INSECURE=1
```

## Examples

```bash
scripts/unifi_api.sh sites
scripts/unifi_api.sh devices
scripts/unifi_api.sh clients
scripts/unifi_api.sh health
```

## Safety

Configuration changes to UniFi networks can disconnect clients or devices. The skill instructs Codex to start with read-only discovery and ask for explicit confirmation before disruptive actions.

## Secret Scanning

This repository uses Gitleaks in GitHub Actions. To run the same scan locally:

```bash
gitleaks git --config .gitleaks.toml --redact .
```

## Validation

Run the same structural checks used by CI:

```bash
python3 scripts/validate_plugin.py
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .commitlintrc.json >/dev/null
shellcheck scripts/*.sh
```

## Repository Conventions

- Formatting defaults are defined in `.editorconfig`.
- Commit message rules are defined in `.commitlintrc.json`.
- Releases are tracked in `CHANGELOG.md` using Keep a Changelog.

## Trademark

This project is not affiliated with, endorsed by, or sponsored by Ubiquiti Inc. UniFi and Ubiquiti are trademarks of Ubiquiti Inc.
