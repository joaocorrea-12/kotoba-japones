#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodegen >/dev/null; then
  echo "Instale o XcodeGen com: brew install xcodegen"
  exit 1
fi
xcodegen generate
echo "Projeto gerado. Abra Kotoba.xcodeproj e configure assinatura e App Groups."
