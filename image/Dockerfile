# Base image for the agent-workspace chart: the tools an agent needs to work on
# a cluster, and nothing proprietary. The agent CLI itself (Claude Code, Codex)
# is installed into the home volume by the chart's init container.
FROM node:26.13.1-trixie-slim@sha256:e6bedef217677b276c591795e169840edd9096dbf13f29df8ef8d1856b8820bc

ARG TARGETARCH
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=1.37.2
# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=4.3.1
# renovate: datasource=github-releases depName=siderolabs/talos
ARG TALOSCTL_VERSION=1.14.6
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.103.3
# renovate: datasource=github-releases depName=tsl0922/ttyd
ARG TTYD_VERSION=1.7.7
# renovate: datasource=github-releases depName=astral-sh/uv
ARG UV_VERSION=0.13.7
# renovate: datasource=github-releases depName=hashicorp/terraform
ARG TERRAFORM_VERSION=1.17.2
# renovate: datasource=npm depName=@ast-grep/cli
ARG AST_GREP_VERSION=0.51.2
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=4.54.3
# difftastic publishes no checksum file; the sha256 values live in install-tools.sh
# and must be updated together with this version (a stale pin fails the build).
# renovate: datasource=github-releases depName=Wilfred/difftastic
ARG DIFFTASTIC_VERSION=0.72.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git jq less bat eza fd-find git-delta hyperfine openssh-client ripgrep sd shellcheck tmux tokei unzip \
 && rm -rf /var/lib/apt/lists/*

# Debian ships these under different names; agents expect `fd` and `bat`.
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd && ln -s /usr/bin/batcat /usr/local/bin/bat

# Structural code search/rewrite (`ast-grep`, `sg`); the node base image has npm.
RUN npm install --global --no-fund --no-audit "@ast-grep/cli@${AST_GREP_VERSION}" && npm cache clean --force

# Every binary is checked against the publisher's checksum file; a mismatch fails the build.
COPY install-tools.sh /usr/local/bin/install-tools.sh
RUN /usr/local/bin/install-tools.sh && rm /usr/local/bin/install-tools.sh

# Wrapper that first on PATH (the chart sets it) fixes Claude Code's messaging socket path.
COPY --chmod=755 claude-wrapper.sh /opt/agent/bin/claude

# Fixed uid so the chart's securityContext and PVC ownership line up. The node
# base image ships a `node` user at 1000; the workspace user is separate.
RUN groupadd --gid 10001 agent && useradd --uid 10001 --gid 10001 --home-dir /home/agent --shell /bin/bash agent \
 && mkdir -p /home/agent && chown 10001:10001 /home/agent

USER 10001:10001
WORKDIR /home/agent
HEALTHCHECK NONE
CMD ["sleep", "infinity"]
