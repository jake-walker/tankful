#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_ID="xyz.jakewalker.tankful"

IPHONE_DEVICE="${IPHONE_DEVICE:-iPhone 17}"
DUO_DEVICE="${DUO_DEVICE:-iPhone Duo}"
ANDROID_AVD="${ANDROID_AVD:-emulator-34-medium_phone}"
ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
EMULATOR="$ANDROID_SDK/emulator/emulator"

BUILD_DIR="$SCRIPT_DIR/.build/screenshots"
DEVICEHUBCTL="${DEVICEHUBCTL:-devicehubctl}"
BUILD_IOS=true
BUILD_ANDROID=true
[[ -n "${IOS_APP+x}" ]] && BUILD_IOS=false
[[ -n "${ANDROID_APK+x}" ]] && BUILD_ANDROID=false
IOS_APP="${IOS_APP:-$BUILD_DIR/Build/Products/Debug-iphonesimulator/TankfulApp.app}"
ANDROID_APK="${ANDROID_APK:-$ROOT_DIR/.build/Android/app/outputs/apk/debug/app-debug.apk}"

active_ios=()
active_android=""
temp_dirs=()

cleanup() {
  local udid temp_dir
  for udid in ${active_ios[@]+"${active_ios[@]}"}; do
    xcrun simctl shutdown "$udid" || true
  done
  if [[ -n "$active_android" ]]; then
    adb -s "$active_android" emu kill || true
  fi
  for temp_dir in ${temp_dirs[@]+"${temp_dirs[@]}"}; do
    rm -rf "$temp_dir"
  done
}
trap cleanup EXIT

fail() {
  echo "$*" >&2
  exit 1
}

capture_screenshots() {
  local platform="$1" serial="$2" folder="$3" set_orientation="$4"
  local output_dir="$SCRIPT_DIR/screenshots/$folder"
  local temp_dir screenshot
  temp_dir="$(mktemp -d)"
  temp_dirs+=("$temp_dir")
  mkdir -p "$output_dir"

  local result=0
  maestro --udid "$serial" test --platform "$platform" \
    -e "APP_ID=$APP_ID" -e "SET_ORIENTATION=$set_orientation" \
    --test-output-dir "$temp_dir" \
    "$SCRIPT_DIR/maestro/screenshots.yaml" || result=$?

  while IFS= read -r -d '' screenshot; do
    cp "$screenshot" "$output_dir/"
  done < <(find "$temp_dir" -type f -path '*/takeScreenshot/*' -name '*.png' -print0)
  if (( result != 0 )); then
    local failed_dir="$BUILD_DIR/failed-$folder-$(date +%Y%m%d-%H%M%S)"
    mv "$temp_dir" "$failed_dir"
    fail "Maestro failed on $folder; artifacts: $failed_dir"
  fi
}

prepare_devicehubctl() {
  command -v "$DEVICEHUBCTL" >/dev/null 2>&1 || fail "iPhone Duo screenshots require devicehubctl. Install it from https://github.com/ChrisThoma/devicehubctl."
}

ios_device_id() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["name"] == name and device["isAvailable"]:
            print(device["udid"])
            sys.exit(0)
sys.exit(1)
' "$1"
}

capture_iphone() {
  local name="$1" folder="$2" set_orientation="$3" udid state
  udid="$(ios_device_id "$name")" || fail "No available iOS simulator named $name"
  state="$(xcrun simctl list devices -j | python3 -c '
import json, sys
udid = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["udid"] == udid:
            print(device["state"])
            sys.exit(0)
sys.exit(1)
' "$udid")"
  active_ios+=("$udid")
  if [[ "$state" != Booted ]]; then
    xcrun simctl boot "$udid"
  fi
  xcrun simctl bootstatus "$udid" -b
  if [[ "$name" == "$DUO_DEVICE" ]]; then
    "$DEVICEHUBCTL" "$udid" hinge 0
  fi
  xcrun simctl install "$udid" "$IOS_APP"
  echo "Capturing $name screenshots..."
  capture_screenshots ios "$udid" "$folder" "$set_orientation"
  if [[ "$name" == "$DUO_DEVICE" ]]; then
    "$DEVICEHUBCTL" "$udid" hinge 180
    xcrun simctl terminate "$udid" "$APP_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$APP_ID" previewMode
    sleep 2
    xcrun simctl io "$udid" screenshot --display=3 \
      "$SCRIPT_DIR/screenshots/$folder/01-overview.png"
  fi
  xcrun simctl shutdown "$udid"
  active_ios=()
}

