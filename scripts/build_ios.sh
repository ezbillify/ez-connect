#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ENV=${APP_ENV:-production}
EXTRA_ARGS=("$@")

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS builds can only be produced on macOS with Xcode installed." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode command line tools before continuing." >&2
  exit 1
fi

ENV_FILE="${PROJECT_ROOT}/config/environments/.env.${APP_ENV}"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file ${ENV_FILE} not found." >&2
  echo "Create it from the provided templates in config/environments/." >&2
  exit 1
fi

echo "Building iOS IPA for environment: ${APP_ENV}."

pushd "${PROJECT_ROOT}" >/dev/null
flutter pub get
flutter build ipa --release --dart-define=APP_ENV=${APP_ENV} "${EXTRA_ARGS[@]}"
popd >/dev/null

IPA_PATH=("${PROJECT_ROOT}"/build/ios/ipa/*.ipa)
if [[ -f "${IPA_PATH[0]}" ]]; then
  echo "iOS build complete: ${IPA_PATH[0]}"
  echo "Configure export options with --export-options-plist when distributing to TestFlight or App Store."
else
  echo "Build finished but no IPA artifact was produced. Check Flutter output above." >&2
fi
