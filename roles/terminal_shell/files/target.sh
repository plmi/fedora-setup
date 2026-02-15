#!/usr/bin/env sh
set -eu

TARGET_IP_FILE="${HOME}/.target"
TARGET_NAME_FILE="${HOME}/.target_name"

usage() {
  cat <<'EOF'
Usage:
  target <ip> [name]    Set current target IP and optional machine/lab name
  target --name <name>  Update machine/lab name for current target
  target --show         Show current target
  target --clear        Clear current target
EOF
}

case "${1:-}" in
  --show|-s)
    IP="unset"
    NAME="unset"
    [ -f "$TARGET_IP_FILE" ] && IP="$(head -n1 "$TARGET_IP_FILE")"
    [ -f "$TARGET_NAME_FILE" ] && NAME="$(head -n1 "$TARGET_NAME_FILE")"
    echo "IP: $IP"
    echo "Name: $NAME"
    exit 0
    ;;
  --name)
    [ "${2:-}" ] || { usage; exit 1; }
    printf '%s\n' "$2" > "$TARGET_NAME_FILE"
    echo "Target name set: $2"
    exit 0
    ;;
  --clear|-c)
    printf 'unset\n' > "$TARGET_IP_FILE"
    printf 'unset\n' > "$TARGET_NAME_FILE"
    echo "Target cleared"
    exit 0
    ;;
  --help|-h|"")
    usage
    exit 0
    ;;
esac

printf '%s\n' "$1" > "$TARGET_IP_FILE"
if [ -n "${2:-}" ]; then
  printf '%s\n' "$2" > "$TARGET_NAME_FILE"
  echo "Target set: $1 ($2)"
else
  printf 'unset\n' > "$TARGET_NAME_FILE"
  echo "Target set: $1"
fi
