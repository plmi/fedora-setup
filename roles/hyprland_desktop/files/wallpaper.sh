#!/usr/bin/env sh
set -eu

MODE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-mode"
WALLPAPER_DIR="$HOME/.local/share/wallpapers"
TILED_BASENAME="classic-mac-os-tile-wallpapers-4.png"

mkdir -p "$(dirname "$MODE_FILE")"

ensure_hyprpaper() {
  if ! pgrep -x hyprpaper >/dev/null 2>&1; then
    nohup hyprpaper >/dev/null 2>&1 &
  fi

  i=0
  while [ "$i" -lt 40 ]; do
    if hyprctl hyprpaper listactive >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 0.1
  done

  printf 'hyprpaper is not ready\n' >&2
  return 1
}

set_wallpaper() {
  image_path="$1"
  mode="$2"

  ensure_hyprpaper

  if [ "$mode" = "tile" ]; then
    wallpaper_arg=",tile:$image_path"
  else
    wallpaper_arg=",$image_path"
  fi

  hyprctl hyprpaper preload "$image_path" >/dev/null 2>&1 || true
  hyprctl hyprpaper wallpaper "$wallpaper_arg" >/dev/null 2>&1
  hyprctl hyprpaper unload unused >/dev/null 2>&1 || true
}

start_image() {
  image_path="$1"
  image_name="$(basename "$image_path")"

  if [ "$image_name" = "$TILED_BASENAME" ]; then
    set_wallpaper "$image_path" "tile"
  else
    set_wallpaper "$image_path" "fill"
  fi

  printf 'image:%s\n' "$image_name" > "$MODE_FILE"
}

list_images() {
  if [ ! -d "$WALLPAPER_DIR" ]; then
    return 0
  fi
  find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    | sort
}

default_image() {
  list_images | head -n1
}

next_image_after() {
  current_name="$1"
  found=0
  list_images | while IFS= read -r image; do
    image_name="$(basename "$image")"
    if [ "$found" -eq 1 ]; then
      printf '%s\n' "$image"
      exit 0
    fi
    if [ "$image_name" = "$current_name" ]; then
      found=1
    fi
  done
}

start_default_image() {
  first="$(default_image || true)"
  if [ -z "${first:-}" ]; then
    printf 'No wallpapers found in %s\n' "$WALLPAPER_DIR" >&2
    return 1
  fi
  start_image "$first"
}

toggle_mode() {
  mode_value="$(head -n1 "$MODE_FILE" 2>/dev/null | tr -d '\r' || true)"
  case "$mode_value" in
    image:*)
      current_name="${mode_value#image:}"
      next="$(next_image_after "$current_name" || true)"
      if [ -n "${next:-}" ]; then
        start_image "$next"
      else
        start_default_image
      fi
      ;;
    *)
      start_default_image
      ;;
  esac
}

case "${1:-apply}" in
  image)
    image_name="${2:-}"
    [ -n "$image_name" ] || { printf 'Usage: %s image <filename>\n' "$0" >&2; exit 1; }
    image_path="$WALLPAPER_DIR/$image_name"
    [ -f "$image_path" ] || { printf 'Image not found: %s\n' "$image_path" >&2; exit 1; }
    start_image "$image_path"
    ;;
  solid|blue|apply)
    start_default_image
    ;;
  toggle)
    toggle_mode
    ;;
  *)
    printf 'Usage: %s [apply|solid|blue|toggle|image <filename>]\n' "$0" >&2
    exit 1
    ;;
esac
