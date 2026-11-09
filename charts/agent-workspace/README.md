# agent-workspace

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A locked-down workspace pod for AI coding agents (Claude Code, Codex, ...) with RBAC profiles and optional ttyd access

**Homepage:** <https://github.com/mainman94/k8s-agent-workspace>

## Security defaults

- Non-root (uid 10001), `readOnlyRootFilesystem`, all capabilities dropped,
  `seccompProfile: RuntimeDefault`.
- No ServiceAccount token unless `rbac.profile` is `readonly` or `namespace-admin`.
- No credentials in values: reference existing Secrets.
- A web terminal is never rendered without authentication.

## Quick start

```sh
helm install agent oci://ghcr.io/mainman94/charts/agent-workspace -n agents --create-namespace
kubectl -n agents exec -it agent-agent-workspace-0 -- tmux new -A -s agent
claude   # then /login once; the session lives in the home PVC
```

## MCP servers

Remote and local (stdio) servers are declared under `mcp.servers` and
rendered into the workspace's project-scope `.mcp.json`. Tokens come from the
Secret in `secrets.existingSecret` via `${VAR}`:

```yaml
mcp:
  servers:
    super-intelligence:
      type: http
      url: https://mcp.example.com/mcp
      headers:
        Authorization: Bearer ${SUPER_INTELLIGENCE_TOKEN}
    firefly:
      command: npx
      args: [-y, mcp-server-firefly-iii]
      env:
        FIREFLY_URL: https://firefly.example.com
        FIREFLY_TOKEN: ${FIREFLY_TOKEN}
```

Local servers run inside the pod, so they need egress to whatever they talk to
and to the package registry. `npx` (Node) and `uvx` (Python, via `uv`) are in the image.

## Plugins and efficiency tooling

`claude.managedSettings` is mounted as Claude Code's managed settings, so it
can declare plugin marketplaces and enabled plugins without touching the
user's own settings in the home volume. See
[examples/efficiency-values.yaml](../../examples/efficiency-values.yaml) for a
headroom + ponytail + caveman setup.

## Requirements

Kubernetes: `>=1.29.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| agent.instructions | string | `""` | Standing instructions for the agent, written on every pod start to ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md (user-level memory files). Empty by default; see examples/ for a search-tool and git-hygiene preset. |
| agent.preset | string | `"claude-code"` | Which agent to install into the home volume: `claude-code`, `codex` or `none`. |
| claude | object | `{"managedSettings":{}}` | Claude Code managed settings, mounted read-only at /etc/claude-code/managed-settings.json. Highest precedence and separate from the user's own settings in the home PVC, so it never clobbers them. Use it to declare plugin marketplaces and enabled plugins (see examples/). |
| env | object | `{}` | Extra plain environment variables. |
| fullnameOverride | string | `""` |  |
| git | object | `{"repos":[],"userEmail":"agent-workspace@users.noreply.github.com","userName":"agent-workspace"}` | Code checkout. `git` and `gh` are in the image. Put a GitHub token in `secrets.existingSecret` as GH_TOKEN: it authenticates `gh` and, through a credential helper wired up by env vars (no files written), `git` over HTTPS. |
| git.repos | list | `[]` | Repositories cloned into the workspace on pod start when the target directory does not exist yet. Existing checkouts are never touched, so the agent's work survives restarts. |
| httpRoute | object | `{"enabled":false,"hostnames":[],"parentRefs":[]}` | Gateway API route to the ttyd service. Requires `ttyd.enabled`. |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/mainman94/k8s-agent-workspace","tag":""}` | Workspace image. The agent CLI is NOT baked in (Claude Code is proprietary software); an init container installs the pinned version into the home volume. |
| image.tag | string | `""` | Defaults to the chart appVersion. |
| imagePullSecrets | list | `[]` |  |
| mcp | object | `{"servers":{}}` | MCP servers for Claude Code, rendered into a project-scope `.mcp.json` in the workspace directory (rewritten on every pod start; values are the source of truth). Remote servers use `type: http` + `url`; local ones run as stdio processes inside the pod (`command: npx`; node is in the image). Put tokens in `secrets.existingSecret` and reference them as ${VAR}, which Claude Code expands at runtime, so no credential ever lands in values or a ConfigMap. Claude Code asks once to approve project-scope servers on first use. |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| persistence.enabled | bool | `true` | Keep the home directory (agent install, auth, shell history) on a PVC. When false the home is an emptyDir and everything is lost on restart. |
| persistence.size | string | `"10Gi"` |  |
| persistence.storageClass | string | `""` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{"fsGroup":10001,"runAsGroup":10001,"runAsNonRoot":true,"runAsUser":10001,"seccompProfile":{"type":"RuntimeDefault"}}` | Merged into the pod/container securityContext. The defaults are the point of this chart. |
| presets | object | `{"claude-code":{"package":"@anthropic-ai/claude-code","version":"2.1.319"},"codex":{"package":"@openai/codex","version":"0.167.0"}}` | Pinned agent CLI versions, installed from npm by the init container. Renovate bumps these; there is deliberately no `latest`. |
| rbac.clusterWide | bool | `false` | `readonly` only: grant cluster-wide instead of release-namespace-only. |
| rbac.profile | string | `"none"` | What the workspace may do in the cluster. `none`            no ServiceAccount token is mounted (default) `readonly`        get/list/watch on common resources, Secrets excluded `namespace-admin` the built-in `admin` ClusterRole, bound in the release namespace only |
| resources.limits.memory | string | `"2Gi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| secrets | object | `{"existingSecret":""}` | Credentials. Never put keys in values: reference a Secret that already exists (e.g. created by an ExternalSecret). Every key becomes an env var. Subscription login: run `claude` in the pod and `/login` once; the session is stored in the home PVC and survives restarts. For headless use put the output of `claude setup-token` in this Secret as CLAUDE_CODE_OAUTH_TOKEN. |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| service.port | int | `7681` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount (e.g. workload identity). |
| tolerations | list | `[]` |  |
| ttyd.enabled | bool | `false` | Serve a web terminal (ttyd + tmux). Needs a credential Secret: a shell without authentication is never rendered. Without ttyd the pod idles and you use `kubectl exec -it <pod> -- tmux new -A -s agent`. |
| ttyd.existingSecret | string | `""` | Secret holding the basic-auth credential as `user:password` under the key below. |
| ttyd.port | int | `7681` |  |
| ttyd.secretKey | string | `"credential"` |  |
