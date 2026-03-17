{{/*
Resource name — uses serviceName from values.yaml.
*/}}
{{- define "ms.fullname" -}}
{{- .Values.serviceName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels — applied to ALL resources.
*/}}
{{- define "ms.labels" -}}
app: {{ include "ms.fullname" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "ms.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used by Deployment + Service to find Pods.
*/}}
{{- define "ms.selectorLabels" -}}
app: {{ include "ms.fullname" . }}
app.kubernetes.io/name: {{ include "ms.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "ms.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ms.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image full path.
*/}}
{{- define "ms.image" -}}
{{- printf "%s/%s/%s:%s" .Values.image.registry .Values.image.project .Values.image.repository .Values.image.tag }}
{{- end }}
