#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)
spec42_dir=${SPEC42_DIR:-"$root_dir/../spec42"}
update_snapshots=${UPDATE_EXAMPLE_SNAPSHOTS:-0}
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
while IFS= read -r source; do
	example_count=$((example_count + 1))
	example_dir=$(dirname "$source")
	example_name=$(basename "$example_dir")
	script_name=$(basename "${source%.roc}")
	model="$example_dir/model.sysml"
	if [[ ! -f "$model" ]]; then
		echo "error: $source has no sibling model.sysml" >&2
		exit 1
	fi

	rewritten_dir="$work_dir/examples/$example_name"
	mkdir -p "$rewritten_dir"
	rewritten="$rewritten_dir/$(basename "$source")"
	sed "s#spec42: platform \"[^\"]*\"#spec42: platform \"$bundle_url\"#" "$source" >"$rewritten"
	if ! rg -q -F "spec42: platform \"$bundle_url\"" "$rewritten"; then
		echo "error: failed to rewrite platform header in $source" >&2
		exit 1
	fi

	plugin="$work_dir/${example_name}_${script_name}.wasm"
	generated="$work_dir/generated/$example_name/$script_name"
	ROC_CACHE_DIR="$cache_dir" roc build "$rewritten" --output="$plugin"

	cargo run \
		--manifest-path "$spec42_dir/Cargo.toml" \
		-p server \
		--bin spec42 \
		--no-default-features \
		-- \
		--no-stdlib \
		generate "$plugin" "$model" \
		--output "$generated" \
		-- scenario="$example_name" script="$script_name"
	case "$example_name/$script_name" in
		electric_vehicle/bom_csv) expected="electric-vehicle-bom.csv"; evidence="EV-BAT-82" ;;
		electric_vehicle/engineering_dashboard) expected="engineering-dashboard.html"; evidence="DrivingRangeRequirement" ;;
		electric_vehicle/vcrm_csv) expected="electric-vehicle-vcrm.csv"; evidence="RangeCertificationTest" ;;
		ground_station/icd_csv) expected="ground-station-icd.csv"; evidence="SpaceLinkPort" ;;
		ground_station/network_graph) expected="ground-station-interface-network.dot"; evidence="MissionControlSystem" ;;
		ground_station/operations_dashboard) expected="ground-station-operations.html"; evidence="PublishProducts" ;;
		warehouse_robot/simulation_manifest) expected="warehouse-robot-simulation.json"; evidence="MissionAssigned" ;;
		warehouse_robot/state_explorer) expected="warehouse-robot-state-explorer.html"; evidence="navigatingToPick" ;;
		warehouse_robot/state_graph) expected="warehouse-robot-state-machine.dot"; evidence='"booting" -> "idle"' ;;
		*) echo "error: no output assertion for $example_name/$script_name" >&2; exit 1 ;;
	esac
	artifact="$generated/$expected"
	if [[ ! -s "$artifact" ]]; then
		echo "error: $example_name/$script_name did not emit non-empty $expected" >&2
		exit 1
	fi
	if ! rg -q -F "$evidence" "$artifact"; then
		echo "error: $expected does not contain expected model evidence: $evidence" >&2
		exit 1
	fi
	snapshot="$example_dir/output/$expected"
	if [[ "$update_snapshots" == "1" ]]; then
		mkdir -p "$example_dir/output"
		cp "$artifact" "$snapshot"
		echo "Updated $example_name/output/$expected"
	elif [[ ! -f "$snapshot" ]]; then
		echo "error: missing golden snapshot $snapshot" >&2
		echo "run scripts/update-example-snapshots.sh to create it" >&2
		exit 1
	elif ! cmp -s "$snapshot" "$artifact"; then
		echo "error: generated output differs from $snapshot" >&2
		diff -u "$snapshot" "$artifact" || true
		echo "run scripts/update-example-snapshots.sh to accept an intentional change" >&2
		exit 1
	else
		echo "Verified $example_name/$script_name -> $expected (golden match)"
	fi
done < <(rg --files "$root_dir/examples" --glob '*.roc' | sort)

if [[ "$example_count" -eq 0 ]]; then
	echo "error: no Roc examples found" >&2
	exit 1
fi

if [[ "$example_count" -ne 9 ]]; then
	echo "error: expected 9 model/script combinations, found $example_count" >&2
	exit 1
fi

roc docs "$root_dir/platform/main.roc" --output="$work_dir/docs" --no-cache
test -s "$work_dir/docs/Model/index.html"
if tr -d '\000' <"$work_dir/docs/Model/index.html" | rg -q 'Model\.to_summary|Model\.to_detail'; then
	echo "error: internal model conversion helpers leaked into public docs" >&2
	exit 1
fi

if [[ "$update_snapshots" == "1" ]]; then
	echo "roc-spec42 example snapshots regenerated"
else
	echo "roc-spec42 packaged end-to-end test passed"
fi
