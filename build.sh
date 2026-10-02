#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir="$script_dir/vendor/linux_ros/linux"
source "$script_dir/platform.sh"

"$script_dir/setup.sh"

for command_name in cmake g++ readelf; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

sdk_lib_target=$(get_sdk_lib_target)
build_dir=$(get_build_dir "$source_dir")
library_dir="$source_dir/libs/lib/$sdk_lib_target"
if [[ ! -d "$library_dir" ]]; then
    echo "The vendor SDK has no libraries for $sdk_lib_target." >&2
    exit 1
fi

cmake -S "$source_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build "$build_dir" --parallel

if [[ ! -x "$build_dir/ascamera" ]]; then
    echo "Build completed without creating the ascamera executable." >&2
    exit 1
fi

binary_machine=$(readelf -h "$build_dir/ascamera" | awk -F: '/^  Machine:/ {gsub(/^[[:space:]]+/, "", $2); print $2}')
case "$sdk_lib_target:$binary_machine" in
    x86_64-linux-gnu:*X86-64*|aarch64-linux-gnu:*AArch64*|arm-linux-gnueabihf:*ARM*) ;;
    *)
        echo "Built executable architecture does not match $sdk_lib_target: $binary_machine" >&2
        exit 1
        ;;
esac

echo "HP60C viewer built successfully: $build_dir/ascamera"
