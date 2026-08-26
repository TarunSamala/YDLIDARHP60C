#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
rules_source="$script_dir/vendor/linux_ros/linux/scripts/angstrong-camera.rules"
rules_target="/etc/udev/rules.d/99-angstrong-camera.rules"

"$script_dir/setup.sh"

if [[ ${EUID} -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

install -m 0644 "$rules_source" "$rules_target"
udevadm control --reload-rules
udevadm trigger

echo "Installed $rules_target"
echo "Unplug and reconnect the HP60C before running the viewer."

