#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"

cd "$ROOT_DIR"
echo "Card Admin Web starting on http://localhost:${PORT}"
echo "Also available path: http://localhost:${PORT}/card-admin"
if [[ -n "${LAN_IP}" ]]; then
  echo "iPhone/Android access URL: http://${LAN_IP}:${PORT}/card-admin"
fi
python3 -m http.server "${PORT}" --bind 0.0.0.0
