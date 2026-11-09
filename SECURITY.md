# Security Policy

This repository holds a Helm chart and a base image for running AI coding
agents in a Kubernetes cluster. Agents execute arbitrary commands, so the
defaults are deliberately locked down: non-root, read-only root filesystem,
all capabilities dropped, no ServiceAccount token unless an RBAC profile asks
for one, no credentials in values.

## Reporting

Report privately via GitHub's
[security advisories](https://github.com/mainman94/k8s-agent-workspace/security/advisories/new).
Please do not open a public issue for anything exploitable.

Worth reporting: a default that is less restrictive than it should be, an RBAC
profile that grants more than documented, a path that leaks a secret into a
rendered manifest, or a supply-chain gap in the image or release pipeline.

## Out of scope

The agents themselves (Claude Code, Codex, ...) are third-party software that
this chart installs at pod start. Report their issues to the vendors.
