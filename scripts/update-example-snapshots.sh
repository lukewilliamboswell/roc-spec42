#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)

UPDATE_EXAMPLE_SNAPSHOTS=1 "$root_dir/scripts/test.sh"

echo "Review changes under examples/*/output before committing them."
