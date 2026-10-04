# Circus config template, rendered by entrypoint.sh with envsubst.
# Every variable below has a default in entrypoint.sh.
# The *_OPT placeholders expand to optional keys, and only when you set them.
# EXTRA_TOML at the bottom is appended verbatim for anything not covered here.

[database]
connect_timeout = ${CONNECTION_TIMEOUT}
max_connections = ${MAX_CONNECTIONS}
url             = "${DB_URL}"

[server]
allowed_origins           = [ "${ALLOWED_ORIGINS}" ]
host                      = "${HOST}"
port                      = ${PORT}
max_body_size             = ${MAX_BODY_SIZE}
request_timeout           = ${REQUEST_TIMEOUT}
cors_permissive           = ${CORS_PERMISSIVE}
force_secure_cookies      = ${FORCE_SECURE_COOKIES}
openapi_enabled           = ${OPENAPI_ENABLED}
require_api_key_for_reads = ${REQUIRE_API_KEY_FOR_READS}
${SERVER_OPT}

[ui]
enabled        = ${UI_ENABLED}
dashboard      = ${UI_DASHBOARD}
assets         = ${UI_ASSETS}
brand_name     = "${UI_BRAND_NAME}"
brand_subtitle = "${UI_BRAND_SUBTITLE}"
${UI_OPT}

${UI_CSS_TABLE}

[evaluator]
allow_ifd            = ${ALLOW_IFD}
auto_allowed_uris    = ${AUTO_ALLOWED_URIS}
git_timeout          = ${GIT_TIMEOUT}
nix_timeout          = ${NIX_TIMEOUT}
poll_interval        = ${POLL_INTERVAL_EVAL}
require_locked_flake = ${REQUIRE_LOCKED_FLAKE}
restrict_eval        = ${RESTRICT_EVAL}
work_dir             = "${WORK_DIR_EVAL}"
max_concurrent_evals = ${MAX_CONCURRENT_EVALS}
eval_workers         = ${EVAL_WORKERS}
${EVALUATOR_OPT}

[queue_runner]
build_timeout     = ${BUILD_TIMEOUT}
poll_interval     = ${POLL_INTERVAL_QUEUE}
work_dir          = "${WORK_DIR_QUEUE}"
workers           = ${WORKERS}
max_silent_time   = ${MAX_SILENT_TIME}
failed_paths_cache = ${FAILED_PATHS_CACHE}
failed_paths_ttl  = ${FAILED_PATHS_TTL}
${QUEUE_RUNNER_OPT}

[cache]
enabled = ${CACHE_BOOL}
${CACHE_OPT}

${CACHE_UPSTREAM_TABLE}

[signing]
enabled = ${SIGNING_ENABLED}
${SIGNING_OPT}

[gc]
enabled          = ${GC_ENABLED}
max_age_days     = ${GC_MAX_AGE_DAYS}
cleanup_interval = ${GC_CLEANUP_INTERVAL}
${GC_OPT}

[logs]
log_dir  = "${LOG_DIR}"
compress = ${LOG_COMPRESS}

[tracing]
level  = "${LOG_LEVEL}"
format = "${LOG_FORMAT}"

[notifications]
email.smtp_host =	"${EMAIL_HOST}"
email.smtp_port = ${EMAIL_PORT}
email.smtp_user = "${EMAIL_USER}"
email.smtp_password = "${EMAIL_PASSWORD}"
email.tls = ${EMAIL_TLS}
email.from_address = "${EMAIL_ADDRESS}"
email.to_addresses =	[ "${EMAIL_RECIPIENTS}" ]
slack.on_failure_only = false
${EXTRA_TOML}
