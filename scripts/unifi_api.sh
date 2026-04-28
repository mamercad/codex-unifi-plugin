#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/unifi_api.sh sites
  scripts/unifi_api.sh devices
  scripts/unifi_api.sh clients
  scripts/unifi_api.sh health
  scripts/unifi_api.sh raw <path>

Environment:
  UNIFI_URL       Base controller URL, for example https://192.168.1.1
  UNIFI_USERNAME  UniFi username
  UNIFI_PASSWORD  UniFi password
  UNIFI_SITE      Site name, defaults to default
  UNIFI_INSECURE  Set to 1 to skip TLS verification
USAGE
}

need_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 2
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

request() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local curl_args=()

  if [[ "${UNIFI_INSECURE:-}" == "1" ]]; then
    curl_args+=("--insecure")
  fi

  if [[ -n "$data" ]]; then
    curl_args+=("--header" "Content-Type: application/json" "--data" "$data")
  fi

  curl --silent --show-error --fail \
    "${curl_args[@]}" \
    --cookie "$COOKIE_JAR" \
    --cookie-jar "$COOKIE_JAR" \
    --request "$method" \
    "${UNIFI_URL%/}${path}"
}

login() {
  local username password payload
  username="$(json_escape "$UNIFI_USERNAME")"
  password="$(json_escape "$UNIFI_PASSWORD")"
  payload="{\"username\":\"${username}\",\"password\":\"${password}\"}"

  if request POST "/api/auth/login" "$payload" >/dev/null 2>&1; then
    API_PREFIX="/proxy/network/api"
    return
  fi

  if request POST "/api/login" "$payload" >/dev/null 2>&1; then
    API_PREFIX="/api"
    return
  fi

  echo "Unable to log in to UniFi controller at ${UNIFI_URL}" >&2
  exit 1
}

site_path() {
  printf '%s/s/%s/%s' "$API_PREFIX" "${UNIFI_SITE:-default}" "$1"
}

command="${1:-}"
if [[ -z "$command" || "$command" == "-h" || "$command" == "--help" ]]; then
  usage
  exit 0
fi

need_env UNIFI_URL
need_env UNIFI_USERNAME
need_env UNIFI_PASSWORD

COOKIE_JAR="$(mktemp "${TMPDIR:-/tmp}/unifi-cookie.XXXXXX")"
trap 'rm -f "$COOKIE_JAR"' EXIT
API_PREFIX=""

login

case "$command" in
  sites)
    request GET "${API_PREFIX}/self/sites"
    ;;
  devices)
    request GET "$(site_path stat/device)"
    ;;
  clients)
    request GET "$(site_path stat/sta)"
    ;;
  health)
    request GET "$(site_path stat/health)"
    ;;
  raw)
    path="${2:-}"
    if [[ -z "$path" ]]; then
      echo "raw requires a path argument" >&2
      exit 2
    fi
    request GET "$path"
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 2
    ;;
esac
