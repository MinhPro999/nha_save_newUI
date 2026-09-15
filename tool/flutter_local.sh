#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/flutter_env.sh"

cd "$FLUTTER_PROJECT_ROOT"
exec flutter "$@"
