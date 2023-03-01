{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm.fullname" -}}
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
{{- define "helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "helm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper Parse dashboard image name
*/}}
{{- define "parse.dashboard.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.dashboard.image "global" .Values.global) }}
{{- end -}}

{{/*
Gets the port to access Parse outside the cluster.
When using ingress, we should use the port 80/443 instead of service.ports.http
*/}}
{{- define "parse.external-port" -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 does not support it, so we need to implement this if-else logic.
*/}}
{{- if .Values.ingress.enabled -}}
{{- $ingressHttpPort := "80" -}}
{{- $ingressHttpsPort := "443" -}}
{{- if eq .Values.dashboard.parseServerUrlProtocol "https" -}}
{{- $ingressHttpsPort -}}
{{- else -}}
{{- $ingressHttpPort -}}
{{- end -}}
{{- else -}}
{{ .Values.service.port }}
{{- end -}}
{{- end -}}

{{/*
Get the user defined LoadBalancerIP for this release.
Note, returns 127.0.0.1 if using ClusterIP.
*/}}
{{- define "parse.serviceIP" -}}
{{- if eq .Values.dashboard.service.type "ClusterIP" -}}
127.0.0.1
{{- else -}}
{{- default "" .Values.dashboard.service.loadBalancerIP -}}
{{- end -}}
{{- end -}}

{{/*
Gets the host to be used for this application.
If not using ClusterIP, or if a host or LoadBalancerIP is not defined, the value will be empty.
*/}}
{{- define "parse.host" -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 does not support it, so we need to implement this if-else logic.
*/}}
{{- $host := default "" -}}
{{- if .Values.ingress.enabled -}}
{{- $ingressHost := .Values.ingress.server.hostname -}}
{{- $serverHost := default $ingressHost $host -}}
{{- default (include "parse.serviceIP" .) $serverHost -}}
{{- else -}}
{{- default (include "parse.serviceIP" .) $host -}}
{{- end -}}
{{- end -}}

{{/* Check if there are rolling tags in the images */}}
{{- define "parse.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.server.image }}
{{- include "common.warnings.rollingTag" .Values.dashboard.image }}
{{- include "common.warnings.rollingTag" .Values.volumePermissions.image }}
{{- end -}}

{{/*
Validate values of Parse Dashboard - if tls is enable on server side must provide https protocol
*/}}
{{- define "parse.validateValues.dashboard.serverUrlProtocol" -}}
{{- if .Values.ingress.enabled -}}
{{- if and .Values.ingress.tls (ne $.Values.dashboard.parseServerUrlProtocol "https") -}}
parse: dashboard.parseServerUrlProtocol
    If Parse Server is using ingress with tls enable then It must be set as "https"
    in order to form the URLs with this protocol, in another case, Parse Dashboard will always redirect to "http".
{{- end -}}
{{- end -}}
{{- end -}}