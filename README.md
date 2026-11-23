# Collector source maps

A GitHub Action that uploads a build's source maps to Collector, so stack
traces show your own code instead of minified bundles. It installs the
`collector` CLI from its GitHub release, checks the archive against the
release's `checksums.txt` and its signed build provenance, and runs
`collector upload`.

Runs on Linux and macOS runners, x64 and arm64.

```yaml
permissions:
  contents: read
  attestations: read # to check the CLI's build provenance

steps:
  - uses: actions/checkout@v7
  - run: npm ci && npm run build
  - uses: chrom-ar/collector-action@v1
    with:
      dir: dist
      upload-token: ${{ secrets.COLLECTOR_UPLOAD_TOKEN }}
      dsn: ${{ vars.COLLECTOR_DSN }}
```

Upload **before you deploy**: events from a release whose maps aren't
uploaded yet stay minified.

## Inputs

| Input | Default | |
|---|---|---|
| `dir` | | Required. The directory to upload, as built |
| `release` | `github.sha` | The release your app reports, exactly as it passes it to the SDK |
| `url-prefix` | `/` | The URL path `dir` is served at, e.g. `/assets` |
| `sources` | `false` | Make maps for scripts served as written, with no bundler (below) |
| `delete` | `false` | Delete the `.map` files after a successful upload, so they aren't deployed |
| `dry-run` | `false` | List what would be uploaded, and send nothing |
| `upload-token` | | An upload token (`cltu_…`), from a secret. Not needed for a dry run |
| `dsn` | | Your project's DSN, which says where Collector is |
| `version` | `latest` | The CLI version to use, e.g. `0.5.0` |
| `verify-attestation` | `true` | Check the CLI's build provenance with `gh attestation verify` |
| `best-effort` | `false` | Never fail the job: a failed install or upload is a warning instead |

## Outputs

| Output | |
|---|---|
| `version` | The `collector` CLI version used |

## Credentials

Create an upload token in your project's settings, or with
`collector upload-tokens create`, and keep it in a repository secret. It
can only upload source maps, and revoking it stops it at once. The DSN
isn't a secret; a repository variable is fine.

## Permissions

Checking the build provenance needs `attestations: read` (and
`contents: read` for the checkout). Without it, set
`verify-attestation: false`; the checksum is still checked.

## Recipes

### Vite

Set the release at build time, and build maps that aren't referenced from
the bundles, then upload and delete them before deploying `dist`:

```ts
// vite.config.ts
export default defineConfig({
  define: { __COLLECTOR_RELEASE__: JSON.stringify(process.env.GITHUB_SHA) },
  build: { sourcemap: "hidden" },
});
```

```yaml
- run: npm ci && npm run build
- uses: chrom-ar/collector-action@v1
  with:
    dir: dist
    delete: "true"
    upload-token: ${{ secrets.COLLECTOR_UPLOAD_TOKEN }}
    dsn: ${{ vars.COLLECTOR_DSN }}
- run: ./deploy.sh dist
```

Pass the same `GITHUB_SHA` to your app's `release`, so events and maps
match.

### No bundler (import maps)

Apps that serve their JavaScript as written, such as Rails with import
maps, have no maps to upload. `sources: true` makes one for each script
that has none: line for line, carrying the script itself, so stack traces
show your code and the lines around it. Point it at what's served, after
fingerprinting:

```yaml
- run: bin/rails assets:precompile
  env:
    RAILS_ENV: production
- uses: chrom-ar/collector-action@v1
  with:
    dir: public/assets
    url-prefix: /assets
    sources: "true"
    upload-token: ${{ secrets.COLLECTOR_UPLOAD_TOKEN }}
    dsn: ${{ vars.COLLECTOR_DSN }}
```

Minified scripts (vendored libraries) are skipped with a warning, and
scripts with a map of their own keep it. Asset digests are left out of the
names shown in stack traces, so `controllers/hello-1a2b3c4d.js` reads as
`controllers/hello.js`.

### Never block a deploy

```yaml
- uses: chrom-ar/collector-action@v1
  with:
    dir: dist
    best-effort: "true"
    upload-token: ${{ secrets.COLLECTOR_UPLOAD_TOKEN }}
    dsn: ${{ vars.COLLECTOR_DSN }}
```

A failed download, check or upload becomes a warning on the run, and the
job goes on. Inputs that aren't valid (`sources: yes`) still fail.

### Check it first

```yaml
- uses: chrom-ar/collector-action@v1
  with:
    dir: dist
    dry-run: "true"
```

## Security

- Every input reaches the scripts only as an environment variable and is
  passed to `collector` as an argument of its own; nothing is pasted into
  a shell command, so no input can run code.
- The upload token is masked in the log, and `collector` never prints it.
- The CLI comes only from its GitHub release, checked against
  `checksums.txt` and, by default, against the provenance signed by the
  release workflow.

## License

MIT
