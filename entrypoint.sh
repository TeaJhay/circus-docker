#!/bin/sh
set -e
export PATH=/root/.nix-profile/bin:$PATH

mkdir -p /var/empty /run/sshd /root/.ssh /keys
grep -q '^sshd:' /etc/passwd || echo 'sshd:x:74:74:sshd:/var/empty:/bin/false' >> /etc/passwd
[ -f /keys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -N '' -f /keys/ssh_host_ed25519_key
# Start sshd in the background
"$(command -v sshd)" -D -e -h /keys/ssh_host_ed25519_key \
  -o PermitRootLogin=permit -o PasswordAuthentication=yes &

# --- Template defaults (placeholders: verify against Circus's defaults) ---
export DB_URL="${DB_URL:-${CIRCUS_DATABASE__URL:-postgresql://circus@localhost/circus}}"
export CIRCUS_DATABASE__URL="$DB_URL"
export CONNECTION_TIMEOUT="${CONNECTION_TIMEOUT:-30}"
export MAX_CONNECTIONS="${MAX_CONNECTIONS:-20}"

export ALLOWED_ORIGINS="${ALLOWED_ORIGINS:-\"http://localhost:3000\"}"
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-3000}"
export MAX_BODY_SIZE="${MAX_BODY_SIZE:-10485760}"
export REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-30}"

export ALLOW_IFD="${ALLOW_IFD:-false}"
export AUTO_ALLOWED_URIS="${AUTO_ALLOWED_URIS:-[]}"
export GIT_TIMEOUT="${GIT_TIMEOUT:-600}"
export NIX_TIMEOUT="${NIX_TIMEOUT:-1800}"
export POLL_INTERVAL_EVAL="${POLL_INTERVAL_EVAL:-60}"
export REQUIRE_LOCKED_FLAKE="${REQUIRE_LOCKED_FLAKE:-false}"
export RESTRICT_EVAL="${RESTRICT_EVAL:-true}"
export WORK_DIR_EVAL="${WORK_DIR_EVAL:-/var/lib/circus/eval}"

export BUILD_TIMEOUT="${BUILD_TIMEOUT:-3600}"
export POLL_INTERVAL_QUEUE="${POLL_INTERVAL_QUEUE:-5}"
export WORK_DIR_QUEUE="${WORK_DIR_QUEUE:-/var/lib/circus/queue}"
export WORKERS="${WORKERS:-4}"

export CACHE_BOOL="${CACHE_BOOL:-false}"

mkdir -p "$WORK_DIR_EVAL" "$WORK_DIR_QUEUE"

envsubst '${CONNECTION_TIMEOUT} ${MAX_CONNECTIONS} ${DB_URL}
          ${ALLOWED_ORIGINS} ${HOST} ${MAX_BODY_SIZE} ${PORT} ${REQUEST_TIMEOUT}
          ${ALLOW_IFD} ${AUTO_ALLOWED_URIS} ${GIT_TIMEOUT} ${NIX_TIMEOUT}
          ${POLL_INTERVAL_EVAL} ${REQUIRE_LOCKED_FLAKE} ${RESTRICT_EVAL} ${WORK_DIR_EVAL}
          ${BUILD_TIMEOUT} ${POLL_INTERVAL_QUEUE} ${WORK_DIR_QUEUE} ${WORKERS}
          ${CACHE_BOOL}' \
  < /etc/circus.toml.tpl > /etc/circus.toml

export CIRCUS_CONFIG_FILE="${CIRCUS_CONFIG_FILE:-/etc/circus.toml}"

# Wait for PostgreSQL
until pg_isready -d "$DB_URL" >/dev/null 2>&1; do
  echo "waiting for postgres..."
  sleep 1
done

# Step 2: migrations
circusctl migrate up "$DB_URL"

# Step 4: evaluator and queue runner
circus-evaluator &
circus-queue-runner &

# Step 3: server
exec circus-server
