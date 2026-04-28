#!/usr/bin/env python3
"""Validate a Codex plugin repository structure."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / ".codex-plugin" / "plugin.json"


def fail(message: str) -> None:
  print(f"validate_plugin.py: {message}", file=sys.stderr)
  raise SystemExit(1)


def load_manifest() -> dict:
  try:
    with MANIFEST_PATH.open() as handle:
      payload = json.load(handle)
  except FileNotFoundError:
    fail(f"missing {MANIFEST_PATH.relative_to(ROOT)}")
  except json.JSONDecodeError as error:
    fail(f"invalid manifest JSON: {error}")

  if not isinstance(payload, dict):
    fail("manifest must be a JSON object")
  return payload


def require_string(payload: dict, key: str) -> str:
  value = payload.get(key)
  if not isinstance(value, str) or not value.strip():
    fail(f"manifest field {key!r} must be a non-empty string")
  return value


def require_url(payload: dict, key: str) -> None:
  value = require_string(payload, key)
  parsed = urlparse(value)
  if parsed.scheme != "https" or not parsed.netloc:
    fail(f"manifest field {key!r} must be an https URL")


def require_relative_path(value: str, field_name: str) -> Path:
  if not value.startswith("./"):
    fail(f"manifest field {field_name!r} must be relative and start with ./")

  target = (ROOT / value[2:]).resolve()
  try:
    target.relative_to(ROOT)
  except ValueError:
    fail(f"manifest field {field_name!r} points outside the plugin root")
  return target


def validate_manifest(payload: dict) -> str:
  name = require_string(payload, "name")
  if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
    fail("manifest name must be kebab-case")

  require_string(payload, "version")
  require_string(payload, "description")
  require_string(payload, "license")
  if payload["license"] != "MIT":
    fail("manifest license must be MIT")
  require_url(payload, "homepage")
  require_url(payload, "repository")

  skills_path = require_relative_path(require_string(payload, "skills"), "skills")
  if not skills_path.is_dir():
    fail("manifest skills path must point to an existing directory")

  interface = payload.get("interface")
  if not isinstance(interface, dict):
    fail("manifest interface must be an object")

  for key in (
    "displayName",
    "shortDescription",
    "longDescription",
    "developerName",
    "category",
    "brandColor",
  ):
    require_string(interface, key)

  for key in ("websiteURL", "privacyPolicyURL", "termsOfServiceURL"):
    require_url(interface, key)

  if not re.fullmatch(r"#[0-9A-Fa-f]{6}", interface["brandColor"]):
    fail("interface.brandColor must be a hex color")

  for key in ("composerIcon", "logo"):
    asset_path = require_relative_path(require_string(interface, key), f"interface.{key}")
    if not asset_path.is_file():
      fail(f"interface.{key} points to a missing file")

  capabilities = interface.get("capabilities")
  if not isinstance(capabilities, list) or not capabilities:
    fail("interface.capabilities must be a non-empty array")
  if not all(isinstance(item, str) and item.strip() for item in capabilities):
    fail("interface.capabilities entries must be non-empty strings")

  prompts = interface.get("defaultPrompt")
  if not isinstance(prompts, list) or not (1 <= len(prompts) <= 3):
    fail("interface.defaultPrompt must include one to three prompts")
  for prompt in prompts:
    if not isinstance(prompt, str) or not prompt.strip():
      fail("interface.defaultPrompt entries must be non-empty strings")
    if len(prompt) > 128:
      fail("interface.defaultPrompt entries must be at most 128 characters")

  screenshots = interface.get("screenshots", [])
  if not isinstance(screenshots, list):
    fail("interface.screenshots must be an array")
  for screenshot in screenshots:
    if not isinstance(screenshot, str):
      fail("interface.screenshots entries must be strings")
    screenshot_path = require_relative_path(screenshot, "interface.screenshots")
    if screenshot_path.suffix.lower() != ".png":
      fail("interface.screenshots entries must be PNG files")
    if not screenshot_path.is_file():
      fail(f"missing screenshot: {screenshot}")

  return name


def validate_skill(plugin_name: str) -> None:
  skill_path = ROOT / "skills" / plugin_name / "SKILL.md"
  if not skill_path.is_file():
    fail(f"missing {skill_path.relative_to(ROOT)}")

  content = skill_path.read_text()
  if not content.startswith("---\n"):
    fail("skill must start with YAML frontmatter")

  try:
    _, frontmatter, _ = content.split("---", 2)
  except ValueError:
    fail("skill frontmatter must be closed")

  if f"\nname: {plugin_name}\n" not in f"\n{frontmatter}":
    fail(f"skill frontmatter must include name: {plugin_name}")
  if "\ndescription:" not in f"\n{frontmatter}":
    fail("skill frontmatter must include a description")


def main() -> None:
  validate_skill(validate_manifest(load_manifest()))
  print("Plugin validation passed.")


if __name__ == "__main__":
  main()
