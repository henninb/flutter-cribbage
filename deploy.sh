#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-debug}"   # debug | release | profile
APK="build/app/outputs/flutter-apk/app-${MODE}.apk"
APP_ID="com.brianhenning.cribbage"

if ! command -v adb > /dev/null 2>&1; then
  echo "adb not found. Install Android SDK platform-tools and ensure adb is in your PATH."
  exit 1
fi

if ! command -v flutter > /dev/null 2>&1; then
  echo "flutter not found. Ensure Flutter is installed and in your PATH."
  exit 1
fi

# ── Device connectivity check ─────────────────────────────────────────────────

echo "==> Checking Android device connectivity..."

DEVICE_LINE=$(adb devices | awk 'NR>1 && NF>0 {print; exit}')

if [ -z "$DEVICE_LINE" ]; then
  cat <<'EOF'

No Android device detected.

To connect your phone via USB:
  1. Plug the phone into your computer with a USB cable.
  2. On the phone, swipe down the notification shade and tap the USB notification.
  3. Select "PTP (Photo Transfer Protocol)" or "File Transfer".
  4. Enable USB Debugging if you haven't already:
       a. Settings > About Phone — tap "Build Number" 7 times to unlock Developer Options.
       b. Settings > Developer Options — toggle on "USB Debugging".
  5. When the "Allow USB Debugging?" dialog appears on the phone, tap "Allow".
  6. Re-run this script.
EOF
  exit 1
fi

DEVICE_SERIAL=$(awk '{print $1}' <<< "$DEVICE_LINE")
DEVICE_STATE=$(awk '{print $2}' <<< "$DEVICE_LINE")

if [ "$DEVICE_STATE" = "offline" ]; then
  cat <<EOF

Device '$DEVICE_SERIAL' is detected but offline.

  1. Unlock your phone screen.
  2. Swipe down the notification shade and tap the USB notification.
  3. Select "PTP (Photo Transfer Protocol)" or "File Transfer".
  4. If an "Allow USB Debugging?" dialog appears, tap "Allow".
  5. If it remains offline: adb kill-server && adb start-server
EOF
  exit 1
fi

if [ "$DEVICE_STATE" = "unauthorized" ]; then
  cat <<EOF

Device '$DEVICE_SERIAL' is connected but not authorized.

  1. Check your phone for an "Allow USB Debugging?" dialog.
  2. Tap "Allow" (tick "Always allow from this computer" to skip this next time).
  3. If no dialog appears, unplug and replug the USB cable.
EOF
  exit 1
fi

echo "Device ready: $DEVICE_SERIAL"

# ── Build ─────────────────────────────────────────────────────────────────────

echo "==> Flutter pub get"
flutter pub get

echo "==> Building APK ($MODE)"
flutter build apk "--$MODE"

if [ ! -f "$APK" ]; then
  echo "APK not found at $APK — build may have failed."
  exit 1
fi

echo "APK size: $(du -sh "$APK" | cut -f1)"

# ── Deploy ────────────────────────────────────────────────────────────────────

echo "Target device: $DEVICE_SERIAL"
echo "Installing $APK..."
adb -s "$DEVICE_SERIAL" install -r "$APK"

echo "Launching app..."
adb -s "$DEVICE_SERIAL" shell am start -n "${APP_ID}/${APP_ID}.MainActivity"

echo "Done."
