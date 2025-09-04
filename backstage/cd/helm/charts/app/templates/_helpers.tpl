{{- define "app.name" -}}
{{- default .Chart.Name .Values.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
environment: {{ .Values.environment }}
{{- end -}}

{{- define "ingress.host" -}}
{{ .Values.name }}.{{ .Values.ingress.host }}
{{- end -}}