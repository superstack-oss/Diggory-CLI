#!/bin/bash
# Lightweight alias to run Diggory via `mo`

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/diggory" "$@"
