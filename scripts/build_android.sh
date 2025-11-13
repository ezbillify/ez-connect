#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ENV=${APP_ENV:-production}
BUILD_TARGET=${BUILD_TARGET:-appbundle}
EXTRA_ARGS=()

if [[ $# -gt 0 ]]; then
  BUILD_TARGET=$1
  shift
fi

EXTRA_ARGS=("$@")

if [[ "${BUILD_TARGET}" != "apk" && "${BUILD_TARGET}" != "appbundle" ]]; then
  echo "Unsupported build target: ${BUILD_TARGET}. Use 'apk' or 'appbundle'." >&2
  exit 1
fi

ENV_FILE="${PROJECT_ROOT}/config/environments/.env.${APP_ENV}"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file ${ENV_FILE} not found." >&2
  echo "Create it from the provided templates in config/environments/." >&2
  exit 1
fi

KEY_PROPERTIES="${PROJECT_ROOT}/android/key.properties"
if [[ ! -f "${KEY_PROPERTIES}" ]]; then
  echo "⚠️  android/key.properties not found. Release builds will fall back to the debug keystore." >&2
fi

echo "Building Android ${BUILD_TARGET} for environment: ${APP_ENV}."

pushd "${PROJECT_ROOT}" >/dev/null
flutter pub get
flutter build "${BUILD_TARGET}" --release --dart-define=APP_ENV=${APP_ENV} "${EXTRA_ARGS[@]}"
popd >/dev/null

case "${BUILD_TARGET}" in
  apk)
    ARTIFACT="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-release.apk"
    ;;
  appbundle)
    ARTIFACT="${PROJECT_ROOT}/build/app/outputs/bundle/release/app-release.aab"
    ;;
esac

if [[ -f "${ARTIFACT}" ]]; then
  echo "Android build complete: ${ARTIFACT}"
else
  echo "Build finished but the expected artifact was not found at ${ARTIFACT}." >&2
fi
