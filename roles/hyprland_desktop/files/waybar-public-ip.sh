#!/usr/bin/env sh
set -eu

get_ip() {
  curl -4fsS --max-time 2 https://api.ipify.org 2>/dev/null || true
}

IP="$(get_ip)"
[ -z "$IP" ] && IP="unknown"

if [ "${1:-}" = "--once" ]; then
  printf 'Public IP: %s\n' "$IP"
  exit 0
fi

printf '{"text":"IP %s","class":"info","tooltip":"Public egress IP: %s"}\n' "$IP" "$IP"
