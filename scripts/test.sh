#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)
spec42_dir=${SPEC42_DIR:-"$root_dir/../spec42"}
update_snapshots=${UPDATE_EXAMPLE_SNAPSHOTS:-0}
work_dir=$(mktemp -d "$root_dir/.bundle-url-test.XXXXXX")
cache_dir=$(mktemp -d "/tmp/roc-spec42-cache.XXXXXX")
server_pid=""

cleanup() {
	status=$?
	if [[ -n "$server_pid" ]]; then
		kill "$server_pid" 2>/dev/null || true
		wait "$server_pid" 2>/dev/null || true
	fi
	rm -rf "$work_dir" "$cache_dir"
	return "$status"
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
	for imported_file in "$example_dir"/*.html; do
		if [[ -f "$imported_file" ]]; then
			cp "$imported_file" "$rewritten_dir/"
		fi
	done
	rewritten="$rewritten_dir/$(basename "$source")"
	sed \
		-e "s#spec42: platform \"[^\"]*\"#spec42: platform \"$bundle_url\"#" \
		"$source" >"$rewritten"
	if ! grep -qF -e "spec42: platform \"$bundle_url\"" "$rewritten"; then
		echo "error: failed to rewrite platform header in $source" >&2
		exit 1
	fi

	plugin="$work_dir/${example_name}_${script_name}.wasm"
	generated="$work_dir/generated/$example_name/$script_name"
	additional_expected=""
	additional_evidence=""
	ROC_CACHE_DIR="$cache_dir" roc test "$rewritten"
	ROC_CACHE_DIR="$cache_dir" roc build "$rewritten" --output="$plugin"

	server_features=(--no-default-features)
	spec42_environment=(--no-stdlib)
	if [[ "$example_name/$script_name" == "door_controller/state_transition_svg" ]]; then
		# Normative view typing must resolve against the pinned SysML standard library.
		server_features+=(--features embed-stdlib)
		# Keep this nonempty for macOS Bash under `set -u`; domain libraries are unrelated.
		spec42_environment=(--disable-kpar-library domain)
	fi
	generator_args=("scenario=$example_name" "script=$script_name")
	if [[ "$example_name/$script_name" == "door_controller/state_transition_svg" ]]; then
		generator_args=(lifecycle "${generator_args[@]}")
	fi
	cargo run \
		--manifest-path "$spec42_dir/Cargo.toml" \
		-p server \
		--bin spec42 \
		"${server_features[@]}" \
		-- \
		"${spec42_environment[@]}" \
		generate "$plugin" "$model" \
		--output "$generated" \
		-- "${generator_args[@]}"
	case "$example_name/$script_name" in
		door_controller/state_transition_svg) expected="door-controller.svg"; evidence='data-kind="initial"' ;;
		electric_vehicle/bom_csv) expected="electric-vehicle-bom.csv"; evidence="EV-BAT-82" ;;
		electric_vehicle/engineering_dashboard) expected="engineering-dashboard.html"; evidence="DrivingRangeRequirement" ;;
		electric_vehicle/vcrm_csv) expected="electric-vehicle-vcrm.csv"; evidence="RangeCertificationTest" ;;
		ground_station/icd_csv) expected="ground-station-icd.csv"; evidence="SpaceLinkPort" ;;
		ground_station/network_graph) expected="ground-station-interface-network.dot"; evidence="MissionControlSystem" ;;
		ground_station/operations_dashboard) expected="ground-station-operations.html"; evidence="PublishProducts" ;;
		warehouse_robot/simulation_manifest)
			expected="warehouse-robot-simulation.json"
			evidence="MissionAssigned"
			additional_expected="simulation/warehouse-robot.properties"
			additional_evidence="initial.state=booting"
			;;
		warehouse_robot/state_explorer) expected="warehouse-robot-state-explorer.html"; evidence="navigatingToPick" ;;
		warehouse_robot/state_graph) expected="warehouse-robot-state-machine.dot"; evidence='"booting" -> "idle"' ;;
		*) echo "error: no output assertion for $example_name/$script_name" >&2; exit 1 ;;
	esac
	output_assertions=("$expected|$evidence")
	if [[ -n "$additional_expected" ]]; then
		output_assertions+=("$additional_expected|$additional_evidence")
	fi
	expected_paths=$(printf '%s\n' "${output_assertions[@]}" | cut -d '|' -f 1 | sort)
	actual_paths=$(find "$generated" -type f ! -name '.spec42-generator-manifest.json' -print \
		| sed "s#^$generated/##" \
		| sort)
	if [[ "$actual_paths" != "$expected_paths" ]]; then
		echo "error: $example_name/$script_name returned an unexpected file set" >&2
		diff -u <(printf '%s\n' "$expected_paths") <(printf '%s\n' "$actual_paths") || true
		exit 1
	fi
	for assertion in "${output_assertions[@]}"; do
		asserted_path="${assertion%%|*}"
		asserted_evidence="${assertion#*|}"
		artifact="$generated/$asserted_path"
		if [[ ! -s "$artifact" ]]; then
			echo "error: $example_name/$script_name did not produce non-empty $asserted_path" >&2
			exit 1
		fi
		if ! grep -qF -e "$asserted_evidence" "$artifact"; then
			echo "error: $asserted_path does not contain expected model evidence: $asserted_evidence" >&2
			exit 1
		fi
		snapshot="$example_dir/output/$asserted_path"
		snapshot_candidate="$artifact"
		if [[ "$example_name/$script_name" == "door_controller/state_transition_svg" ]]; then
			# Semantic IDs and source URIs intentionally contain the checkout's absolute URI.
			# Keep the checked-in notation golden deterministic while testing live provenance above.
			snapshot_candidate="$work_dir/normalized-$asserted_path"
			sed -E \
				-e 's# data-view-semantic-id="[^"]*"##g' \
				-e 's# data-semantic-id="[^"]*"##g' \
				-e 's#data-source-uri="[^"]*"#data-source-uri="file:///workspace/model.sysml"#g' \
				"$artifact" >"$snapshot_candidate"
		fi
		if [[ "$update_snapshots" == "1" ]]; then
			mkdir -p "$(dirname "$snapshot")"
			cp "$snapshot_candidate" "$snapshot"
			echo "Updated $example_name/output/$asserted_path"
		elif [[ ! -f "$snapshot" ]]; then
			echo "error: missing golden snapshot $snapshot" >&2
			echo "run scripts/update-example-snapshots.sh to create it" >&2
			exit 1
		elif ! cmp -s "$snapshot" "$snapshot_candidate"; then
			echo "error: generated output differs from $snapshot" >&2
			diff -u "$snapshot" "$snapshot_candidate" || true
			echo "run scripts/update-example-snapshots.sh to accept an intentional change" >&2
			exit 1
		else
			echo "Verified $example_name/$script_name -> $asserted_path (golden match)"
		fi
	done
done < <(find "$root_dir/examples" -type f -name '*.roc' -print | sort)

if [[ "$example_count" -eq 0 ]]; then
	echo "error: no Roc examples found" >&2
	exit 1
fi

if [[ "$example_count" -ne 10 ]]; then
	echo "error: expected 10 model/script combinations, found $example_count" >&2
	exit 1
fi

roc docs "$root_dir/platform/main.roc" --output="$work_dir/docs" --no-cache
test -s "$work_dir/docs/Model/index.html"
test -s "$work_dir/docs/StateTransition/index.html"
if tr -d '\000' <"$work_dir/docs/Model/index.html" | grep -qE 'Model\.to_summary|Model\.to_detail'; then
	echo "error: internal model conversion helpers leaked into public docs" >&2
	exit 1
fi

if [[ "$update_snapshots" == "1" ]]; then
	echo "roc-spec42 example snapshots regenerated"
else
	echo "roc-spec42 packaged end-to-end test passed"
fi
