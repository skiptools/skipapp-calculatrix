#!/bin/bash
# Run all Maestro tests against iOS Simulator and/or Android emulator
# for each configured locale. Screenshots are saved to:
#   screenshots-ios/<locale>/   and   screenshots-android/<locale>/
#
# Usage:
#   ./run_tests.sh                     # Run on both platforms
#   ./run_tests.sh --platform ios      # iOS only
#   ./run_tests.sh --platform android  # Android only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_ID="skip.Calculatrix"

# Locales to test: language code and locale identifier
LOCALES=("en_US" "fr_FR" "ja_JP")

# Parse arguments
PLATFORM="all"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform) PLATFORM="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Output directories
IOS_SCREENSHOTS="$SCRIPT_DIR/screenshots-ios"
ANDROID_SCREENSHOTS="$SCRIPT_DIR/screenshots-android"

if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then
    rm -rf "$IOS_SCREENSHOTS"
fi
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
    rm -rf "$ANDROID_SCREENSHOTS"
fi

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
echo "Locales: ${LOCALES[*]}"
FAILED=0

# Extract the language code from a locale (e.g., "fr_FR" -> "fr")
lang_code() {
    echo "${1%%_*}"
}

# Convert locale to Android format (e.g., "fr_FR" -> "fr-FR")
android_locale() {
    echo "${1/_/-}"
}

# --- iOS Simulator ---
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then
    IOS_DEVICE=$(xcrun simctl list devices booted -j 2>/dev/null \
        | python3 -c "import json,sys; devs=[d for r in json.load(sys.stdin)['devices'].values() for d in r if d['state']=='Booted']; print(devs[0]['udid'] if devs else '')" 2>/dev/null || true)

    if [ -n "$IOS_DEVICE" ]; then
        echo ""
        echo "=== Running iOS tests (device: $IOS_DEVICE) ==="
        for locale in "${LOCALES[@]}"; do
            LOCALE_DIR="$IOS_SCREENSHOTS/$locale"
            mkdir -p "$LOCALE_DIR"
            lang="$(lang_code "$locale")"

            echo ""
            echo "--- Setting iOS locale: $locale (lang=$lang) ---"
            xcrun simctl spawn "$IOS_DEVICE" defaults write -g AppleLanguages -array "$lang"
            xcrun simctl spawn "$IOS_DEVICE" defaults write -g AppleLocale -string "$locale"
            xcrun simctl terminate "$IOS_DEVICE" "$APP_ID" 2>/dev/null || true

            for flow in "${FLOWS[@]}"; do
                name="$(basename "$flow" .yaml)"
                echo "  Running: $name"
                cd "$LOCALE_DIR"
                if "$MAESTRO" --device "$IOS_DEVICE" test "$flow"; then
                    echo "  PASSED: $name [$locale]"
                else
                    echo "  FAILED: $name [$locale]" >&2
                    FAILED=1
                fi
                cd "$PROJECT_DIR"
            done
        done
    else
        echo "WARNING: No booted iOS Simulator found, skipping iOS tests" >&2
    fi
fi

# --- Android Emulator ---
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
    ADB="${ANDROID_HOME:-${HOME}/Library/Android/sdk}/platform-tools/adb"
    if [ ! -x "$ADB" ]; then
        ADB=$(command -v adb 2>/dev/null || true)
    fi

    ANDROID_DEVICE=""
    if [ -n "${ADB:-}" ] && [ -x "$ADB" ]; then
        ANDROID_DEVICE=$("$ADB" devices 2>/dev/null | grep -w "device$" | head -1 | awk '{print $1}')
    fi

    if [ -n "$ANDROID_DEVICE" ]; then
        echo ""
        echo "=== Running Android tests (device: $ANDROID_DEVICE) ==="
        for locale in "${LOCALES[@]}"; do
            LOCALE_DIR="$ANDROID_SCREENSHOTS/$locale"
            mkdir -p "$LOCALE_DIR"
            android_loc="$(android_locale "$locale")"

            echo ""
            echo "--- Setting Android locale: $android_loc ---"
            "$ADB" -s "$ANDROID_DEVICE" shell "cmd locale set-app-locales $APP_ID --locales $android_loc" 2>/dev/null || true
            "$ADB" -s "$ANDROID_DEVICE" shell "am force-stop $APP_ID" 2>/dev/null || true
            sleep 3

            for flow in "${FLOWS[@]}"; do
                name="$(basename "$flow" .yaml)"
                echo "  Running: $name"
                cd "$LOCALE_DIR"
                if "$MAESTRO" --device "$ANDROID_DEVICE" test "$flow"; then
                    echo "  PASSED: $name [$locale]"
                else
                    echo "  FAILED: $name [$locale]" >&2
                    FAILED=1
                fi
                cd "$PROJECT_DIR"
            done
        done
    else
        echo "WARNING: No connected Android device/emulator found, skipping Android tests" >&2
    fi
fi

# Summary
echo ""
echo "=== Screenshots ==="
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then
    echo "iOS:"
    for locale in "${LOCALES[@]}"; do
        echo "  $locale:"
        ls "$IOS_SCREENSHOTS/$locale"/*.png 2>/dev/null | sed 's/^/    /' || echo "    (none)"
    done
fi
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
    echo "Android:"
    for locale in "${LOCALES[@]}"; do
        echo "  $locale:"
        ls "$ANDROID_SCREENSHOTS/$locale"/*.png 2>/dev/null | sed 's/^/    /' || echo "    (none)"
    done
fi

exit $FAILED
