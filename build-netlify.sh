#!/bin/bash
set -e

echo "=== Installing Flutter ==="
git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
export PATH="$HOME/flutter/bin:$PATH"

echo "=== Building Web ==="
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release

echo "=== Build Complete ==="
