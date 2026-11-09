#!/usr/bin/env bash
# Install kubectl, helm, talosctl, gh, ttyd, uv, terraform, yq and difftastic with checksum verification.
# Expects TARGETARCH (amd64|arm64) and the *_VERSION build args in the env.
set -euo pipefail

arch="${TARGETARCH:?}"
case "$arch" in
  amd64) ttyd_arch=x86_64 ;;
  arm64) ttyd_arch=aarch64 ;;
  *) echo "unsupported arch: $arch" >&2; exit 1 ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

# fetch <url> <outfile>
fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }
# check <file> <expected sha256>
check() { echo "$2  $1" | sha256sum -c -; }

# kubectl
fetch "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${arch}/kubectl" kubectl
check kubectl "$(cat <(curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${arch}/kubectl.sha256"))"
install -m 0755 kubectl /usr/local/bin/kubectl

# helm
fetch "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${arch}.tar.gz" helm.tgz
check helm.tgz "$(cut -d' ' -f1 <(curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${arch}.tar.gz.sha256sum"))"
tar -xzf helm.tgz "linux-${arch}/helm"
install -m 0755 "linux-${arch}/helm" /usr/local/bin/helm

# talosctl
base="https://github.com/siderolabs/talos/releases/download/v${TALOSCTL_VERSION}"
fetch "${base}/talosctl-linux-${arch}" talosctl
check talosctl "$(curl -fsSL "${base}/sha256sum.txt" | awk -v f="talosctl-linux-${arch}" '$2==f {print $1}')"
install -m 0755 talosctl /usr/local/bin/talosctl

# gh
base="https://github.com/cli/cli/releases/download/v${GH_VERSION}"
fetch "${base}/gh_${GH_VERSION}_linux_${arch}.tar.gz" gh.tgz
check gh.tgz "$(curl -fsSL "${base}/gh_${GH_VERSION}_checksums.txt" | awk -v f="gh_${GH_VERSION}_linux_${arch}.tar.gz" '$2==f {print $1}')"
tar -xzf gh.tgz
install -m 0755 "gh_${GH_VERSION}_linux_${arch}/bin/gh" /usr/local/bin/gh

# ttyd
base="https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}"
fetch "${base}/ttyd.${ttyd_arch}" ttyd
check ttyd "$(curl -fsSL "${base}/SHA256SUMS" | awk -v f="ttyd.${ttyd_arch}" '$2==f {print $1}')"
install -m 0755 ttyd /usr/local/bin/ttyd

# uv + uvx, for Python-based MCP servers (`command: uvx`)
base="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}"
uv_file="uv-${ttyd_arch}-unknown-linux-gnu.tar.gz"
fetch "${base}/${uv_file}" uv.tgz
check uv.tgz "$(cut -d' ' -f1 <(curl -fsSL "${base}/${uv_file}.sha256"))"
tar -xzf uv.tgz
install -m 0755 "uv-${ttyd_arch}-unknown-linux-gnu/uv" "uv-${ttyd_arch}-unknown-linux-gnu/uvx" /usr/local/bin/

# terraform (HashiCorp publishes a signed SHA256SUMS next to every release)
base="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"
fetch "${base}/terraform_${TERRAFORM_VERSION}_linux_${arch}.zip" terraform.zip
check terraform.zip "$(curl -fsSL "${base}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" | awk -v f="terraform_${TERRAFORM_VERSION}_linux_${arch}.zip" '$2==f {print $1}')"
unzip -q terraform.zip terraform
install -m 0755 terraform /usr/local/bin/terraform

# yq (mikefarah's Go yq, not Debian's Python wrapper of the same name)
base="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}"
fetch "${base}/yq_linux_${arch}" yq
check yq "$(curl -fsSL "${base}/checksums-bsd" | awk -v f="(yq_linux_${arch})" '$1=="SHA256" && $2==f {print $NF}')"
install -m 0755 yq /usr/local/bin/yq

# difftastic: no published checksum file, so the sha256 values are pinned here.
# Update both together with DIFFTASTIC_VERSION (GitHub shows them as asset digests).
case "$arch" in
  amd64) difft_arch=x86_64;  difft_sha=33ea1f003081e9f2422299a434e6040c89085bd9f102b08f3fe30393720d5d4a ;;
  arm64) difft_arch=aarch64; difft_sha=0993a82a6708a24adc6c6b8de366924728ed08f537a5b488940082c8edc79353 ;;
esac
fetch "https://github.com/Wilfred/difftastic/releases/download/${DIFFTASTIC_VERSION}/difft-${DIFFTASTIC_VERSION}-${difft_arch}-unknown-linux-gnu.tar.gz" difft.tgz
check difft.tgz "$difft_sha"
tar -xzf difft.tgz difft
install -m 0755 difft /usr/local/bin/difft
