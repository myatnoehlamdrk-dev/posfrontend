#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.9}"
CACHE_DIR="${NETLIFY_CACHE_DIR:-/opt/build/cache}"
SDK_DIR="$CACHE_DIR/flutter-$FLUTTER_VERSION"
PUB_CACHE_DIR="$CACHE_DIR/pub-cache"

export PUB_CACHE="$PUB_CACHE_DIR"
export XDG_CONFIG_HOME="$CACHE_DIR/flutter-config"
mkdir -p "$XDG_CONFIG_HOME"

if [ ! -x "$SDK_DIR/bin/flutter" ]; then
  TMP_DIR="$CACHE_DIR/flutter-download-tmp"
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"
  echo "Downloading Flutter $FLUTTER_VERSION..."
  curl -sSL --retry 3 \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o "$TMP_DIR/flutter.tar.xz"
  tar -xJf "$TMP_DIR/flutter.tar.xz" -C "$TMP_DIR"
  mv "$TMP_DIR/flutter" "$SDK_DIR"
  rm -rf "$TMP_DIR"
fi

export PATH="$SDK_DIR/bin:$PATH"

# The release tarball ships a prebuilt flutter tool plus a flutter_tools.stamp
# holding the exact revision it was built from. The build environment's git
# wrapper blocks `git -C <dir> ...`, so bin/internal/shared.sh computes the
# revision as an error-note string, sees a stamp mismatch, DELETES
# bin/cache/flutter.version.json, and recompiles the whole tool from source.
# After that, pub reports the SDK version as "0.0.0-unknown" and dependency
# resolution fails.
#
# The wrapper's official escape hatch is NETLIFY_INTERNAL_GIT=1 (see the
# wrapper script): it execs the real git for internal system calls. With real
# git, the computed revision matches the shipped stamp, so no rebuild happens
# and the tarball's valid flutter.version.json is used as-is.
export NETLIFY_INTERNAL_GIT=1

# Declare the SDK and repo as safe git directories without using `git config`.
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0=safe.directory
export GIT_CONFIG_VALUE_0="$SDK_DIR"
export GIT_CONFIG_KEY_1=safe.directory
export GIT_CONFIG_VALUE_1="$(pwd)"

flutter config --no-analytics >/dev/null
flutter precache --web
flutter pub get
flutter build web --release

echo "Flutter web build complete."
