# commit-release-template

A starting point for repositories that check every commit message and release automatically with Git Flow.

- **Commit checks:** husky runs commitlint on every commit (`commit-msg` hook).
- **Releases:** semantic-release on `main` decides the version from commit messages and writes `CHANGELOG.md`, the `package.json` version, a Git tag, and a GitHub Release.
- **Release branch check:** a pull request from `release/<version>` to `main` fails if `<version>` is not the version semantic-release will publish.

## Requirements

- [mise](https://mise.jdx.dev) (installs Node 24, pnpm 12.10.0, bun, gh from `mise.toml`)
- A GitHub account that can create a GitHub App

## Getting started

1. Click **Use this template** and select **Include all branches** so `develop` is copied too.
2. Clone the new repository and install the tools and dependencies:

   ```sh
   mise trust
   mise install
   pnpm install
   ```

   `pnpm install` runs `prepare`, which points Git hooks at `.husky/_`.
3. Change `name` in `package.json` to your repository name.
4. Set up the release app, repository rules, and merge settings below. Settings are not copied from a template.

### Release app

`main` only accepts pull requests, so the release workflow pushes the release commit with a GitHub App that may bypass that rule.

1. Create a GitHub App (Settings → Developer settings → GitHub Apps → New GitHub App).
   - Repository permissions: **Contents**, **Issues**, **Pull requests**: Read and write.
   - Webhook: off.
2. Generate a private key and install the app on this repository only.
3. Add repository secrets (Settings → Secrets and variables → Actions):
   - `RELEASE_APP_CLIENT_ID`: the app's Client ID (on the app's General page)
   - `RELEASE_APP_PRIVATE_KEY`: the private key file contents

### Repository rules

Create two branch rulesets (Settings → Rules → Rulesets):

| Ruleset | Target | Rules | Bypass list |
| ------- | ------ | ----- | ----------- |
| main | `main` | Require a pull request, block force pushes, restrict deletions | the release app |
| develop | `develop` | Require a pull request, block force pushes, restrict deletions | none |

### Merge settings

Allow **merge commits** only and turn off squash and rebase merging (Settings → General → Pull Requests). A squash merge turns the pull request title into the commit message without running commitlint.

## Commit messages

Every commit must pass these rules. Merge commits, `Revert "…"` commits, and semantic-release's `chore(release): x.y.z [skip ci]` commits are skipped.

| Rule | Setting |
| ---- | ------- |
| `type-enum` | `feat`, `fix`, `docs`, `refactor`, `test`, `chore` |
| `header-max-length` | 50 characters, including type and scope |
| `subject-case` | lower case only (`update readme`, not `update README`) |
| `ascii-only` | ASCII characters only in the whole message (Git comment lines are ignored) |
| `tense/subject-tense` | the first verb is imperative (`add`, not `added`, `adds`, or `adding`) |
| `subject-empty` | the subject must not be empty |
| `subject-full-stop` | the subject must not end with `.` |
| `subject-end-punctuation` | the subject must not end with `?` or `...` |
| `body-max-line-length` | 72 characters per body line (lines with URLs are skipped) |
| `body-leading-blank` | a blank line between the header and the body |
| `footer-max-line-length` | 72 characters per footer line |
| `footer-leading-blank` | a blank line between the body and the footer |

Example:

```text
feat(auth): add token refresh

refresh the access token one minute before it expires
so long requests do not fail halfway.

Refs: 42
```

## Branches (Git Flow)

| Branch | From | Merges into |
| ------ | ---- | ----------- |
| `feature/*` | `develop` | `develop` |
| `release/<version>` | `develop` | `main`, then `main` back into `develop` |
| `hotfix/*` | `main` | `main`, then `main` back into `develop` |

## Releasing

1. On `develop`, see the next version:

   ```sh
   pnpm release:next
   ```

   Read the line `The next release version is X.Y.Z`. This needs push access to the remote.
2. Create `release/X.Y.Z` from `develop` and open a pull request to `main`.
   - The **Release branch check** workflow fails if `X.Y.Z` is not the version semantic-release will publish. Rename the branch or fix the commits.
3. Merge the pull request. The **Release** workflow publishes `vX.Y.Z`.
4. Open a pull request from `main` to `develop` so the release commit (`CHANGELOG.md`, version) reaches `develop`.

Versions come from commit messages:

| Commit | Release |
| ------ | ------- |
| `BREAKING CHANGE:` footer | major |
| `feat` | minor |
| `fix` | patch |
| `docs`, `refactor`, `test`, `chore` | none |

The first release is `1.0.0`. Only `main` publishes releases.
