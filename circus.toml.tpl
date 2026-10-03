# Configuration File for Circus CI system
# This file contains default configuration for all circus components
[database]
connect_timeout = ${CONNECTION_TIMEOUT}
max_connections = ${MAX_CONNECTIONS}
url             = "${DB_URL}"

[server]
allowed_origins = [ ${ALLOWED_ORIGINS} ]
host            = "${HOST}"
max_body_size   = ${MAX_BODY_SIZE}    # 10MB
port            = ${PORT}
request_timeout = ${REQUEST_TIMEOUT}

# Security options
# openapi_enabled      = false # disable /api/v1/openapi.json
# force_secure_cookies = true # enable when behind HTTPS reverse proxy (nginx/caddy)
# rate_limit_rps       = 100  # requests per second per IP (helps prevent DoS attacks)
# rate_limit_burst     = 20   # burst size before rate limit enforcement

[ui]
assets         = true
brand_name     = "circus"
brand_subtitle = "Nix CI"
dashboard      = true
enabled        = true
# logo_url    = "/static/custom/logo.svg"
# favicon_url = "/static/custom/favicon.svg"
# custom_css  = "/etc/circus/dashboard.css"
# static_dir  = "/etc/circus/static"

# [ui.css_variables]
# accent = "#2563eb"
# bg     = "#f8fafc"
# text   = "#0f172a"

[evaluator]
allow_ifd         = ${ALLOW_IFD}
auto_allowed_uris = ${AUTO_ALLOWED_URIS}
git_timeout       = ${GIT_TIMEOUT}
nix_timeout       = ${NIX_TIMEOUT}
# max_eval_time      = 3600
# Per Nix subprocess. Peak evaluator allowance is approximately this times
# eval_workers times max_concurrent_evals, plus the Circus parent process.
# memory_limit_mb     = 4096
poll_interval        = ${POLL_INTERVAL_EVAL} 
require_locked_flake = ${REQUIRE_LOCKED_FLAKE}
restrict_eval        = ${RESTRICT_EVAL}
work_dir             = "${WORK_DIR_EVAL}"

[queue_runner]
build_timeout = ${BUILD_TIMEOUT}
poll_interval = ${POLL_INTERVAL_QUEUE}
work_dir      = "${WORK_DIR_QUEUE}"
workers       = ${WORKERS}

[cache]
enabled = ${CACHE_BOOL}
# cache_url = "https://ci.example.org/nix-cache/"

# [[cache.upstreams]]
# url = "${CACHE_UPSTREAM}"
# public_key = "${CACHE_UPSTREAM_KEY}"
