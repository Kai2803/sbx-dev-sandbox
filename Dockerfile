# syntax=docker/dockerfile:1

# Which Docker sandbox base to extend: claude-code, codex, ...
ARG AGENT=claude-code
FROM docker/sandbox-templates:${AGENT}

# Non-root user the sandbox runs as. Verify with:
#   docker run --rm docker/sandbox-templates:claude-code id
ARG SANDBOX_USER=agent
ARG MAVEN_VERSION=3.9.9
ARG GLAB_VERSION=1.53.0
# Full "ansible" package: ansible-core plus the community collection bundle.
ARG ANSIBLE_VERSION=14.6.0
# Set automatically by buildx (amd64 / arm64)
ARG TARGETARCH

USER root
ENV DEBIAN_FRONTEND=noninteractive

# --- Base packages + Python -------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg unzip git \
      build-essential pkg-config libssl-dev \
      python3 python3-pip python3-venv \
 && rm -rf /var/lib/apt/lists/*

# --- JDK 17 / 21 / 25 (Eclipse Temurin), stable paths under /opt -------------
RUN install -d -m 0755 /etc/apt/keyrings \
 && wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public \
      | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
      > /etc/apt/sources.list.d/adoptium.list \
 && apt-get update && apt-get install -y --no-install-recommends \
      temurin-17-jdk temurin-21-jdk temurin-25-jdk \
 && rm -rf /var/lib/apt/lists/* /usr/lib/jvm/temurin-*/lib/src.zip \
 && for v in 17 21 25; do ln -s "$(ls -d /usr/lib/jvm/temurin-$v-jdk-*)" /opt/jdk-$v; done

# --- Maven (tarball, so apt doesn't pull in an extra default JDK) -----------
RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
      | tar -xz -C /opt \
 && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven

# --- Rust (system-wide, owned by the sandbox user so `cargo install` works) ---
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path \
      --profile minimal --component clippy,rustfmt \
 && chown -R ${SANDBOX_USER}: /usr/local/rustup /usr/local/cargo

# --- glab (GitLab CLI). No login here: auth is injected by the sbx proxy. ----
RUN curl -fsSL -o /tmp/glab.deb \
      "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_${TARGETARCH}.deb" \
 && dpkg -i /tmp/glab.deb && rm /tmp/glab.deb

# --- Ansible (own venv, so it doesn't touch system Python / PEP 668) ---------
RUN python3 -m venv /opt/ansible \
 && /opt/ansible/bin/pip install --no-cache-dir "ansible==${ANSIBLE_VERSION}" \
 && ln -s /opt/ansible/bin/ansible* /usr/local/bin/

ENV JAVA_HOME=/opt/jdk-25 \
    MAVEN_HOME=/opt/maven \
    PATH=/opt/jdk-25/bin:/opt/maven/bin:/usr/local/cargo/bin:${PATH}

# --- Environment description for the agents ---------------------------------
# Claude Code loads /etc/claude-code/CLAUDE.md for every session;
# Codex reads ~/.codex/AGENTS.md.
COPY context/sandbox-environment.md /etc/claude-code/CLAUDE.md
# Machine-wide Claude Code settings (highest precedence, e.g. no commit/PR attribution)
COPY config/claude-managed-settings.json /etc/claude-code/managed-settings.json
COPY --chown=${SANDBOX_USER}: context/sandbox-environment.md /home/${SANDBOX_USER}/.codex/AGENTS.md

USER ${SANDBOX_USER}
