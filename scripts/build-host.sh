#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)
archive="$root_dir/target/wasm32-unknown-unknown/release/libhost.a"
output="$root_dir/platform/targets/wasm32/host.wasm"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/roc-spec42-host.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

cargo build --manifest-path "$root_dir/Cargo.toml" --release --target wasm32-unknown-unknown

mkdir -p "$work_dir/members"
zig ar x --output "$work_dir/members" "$archive"

rsp="$work_dir/members.rsp"
wasm_members=0
while IFS= read -r -d '' member; do
	magic=$(od -An -tx1 -N4 "$member" | tr -d ' \n')
	if [[ "$magic" == "0061736d" ]]; then
		printf '"%s"\n' "$member" >> "$rsp"
		wasm_members=$((wasm_members + 1))
	fi
done < <(find "$work_dir/members" -type f -print0)

if [[ "$wasm_members" -eq 0 ]]; then
	echo "error: Rust static library contained no WebAssembly object members" >&2
	exit 1
fi

zig ar rcs "$work_dir/host-wasm-only.a" "@$rsp"
mkdir -p "$(dirname "$output")"
ZIG_LOCAL_CACHE_DIR="$work_dir/zig-local-cache" \
	ZIG_GLOBAL_CACHE_DIR="$work_dir/zig-global-cache" \
	zig wasm-ld -r --whole-archive "$work_dir/host-wasm-only.a" -o "$output"

echo "Built $output from $wasm_members WebAssembly object members"
