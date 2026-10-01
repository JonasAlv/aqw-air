#!/bin/bash
# build-android-armv7.sh - Build Android armv7 APKs locally
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for libdir in "$HOME/lib" "/home/me/lib"; do
    if [ -d "$libdir" ] && [[ ":$LD_LIBRARY_PATH:" != *":$libdir:"* ]]; then
        export LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
done
ARCH="armv7" exec "$DIR/build-android.sh" "$@"
