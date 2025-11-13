#!/usr/bin/env bash
set -euo pipefail

HOST=${1:-127.0.0.1}
PORT=${2:-54321}
TIMEOUT=${3:-90}

if ! command -v nc >/dev/null 2>&1; then
  echo "[wait_for_supabase] netcat (nc) is not installed. Falling back to Python socket check." >&2
  python3 - "${HOST}" "${PORT}" "${TIMEOUT}" <<'PY'
import socket
import sys
import time

host = sys.argv[1]
port = int(sys.argv[2])
timeout = int(sys.argv[3])
end_time = time.time() + timeout

while time.time() < end_time:
    try:
        with socket.create_connection((host, port), timeout=2):
            print('Supabase service is reachable on %s:%s' % (host, port))
            sys.exit(0)
    except OSError:
        time.sleep(1)

print('Timed out waiting for Supabase at %s:%s' % (host, port), file=sys.stderr)
sys.exit(1)
PY
  exit 0
fi

for ((i=1; i<=TIMEOUT; i++)); do
  if nc -z "${HOST}" "${PORT}" >/dev/null 2>&1; then
    echo "Supabase service is reachable on ${HOST}:${PORT}"
    exit 0
  fi
  sleep 1
  if (( i % 5 == 0 )); then
    echo "Waiting for Supabase to accept connections on ${HOST}:${PORT} (elapsed: ${i}s)"
  fi

done

echo "Timed out waiting for Supabase to accept connections on ${HOST}:${PORT} after ${TIMEOUT}s" >&2
exit 1
