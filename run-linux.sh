#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-release}"   # release | debug | profile

echo "==> Flutter pub get"
flutter pub get

echo "==> Running Linux ($MODE)"
flutter run -d linux "--$MODE"
