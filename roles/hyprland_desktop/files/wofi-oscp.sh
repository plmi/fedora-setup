#!/usr/bin/env sh
set -eu

TARGET_FILE="$HOME/.target"
TARGET_NAME_FILE="$HOME/.target_name"
BASE_DIR="$HOME/oscp"
TARGETS_DIR="$BASE_DIR/targets"

mkdir -p "$TARGETS_DIR"

read_target() {
  if [ -f "$TARGET_FILE" ]; then
    t="$(head -n1 "$TARGET_FILE" | tr -d '\r')"
    if [ -n "$t" ] && [ "$t" != "unset" ]; then
      printf '%s\n' "$t"
      return 0
    fi
  fi
  return 1
}

read_target_name() {
  if [ -f "$TARGET_NAME_FILE" ]; then
    t="$(head -n1 "$TARGET_NAME_FILE" | tr -d '\r')"
    if [ -n "$t" ] && [ "$t" != "unset" ]; then
      printf '%s\n' "$t"
      return 0
    fi
  fi
  return 1
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/_/g; s/^_+//; s/_+$//; s/_+/_/g'
}

show_msg() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "OSCP" "$1"
  else
    printf 'OSCP: %s\n' "$1" >&2
  fi
}

need_target() {
  if ! IP="$(read_target)"; then
    show_msg "No target set. Use: target <ip> [lab-or-machine-name]"
    exit 0
  fi
  if TARGET_NAME="$(read_target_name)"; then
    :
  else
    TARGET_NAME="$IP"
  fi
  TARGET_KEY="$(slugify "$TARGET_NAME")"
  [ -n "$TARGET_KEY" ] || TARGET_KEY="$(slugify "$IP")"
  TARGET_DIR="$TARGETS_DIR/$TARGET_KEY"
  SCANS_DIR="$TARGET_DIR/scans"
  LOOT_DIR="$TARGET_DIR/loot"
  REPORTS_DIR="$TARGET_DIR/reports"
  NOTES_DIR="$TARGET_DIR/notes"
  mkdir -p "$SCANS_DIR" "$LOOT_DIR" "$REPORTS_DIR" "$NOTES_DIR"
  export IP TARGET_NAME TARGET_KEY TARGET_DIR SCANS_DIR LOOT_DIR REPORTS_DIR NOTES_DIR
}

choose() {
  printf '%s\n' \
    "Target: set/update" \
    "VPN: toggle connection" \
    "Recon: nmap quick (top 1000)" \
    "Recon: nmap full (-p-)" \
    "Web: feroxbuster (http)" \
    "Web: nikto (http)" \
    "Web: whatweb (http)" \
    "Pivot: add hosts entry" \
    "Pivot: ssh command" \
    "Pivot: xfreerdp command" \
    "Pivot: evil-winrm command" \
    "Notes: new target note" \
    "Notes: open notes dir" \
    "Report: capture evidence screenshot" \
  | wofi --dmenu --prompt "OSCP" --insensitive --cache-file /dev/null
}

set_target() {
  NEW_IP="$(prompt_text 'Target IP')"
  [ -z "${NEW_IP:-}" ] && exit 0
  NEW_NAME="$(prompt_text 'Target Name (Lab/Machine)')"
  printf '%s\n' "$NEW_IP" > "$TARGET_FILE"
  if [ -n "${NEW_NAME:-}" ]; then
    printf '%s\n' "$NEW_NAME" > "$TARGET_NAME_FILE"
    show_msg "Target set: $NEW_NAME ($NEW_IP)"
  else
    printf 'unset\n' > "$TARGET_NAME_FILE"
    show_msg "Target set: $NEW_IP"
  fi
}

prompt_text() {
  PROMPT="$1"
  printf '' | wofi --dmenu --prompt "$PROMPT" --cache-file /dev/null
}

prompt_text_default() {
  PROMPT="$1"
  DEFAULT_VALUE="$2"
  wofi --dmenu --prompt "$PROMPT" --cache-file /dev/null --search "$DEFAULT_VALUE"
}

new_note() {
  need_target
  NOTE_PATH="$NOTES_DIR/main.md"
  if [ ! -f "$NOTE_PATH" ]; then
    cat > "$NOTE_PATH" <<EOF
# Target: $TARGET_NAME
IP: $IP

## Recon

## Enumeration

## Exploitation

## Privilege Escalation

## Proof

## Notes
EOF
  fi
  foot -e nvim "$NOTE_PATH"
}

capture_evidence() {
  need_target
  TS="$(date +%Y%m%d-%H%M%S)"
  EVIDENCE_DIR="$REPORTS_DIR/evidence"
  FILE="$EVIDENCE_DIR/${TS}.png"
  mkdir -p "$EVIDENCE_DIR"

  if grim -g "$(slurp)" "$FILE"; then
    show_msg "Evidence saved: $FILE"
  else
    show_msg "Screenshot canceled."
  fi
}

