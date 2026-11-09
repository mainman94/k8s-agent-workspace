# k8s-agent-workspace — Helm chart + base image.
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

CHART := charts/agent-workspace
# Every values file under ci/ is rendered and linted: one per feature toggle.
CI_VALUES := $(wildcard $(CHART)/ci/*-values.yaml) $(wildcard examples/*-values.yaml)

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.PHONY: tools
tools: ## Install the pinned toolchain from mise.toml
	mise install

.PHONY: hooks
hooks: ## Install the git pre-commit hook
	prek install

.PHONY: lint
lint: ## Run every pre-commit hook
	prek run --all-files

.PHONY: template
template: ## Render + lint + kubeconform every ci/ values file
	@for f in $(CI_VALUES); do \
		echo "==> $$f"; \
		helm lint $(CHART) -f $$f --strict; \
		helm template t $(CHART) -f $$f | kubeconform -strict -summary -ignore-missing-schemas; \
	done

.PHONY: docs
docs: ## Regenerate the chart README
	helm-docs --chart-search-root=charts

.PHONY: check
check: lint template ## Everything a PR needs
