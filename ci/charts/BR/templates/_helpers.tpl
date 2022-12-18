{{/*
Common labels. Other besides selector labels can be added.
*/}}
{{- define "br.labels" -}}
{{ include "br.selectorLabels" . }}
app.kubernetes.io/region: '{{ .Values.global.region }}'
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "br.selectorLabels" -}}
app.kubernetes.io/type: '{{ .Chart.Name | lower }}'
environment: '{{ .Values.global.environment }}'
app: 'BR'
{{- end -}}