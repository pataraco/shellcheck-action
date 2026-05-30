# ShellCheck GitHub Action

[![Release](https://img.shields.io/github/v/release/pataraco/shellcheck-action?label=release&logo=github&style=flat-square)](https://github.com/pataraco/shellcheck-action/releases/latest)
[![Shell Lint](https://img.shields.io/github/actions/workflow/status/pataraco/shellcheck-action/shell_linting.yaml?branch=master&label=shell%20lint&logo=github&style=flat-square)](https://github.com/pataraco/shellcheck-action/actions/workflows/shell_linting.yaml)

_Run [shellcheck](https://github.com/koalaman/shellcheck) on ALL shell files in the repository via GitHub Actions._

The action discovers every shell script/file in the repo (by name, path, or
shebang), runs ShellCheck over them, and emits **inline GitHub annotations** so
findings show up on the PR diff — not just buried in the job log.

## Inputs

| Input | Default | Description |
|---|---|---|
| `exclude_dirs` | `''` | Space-separated directory names/paths to skip. A bare name (`vendor`) matches anywhere in the tree; a `./`-prefixed value (`./build`) matches that specific path. |
| `severity` | `style` | Minimum severity to report **and fail on**: `error`, `warning`, `info`, or `style`. Use `error`/`warning` to keep style/info findings non-blocking. |
| `external_sources` | `false` | `true` to follow `source`d files (`shellcheck -x`). |

> ShellCheck is pinned to a specific release in the image for reproducible runs
> (see `SHELLCHECK_VERSION` in the `Dockerfile`).

## Versioning

**Pin to an exact release** — e.g. `pataraco/shellcheck-action@v1.0.0` — for
reproducible builds. Let [Dependabot](https://docs.github.com/code-security/dependabot)
(`github-actions` ecosystem) propose version bumps as PRs so updates stay
reviewable. A floating major tag (`@v1`) also exists if you prefer to auto-track
`v1.x` patches, at the cost of reproducibility.

## Example

```yaml
name: Shell Lint

on:
  push:
    branches:
      - master
  pull_request:
    branches:
      - master
    types: ['opened', 'edited', 'reopened', 'synchronize']

jobs:
  shellcheck:
    name: Shell Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Check Shell Files
        uses: pataraco/shellcheck-action@v1.0.0
        with:
          # all inputs are optional
          exclude_dirs: '.github vendor'   # dir names anywhere, or ./specific/path
          severity: 'warning'              # fail on warning+; ignore info/style
          external_sources: 'false'
```

Minimal (lint everything, fail on any finding):

```yaml
      - uses: actions/checkout@v5
      - uses: pataraco/shellcheck-action@v1.0.0
```

## Example (using a private copy)

If you fork this into a private repo, check it out alongside your code and run it locally:

```yaml
jobs:
  shellcheck:
    name: Shell Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v5
      - name: Checkout the action (private)
        uses: actions/checkout@v5
        with:
          repository: SomeGitHubUser/shellcheck-action
          ref: v1.0.0
          token: ${{ secrets.GH_PAT }}   # PAT with access to the private repo
          path: .github/actions/shellcheck-action
      - name: Check Shell Files
        uses: ./.github/actions/shellcheck-action
        with:
          exclude_dirs: '.github'        # the action lives here; skip it
```

## Inspired By

Copied/modified from [ludeeus/action-shellcheck](https://github.com/ludeeus/action-shellcheck).
