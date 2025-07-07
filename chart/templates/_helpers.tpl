{{- define "chartDetail" -}}
    {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "clusterName" -}}
    {{ .Values.application }}-db-devel
{{- end -}}

{{- define "databaseName" -}}
    {{ .Values.application | replace "-" "_" }}_devel
{{- end -}}

{{- define "schemaName" -}}
    {{- include "databaseName" . -}}
{{- end -}}

{{- define "ownerName" -}}
    {{- include "databaseName" . -}}
{{- end -}}

{{- define "readonlyRoleName" -}}
    {{- include "databaseName" . -}}_readonly
{{- end -}}

{{- define "debeziumRoleName" -}}
    {{- if .Values.cluster.spec.managed.roles.debezium.enable -}}
        {{- include "databaseName" . -}}_debezium
    {{- end -}}
{{- end -}}

{{- define "trinoRoleName" -}}
    {{- if or
    (eq .Values.environment "production")
    .Values.cluster.spec.managed.roles.trino.enable -}}
        {{- include "databaseName" . -}}_trino
    {{- end -}}
{{- end -}}

{{- define "objectStoreParams" -}}
    {{- if eq .Values.environment "devel" -}}
        {{- dict "path" "s3://cnpg-bucket-k8s02-dev-capi/" "username" "cnpg-user-k8s02-dev-capi" "password" .Values.objectStore.password.devel | toJson -}}
    {{- else if eq .Values.environment "quality" -}}
        {{- dict "path" "s3://cnpg-bucket-k8s02-qa-capi/" "username" "cnpg-user-k8s02-qa-capi" "password" .Values.objectStore.password.quality | toJson -}}
    {{- else if eq .Values.environment "utils" -}}
        {{- dict "path" "s3://cnpg-bucket-k8s03-utils-capi/" "username" "cnpg-user-k8s03-utils-capi" "password" .Values.objectStore.password.utils | toJson -}}
    {{- else if eq .Values.environment "production" -}}
        {{- dict "path" "s3://cnpg-bucket-k8s04-capi/" "username" "cnpg-user-k8s04-capi" "password" .Values.objectStore.password.production | toJson -}}
    {{- end -}}
{{- end -}}

{{- define "objectStoreEndpoint" -}}
    {{- $urlWithoutProtocol := regexReplaceAll "(https?://)" .Values.objectStore.endpoint "" -}}
    {{- $hostWithPort := splitList "/" $urlWithoutProtocol | first -}}
    {{- $hostPortSplit := splitList ":" $hostWithPort -}}
    {{- $fqdn := index $hostPortSplit 0 -}}
    {{- $dict := dict "fqdn" $fqdn -}}
    {{- if gt (len $hostPortSplit) 1 -}}
        {{- $_ := set $dict "port" (index $hostPortSplit 1) -}}
    {{- end -}}
    {{- $dict | toJson -}}
{{- end -}}

{{- define "walStorageSize" -}}
    {{- if or
    (eq .Values.environment "utils")
    (eq .Values.environment "production") -}}
        {{- $size := .Values.cluster.spec.walStorage.size -}}
        {{- $number := (regexReplaceAll "(\\d+)(.*)" $size "$1") | int -}}
        {{- $unit := (regexReplaceAll "(\\d+)(.*)" $size "$2") -}}
        {{- $doubled := add $number $number -}}
        {{- printf "%d%s" $doubled $unit -}}
    {{- else -}}
        {{ .Values.cluster.spec.walStorage.size }}
    {{- end -}}
{{- end -}}

{{- define "cpuResourceLimit" -}}
    {{- if (eq .Values.environment "production") -}}
        {{- $cores := .Values.cluster.spec.resources.limits.cpu -}}
        {{- $doubled := add $cores $cores -}}
        {{- printf "%d" $doubled -}}
    {{- else -}}
        {{ .Values.cluster.spec.resources.limits.cpu }}
    {{- end -}}
{{- end -}}