android_serial_for_avd() {
  local serial name
  while read -r serial _; do
    [[ "$serial" == emulator-* ]] || continue
    name="$(adb -s "$serial" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')"
    if [[ "$name" == "$ANDROID_AVD" ]]; then
      echo "$serial"
      return 0
    fi
  done < <(adb devices | tail -n +2)
  return 1
}

start_android() {
  local port serial attempt
  serial="$(android_serial_for_avd)" && { android_serial="$serial"; active_android="$serial"; return; }
  [[ -x "$EMULATOR" ]] || fail "Android emulator not found at $EMULATOR"
  "$EMULATOR" -list-avds | grep -Fxq "$ANDROID_AVD" || fail "Android AVD not found: $ANDROID_AVD"
  for ((port=5554; port<=5680; port+=2)); do
    if ! lsof -nP -iTCP:"$port" -iTCP:"$((port + 1))" 2>/dev/null | grep -q .; then
      serial="emulator-$port"
      break
    fi
  done
  [[ -n "${serial:-}" ]] || fail "No free Android emulator port"
  "$EMULATOR" -avd "$ANDROID_AVD" -port "$port" -no-snapshot-save >"$BUILD_DIR/emulator.log" 2>&1 &
  active_android="$serial"
  for ((attempt=0; attempt<180; attempt++)); do
    if [[ "$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]]; then
      android_serial="$serial"
      return
    fi
    sleep 2
  done
  fail "Android emulator did not finish booting; see $BUILD_DIR/emulator.log"
}

capture_android() {
  local folder="$1" serial
  start_android
  serial="$android_serial"
  adb -s "$serial" install -r "$ANDROID_APK"
  echo "Capturing Android screenshots..."
  capture_screenshots android "$serial" "$folder" true
  adb -s "$active_android" emu kill
  active_android=""
}

if [[ $# -eq 0 ]]; then
  set -- iphone duo android
fi

for device in "$@"; do
  case "$device" in
    iphone|duo|android) ;;
    *) fail "Unknown device: $device (usage: $0 [iphone|duo|android]...)" ;;
  esac
done

for device in "$@"; do
  if [[ "$device" == duo ]]; then
    prepare_devicehubctl
    break
  fi
done

need_ios=false
need_android=false
for device in "$@"; do
  case "$device" in
    iphone|duo) need_ios=true ;;
    android) need_android=true ;;
  esac
done

mkdir -p "$BUILD_DIR"
if $need_ios; then
  if $BUILD_IOS; then
    xcodebuild -workspace "$ROOT_DIR/Project.xcworkspace" \
      -scheme 'Tankful App' -configuration Debug \
      -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath "$BUILD_DIR" CODE_SIGNING_ALLOWED=NO SKIP_ACTION=none build
  fi
  [[ -d "$IOS_APP" ]] || fail "iOS app not found: $IOS_APP"
fi
if $need_android; then
  if $BUILD_ANDROID; then
    skip gradle -p "$ROOT_DIR/Android" :app:assembleDebug
  fi
  [[ -f "$ANDROID_APK" ]] || fail "Android APK not found: $ANDROID_APK"
fi

for device in "$@"; do
  case "$device" in
    iphone) capture_iphone "$IPHONE_DEVICE" ios true ;;
    duo) capture_iphone "$DUO_DEVICE" ios-duo true ;;
    android) capture_android android ;;
  esac
done

echo "Screenshot capture complete."
