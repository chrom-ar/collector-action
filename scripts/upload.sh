#!/usr/bin/env bash
# Runs collector upload with the action's inputs, each passed as an
# argument of its own.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

sources=${INPUT_SOURCES:-false}
delete=${INPUT_DELETE:-false}
dry_run=${INPUT_DRY_RUN:-false}
bool best-effort "${INPUT_BEST_EFFORT:-false}"
bool sources "$sources"
bool delete "$delete"
bool dry-run "$dry_run"

if [ -n "${COLLECTOR_UPLOAD_TOKEN:-}" ]; then
  echo "::add-mask::$COLLECTOR_UPLOAD_TOKEN"
fi
export COLLECTOR_NO_UPDATE_NOTIFIER=1

args=(upload "${INPUT_DIR:?dir is required}" --release "${INPUT_RELEASE:?release is required}" --url-prefix "${INPUT_URL_PREFIX:-/}")
[ "$sources" = true ] && args+=(--sources)
[ "$delete" = true ] && args+=(--delete)
[ "$dry_run" = true ] && args+=(--dry-run)

if ! "${COLLECTOR_BIN:?}" "${args[@]}"; then
  fail "collector couldn't upload the source maps"
fi
