#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/unifi_site_manager_api.sh hosts [page_size] [next_token]
  scripts/unifi_site_manager_api.sh host <host_id>
  scripts/unifi_site_manager_api.sh sites [page_size] [next_token]
  scripts/unifi_site_manager_api.sh devices [page_size] [next_token]
  scripts/unifi_site_manager_api.sh isp-metrics <5m|1h> [duration]
  scripts/unifi_site_manager_api.sh raw <path> [key=value ...]

Environment:
  UNIFI_API_TOKEN     Required API token for api.ui.com.
  UNIFI_API_BASE_URL  Optional base URL, defaults to https://api.ui.com.

Examples:
  scripts/unifi_site_manager_api.sh hosts
  scripts/unifi_site_manager_api.sh sites 100
  scripts/unifi_site_manager_api.sh devices
  scripts/unifi_site_manager_api.sh isp-metrics 5m 24h
  scripts/unifi_site_manager_api.sh raw /v1/sites pageSize=10
USAGE
}

need_token() {
  if [[ -z "${UNIFI_API_TOKEN:-}" ]]; then
    echo "Missing required environment variable: UNIFI_API_TOKEN" >&2
    exit 2
  fi
}

request_get() {
  local path="$1"
  shift || true
  local base_url="${UNIFI_API_BASE_URL:-https://api.ui.com}"
  local curl_args=(
    --silent
    --show-error
    --fail
    --get
    "${base_url%/}/${path#/}"
    --header "Accept: application/json"
    --header "X-API-Key: ${UNIFI_API_TOKEN}"
  )
  local query_arg

  for query_arg in "$@"; do
    if [[ "$query_arg" != *=* ]]; then
      echo "Query argument must use key=value form: $query_arg" >&2
      exit 2
    fi
    curl_args+=(--data-urlencode "$query_arg")
  done

  curl "${curl_args[@]}"
  printf '\n'
}

command="${1:-}"
if [[ -z "$command" || "$command" == "-h" || "$command" == "--help" ]]; then
  usage
  exit 0
fi

need_token

case "$command" in
  hosts)
    params=()
    if [[ -n "${2:-}" ]]; then
      params+=("pageSize=$2")
    fi
    if [[ -n "${3:-}" ]]; then
      params+=("nextToken=$3")
    fi
    request_get /v1/hosts "${params[@]}"
    ;;
  host)
    host_id="${2:-}"
    if [[ -z "$host_id" ]]; then
      echo "host requires a host id" >&2
      exit 2
    fi
    request_get "/v1/hosts/$host_id"
    ;;
  sites)
    params=()
    if [[ -n "${2:-}" ]]; then
      params+=("pageSize=$2")
    fi
    if [[ -n "${3:-}" ]]; then
      params+=("nextToken=$3")
    fi
    request_get /v1/sites "${params[@]}"
    ;;
  devices)
    params=()
    if [[ -n "${2:-}" ]]; then
      params+=("pageSize=$2")
    fi
    if [[ -n "${3:-}" ]]; then
      params+=("nextToken=$3")
    fi
    request_get /v1/devices "${params[@]}"
    ;;
  isp-metrics)
    metric_type="${2:-}"
    duration="${3:-}"
    if [[ "$metric_type" != "5m" && "$metric_type" != "1h" ]]; then
      echo "isp-metrics requires metric type 5m or 1h" >&2
      exit 2
    fi
    if [[ -n "$duration" ]]; then
      request_get "/ea/isp-metrics/$metric_type" "duration=$duration"
    else
      request_get "/ea/isp-metrics/$metric_type"
    fi
    ;;
  raw)
    path="${2:-}"
    if [[ -z "$path" ]]; then
      echo "raw requires a path argument, for example /v1/sites" >&2
      exit 2
    fi
    shift 2
    request_get "$path" "$@"
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 2
    ;;
esac
