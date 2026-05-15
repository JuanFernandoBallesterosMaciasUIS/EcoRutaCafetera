#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="/tmp/flutter"

echo "==> Installing Flutter..."
if [ ! -d "$FLUTTER_DIR/bin" ]; then
  git clone https://github.com/flutter/flutter.git \
    --depth 1 -b stable "$FLUTTER_DIR" --quiet
else
  echo "Flutter already present, skipping clone"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

echo "==> Flutter version"
flutter --version

echo "==> Enabling web"
flutter config --enable-web --no-analytics

echo "==> pub get"
flutter pub get

echo "==> Building web"
flutter build web --release

echo "==> Listing output"
ls -la build/web/

echo "==> Done"
