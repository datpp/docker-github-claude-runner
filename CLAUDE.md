# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Docker image that bundles a self-hosted GitHub Actions runner with Claude Code. On container start, `entrypoint.sh` installs the latest `@anthropic-ai/claude-code` from npm, writes the Claude OAuth config if provided, authenticates the GitHub CLI, registers the runner against a repo, then calls `./run.sh` to start accepting jobs.

## Build & run

```bash
# Build the image
docker build -t github-claude-runner .

# Run (all three env vars are required for a functional runner)
docker run -d \
  -e GITHUB_REPO=owner/repo \
  -e RUNNER_TOKEN=<token-from-github> \
  -e CLAUDE_CODE_OAUTH_TOKEN=<oauth-token> \
  -e GH_TOKEN=<github-pat> \          # optional, enables gh CLI auth
  -e RUNNER_NAME=my-claude-runner \    # optional, defaults to "claude-runner"
  github-claude-runner
```

`RUNNER_TOKEN` is a short-lived token from **Settings → Actions → Runners → New self-hosted runner** on the target repo.

## Architecture

| File | Role |
|---|---|
| `Dockerfile` | Ubuntu 24.04 base; installs system deps, GitHub CLI, GitHub Actions runner (pinned via `RUNNER_VERSION` ARG), creates a `runner` user with passwordless sudo, sets `CLAUDE_SKILLS_DIR=/opt/claude/skills` |
| `entrypoint.sh` | Runtime init: installs Claude Code, writes OAuth config, logs into gh CLI, registers the runner (`config.sh --replace`), then `exec ./run.sh` |

Claude Code is intentionally installed at runtime (not baked into the image) so the container always gets the latest version without a rebuild. To pin a version, change the `npm install -g @anthropic-ai/claude-code@latest` line in `entrypoint.sh` to a specific version.

## Updating the runner version

Change the `ARG RUNNER_VERSION` value in `Dockerfile` and rebuild. Releases are listed at `https://github.com/actions/runner/releases`.
