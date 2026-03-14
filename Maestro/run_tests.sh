#!/bin/bash
# Run all Maestro tests against both iOS Simulator and Android emulator.
# Screenshots are saved to screenshots-ios/ and screenshots-android/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Output directories
IOS_SCREENSHOTS="$SCRIPT_DIR/screenshots-ios"
ANDROID_SCREENSHOTS="$SCRIPT_DIR/screenshots-android"

rm -rf "$IOS_SCREENSHOTS" "$ANDROID_SCREENSHOTS"
mkdir -p "$IOS_SCREENSHOTS" "$ANDROID_SCREENSHOTS"

# Ensure JAVA_HOME is set
if [ -z "${JAVA_HOME:-}" ]; then
    if [ -x /usr/libexec/java_home ]; then
        export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || true)
    fi
    if [ -z "${JAVA_HOME:-}" ] && [ -d /opt/homebrew/opt/openjdk@21 ]; then
        export JAVA_HOME=$(find /opt/homebrew/opt/openjdk@21 -name "Home" -type d | head -1)
    fi
fi

# Find maestro
MAESTRO="${MAESTRO:-$(command -v maestro 2>/dev/null || echo "$HOME/.maestro/bin/maestro")}"
if [ ! -x "$MAESTRO" ]; then
    echo "Error: maestro not found. Install from https://maestro.mobile.dev" >&2
    exit 1
fi

# Collect test flows
FLOWS=("$SCRIPT_DIR"/*.yaml)
if [ ${#FLOWS[@]} -eq 0 ]; then
    echo "No Maestro test flows found in $SCRIPT_DIR" >&2
    exit 1
fi

echo "Found ${#FLOWS[@]} test flow(s)"
FAILED=0

# --- iOS Simulator ---
IOS_DEVICE=$(xcrun simctl list devices booted -j 2>/dev/null \
    | python3 -c "import json,sys; devs=[d for r in json.load(sys.stdin)['devices'].values() for d in r if d['state']=='Booted']; print(devs[0]['udid'] if devs else '')" 2>/dev/null || true)

if [ -n "$IOS_DEVICE" ]; then
    echo ""
    echo "=== Running iOS tests (device: $IOS_DEVICE) ==="
    for flow in "${FLOWS[@]}"; do
        name="$(basename "$flow" .yaml)"
        echo "  Running: $name"
        # Run from the screenshots output dir so takeScreenshot saves there
        cd "$IOS_SCREENSHOTS"
        if "$MAESTRO" --device "$IOS_DEVICE" test "$flow"; then
            echo "  PASSED: $name"
        else
            echo "  FAILED: $name" >&2
            FAILED=1
        fi
        cd "$PROJECT_DIR"
    done
else
    echo "WARNING: No booted iOS Simulator found, skipping iOS tests" >&2
fi

# --- Android Emulator ---
ADB="${ANDROID_HOME:-${HOME}/Library/Android/sdk}/platform-tools/adb"
if [ ! -x "$ADB" ]; then
    ADB=$(command -v adb 2>/dev/null || true)
fi

ANDROID_DEVICE=""
if [ -n "$ADB" ] && [ -x "$ADB" ]; then
    ANDROID_DEVICE=$("$ADB" devices 2>/dev/null | grep -w "device$" | head -1 | awk '{print $1}')
fi

if [ -n "$ANDROID_DEVICE" ]; then
    echo ""
    echo "=== Running Android tests (device: $ANDROID_DEVICE) ==="
    for flow in "${FLOWS[@]}"; do
        name="$(basename "$flow" .yaml)"
        echo "  Running: $name"
        cd "$ANDROID_SCREENSHOTS"
        if "$MAESTRO" --device "$ANDROID_DEVICE" test "$flow"; then
            echo "  PASSED: $name"
        else
            echo "  FAILED: $name" >&2
            FAILED=1
        fi
        cd "$PROJECT_DIR"
    done
else
    echo "WARNING: No connected Android device/emulator found, skipping Android tests" >&2
fi

# Summary
echo ""
echo "=== Screenshots ==="
echo "iOS:     $IOS_SCREENSHOTS/"
ls "$IOS_SCREENSHOTS"/*.png 2>/dev/null || echo "  (none)"
echo "Android: $ANDROID_SCREENSHOTS/"
ls "$ANDROID_SCREENSHOTS"/*.png 2>/dev/null || echo "  (none)"

exit $FAILED
