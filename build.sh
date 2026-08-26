#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir="$script_dir/vendor/linux_ros/linux"
build_dir="$source_dir/build-hp60c"

"$script_dir/setup.sh"

for command_name in cmake g++; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

cmake -S "$source_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build "$build_dir" --parallel

if [[ ! -x "$build_dir/ascamera" ]]; then
    echo "Build completed without creating the ascamera executable." >&2
    exit 1
fi

echo "HP60C viewer built successfully: $build_dir/ascamera"
