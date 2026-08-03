#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)
host="$root_dir/platform/targets/wasm32/host.wasm"

if [[ ! -f "$host" ]]; then
	echo "error: missing $host; run scripts/build-host.sh first" >&2
	exit 1
fi

mkdir -p "$root_dir/dist"
roc bundle \
	"$root_dir/platform/main.roc" \
	"$root_dir/platform/Model.roc" \
	"$root_dir/platform/HostModel.roc" \
	"$root_dir/platform/Artifacts.roc" \
	"$root_dir/platform/Diagnostics.roc" \
	"$root_dir/platform/HostDiagnostics.roc" \
	"$host" \
	--output-dir "$root_dir/dist"
