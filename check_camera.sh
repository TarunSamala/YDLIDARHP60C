#!/usr/bin/env bash
set -euo pipefail

camera_usb_id="3482:6723"

for command_name in lsusb v4l2-ctl udevadm; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

echo "USB camera check:"
if lsusb | grep -iE "$camera_usb_id|YDLIDAR|Angstrong"; then
    echo "HP60C-compatible USB interface found."
else
    echo "HP60C USB interface ($camera_usb_id) was not found."
    echo "Connect the camera directly to a powered USB port and run this again."
fi

echo
echo "Video devices:"
if compgen -G '/dev/video*' >/dev/null; then
    v4l2-ctl --list-devices
    hp60c_video_count=0
    for video_device in /dev/video*; do
        [[ -e "$video_device" ]] || continue
        properties=$(udevadm info --query=property --name "$video_device" 2>/dev/null || true)
        if ! grep -q '^ID_VENDOR_ID=3482$' <<<"$properties" ||
           ! grep -q '^ID_MODEL_ID=6723$' <<<"$properties"; then
            continue
        fi

        ((hp60c_video_count += 1))
        printf '\nHP60C %s: ' "$video_device"
        if [[ -r "$video_device" && -w "$video_device" ]]; then
            echo "accessible"
        else
            echo "permission denied (install the udev rule)"
        fi
        v4l2-ctl --device "$video_device" --list-formats-ext || true
    done

    if ((hp60c_video_count == 0)); then
        echo "No V4L2 node belonging to USB device $camera_usb_id was identified."
    fi
else
    echo "No /dev/video* devices found."
fi
