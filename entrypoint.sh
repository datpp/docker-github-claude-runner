#!/usr/bin/env bash

set -e

# -----------------------------------------------------------------------------
# Install/update Claude Code
# -----------------------------------------------------------------------------
echo "Installing/updating Claude Code..."

npm install -g @anthropic-ai/claude-code@latest

echo "Claude version:"
claude --version || true

# -----------------------------------------------------------------------------
# Claude OAuth token
#
# Pass:
# -e CLAUDE_CODE_OAUTH_TOKEN=xxxxx
# -----------------------------------------------------------------------------
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN}" ]; then
  echo "Configuring Claude OAuth token..."

  mkdir -p /home/runner/.config/claude

  cat > /home/runner/.config/claude/config.json <<EOF
{
  "claudeAiOauth": "${CLAUDE_CODE_OAUTH_TOKEN}"
}
EOF

  chmod 600 /home/runner/.config/claude/config.json
elif [ -n "${ANTHROPIC_API_KEY}" ]; then
  echo "Using ANTHROPIC_API_KEY for Claude authentication..."
fi

# -----------------------------------------------------------------------------
# Configure runner
# -----------------------------------------------------------------------------
if [ ! -f /actions-runner/.runner ]; then
  echo "Configuring GitHub runner..."

  cd /actions-runner

  ./config.sh \
    --url "https://github.com/${GITHUB_REPO}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME:-claude-runner}" \
    ${RUNNER_LABELS:+--labels "${RUNNER_LABELS}"} \
    --unattended \
    --replace
fi

echo "Claude skills dir: ${CLAUDE_SKILLS_DIR}"

cd /actions-runner

exec ./run.sh
