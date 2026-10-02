#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir="$script_dir/vendor/linux_ros/linux"
source "$script_dir/platform.sh"
camera_usb_id="3482:6723"

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "No graphical desktop session was detected." >&2
    echo "Run this from a desktop terminal to view RGB and depth windows." >&2
    exit 1
fi

if ! command -v lsusb >/dev/null 2>&1; then
    echo "Missing required command: lsusb" >&2
    exit 1
fi

if ! lsusb | grep -qiE "$camera_usb_id|YDLIDAR|Angstrong"; then
    echo "HP60C USB interface ($camera_usb_id) was not found." >&2
    echo "Connect the camera and run ./check_camera.sh first." >&2
    exit 1
fi

sdk_lib_target=$(get_sdk_lib_target)
build_dir=$(get_build_dir "$source_dir")

if [[ ! -x "$build_dir/ascamera" ]]; then
    "$script_dir/build.sh"
fi

library_dir="$source_dir/libs/lib/$sdk_lib_target"
if [[ ! -d "$library_dir" ]]; then
    echo "The vendor SDK has no libraries for $sdk_lib_target." >&2
    exit 1
fi

if ! command -v readelf >/dev/null 2>&1; then
    echo "Missing required command: readelf (install binutils)." >&2
    exit 1
fi

binary_machine=$(readelf -h "$build_dir/ascamera" | awk -F: '/^  Machine:/ {gsub(/^[[:space:]]+/, "", $2); print $2}')
case "$sdk_lib_target:$binary_machine" in
    x86_64-linux-gnu:*X86-64*|aarch64-linux-gnu:*AArch64*|arm-linux-gnueabihf:*ARM*) ;;
    *)
        echo "Executable architecture does not match $sdk_lib_target: $binary_machine" >&2
        echo "Run ./build.sh to rebuild for this machine." >&2
        exit 1
        ;;
esac

echo "Starting HP60C camera viewer."
echo "After 'camera start streaming' appears, press d to show RGB and depth."
echo "Keys: d=view, s=save, f=FPS, q=quit"

cd "$build_dir"
export LD_LIBRARY_PATH="$library_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec ./ascamera
