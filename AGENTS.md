# Working in this repository

`chrom-ar/collector-action` is the GitHub Action that installs the
`collector` CLI from its release and uploads a build's source maps to
Collector.

- Inputs reach the scripts as environment variables only, never pasted
  into `run:`, so none can inject commands. No third-party actions, and
  nothing downloaded is piped into a shell.
- Every download is checked against the release's `checksums.txt`, and
  by default its build provenance (`gh attestation verify`).
- `shellcheck -x scripts/*.sh` and `actionlint` are clean; the `test`
  workflow runs the action on Linux and macOS, x64 and arm64, with dry
  runs.
- Comments only say what the code can't: no excuses for sloppy code, no
  restating what a good name or signature would, no history.
- Never commit or run git-modifying commands unless asked; end each change
  with a commit subject of 50 characters or less.
- Never name or point at other codebases in code, comments or docs.
- Releases: tag `vX.Y.Z`, move `v1` to it and publish a GitHub Release for
  the tag (the Marketplace lists releases). Say whether a change is worth
  releasing, with the commands.