add_hosts_entry() {
  DEFAULT_IP=""
  if DEFAULT_IP="$(read_target)"; then
    :
  else
    DEFAULT_IP=""
  fi
  DEFAULT_ALIAS=""
  if DEFAULT_ALIAS="$(read_target_name)"; then
    :
  else
    DEFAULT_ALIAS=""
  fi

  if [ -n "$DEFAULT_IP" ]; then
    HOST_IP="$(prompt_text_default "Hosts IP" "$DEFAULT_IP")"
    [ -z "${HOST_IP:-}" ] && HOST_IP="$DEFAULT_IP"
  else
    HOST_IP="$(prompt_text 'Hosts IP (e.g. 10.10.10.10)')"
  fi
  [ -z "${HOST_IP:-}" ] && { show_msg "No IP provided."; exit 0; }

  if [ -n "$DEFAULT_ALIAS" ]; then
    HOST_ALIAS="$(prompt_text_default "Hosts Alias" "$DEFAULT_ALIAS")"
    [ -z "${HOST_ALIAS:-}" ] && HOST_ALIAS="$DEFAULT_ALIAS"
  else
    HOST_ALIAS="$(prompt_text 'Hosts alias (e.g. dc01.local)')"
  fi
  [ -z "${HOST_ALIAS:-}" ] && exit 0

  ENTRY="$HOST_IP $HOST_ALIAS"
  if grep -Eq "^[[:space:]]*${HOST_IP}[[:space:]]+${HOST_ALIAS}([[:space:]]+|$)" /etc/hosts 2>/dev/null; then
    show_msg "Hosts entry already exists: $ENTRY"
    return 0
  fi

  if sudo -n sh -c "printf '%s\n' \"$ENTRY\" >> /etc/hosts" 2>/dev/null; then
    show_msg "Added hosts entry: $ENTRY"
    return 0
  fi

  # Fallback: prompt for sudo password in terminal.
  foot -e sh -lc "printf '%s\n' '$ENTRY' | sudo tee -a /etc/hosts >/dev/null && notify-send 'OSCP' 'Added hosts entry: $ENTRY' || notify-send 'OSCP' 'Failed to add hosts entry'"
}

copy_cmd() {
  CMD="$1"
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$CMD" | wl-copy
    show_msg "Copied to clipboard:\n$CMD"
  else
    show_msg "wl-copy is not installed.\n\n$CMD"
  fi
}

toggle_vpn_connection() {
  if ! command -v nmcli >/dev/null 2>&1; then
    show_msg "nmcli is not installed."
    return 0
  fi

  ACTIVE_VPN="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="vpn" || $2=="wireguard" {print $1; exit}' || true)"
  if [ -n "${ACTIVE_VPN:-}" ]; then
    if nmcli connection down id "$ACTIVE_VPN" >/dev/null 2>&1; then
      show_msg "VPN disconnected: $ACTIVE_VPN"
    else
      show_msg "Failed to disconnect VPN: $ACTIVE_VPN"
    fi
    return 0
  fi

  VPN_CHOICES="$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2=="vpn" || $2=="wireguard" {print $1}' || true)"
  if [ -z "${VPN_CHOICES:-}" ]; then
    show_msg "No VPN/WireGuard NetworkManager profiles found."
    return 0
  fi

  VPN_NAME="$(printf '%s\n' "$VPN_CHOICES" | wofi --dmenu --prompt 'VPN profile' --insensitive --cache-file /dev/null || true)"
  [ -z "${VPN_NAME:-}" ] && return 0

  if nmcli connection up id "$VPN_NAME" >/dev/null 2>&1; then
    show_msg "VPN connected: $VPN_NAME"
  else
    show_msg "Failed to connect VPN: $VPN_NAME"
  fi
}

ACTION="$(choose || true)"
[ -z "${ACTION:-}" ] && exit 0

case "$ACTION" in
  "Target: set/update")
    set_target
    ;;
  "VPN: toggle connection")
    toggle_vpn_connection
    ;;
  "Recon: nmap quick (top 1000)")
    need_target
    copy_cmd "nmap -sC -sV -Pn --top-ports 1000 $IP -oA $SCANS_DIR/${IP}_quick"
    ;;
  "Recon: nmap full (-p-)")
    need_target
    copy_cmd "nmap -sC -sV -Pn -p- $IP -oA $SCANS_DIR/${IP}_full"
    ;;
  "Web: feroxbuster (http)")
    need_target
    copy_cmd "feroxbuster -u http://$IP -o $SCANS_DIR/${IP}_ferox.txt"
    ;;
  "Web: nikto (http)")
    need_target
    copy_cmd "nikto -h http://$IP -output $SCANS_DIR/${IP}_nikto.txt"
    ;;
  "Web: whatweb (http)")
    need_target
    copy_cmd "whatweb http://$IP | tee $SCANS_DIR/${IP}_whatweb.txt"
    ;;
  "Pivot: add hosts entry")
    add_hosts_entry
    ;;
  "Pivot: ssh command")
    need_target
    copy_cmd "ssh $IP"
    ;;
  "Pivot: xfreerdp command")
    need_target
    copy_cmd "xfreerdp /v:$IP /u:Administrator /cert:ignore"
    ;;
  "Pivot: evil-winrm command")
    need_target
    copy_cmd "evil-winrm -i $IP -u Administrator -p '<password>'"
    ;;
  "Notes: new target note")
    new_note
    ;;
  "Notes: open notes dir")
    need_target
    foot -e sh -lc "cd \"$NOTES_DIR\" && nvim ."
    ;;
  "Report: capture evidence screenshot")
    capture_evidence
    ;;
esac
