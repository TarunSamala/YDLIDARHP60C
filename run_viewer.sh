#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir="$script_dir/vendor/linux_ros/linux"
build_dir="$source_dir/build-hp60c"
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

if [[ ! -x "$build_dir/ascamera" ]]; then
    "$script_dir/build.sh"
fi

compiler_target=$(g++ -dumpmachine)
library_dir="$source_dir/libs/lib/$compiler_target"
if [[ ! -d "$library_dir" ]]; then
    case "$(uname -m)" in
        x86_64) library_dir="$source_dir/libs/lib/x86_64-linux-gnu" ;;
        aarch64) library_dir="$source_dir/libs/lib/aarch64-linux-gnu" ;;
        armv7l|armv8l) library_dir="$source_dir/libs/lib/arm-linux-gnueabihf" ;;
        *) echo "Unsupported machine architecture: $(uname -m)" >&2; exit 1 ;;
    esac
fi

echo "Starting HP60C camera viewer."
echo "After 'camera start streaming' appears, press d to show RGB and depth."
echo "Keys: d=view, s=save, f=FPS, q=quit"

cd "$build_dir"
export LD_LIBRARY_PATH="$library_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec ./ascamera
