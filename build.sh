#!/bin/bash
cd "$(dirname "$0")"
echo "Building release..."
flutter build linux --release || flutter build macos --release
