#!/usr/bin/env sh
set -eu

show_msg() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "VPN" "$1"
  else
    printf 'VPN: %s\n' "$1" >&2
  fi
}

if ! command -v nmcli >/dev/null 2>&1; then
  show_msg "nmcli is not installed."
  exit 0
fi

ACTIVE_VPN="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="vpn" || $2=="wireguard" {print $1; exit}' || true)"
if [ -n "${ACTIVE_VPN:-}" ]; then
  if nmcli connection down id "$ACTIVE_VPN" >/dev/null 2>&1; then
    show_msg "Disconnected: $ACTIVE_VPN"
  else
    show_msg "Failed to disconnect: $ACTIVE_VPN"
  fi
  exit 0
fi

VPN_CHOICES="$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2=="vpn" || $2=="wireguard" {print $1}' || true)"
if [ -z "${VPN_CHOICES:-}" ]; then
  show_msg "No VPN/WireGuard profiles found."
  exit 0
fi

if ! command -v wofi >/dev/null 2>&1; then
  show_msg "wofi is not installed."
  exit 0
fi

VPN_NAME="$(printf '%s\n' "$VPN_CHOICES" | wofi --dmenu --prompt 'VPN profile' --insensitive --cache-file /dev/null || true)"
[ -z "${VPN_NAME:-}" ] && exit 0

if nmcli connection up id "$VPN_NAME" >/dev/null 2>&1; then
  show_msg "Connected: $VPN_NAME"
else
  show_msg "Failed to connect: $VPN_NAME"
fi
