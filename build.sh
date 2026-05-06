#!/bin/bash
set -e

echo "=== Flutter Web Build ==="

export FLUTTER_ROOT="$HOME/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
export PUB_CACHE="$HOME/.pub-cache"

# Install Flutter
if [ ! -d "$FLUTTER_ROOT" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_ROOT"
fi

# Quick setup
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release

echo "=== Build Complete ==="
