# AGENTS

A Helm chart (`charts/agent-workspace`) and base image (`image/`) for running
AI coding agents safely in a Kubernetes cluster. Public repo; the chart is the
product.

## Local workflow

| Command      | What it does                                         |
| ------------ | ---------------------------------------------------- |
| `make tools` | Install the pinned toolchain from `mise.toml`        |
| `make hooks` | Install the git pre-commit hook (once)               |
| `make check` | Hooks + render/lint/kubeconform every `ci/` values   |
| `make docs`  | Regenerate the chart README from `values.yaml`       |

Tool versions live in `mise.toml` only; CI installs from the same file.
Every action reference is pinned to a commit SHA with the tag in a trailing
comment; Renovate keeps them current. Do not tidy a pin back to a tag.

## Design rules

- **Claude Code is never baked into the image.** It is proprietary; an init
  container installs a pinned version into the home volume. `presets.*.version`
  has a Renovate marker comment and never says `latest`.
- **Secure by default, loosened on purpose.** Non-root, read-only root fs,
  drop ALL, no SA token unless `rbac.profile` asks. New features must not
  weaken defaults.
- **No credentials in values.** Reference existing Secrets (`secrets.existingSecret`);
  MCP tokens use `${VAR}` expansion.
- **Fail closed.** ttyd without a credential Secret does not render.
- **Each feature toggle gets a `charts/agent-workspace/ci/*-values.yaml`**;
  `make template` renders and validates all of them.
- Bump `Chart.yaml` `version` when the chart changes.

## Not done yet

NetworkPolicy + CiliumNetworkPolicy (`toFQDNs`), ExternalSecret, repo-clone
init container, Codex MCP config (`~/.codex/config.toml`), GHCR publish with
Cosign, Artifact Hub listing, branch ruleset (defined in homelab
`terraform/github`).
