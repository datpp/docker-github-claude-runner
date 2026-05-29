# docker-github-claude-runner

A self-hosted GitHub Actions runner with [Claude Code](https://claude.ai/code) pre-configured, so your workflows can use Claude as an AI coding agent.

## Docker Hub

```
datpp/github-claude-runner
```

## How it works

On startup the container:
1. Installs the latest `@anthropic-ai/claude-code` from npm
2. Writes the Claude OAuth token to the runner's config
3. Authenticates the GitHub CLI (optional)
4. Registers itself as a self-hosted runner against your repo
5. Starts listening for jobs

## Prerequisites

- A Docker host (local machine, VPS, etc.)
- A Claude account with an API key or OAuth token
- A GitHub repo you own or admin

## Setup

### 1. Get a runner registration token

Go to your repo → **Settings → Actions → Runners → New self-hosted runner**, copy the token shown. It expires after 1 hour and is only used for registration.

### 2. Get your Claude credentials

Claude Code accepts either:
- `ANTHROPIC_API_KEY` — recommended for long-lived runners, never expires
- `CLAUDE_CODE_OAUTH_TOKEN` — your personal session token, expires periodically

### 3. Run the container

```bash
docker run -d \
  --name claude-runner \
  --restart unless-stopped \
  -e GITHUB_REPO=your-org/your-repo \
  -e RUNNER_TOKEN=<registration-token> \
  -e ANTHROPIC_API_KEY=<your-api-key> \
  -e GH_TOKEN=<github-pat> \
  -e RUNNER_LABELS=claude \
  -v claude-memory:/home/runner/.claude \
  datpp/github-claude-runner
```

Or with docker-compose:

```yaml
services:
  claude-runner:
    image: datpp/github-claude-runner
    restart: unless-stopped
    volumes:
      - claude-memory:/home/runner/.claude
    environment:
      GITHUB_REPO: your-org/your-repo
      RUNNER_TOKEN: ${RUNNER_TOKEN}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      GH_TOKEN: ${GH_TOKEN}
      RUNNER_NAME: claude-runner   # optional
      RUNNER_LABELS: claude         # optional, for runs-on targeting

volumes:
  claude-memory:
```

### 4. Verify the runner is online

Go to **Settings → Actions → Runners** — you should see `claude-runner` with a green idle status.

## Using Claude in a workflow

Set `RUNNER_LABELS=claude` when starting the container, then use `runs-on: [self-hosted, claude]` to target it. Call `claude` with `--print` and `--dangerously-skip-permissions` for non-interactive use:

```yaml
name: Claude Agent

on:
  workflow_dispatch:
    inputs:
      task:
        description: Task for Claude
        required: true

jobs:
  agent:
    runs-on: [self-hosted, claude]
    steps:
      - uses: actions/checkout@v4

      - name: Run Claude agent
        run: |
          claude --print "${{ github.event.inputs.task }}" \
                 --dangerously-skip-permissions
```

### Trigger on issue label

```yaml
on:
  issues:
    types: [labeled]

jobs:
  agent:
    if: github.event.label.name == 'claude'
    runs-on: [self-hosted, claude]
    steps:
      - uses: actions/checkout@v4
      - name: Run Claude agent
        run: |
          claude --print "${{ github.event.issue.body }}" \
                 --dangerously-skip-permissions
```

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `GITHUB_REPO` | Yes | Target repo in `owner/repo` format |
| `RUNNER_TOKEN` | Yes | Short-lived registration token from GitHub |
| `ANTHROPIC_API_KEY` | One of these | Anthropic API key — never expires, recommended for long-lived runners |
| `CLAUDE_CODE_OAUTH_TOKEN` | One of these | Claude OAuth session token — alternative to API key |
| `GH_TOKEN` | No | GitHub PAT — enables `gh` CLI in workflows |
| `RUNNER_NAME` | No | Runner display name (default: `claude-runner`) |
| `RUNNER_LABELS` | No | Comma-separated labels for `runs-on` targeting (e.g. `claude,gpu`) |

## Persisting Claude memory

Mount a volume to `/home/runner/.claude` to keep Claude's memory and settings across container restarts:

```bash
-v claude-memory:/home/runner/.claude
```

Project-level memory (`.claude/` in the repo) is preserved automatically if you commit it to your repository.

## Security

- The `runner` user has passwordless `sudo` inside the container. Only point this runner at trusted workflows.
- Register the runner at the **repo** level (not org-wide) to limit blast radius.
- Use branch protection rules to prevent untrusted PRs from triggering Claude workflows.
