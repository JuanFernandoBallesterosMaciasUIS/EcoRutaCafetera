#!/usr/bin/env bash
set -e

FLUTTER_DIR="/tmp/flutter"

# Install Flutter if not present (Vercel build environment is ephemeral)
if [ ! -d "$FLUTTER_DIR/bin" ]; then
  echo "Cloning Flutter stable..."
  git clone https://github.com/flutter/flutter.git \
    --depth 1 -b stable "$FLUTTER_DIR" --quiet
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release --web-renderer canvaskit

echo "Build complete → build/web"
