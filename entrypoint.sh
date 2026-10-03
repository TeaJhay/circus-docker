#!/bin/sh
set -e
export PATH=/root/.nix-profile/bin:$PATH

# ===================== sshd =====================
mkdir -p /var/empty /run/sshd /root/.ssh /keys
chmod 700 /root/.ssh
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
  printf '%s\n' "$SSH_AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi
grep -q '^sshd:' /etc/passwd || echo 'sshd:x:74:74:sshd:/var/empty:/bin/false' >> /etc/passwd
[ -f /keys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -N '' -f /keys/ssh_host_ed25519_key
"$(command -v sshd)" -D -e -h /keys/ssh_host_ed25519_key \
  -o PermitRootLogin=prohibit-password -o PasswordAuthentication=no &

# ===================== CONFIG BEGIN =====================
# Every default below can be overridden from the container environment.
# Values are the documented Circus defaults unless noted.
set -a

# --- database ---
: "${DB_URL:=${CIRCUS_DATABASE__URL:-postgresql://circus@postgres/circus?sslmode=disable}}"
: "${CONNECTION_TIMEOUT:=30}"
: "${MAX_CONNECTIONS:=20}"

# --- server ---
: "${ALLOWED_ORIGINS=http://localhost:3000}"   # comma-separated, plain URLs
: "${HOST:=0.0.0.0}"                            # container default; Circus's own is 127.0.0.1
: "${PORT:=3000}"
: "${MAX_BODY_SIZE:=10485760}"
: "${REQUEST_TIMEOUT:=30}"
: "${CORS_PERMISSIVE:=false}"
: "${FORCE_SECURE_COOKIES:=false}"              # true when behind an HTTPS proxy
: "${OPENAPI_ENABLED:=true}"
: "${REQUIRE_API_KEY_FOR_READS:=true}"
# Optional (unset = omitted): RATE_LIMIT_RPS RATE_LIMIT_BURST
#   ALLOWED_URL_SCHEMES (TOML list, e.g. ["https","ssh"]) CONFIG_EDITOR_ENABLED
#   WEBHOOK_SECRET_ENCRYPTION_KEY_FILE   SERVER_EXTRA (raw TOML lines)

# --- ui ---
: "${UI_ENABLED:=true}"
: "${UI_DASHBOARD:=true}"
: "${UI_ASSETS:=true}"
: "${UI_BRAND_NAME:=circus}"
: "${UI_BRAND_SUBTITLE:=Nix CI}"
# Optional: UI_LOGO_URL UI_FAVICON_URL UI_CUSTOM_CSS UI_STATIC_DIR UI_EXTRA
#   UI_CSS_VARIABLES="accent=#2563eb,bg=#f8fafc,text=#0f172a"

# --- evaluator ---
: "${ALLOW_IFD:=false}"
: "${AUTO_ALLOWED_URIS:=true}"
: "${GIT_TIMEOUT:=600}"
: "${NIX_TIMEOUT:=1800}"
: "${POLL_INTERVAL_EVAL:=60}"
: "${REQUIRE_LOCKED_FLAKE:=false}"
: "${RESTRICT_EVAL:=true}"
: "${WORK_DIR_EVAL:=/var/lib/circus/eval}"
: "${MAX_CONCURRENT_EVALS:=4}"
: "${EVAL_WORKERS:=4}"
# Optional: MAX_EVAL_TIME MEMORY_LIMIT_MB (per Nix subprocess; peak is roughly
#   MEMORY_LIMIT_MB * EVAL_WORKERS * MAX_CONCURRENT_EVALS)   EVALUATOR_EXTRA

# --- queue runner ---
: "${BUILD_TIMEOUT:=3600}"
: "${POLL_INTERVAL_QUEUE:=5}"
: "${WORK_DIR_QUEUE:=/var/lib/circus/queue}"
: "${WORKERS:=4}"
: "${MAX_SILENT_TIME:=0}"
: "${FAILED_PATHS_CACHE:=true}"
: "${FAILED_PATHS_TTL:=86400}"
# Optional: QUEUE_RUNNER_EXTRA

# --- cache / signing ---
: "${CACHE_BOOL:=false}"                        # Circus's own default is true
# Optional: CACHE_URL CACHE_EXTRA
#   CACHE_UPSTREAM + CACHE_UPSTREAM_KEY (one upstream; more via EXTRA_TOML)
: "${SIGNING_ENABLED:=false}"
# Optional: SIGNING_KEY_FILE (mount the key as a file) SIGNING_EXTRA

# --- gc / logs / tracing ---
: "${GC_ENABLED:=true}"
: "${GC_MAX_AGE_DAYS:=30}"
: "${GC_CLEANUP_INTERVAL:=3600}"
# Optional: GC_ROOTS_DIR GC_EXTRA
: "${LOG_DIR:=/var/lib/circus/logs}"
: "${LOG_COMPRESS:=false}"
: "${LOG_LEVEL:=info}"
: "${LOG_FORMAT:=compact}"

# --- escape hatch: raw TOML appended at the end of the file ---
# EXTRA_TOML="..."  and/or  EXTRA_TOML_FILE=/path/to/extra.toml
# Use it for new tables or array entries (e.g. [[declarative.projects]],
# more [[cache.upstreams]]). It cannot redefine a table already in the template;
# use the per-section *_EXTRA variables to add keys to an existing table.

# Helpers: print "key = value" only when the value is non-empty.
opt_raw() { [ -n "$2" ] && printf '%s = %s\n'   "$1" "$2"; return 0; }
opt_str() { [ -n "$2" ] && printf '%s = "%s"\n' "$1" "$2"; return 0; }

css_table() {
  [ -n "$UI_CSS_VARIABLES" ] || return 0
  echo "[ui.css_variables]"
  IFS=,
  for kv in $UI_CSS_VARIABLES; do
    printf '%s = "%s"\n' "${kv%%=*}" "${kv#*=}"
  done
}

SERVER_OPT="$(
  opt_raw rate_limit_rps "$RATE_LIMIT_RPS"
  opt_raw rate_limit_burst "$RATE_LIMIT_BURST"
  opt_raw allowed_url_schemes "$ALLOWED_URL_SCHEMES"
  opt_raw config_editor_enabled "$CONFIG_EDITOR_ENABLED"
  opt_str webhook_secret_encryption_key_file "$WEBHOOK_SECRET_ENCRYPTION_KEY_FILE"
  printf '%s' "$SERVER_EXTRA"
)"
UI_OPT="$(
  opt_str logo_url "$UI_LOGO_URL"
  opt_str favicon_url "$UI_FAVICON_URL"
  opt_str custom_css "$UI_CUSTOM_CSS"
  opt_str static_dir "$UI_STATIC_DIR"
  printf '%s' "$UI_EXTRA"
)"
UI_CSS_TABLE="$(css_table)"
EVALUATOR_OPT="$(
  opt_raw max_eval_time "$MAX_EVAL_TIME"
  opt_raw memory_limit_mb "$MEMORY_LIMIT_MB"
  printf '%s' "$EVALUATOR_EXTRA"
)"
QUEUE_RUNNER_OPT="$(printf '%s' "$QUEUE_RUNNER_EXTRA")"
CACHE_OPT="$(
  opt_str cache_url "$CACHE_URL"
  printf '%s' "$CACHE_EXTRA"
)"
CACHE_UPSTREAM_TABLE=""
if [ -n "$CACHE_UPSTREAM" ]; then
  CACHE_UPSTREAM_TABLE="[[cache.upstreams]]
