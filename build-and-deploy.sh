#!/bin/bash
set -e

echo "=== Building Flutter Web App ==="

# Build web
flutter build web --release

echo "=== Build Complete ==="
echo "=== Deploying to Firebase Hosting ==="

# Deploy to Firebase
firebase deploy --only hosting

echo "=== Deployment Complete ==="
echo "Your app is now live!"
