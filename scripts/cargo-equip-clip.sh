#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  cargo-equip-clip.sh <bin-name> [--manifest-path PATH] [-- extra args...]
  cargo-equip-clip.sh --bin <bin-name> [--manifest-path PATH] [-- extra args...]

Environment:
  EQUIP_MINE   Override --mine (default: github.com/itto4869)

  Notes:
  If src/bin/<bin>.rs exists, resolve the bin name from Cargo.toml.
  Over SSH, copies to the local terminal clipboard using OSC 52.
  On WSL, uses clip.exe to copy to the Windows clipboard.
  Otherwise, uses pbcopy, wl-copy, xclip, or xsel.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

bin_name=""
manifest_path=""
extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--manifest-path)
      manifest_path="${2:-}"
      shift 2
      ;;
    --bin)
      bin_name="${2:-}"
      shift 2
      ;;
    --)
      shift
      extra_args+=("$@")
      break
      ;;
    -*)
      extra_args+=("$1")
      shift
      ;;
    *)
      if [[ -z "$bin_name" ]]; then
        bin_name="$1"
      else
        extra_args+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ -z "$bin_name" ]]; then
  echo "error: bin name is required" >&2
  usage >&2
  exit 1
fi

manifest_dir="."
if [[ -n "$manifest_path" ]]; then
  manifest_dir="$(dirname "$manifest_path")"
fi

if [[ -f "$manifest_dir/src/bin/${bin_name}.rs" ]]; then
  manifest_file="$manifest_path"
  if [[ -z "$manifest_file" ]]; then
    manifest_file="$manifest_dir/Cargo.toml"
  fi

  if [[ ! -f "$manifest_file" ]]; then
    echo "error: Cargo.toml not found at $manifest_file" >&2
    exit 1
  fi

  resolved_bin="$(
    cargo metadata --no-deps --format-version 1 --manifest-path "$manifest_file" |
      python3 -c '
import json, pathlib, sys
source = pathlib.Path(sys.argv[1]).resolve()
for package in json.load(sys.stdin)["packages"]:
    for target in package["targets"]:
        if "bin" in target["kind"] and pathlib.Path(target["src_path"]).resolve() == source:
            print(target["name"])
            sys.exit(0)
sys.exit("error: matching binary target not found")
' "$manifest_dir/src/bin/${bin_name}.rs"
  )"

  if [[ -z "$resolved_bin" ]]; then
    echo "error: failed to resolve bin name for src/bin/${bin_name}.rs in $manifest_file" >&2
    exit 1
  fi

  bin_name="$resolved_bin"
fi

copy_with_osc52() {
  local encoded
  encoded="$(base64 | tr -d '\r\n')"

  # tmux requires the OSC sequence to be wrapped in a passthrough sequence.
  if [[ -n "${TMUX:-}" ]]; then
    printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "$encoded" > /dev/tty
  else
    printf '\033]52;c;%s\a' "$encoded" > /dev/tty
  fi
}

copy_with_windows_clip() {
  # clip.exe accepts UTF-16LE; preserve Japanese comments and other Unicode.
  iconv -f UTF-8 -t UTF-16LE | clip.exe
}

if [[ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]]; then
  if [[ ! -w /dev/tty ]]; then
    echo "error: OSC 52 requires a terminal (/dev/tty is not writable)" >&2
    exit 1
  fi
  clip_cmd=(copy_with_osc52)
  clip_description="local clipboard via OSC 52"
elif [[ -r /proc/sys/kernel/osrelease ]] &&
     grep -qi microsoft /proc/sys/kernel/osrelease &&
     command -v clip.exe >/dev/null 2>&1; then
  clip_cmd=(copy_with_windows_clip)
  clip_description="Windows clipboard via clip.exe"
elif command -v pbcopy >/dev/null 2>&1; then
  clip_cmd=(pbcopy)
  clip_description="clipboard via pbcopy"
elif command -v wl-copy >/dev/null 2>&1; then
  clip_cmd=(wl-copy)
  clip_description="clipboard via wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  clip_cmd=(xclip -selection clipboard)
  clip_description="clipboard via xclip"
elif command -v xsel >/dev/null 2>&1; then
  clip_cmd=(xsel --clipboard --input)
  clip_description="clipboard via xsel"
else
  echo "error: clipboard command not found (pbcopy, wl-copy, xclip, xsel)" >&2
  exit 1
fi

equip_args=(
  --exclude proconio num itertools ac-library-rs
  --remove docs
  --minify libs
  --bin "$bin_name"
  --mine "${EQUIP_MINE:-github.com/itto4869}"
)

if [[ -n "$manifest_path" ]]; then
  equip_args+=(--manifest-path "$manifest_path")
fi

equip_args+=("${extra_args[@]}")

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

cargo equip "${equip_args[@]}" > "$tmpfile"
"${clip_cmd[@]}" < "$tmpfile" >/dev/null

bytes="$(wc -c <"$tmpfile" | tr -d ' ')"
echo "Copied ${bytes} bytes to ${clip_description}."
