#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$DIR/build"

# Ensure library path includes ~/lib for node / simdjson compatibility
for libdir in "$HOME/lib" "/home/me/lib"; do
    if [ -d "$libdir" ] && [[ ":$LD_LIBRARY_PATH:" != *":$libdir:"* ]]; then
        export LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
done

# Build if explicitly requested (--build / -b) or if Desktop.swf does not exist yet
if [ "$1" = "--build" ] || [ "$2" = "--build" ] || [ "$1" = "-b" ] || [ "$2" = "-b" ]; then
    "$DIR/build.sh"
elif [ ! -f "$BUILD/Desktop.swf" ]; then
    echo "=> Desktop.swf not found in $BUILD. Automatically running build.sh..."
    "$DIR/build.sh"
fi

if [ ! -f "$BUILD/Desktop.swf" ]; then
    echo "ERROR: $BUILD/Desktop.swf is missing. Build failed or did not produce Desktop.swf." >&2
    exit 1
fi

# Set up build/ directory with symlinks to assets, icons, and gamefiles
mkdir -p "$BUILD"
for link in assets icons gamefiles; do
    if [ ! -e "$BUILD/$link" ]; then
        ln -sf "$DIR/loader/$link" "$BUILD/$link"
    fi
done

# Copy/refresh Desktop-app-local.xml into build/ (or fallback to Desktop-app.xml)
if [ -f "$DIR/loader/Desktop-app-local.xml" ]; then
    cp "$DIR/loader/Desktop-app-local.xml" "$BUILD/Desktop-app-local.xml"
else
    cp "$DIR/loader/Desktop-app.xml" "$BUILD/Desktop-app-local.xml"
fi

# Ensure assets/api.log exists and is symlinked for live tailing and user access
CURRENT_USER="${USER:-$(whoami)}"
WINE_PREFIX="${WINEPREFIX:-$HOME/.wine}"
WINE_LOG_DIR="${WINE_LOG_DIR:-$WINE_PREFIX/drive_c/users/$CURRENT_USER/AppData/Roaming/com.aqw.pocket/Local Store}"

mkdir -p "$DIR/loader/assets"
touch "$DIR/loader/assets/api.log"

if [ -d "$DIR/.." ]; then
    ln -sf "$DIR/loader/assets/api.log" "$DIR/../api.log" 2>/dev/null || true
fi
ln -sf "$DIR/loader/assets/api.log" "$BUILD/api.log" 2>/dev/null || true
ln -sf "$DIR/loader/assets/api.log" "$DIR/loader/api.log" 2>/dev/null || true

if [ -d "$WINE_PREFIX" ]; then
    mkdir -p "$WINE_LOG_DIR"
    mkdir -p "$WINE_LOG_DIR/assets"
    ln -sf "$DIR/loader/assets/api.log" "$WINE_LOG_DIR/assets/api.log" 2>/dev/null || true
    ln -sf "$DIR/loader/assets/api.log" "$WINE_LOG_DIR/api.log" 2>/dev/null || true
fi

# AIRSDK_WINDOWS environment variable (configurable via ~/.bashrc or environment)
AIRSDK_WINDOWS="${AIRSDK_WINDOWS:-${AIR_WINDOWS_HOME:-$HOME/.airsdk/AIRSDK_Windows}}"

if [ -z "$AIRSDK_WINDOWS" ] || [ ! -f "$AIRSDK_WINDOWS/bin/adl.exe" ]; then
    echo "ERROR: AIRSDK_WINDOWS (or AIR_WINDOWS_HOME) is not set or adl.exe was not found." >&2
    echo "Please set AIRSDK_WINDOWS in your environment (e.g. in ~/.bashrc):" >&2
    echo "  export AIRSDK_WINDOWS=\$HOME/.airsdk/AIRSDK_Windows" >&2
    exit 1
fi

echo "=> Launching ADL (Windows AIR Debug Launcher) via Wine from build/..."
echo "   (Using Desktop-app-local.xml - Discord RPC disabled for local testing)"
cd "$BUILD"
wine "$AIRSDK_WINDOWS/bin/adl.exe" -profile extendedDesktop Desktop-app-local.xml

echo "=> ADL closed."
