# YDLIDAR HP60C camera test

This is a standalone Linux test directory for the YDLIDAR HP60C depth camera,
including Raspberry Pi 4B running Raspberry Pi OS.
It detects the camera, downloads and builds the camera SDK on first use, and
opens live RGB and color-mapped depth views.

It does not depend on YDLidar-SDK or any parent directory. A fresh clone can
download, patch, build, detect, and run the camera on its own.

## Quick start

Connect the HP60C to a sufficiently powered USB port and run:

```bash
./test_camera.sh
```

The first run downloads the camera SDK, verifies its SHA-256 checksum, applies
Linux/OpenCV compatibility fixes, builds the viewer, and starts it. Later runs
reuse the built viewer.

When the program reports that the camera is streaming, use:

- `d` — toggle the live RGB and color-mapped depth windows
- `s` — save RGB, raw depth, and point-cloud frames
- `f` — toggle frame-rate logging
- `l` — print the active camera configuration
- `q` — quit

Snapshots are written under the architecture-specific build directory, for
example `vendor/linux_ros/linux/build-hp60c-aarch64-linux-gnu/` on 64-bit Pi OS.

## Supported camera output

The viewer uses the HP60C vendor SDK's synchronized default stream, which is
the reliable full-depth mode:

- Live RGB image
- Live color-mapped RAW16 depth image
- 640 x 480 depth at up to 20 fps
- Frame-rate and camera-configuration logging
- RGB and raw-depth snapshots
- Point-cloud snapshots in PCD format
- Camera serial number, firmware version, and calibration parameters

The HP60C datasheet advertises RGB up to 1920 x 1080 at 20 fps, while
640 x 360 and 640 x 480 at 20 fps are the recommended synchronized RGB modes.
The included Linux SDK chooses its firmware-supported default. This project
does not force 1080p because some HP60C firmware/SDK combinations advertise
that mode but reject it or stop producing synchronized depth frames.

## Individual commands

```bash
./check_camera.sh  # Detect USB and V4L2 interfaces
./setup.sh         # Download and prepare the vendor SDK
./build.sh         # Compile the viewer
./run_viewer.sh    # Start the viewer
```

The HP60C should expose its UVC and communication interfaces. The expected
camera USB ID in the vendor rules is `3482:6723`.

`check_camera.sh` also prints the formats and frame rates advertised by each
HP60C V4L2 node, so you can verify the capabilities of your exact firmware.

If access is denied, install the included vendor udev rule once:

```bash
sudo ./install_udev_rules.sh
```

Then unplug and reconnect the camera. The udev installation is intentionally
not performed automatically because it modifies system configuration.

## Requirements

- Linux on x86_64, aarch64, or arm-linux-gnueabihf
- Raspberry Pi 4B with either 64-bit Raspberry Pi OS or 32-bit Raspberry Pi OS
- CMake, a C++ compiler, X11, and OpenCV development files
- `curl`, `xz`, `tar`, `patch`, `lsusb`, and `v4l2-ctl`
- A graphical session (`DISPLAY` or `WAYLAND_DISPLAY`) for live windows

Arch Linux:

```bash
sudo pacman -S --needed cmake gcc binutils opencv libusb usbutils v4l-utils curl xz patch
```

Ubuntu/Debian:

```bash
sudo apt install cmake g++ binutils libopencv-dev libusb-1.0-0 usbutils v4l-utils curl xz-utils patch
```

For Raspberry Pi OS, install the complete build and camera toolchain:

```bash
sudo apt update && sudo apt install -y \
  build-essential cmake binutils pkg-config \
  libopencv-dev libusb-1.0-0-dev \
  v4l-utils usbutils \
  curl xz-utils tar patch git \
  libx11-dev
```

Add the user to the camera groups, then log out and back in:

```bash
sudo usermod -aG video,plugdev "$USER"
```

No cross-compiler is needed when building directly on the Pi. The first build
selects the matching vendor libraries automatically:
`aarch64-linux-gnu` for 64-bit Pi OS or `arm-linux-gnueabihf` for 32-bit Pi OS.

## Repository contents

Only the wrapper scripts and compatibility patch should be committed.
Downloaded vendor SDK files and build products live under `vendor/` and are
excluded by `.gitignore`. This keeps the repository small and avoids
redistributing the vendor binaries through your Git history.

The SDK package source is a community mirror of YDLIDAR's public Linux camera
package:
https://github.com/Drone-SWAN/YDLIDAR-ICA-ASC60C
