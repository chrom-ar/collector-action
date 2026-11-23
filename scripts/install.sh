#!/usr/bin/env bash
# Installs the collector CLI from its GitHub release: the archive for this
# runner, checked against the release's checksums.txt and, unless turned
# off, its signed build provenance.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

repo=chrom-ar/collector-cli
version=${INPUT_VERSION:-latest}
verify=${INPUT_VERIFY_ATTESTATION:-true}
bool best-effort "${INPUT_BEST_EFFORT:-false}"
bool verify-attestation "$verify"
echo "installed=false" >>"$GITHUB_OUTPUT"

case "${RUNNER_OS:-}" in
  Linux) os=linux ;;
  macOS) os=darwin ;;
  *) fail "collector-action runs on Linux and macOS runners, not ${RUNNER_OS:-this one}" ;;
esac
case "${RUNNER_ARCH:-}" in
  X64) arch=amd64 ;;
  ARM64) arch=arm64 ;;
  *) fail "collector-action runs on x64 and arm64 runners, not ${RUNNER_ARCH:-this one}" ;;
esac

if [ "$version" = latest ]; then
  # releases/latest redirects to releases/tag/<tag>: no API call, so no
  # rate limit.
  where=$(curl -fsSL --retry 3 --proto '=https' -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest") ||
    fail "couldn't find collector's latest release"
  tag=${where##*/}
  [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "couldn't find collector's latest release"
else
  if ! [[ "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "::error::version must be latest or a release like 0.5.0, not '$version'" >&2
    exit 2
  fi
  tag=v${version#v}
fi

archive="collector_${os}_${arch}.tar.gz"
dir="${RUNNER_TEMP:?}/collector-cli-$tag"
mkdir -p "$dir"
base="https://github.com/$repo/releases/download/$tag"
for file in "$archive" checksums.txt; do
  curl -fsSL --retry 3 --proto '=https' -o "$dir/$file" "$base/$file" ||
    fail "couldn't download $file of collector $tag"
done

want=$(awk -v f="$archive" '$2 == f { print $1 }' "$dir/checksums.txt")
if command -v sha256sum >/dev/null; then
  got=$(sha256sum "$dir/$archive" | awk '{ print $1 }')
else
  got=$(shasum -a 256 "$dir/$archive" | awk '{ print $1 }')
fi
if [ -z "$want" ] || [ "$want" != "$got" ]; then
  fail "$archive of collector $tag doesn't match checksums.txt"
fi

if [ "$verify" = true ]; then
  command -v gh >/dev/null || fail "verify-attestation needs the gh CLI on the runner"
  gh attestation verify "$dir/$archive" --repo "$repo" \
    --signer-workflow "$repo/.github/workflows/release.yml" >/dev/null ||
    fail "$archive of collector $tag has no valid build provenance (permissions: attestations: read is needed)"
fi

tar -xzf "$dir/$archive" -C "$dir" collector
bin="$dir/collector"
installed=$("$bin" --version | awk '{ print $2 }')
echo "$dir" >>"$GITHUB_PATH"
{
  echo "installed=true"
  echo "version=$installed"
  echo "path=$bin"
} >>"$GITHUB_OUTPUT"
echo "collector $installed installed ($os/$arch)"
