#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${project_root}/tool/flutter_env.sh"
cd "${project_root}"

# CocoaPods crashes with Encoding::CompatibilityError under an ASCII locale.
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

xcode_major="$(xcodebuild -version | awk '/Xcode/ { split($2, version, "."); print version[1] }')"
if [[ -z "${xcode_major}" || "${xcode_major}" -lt 14 ]]; then
  echo "Xcode 14+ is required for the Construction Plan iOS build." >&2
  exit 1
fi

available_kb="$(df -Pk "${project_root}" | awk 'NR == 2 { print $4 }')"
minimum_kb=$((2 * 1024 * 1024))
if [[ "${available_kb}" -lt "${minimum_kb}" ]]; then
  available_gb="$(awk -v kb="${available_kb}" 'BEGIN { printf "%.1f", kb / 1024 / 1024 }')"
  echo "Not enough disk space: ${available_gb} GB available; iOS build requires at least 2 GB." >&2
  echo "Run 'flutter clean' and clear Xcode DerivedData before retrying." >&2
  exit 1
fi

flutter pub get

# Prefer the fast, locked install. Refresh specs only when the local CocoaPods
# index cannot satisfy Podfile.lock (common on a newly configured machine).
if ! (cd ios && pod install); then
  (cd ios && pod install --repo-update)
fi

if [[ "$#" -eq 0 ]]; then
  set -- --release --no-codesign --flavor prod -t lib/main_prod.dart
fi

flutter build ios "$@"
