#!/bin/bash
# build-android.sh - Build Android APKs locally using isolated build sandbox
# Supports ARMv8, ARMv7, or both (default)
# Produces exactly 3 render files per arch: auto, gpu, direct
# Output: android_builds/AQWPocket-Mod-${ARCH}-${MODE}.apk

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Ensure library path includes ~/lib for node / simdjson compatibility
for libdir in "$HOME/lib" "/home/me/lib"; do
    if [ -d "$libdir" ] && [[ ":$LD_LIBRARY_PATH:" != *":$libdir:"* ]]; then
        export LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
done

# ---- AIR SDK & Java environment variables ----
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
OUTPUT_DIR="${OUTPUT_DIR:-$DIR/../android_builds}"

echo "=> Cleaning build sandbox..."
rm -rf "$STAGING"
mkdir -p "$BUILD"
mkdir -p "$STAGING"
mkdir -p "$OUTPUT_DIR"

# Ensure staging sandbox is cleaned up when script exits
trap 'rm -rf "$STAGING"' EXIT

# Determine target architectures (default: both armv8 and armv7)
if [ -n "$ARCH" ] && [ "$ARCH" != "all" ]; then
    ARCHS=("$ARCH")
else
    ARCHS=("armv8" "armv7")
fi

# Parse render modes: defaults to auto, gpu, and direct if none specified
TARGET_MODES=("$@")
if [ ${#TARGET_MODES[@]} -eq 0 ]; then
    TARGET_MODES=("auto" "gpu" "direct")
fi

KEYSTORE="${KEYSTORE:-$DIR/aqwpocket_keystore_local.p12}"
HAXE_API_DIR="${HAXE_API_DIR:-$DIR/../aqw-haxe-api}"
HAXE_UI_DIR="${HAXE_UI_DIR:-$DIR}"

# ---- Step 0: Pull latest upstream gamefiles from Anthony's release ----
echo "=> [0/5] Checking latest upstream gamefiles from Anthony (anthony-hyo/aqw-mobile)..."
mkdir -p "$DIR/loader/gamefiles"
UPSTREAM_APK_URL=$(curl -s "https://api.github.com/repos/anthony-hyo/aqw-mobile/releases/latest" 2>/dev/null | grep -m1 "browser_download_url.*AQWPocket-.*-armv8\.apk" | cut -d '"' -f 4 || true)

if [ -n "$UPSTREAM_APK_URL" ]; then
    echo "   Found upstream release APK: $UPSTREAM_APK_URL"
    TMP_UPSTREAM="$BUILD/upstream.apk"
    if curl -sL "$UPSTREAM_APK_URL" -o "$TMP_UPSTREAM"; then
        echo "   Extracting latest gamefiles from upstream APK..."
        mkdir -p "$STAGING/gamefiles"
        unzip -q -o -j "$TMP_UPSTREAM" "assets/gamefiles/*" -d "$STAGING/gamefiles/" 2>/dev/null || true
        # Update loader cache so offline builds remain updated
        cp -f "$STAGING/gamefiles/"*.swf "$DIR/loader/gamefiles/" 2>/dev/null || true
        rm -f "$TMP_UPSTREAM"
        echo "   Upstream gamefiles updated successfully."
    else
        echo "   Warning: Failed to download upstream APK, falling back to local loader/gamefiles."
    fi
else
    echo "   Notice: Offline or GitHub API rate-limited. Using local loader/gamefiles."
fi

# ---- Step 1: Copy pristine files into sandbox ----
echo "=> [1/5] Copying repository files to sandbox ($STAGING)..."
mkdir -p "$STAGING/libs"
cp -r "$DIR/loader/src" "$STAGING/src"
if [ ! -d "$STAGING/gamefiles" ] || [ -z "$(ls -A "$STAGING/gamefiles" 2>/dev/null)" ]; then
    mkdir -p "$STAGING/gamefiles"
    cp -r "$DIR/loader/gamefiles/"* "$STAGING/gamefiles/" 2>/dev/null || true
fi
cp -r "$DIR/loader/assets" "$STAGING/assets"
cp -r "$DIR/loader/icons" "$STAGING/icons"
cp "$DIR/loader/Mobile-app.xml" "$STAGING/Mobile-app.xml"
if [ -d "$DIR/loader/libs" ]; then
    cp -r "$DIR/loader/libs/"* "$STAGING/libs/" 2>/dev/null || true
fi

# ---- Step 2: Compile Haxe API & UI into sandbox ----
if [ "$SKIP_HAXE_API" != "1" ]; then
    if [ -d "$HAXE_API_DIR" ]; then
        echo "=> [2a/5] Compiling Haxe API (aqw-haxe-api)..."
        (cd "$HAXE_API_DIR" && if command -v haxe >/dev/null 2>&1; then haxe build.hxml; elif command -v pnpm >/dev/null 2>&1; then pnpm exec haxe build.hxml; else npx haxe build.hxml; fi)
        cp "$HAXE_API_DIR/bin/AqwApi.swc" "$STAGING/libs/AqwApi.swc"
        cp "$HAXE_API_DIR/bin/AqwApi.swc" "$DIR/loader/libs/AqwApi.swc" 2>/dev/null || true
    fi
    if [ -d "$HAXE_UI_DIR" ]; then
        echo "=> [2b/5] Compiling Haxe UI & Worker (aqw-haxe-ui)..."
        (cd "$HAXE_UI_DIR" && if command -v haxe >/dev/null 2>&1; then haxe build.hxml && haxe build-worker.hxml; elif command -v pnpm >/dev/null 2>&1; then pnpm exec haxe build.hxml && pnpm exec haxe build-worker.hxml; else npx haxe build.hxml && npx haxe build-worker.hxml; fi)
        cp "$HAXE_UI_DIR/bin/ModUI.swc" "$STAGING/libs/ModUI.swc"
        cp "$HAXE_UI_DIR/bin/ModUI.swc" "$DIR/loader/libs/ModUI.swc" 2>/dev/null || true
        mkdir -p "$DIR/loader/gamefiles/embed" "$STAGING/gamefiles/embed"
        cp "$HAXE_UI_DIR/bin/WorkerMain.swf" "$DIR/loader/gamefiles/embed/WorkerMain.swf"
        cp "$HAXE_UI_DIR/bin/WorkerMain.swf" "$STAGING/gamefiles/embed/WorkerMain.swf"
    fi
fi

# ---- Step 3: Verify WorkerMain.swf inside sandbox ----
echo "=> [3/5] Verifying WorkerMain.swf inside sandbox..."
if [ ! -f "$STAGING/gamefiles/embed/WorkerMain.swf" ]; then
    echo "ERROR: $STAGING/gamefiles/embed/WorkerMain.swf missing!" >&2
    exit 1
fi

# ---- Step 4: Compile Mobile.swf directly from source ----
echo "=> [4/5] Compiling Mobile.swf directly from source with amxmlc..."
"$AIR_HOME/bin/amxmlc" \
    +configname=air \
    -strict=false \
    -default-size 960 550 \
    -default-frame-rate 120 \
    -default-background-color 0x000000 \
    -define+=POCKET::IS_DESKTOP,false \
    -define+=POCKET::IS_MOBILE,true \
    -library-path+="$STAGING/libs" \
    -source-path+="$STAGING/src" \
    -output "$STAGING/Mobile.swf" \
    "$STAGING/src/Pocket.as"

# Copy final Mobile.swf to build/
cp "$STAGING/Mobile.swf" "$BUILD/Mobile.swf"

# ---- Step 5: Keystore & Packaging ----
echo "=> [5/5] Checking keystore..."
if [ ! -f "$KEYSTORE" ]; then
    echo "   Generating local test keystore..."
    "$AIR_HOME/bin/adt" -certificate -cn "AQWPocketLocal" 2048-RSA "$KEYSTORE" password
fi

echo "=> Packaging APKs (${TARGET_MODES[*]}) for architectures: ${ARCHS[*]}..."

BUILT_APKS=()
for CURRENT_ARCH in "${ARCHS[@]}"; do
    for MODE in "${TARGET_MODES[@]}"; do
        OUTPUT_FILE="AQWPocket-Mod-${CURRENT_ARCH}-${MODE}.apk"
        OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILE"
        TMP_APP_XML="$BUILD/Mobile-app-${CURRENT_ARCH}-${MODE}.xml"

        echo "   -> Packaging $OUTPUT_FILE (renderMode: $MODE, arch: $CURRENT_ARCH)..."
        cp "$STAGING/Mobile-app.xml" "$TMP_APP_XML"
        sed -i "s|<renderMode>.*</renderMode>|<renderMode>${MODE}</renderMode>|" "$TMP_APP_XML"

        "$AIR_HOME/bin/adt" -package \
            -target apk-captive-runtime \
            -arch "$CURRENT_ARCH" \
            -storetype PKCS12 \
            -keystore "$KEYSTORE" \
            -storepass password \
            "$OUTPUT_PATH" \
            "$TMP_APP_XML" \
            -C "$BUILD" Mobile.swf \
            -C "$STAGING" \
                assets \
                icons/icon-36x36.png \
                icons/icon-48x48.png \
                icons/icon-72x72.png \
                icons/icon-96x96.png \
                icons/icon-144x144.png \
                icons/icon-192x192.png \
                gamefiles/game.swf \
                gamefiles/world-map.swf \
                gamefiles/book-of-lore.swf \
                gamefiles/character-select.swf

        rm -f "$TMP_APP_XML"

        FILE_SIZE=$(du -sh "$OUTPUT_PATH" | cut -f1)
        BUILT_APKS+=("$OUTPUT_FILE ($FILE_SIZE)")
    done
done

echo ""
echo "=> Done! Built Android APKs in $OUTPUT_DIR:"
for APK_INFO in "${BUILT_APKS[@]}"; do
    echo "   • $APK_INFO"
done
echo ""
echo "   Install on device with: adb install -r $OUTPUT_DIR/<apk-file>"
