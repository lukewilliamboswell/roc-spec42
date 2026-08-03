#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)
spec42_dir=${SPEC42_DIR:-"$root_dir/../spec42"}
work_dir=$(mktemp -d "$root_dir/.bundle-url-test.XXXXXX")
cache_dir=$(mktemp -d "/tmp/roc-spec42-cache.XXXXXX")
server_pid=""

cleanup() {
	if [[ -n "$server_pid" ]]; then
		kill "$server_pid" 2>/dev/null || true
		wait "$server_pid" 2>/dev/null || true
	fi
	rm -rf "$work_dir" "$cache_dir"
}
trap cleanup EXIT

"$root_dir/scripts/build-host.sh"

bundle_output=$("$root_dir/scripts/bundle.sh")
echo "$bundle_output"
bundle_path=$(printf '%s\n' "$bundle_output" | awk '/^Created:/ { print $2; exit }')
if [[ -z "$bundle_path" || ! -f "$bundle_path" ]]; then
	echo "error: bundle command did not produce a readable archive" >&2
	exit 1
fi

port_file="$work_dir/http-port"
python3 "$root_dir/scripts/serve-bundle.py" "$(dirname "$bundle_path")" "$port_file" &
server_pid=$!
for _ in {1..100}; do
	if [[ -s "$port_file" ]]; then
		break
	fi
	sleep 0.1
done
if [[ ! -s "$port_file" ]]; then
	echo "error: local bundle server did not start" >&2
	exit 1
fi

bundle_url="http://127.0.0.1:$(<"$port_file")/$(basename "$bundle_path")"
curl --fail --silent --show-error --head "$bundle_url" >/dev/null
echo "Testing examples against packaged platform: $bundle_url"

mkdir -p "$work_dir/examples"
example_count=0
for source in "$root_dir"/examples/*.roc; do
	[[ -f "$source" ]] || continue
	example_count=$((example_count + 1))
	rewritten="$work_dir/examples/$(basename "$source")"
	sed "s#spec42: platform \"[^\"]*\"#spec42: platform \"$bundle_url\"#" "$source" >"$rewritten"
	if ! rg -q -F "spec42: platform \"$bundle_url\"" "$rewritten"; then
		echo "error: failed to rewrite platform header in $source" >&2
		exit 1
	fi

	plugin="$work_dir/$(basename "${source%.roc}").wasm"
	generated="$work_dir/generated/$(basename "${source%.roc}")"
	ROC_CACHE_DIR="$cache_dir" roc build "$rewritten" --output="$plugin"

	cargo run \
		--manifest-path "$spec42_dir/Cargo.toml" \
		-p server \
		--bin spec42 \
		--no-default-features \
		-- \
		--no-stdlib \
		generate "$plugin" "$root_dir/test/fixtures/model.sysml" \
		--output "$generated" \
		-- target=roc
	test -s "$generated/summary.txt"
done

if [[ "$example_count" -eq 0 ]]; then
	echo "error: no Roc examples found" >&2
	exit 1
fi

roc docs "$root_dir/platform/main.roc" --output="$work_dir/docs" --no-cache
test -s "$work_dir/docs/Model/index.html"
if tr -d '\000' <"$work_dir/docs/Model/index.html" | rg -q 'Model\.to_summary|Model\.to_detail'; then
	echo "error: internal model conversion helpers leaked into public docs" >&2
	exit 1
fi

echo "roc-spec42 packaged end-to-end test passed"
