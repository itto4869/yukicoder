#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

(
    cd "$root_dir"
    cargo update -p cp_library
    cargo clean -p cp_library
)
