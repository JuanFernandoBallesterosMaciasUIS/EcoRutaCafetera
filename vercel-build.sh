#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="/tmp/flutter"

# Avoid permission issues when running as root
export PUB_CACHE="/tmp/pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export FLUTTER_NO_ANALYTICS=true
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

echo "==> Installing Flutter..."
if [ ! -d "$FLUTTER_DIR/bin" ]; then
  git clone https://github.com/flutter/flutter.git \
    --depth 1 -b stable "$FLUTTER_DIR" --quiet
else
  echo "Already present"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

echo "==> Flutter version"
flutter --version --suppress-analytics 2>&1 || flutter --version

echo "==> Enabling web"
flutter config --enable-web --suppress-analytics

echo "==> pub get"
flutter pub get --suppress-analytics

echo "==> Building web"
flutter build web --release --suppress-analytics

echo "==> Output"
ls -la build/web/
echo "==> Done"
