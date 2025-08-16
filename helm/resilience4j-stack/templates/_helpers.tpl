{{/*
Expand the name of the chart.
*/}}
{{- define "resilience4j-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "resilience4j-stack.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "resilience4j-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "resilience4j-stack.labels" -}}
helm.sh/chart: {{ include "resilience4j-stack.chart" . }}
{{ include "resilience4j-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "resilience4j-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "resilience4j-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service A labels
*/}}
{{- define "resilience4j-stack.serviceA.labels" -}}
helm.sh/chart: {{ include "resilience4j-stack.chart" . }}
{{ include "resilience4j-stack.serviceA.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "resilience4j-stack.serviceA.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.serviceA.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service B labels
*/}}
{{- define "resilience4j-stack.serviceB.labels" -}}
helm.sh/chart: {{ include "resilience4j-stack.chart" . }}
{{ include "resilience4j-stack.serviceB.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "resilience4j-stack.serviceB.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.serviceB.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}