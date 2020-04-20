# ShellCheck GitHub Action

![Version](https://img.shields.io/github/v/release/pataraco/shellcheck-action?style=flat-square)
 ![Shell Lint](https://github.com/pataraco/shellcheck-action/workflows/Shell%20Lint/badge.svg)

_Run [shellcheck](https://github.com/koalaman/shellcheck) on ALL shell files in the repository via GitHub actions_

## Example (using this public repo)

```
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
      - uses: actions/checkout@master
      - name: Check Shell Files
        uses: pataraco/shellcheck-action@v0.0.0
        env:
          EXCLUDE_DIRS: dir_name_1 dir_name_2 # dirs anywhere in the path
          # EXCLUDE_DIRS: ./dir_name          # specific directory
          # EXCLUDE_DIRS: ./path_to/dir_name  # specific deeper directory
          # EXCLUDE_DIRS: ./dir_1 dir_2       # combination of above
```

## Example (using a private repo)

If you decide to create your own copy and place in a private repo

```
name: Shell Lint

on:
  pull_request:
    types: ['opened', 'edited', 'reopened', 'synchronize']

jobs:
  shellcheck:
    name: Shell Check
    runs-on: ubuntu-latest
    steps:
      # checkout current repo
      - name: Checkout Repo
        uses: actions/checkout@v2
      # checkout the private repo containing the action to run
      - name: Checkout GitHub Action Private Repo
        uses: actions/checkout@v2
        with:
          repository: SomeGitHubUser/shellcheck-action
          ref: v0.0.0
	  # use a PAT of a user that has access to the private repo
	  # stored in GitHub secrets
          token: ${{ secrets.GIT_HUB_TOKEN }}
	  # store the repo (action) locally
          path: .github/actions/my-action
      - name: Check Shell Files
        # run the action locally
        uses: ./.github/actions/my-action
        env:
	  # good to exclude .github because the script will find/check there
          EXCLUDE_DIRS: .github
```

## Inspired By

This project was copied/modied from: [ludeeus/action-shellcheck](https://github.com/ludeeus/action-shellcheck)
