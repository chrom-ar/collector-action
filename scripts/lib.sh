# shellcheck shell=bash
# Shared by install.sh and upload.sh. Every input arrives as an
# environment variable: nothing from the workflow is ever pasted into a
# script.

# bool NAME VALUE: VALUE must be true or false.
bool() {
  case "$2" in
    true | false) ;;
    *)
      echo "::error::$1 must be true or false, not '$2'" >&2
      exit 2
      ;;
  esac
}

# fail MESSAGE: an error, or with best-effort a warning, and stop this step.
fail() {
  if [ "${INPUT_BEST_EFFORT:-false}" = true ]; then
    echo "::warning::$1 (best-effort: the job goes on)"
    exit 0
  fi
  echo "::error::$1"
  exit 1
}
