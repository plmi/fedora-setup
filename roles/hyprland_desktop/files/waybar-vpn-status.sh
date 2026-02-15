#!/usr/bin/env sh
set -eu

VPN_IF="$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(tun|tap|wg|ppp)[0-9]*$' | head -n1 || true)"
if [ -n "$VPN_IF" ]; then
  ADDR="$(ip -4 -o addr show dev "$VPN_IF" 2>/dev/null | awk '{print $4}' | head -n1 || true)"
  [ -z "$ADDR" ] && ADDR="no-ip"
  printf '{"text":"VPN %s","class":"connected","tooltip":"VPN interface: %s\\nAddress: %s"}\n' "$VPN_IF" "$VPN_IF" "$ADDR"
else
  printf '{"text":"VPN down","class":"disconnected","tooltip":"No tun/tap/wg/ppp interface is up"}\n'
fi
