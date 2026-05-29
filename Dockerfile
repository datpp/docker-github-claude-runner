# -----------------------------------------------------------------------------
# Dockerfile
# -----------------------------------------------------------------------------

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    unzip \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# GitHub CLI
# -----------------------------------------------------------------------------
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y gh

# -----------------------------------------------------------------------------
# GitHub Runner
# -----------------------------------------------------------------------------
ARG RUNNER_VERSION=2.328.0
ARG TARGETARCH

RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") && \
    mkdir -p /actions-runner && \
    cd /actions-runner && \
    curl -o actions-runner.tar.gz -L \
      https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz && \
    tar xzf actions-runner.tar.gz && \
    rm actions-runner.tar.gz

# -----------------------------------------------------------------------------
# Runner user
# -----------------------------------------------------------------------------
RUN useradd -m runner && \
    usermod -aG sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# -----------------------------------------------------------------------------
# Claude setup
# -----------------------------------------------------------------------------
RUN mkdir -p \
    /opt/claude/skills \
    /home/runner/.config/claude \
    /home/runner/.claude \
    /home/runner/.npm-global \
    && chown -R runner:runner /opt/claude /home/runner/.config /home/runner/.claude /home/runner/.npm-global

ENV CLAUDE_SKILLS_DIR=/opt/claude/skills
ENV RUNNER_LABELS=""

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER runner

RUN npm config set prefix '/home/runner/.npm-global'

ENV PATH=/home/runner/.npm-global/bin:$PATH

WORKDIR /home/runner

ENTRYPOINT ["/entrypoint.sh"]
