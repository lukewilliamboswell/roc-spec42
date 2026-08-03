#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)
rust_glue=${ROC_RUST_GLUE:-}

if [[ -z "$rust_glue" || ! -f "$rust_glue" ]]; then
	echo "error: set ROC_RUST_GLUE to Roc's RustGlue.roc" >&2
	exit 1
fi

cache_dir=$(mktemp -d "/tmp/roc-spec42-glue.XXXXXX")
trap 'rm -rf "$cache_dir"' EXIT
output_dir="$cache_dir/output"
mkdir -p "$output_dir"

ROC_CACHE_DIR="$cache_dir" roc glue --no-cache "$rust_glue" "$output_dir" "$root_dir/platform/main.roc"
cp "$output_dir/roc_platform_abi.rs" "$root_dir/src/roc_platform_abi.rs"
