#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Ensure library path includes ~/lib for node / simdjson compatibility
for libdir in "$HOME/lib" "/home/me/lib"; do
    if [ -d "$libdir" ] && [[ ":$LD_LIBRARY_PATH:" != *":$libdir:"* ]]; then
        export LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
done

# AIR SDK & Java environment variables (configurable via ~/.bashrc or environment)
AIR_HOME="${AIR_HOME:-${AIRSDK_HOME:-$HOME/.airsdk/AIRSDK_Linux}}"
JAVA_HOME="${JAVA_HOME:-$HOME/.sdkman/candidates/java/current}"

if [ -z "$AIR_HOME" ] || [ ! -f "$AIR_HOME/bin/amxmlc" ]; then
    echo "ERROR: AIR_HOME (or AIRSDK_HOME) is not set or amxmlc was not found." >&2
    echo "Please set AIR_HOME in your environment (e.g. in ~/.bashrc):" >&2
    echo "  export AIR_HOME=\$HOME/.airsdk/AIRSDK_Linux" >&2
    exit 1
fi

if [ -z "$JAVA_HOME" ] || [ ! -d "$JAVA_HOME" ]; then
    echo "ERROR: JAVA_HOME is not set or not a directory." >&2
    echo "Please set JAVA_HOME in your environment (e.g. in ~/.bashrc):" >&2
    echo "  export JAVA_HOME=\$HOME/.sdkman/candidates/java/current" >&2
    exit 1
fi

export PATH="$AIR_HOME/bin:$JAVA_HOME/bin:$PATH"

BUILD="$DIR/build"
STAGING="$BUILD/staging"

# If --clean is passed, remove old built SWFs
if [ "$1" = "--clean" ] || [ "$2" = "--clean" ]; then
    echo "=> Cleaning previous build artifacts..."
    rm -f "$BUILD/Desktop.swf" "$BUILD/Mobile.swf"
fi

# Ensure build directory exists
mkdir -p "$BUILD"

# Clean and recreate staging sandbox only (keeps existing built SWFs intact until new ones succeed)
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Ensure staging sandbox is always deleted when script exits
trap 'rm -rf "$STAGING"' EXIT

# Optional project directory overrides
HAXE_API_DIR="${HAXE_API_DIR:-$DIR/../aqw-haxe-api}"
HAXE_UI_DIR="${HAXE_UI_DIR:-$DIR}"

# ---- Step 0: Set up pristine staging sandbox ----
echo "=> [0/3] Copying files to sandbox (build/staging/)..."
mkdir -p "$STAGING/libs"
cp -r "$DIR/loader/src" "$STAGING/src"
cp -r "$DIR/loader/gamefiles" "$STAGING/gamefiles"
if [ -d "$DIR/loader/libs" ]; then
    cp -r "$DIR/loader/libs/"* "$STAGING/libs/" 2>/dev/null || true
fi

# ---- Step 1: Compile Haxe API & UI directly into staging sandbox ----
if [ "$SKIP_HAXE_API" != "1" ]; then
    if [ -d "$HAXE_API_DIR" ]; then
        echo "=> [1a/3] Compiling Haxe API (aqw-haxe-api)..."
        (cd "$HAXE_API_DIR" && if command -v haxe >/dev/null 2>&1; then haxe build.hxml; elif command -v pnpm >/dev/null 2>&1; then pnpm exec haxe build.hxml; else npx haxe build.hxml; fi)
        cp "$HAXE_API_DIR/bin/AqwApi.swc" "$STAGING/libs/AqwApi.swc"
        cp "$HAXE_API_DIR/bin/AqwApi.swc" "$DIR/loader/libs/AqwApi.swc" 2>/dev/null || true
    fi
    if [ -d "$HAXE_UI_DIR" ]; then
        echo "=> [1b/3] Compiling Haxe UI & Worker (aqw-haxe-ui)..."
        (cd "$HAXE_UI_DIR" && if command -v haxe >/dev/null 2>&1; then haxe build.hxml && haxe build-worker.hxml; elif command -v pnpm >/dev/null 2>&1; then pnpm exec haxe build.hxml && pnpm exec haxe build-worker.hxml; else npx haxe build.hxml && npx haxe build-worker.hxml; fi)
        cp "$HAXE_UI_DIR/bin/ModUI.swc" "$STAGING/libs/ModUI.swc"
        cp "$HAXE_UI_DIR/bin/ModUI.swc" "$DIR/loader/libs/ModUI.swc" 2>/dev/null || true
        mkdir -p "$DIR/loader/gamefiles/embed" "$STAGING/gamefiles/embed"
        cp "$HAXE_UI_DIR/bin/WorkerMain.swf" "$DIR/loader/gamefiles/embed/WorkerMain.swf"
        cp "$HAXE_UI_DIR/bin/WorkerMain.swf" "$STAGING/gamefiles/embed/WorkerMain.swf"
    fi
fi

# ---- Step 2: Verify WorkerMain.swf inside staging sandbox ----
echo "=> [2/3] Verifying WorkerMain.swf inside sandbox..."
if [ ! -f "$STAGING/gamefiles/embed/WorkerMain.swf" ]; then
    echo "ERROR: $STAGING/gamefiles/embed/WorkerMain.swf missing!" >&2
    exit 1
fi

# ---- Step 3a: Compile Desktop.swf directly from source ----
echo "=> [3a/3] Compiling Desktop.swf from source with amxmlc..."
"$AIR_HOME/bin/amxmlc" \
    +configname=air \
    -strict=false \
    -debug=true \
    -default-size 960 550 \
    -default-frame-rate 120 \
    -default-background-color 0x000000 \
    -define+=POCKET::IS_DESKTOP,true \
    -define+=POCKET::IS_MOBILE,false \
    -library-path+="$STAGING/libs" \
    -source-path+="$STAGING/src" \
    -output "$BUILD/Desktop.swf" \
    "$STAGING/src/Pocket.as"

# ---- Step 3b: Compile Mobile.swf directly from source ----
echo "=> [3b/3] Compiling Mobile.swf from source with amxmlc..."
"$AIR_HOME/bin/amxmlc" \
    +configname=air \
    -strict=false \
    -debug=true \
    -default-size 960 550 \
    -default-frame-rate 120 \
    -default-background-color 0x000000 \
    -define+=POCKET::IS_DESKTOP,false \
    -define+=POCKET::IS_MOBILE,true \
    -library-path+="$STAGING/libs" \
    -source-path+="$STAGING/src" \
    -output "$BUILD/Mobile.swf" \
    "$STAGING/src/Pocket.as"

# Set up build/ directory with symlinks to assets, icons, and gamefiles
for link in assets icons gamefiles; do
    if [ ! -e "$BUILD/$link" ]; then
        ln -sf "$DIR/loader/$link" "$BUILD/$link"
    fi
done

if [ -f "$DIR/loader/Desktop-app.xml" ]; then
    cp "$DIR/loader/Desktop-app.xml" "$BUILD/Desktop-app.xml"
    sed "s|<renderMode>.*</renderMode>|<renderMode>gpu</renderMode>|" "$DIR/loader/Desktop-app.xml" > "$BUILD/Desktop-app-gpu.xml"
fi

echo "=> Build Complete! Pristine loader/ was untouched. Artifacts isolated in build/"
