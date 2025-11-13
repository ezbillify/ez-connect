#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ENV=${APP_ENV:-test}
START_SUPABASE=${START_SUPABASE:-true}
WITH_COVERAGE=${WITH_COVERAGE:-true}
EXTRA_ARGS=("$@")

export APP_ENV

cleanup_supabase() {
  if command -v supabase >/dev/null 2>&1; then
    (cd "${PROJECT_ROOT}/supabase" && supabase stop >/dev/null 2>&1 || true)
  fi
}

if [[ "${START_SUPABASE}" == "true" ]]; then
  if command -v supabase >/dev/null 2>&1; then
    "${PROJECT_ROOT}/scripts/bootstrap_supabase_ci.sh"
    trap cleanup_supabase EXIT
  else
    echo "Supabase CLI not found. Skipping Supabase bootstrap. Set START_SUPABASE=false to suppress this warning." >&2
  fi
fi

pushd "${PROJECT_ROOT}" >/dev/null
flutter pub get

if [[ "${WITH_COVERAGE}" == "true" ]]; then
  flutter test --coverage "${EXTRA_ARGS[@]}"
else
  flutter test "${EXTRA_ARGS[@]}"
fi
popd >/dev/null
