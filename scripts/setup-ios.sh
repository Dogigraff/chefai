#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Installing XcodeGen..."
  brew install xcodegen
fi

echo "Generating ChefOS.xcodeproj..."
xcodegen generate

echo ""
echo "Done. Open the project:"
echo "  open ChefOS.xcodeproj"
echo ""
echo "In Xcode:"
echo "  1. Select an iPhone Simulator"
echo "  2. Product → Run (⌘R)"
echo "  3. Optional: Edit Scheme → Run → Environment Variables → OPENAI_API_KEY"
