# k8s-agent-workspace

Helm chart for running AI coding agents (Claude Code, Codex, ...) safely in a
Kubernetes cluster: a locked-down workspace pod with a persistent home,
RBAC profiles, MCP server configuration and an optional authenticated web
terminal.

- Chart docs and values: [charts/agent-workspace](charts/agent-workspace/README.md)
- Base image (kubectl, helm, terraform, gh, talosctl, uv, tmux, ttyd; no agent CLI): [image/](image/)
- Agent CLIs are installed at pod start into the home volume at a pinned
  version, so the public image carries no proprietary software.

Status: early (v0.1). Not published to GHCR yet.

License: MIT.
