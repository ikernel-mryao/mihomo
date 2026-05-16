#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

"$ROOT_DIR/stop-mihomo.sh" "${1:-}"
exec "$ROOT_DIR/start-mihomo.sh"
