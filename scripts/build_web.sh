#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ENV=${APP_ENV:-production}
EXTRA_ARGS=("$@")
ENV_FILE="${PROJECT_ROOT}/config/environments/.env.${APP_ENV}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file ${ENV_FILE} not found." >&2
  echo "Create it from the provided templates in config/environments/." >&2
  exit 1
fi

echo "Building Flutter web bundle for environment: ${APP_ENV}."

pushd "${PROJECT_ROOT}" >/dev/null
flutter pub get
flutter build web --release --dart-define=APP_ENV=${APP_ENV} "${EXTRA_ARGS[@]}"
popd >/dev/null

BUILD_DIR="${PROJECT_ROOT}/build/web"
if [[ -d "${BUILD_DIR}" ]]; then
  echo "Web build complete: ${BUILD_DIR}"
else
  echo "Build failed. Verify Flutter output above." >&2
  exit 1
fi
