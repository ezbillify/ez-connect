#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUPABASE_DIR="${PROJECT_ROOT}/supabase"
SUPABASE_BIN=${SUPABASE_BIN:-supabase}

if ! command -v "${SUPABASE_BIN}" >/dev/null 2>&1; then
  echo "Supabase CLI is required but was not found on PATH." >&2
  echo "Install it with: npm install -g supabase" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required to run the local Supabase stack." >&2
  exit 1
fi

pushd "${SUPABASE_DIR}" >/dev/null

# Ensure we start from a clean state
"${SUPABASE_BIN}" stop >/dev/null 2>&1 || true

# Start the local Supabase stack (skip optional heavy services for CI to reduce resource usage)
"${SUPABASE_BIN}" start -x studio,inbucket,edge-runtime >"${PROJECT_ROOT}/supabase-ci.log" 2>&1 || {
  echo "Failed to start Supabase services. See supabase-ci.log for details." >&2
  popd >/dev/null
  exit 1
}

# Ensure the API is ready before applying migrations
"${PROJECT_ROOT}/scripts/wait_for_supabase.sh" 127.0.0.1 54321 120

# Reset and apply migrations (includes seed data through migration files)
yes | "${SUPABASE_BIN}" db reset >/dev/null

"${SUPABASE_BIN}" status

popd >/dev/null
