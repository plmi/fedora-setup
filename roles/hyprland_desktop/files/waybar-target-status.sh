#!/usr/bin/env sh
set -eu

TARGET_FILE="$HOME/.target"
TARGET_NAME_FILE="$HOME/.target_name"
if [ -f "$TARGET_FILE" ]; then
  TARGET="$(head -n1 "$TARGET_FILE" | tr -d '\r')"
  if [ -n "$TARGET" ] && [ "$TARGET" != "unset" ]; then
    TARGET_NAME=""
    if [ -f "$TARGET_NAME_FILE" ]; then
      TARGET_NAME="$(head -n1 "$TARGET_NAME_FILE" | tr -d '\r')"
    fi
    if [ -n "$TARGET_NAME" ] && [ "$TARGET_NAME" != "unset" ]; then
      printf '{"text":"Target %s","class":"active","tooltip":"Name: %s\nIP: %s"}\n' "$TARGET_NAME" "$TARGET_NAME" "$TARGET"
    else
      printf '{"text":"Target %s","class":"active","tooltip":"IP: %s"}\n' "$TARGET" "$TARGET"
    fi
    exit 0
  fi
fi
printf '{"text":"No Target","class":"missing","tooltip":"Set target with: target 10.10.10.10"}\n'
