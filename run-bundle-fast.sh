#!/bin/sh

# Fast bundle build - uses incremental compilation (no clean)

# Stop any existing Flutter daemon processes to clear file watchers
#echo "Stopping Flutter daemon..."
#flutter --suppress-analytics daemon shutdown 2>/dev/null || true

# Kill any lingering Flutter processes
pkill -f "flutter" 2>/dev/null || true

# Brief pause to ensure processes are cleaned up
sleep 1

echo "Building release bundle..."
flutter build appbundle --release

exit 0
