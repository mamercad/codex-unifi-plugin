# AGENTS.md

Guidance for agents working in this repository.

## Project Overview

This repository contains an unofficial Codex plugin package for Ubiquiti UniFi Network controllers.

- `.codex-plugin/plugin.json` defines plugin metadata and points Codex at the skills directory.
- `skills/unifi/SKILL.md` is the primary behavior surface for the plugin.
- `scripts/unifi_api.sh` is a small helper for authenticated UniFi Network API calls.
- `assets/` contains plugin branding assets.

The plugin is currently instructions plus a helper script. It does not define an MCP server or custom app tools.

## Secrets

- Never commit `.env`.
- Never print API tokens or credentials in responses, logs, examples, or test output.
- Read UniFi credentials from `UNIFI_URL`, `UNIFI_USERNAME`, and `UNIFI_PASSWORD`.
- Use `UNIFI_SITE` for site-scoped calls when needed.
- Use Gitleaks before publishing changes that touch scripts, docs, workflows, or examples.

## Useful Commands

Validate plugin JSON:

```bash
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
```

Validate commitlint config JSON:

```bash
python3 -m json.tool .commitlintrc.json >/dev/null
```

Lint shell scripts:

```bash
shellcheck scripts/*.sh
```

Validate plugin structure:

```bash
python3 scripts/validate_plugin.py
```

Run a local Gitleaks scan without scanning private local `.env` contents:

```bash
rsync -a --delete --exclude .git --exclude .env ./ /tmp/unifi-plugin-gitleaks-scan/
gitleaks dir /tmp/unifi-plugin-gitleaks-scan \
  --config /tmp/unifi-plugin-gitleaks-scan/.gitleaks.toml \
  --redact \
  --no-banner
```

List UniFi sites when `.env` contains the required `UNIFI_*` variables:

```bash
set -a
source .env
set +a
scripts/unifi_api.sh sites
```

## Change Guidelines

- Keep edits small and aligned with the plugin's current shape.
- Prefer improving `skills/unifi/SKILL.md` for agent behavior changes.
- Prefer improving `scripts/unifi_api.sh` for reusable API execution behavior.
- Do not add a package manager just for linting unless the repo already adopts one.
- Keep placeholder assets unless properly licensed Ubiquiti brand assets are supplied.
- Update `CHANGELOG.md` using Keep a Changelog sections for user-visible changes.
- Use conventional commits; this checkout is configured with `.gitmessage` as the local commit template.

## UniFi Safety

UniFi changes can disrupt networks. Default to read-only discovery. For any action that changes controller configuration, reboots devices, upgrades firmware, blocks clients, changes WLANs, or changes firewall/routing behavior:

1. Identify the exact target.
2. Summarize the intended request and expected effect.
3. Ask for explicit confirmation before executing.
4. Read back the changed state after execution.

## CI Expectations

GitHub Actions runs:

- Gitleaks secret scanning.
- JSON validation for plugin and commitlint config files.
- Plugin manifest, asset path, and skill frontmatter validation.
- ShellCheck for scripts.
- Required-file checks for plugin metadata, skill, script, license, changelog, and assets.