url        = \"$CACHE_UPSTREAM\"
public_key = \"$CACHE_UPSTREAM_KEY\""
fi
SIGNING_OPT="$(
  opt_str key_file "$SIGNING_KEY_FILE"
  printf '%s' "$SIGNING_EXTRA"
)"
GC_OPT="$(
  opt_str gc_roots_dir "$GC_ROOTS_DIR"
  printf '%s' "$GC_EXTRA"
)"
if [ -n "$EXTRA_TOML_FILE" ] && [ -f "$EXTRA_TOML_FILE" ]; then
  EXTRA_TOML="$EXTRA_TOML
$(cat "$EXTRA_TOML_FILE")"
fi
set +a

mkdir -p "$WORK_DIR_EVAL" "$WORK_DIR_QUEUE" "$LOG_DIR"

# Substitute exactly the variables the template references, so the list can't drift.
TPL="${CIRCUS_TEMPLATE:-/etc/circus.toml.tpl}"
OUT="${CIRCUS_RENDERED:-/etc/circus.toml}"
VARS="$(grep -o '\${[A-Za-z_][A-Za-z0-9_]*}' "$TPL" | sort -u | tr '\n' ' ')"
envsubst "$VARS" < "$TPL" > "$OUT"

export CIRCUS_CONFIG_FILE="${CIRCUS_CONFIG_FILE:-$OUT}"
export CIRCUS_DATABASE__URL="$DB_URL"
# ===================== CONFIG END =====================

# ===================== database =====================
# Optional: create the role and database on an existing server (needs a superuser URL).
if [ -n "$PG_ADMIN_URL" ]; then
  until pg_isready -d "$PG_ADMIN_URL" >/dev/null 2>&1; do sleep 1; done
  psql "$PG_ADMIN_URL" -tAc "SELECT 1 FROM pg_roles WHERE rolname='circus'" | grep -q 1 \
    || psql "$PG_ADMIN_URL" -c "CREATE ROLE circus LOGIN"
  psql "$PG_ADMIN_URL" -tAc "SELECT 1 FROM pg_database WHERE datname='circus'" | grep -q 1 \
    || psql "$PG_ADMIN_URL" -c "CREATE DATABASE circus OWNER circus"
fi

until pg_isready -d "$DB_URL" >/dev/null 2>&1; do
  echo "waiting for postgres..."
  sleep 1
done

circusctl migrate up "$DB_URL"

# Seed the initial admin API key (idempotent). Format: circus_<hex>
if [ -n "$CIRCUS_ADMIN_KEY" ]; then
  KEY_HASH=$(printf '%s' "$CIRCUS_ADMIN_KEY" | sha256sum | cut -d' ' -f1)
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
    "INSERT INTO api_keys (name, key_hash, role)
     SELECT 'admin', '$KEY_HASH', 'admin'
     WHERE NOT EXISTS (SELECT 1 FROM api_keys WHERE key_hash = '$KEY_HASH')"
fi

# ===================== services =====================
circus-evaluator &
circus-queue-runner &
exec circus-server
