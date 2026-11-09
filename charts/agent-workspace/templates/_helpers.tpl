{{- define "agent-workspace.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "agent-workspace.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "agent-workspace.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "agent-workspace.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "agent-workspace.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agent-workspace.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* The selected preset's package spec, e.g. @anthropic-ai/claude-code@2.1.319. Empty for preset "none". */}}
{{- define "agent-workspace.agentPackage" -}}
{{- if ne .Values.agent.preset "none" }}
{{- $p := index .Values.presets .Values.agent.preset }}
{{- printf "%s@%s" $p.package $p.version }}
{{- end }}
{{- end }}

{{/* Only the readonly/namespace-admin profiles need a ServiceAccount token. */}}
{{- define "agent-workspace.mountToken" -}}
{{- ne .Values.rbac.profile "none" }}
{{- end }}

{{/* Env shared by the installer and the workspace: everything writable lives under the home volume. */}}
{{- define "agent-workspace.baseEnv" -}}
- name: HOME
  value: /home/agent
- name: NPM_CONFIG_PREFIX
  value: /home/agent/.local
- name: NPM_CONFIG_CACHE
  value: /home/agent/.cache/npm
- name: TMUX_TMPDIR
  value: /tmp
- name: PATH
  value: /home/agent/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- name: GIT_CONFIG_COUNT
  value: "3"
- name: GIT_CONFIG_KEY_0
  value: credential.https://github.com.helper
- name: GIT_CONFIG_VALUE_0
  value: "!gh auth git-credential"
- name: GIT_CONFIG_KEY_1
  value: user.name
- name: GIT_CONFIG_VALUE_1
  value: {{ .Values.git.userName | quote }}
- name: GIT_CONFIG_KEY_2
  value: user.email
- name: GIT_CONFIG_VALUE_2
  value: {{ .Values.git.userEmail | quote }}
{{- end }}
