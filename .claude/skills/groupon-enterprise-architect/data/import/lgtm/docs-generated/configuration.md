---
service: "lgtm"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [helm-values, env-vars, k8s-secret]
---

# Configuration

## Overview

LGTM is configured entirely through Helm values files layered in a common-plus-environment pattern. A `common.yml` file defines baseline configuration shared across all environments, and per-environment files (e.g., `staging-us-central1.yml`, `production-us-central1.yml`) override environment-specific values such as GCS bucket names, exporter endpoints, and namespace references. Configuration is passed to deployments via Helm 3 templating during the `deploy.sh` script invocation. No external config store (Consul, Vault) is used directly; GCP service account credentials are bound via GKE Workload Identity annotations on Kubernetes service accounts.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MY_POD_IP` | Binds the OTLP receiver endpoints (gRPC: 4317, HTTP: 4318) to the pod's IP | yes | injected by Kubernetes downward API | env (k8s downward API) |
| `DEPLOYBOT_KUBE_CONTEXT` | Kubernetes context used by krane during deploy | yes | set by deploy bot | env (CI/deploybot) |
| `DEPLOYBOT_PARSED_VERSION` | Image version tag (commented out, reserved for future use) | no | — | env (CI/deploybot) |
| `DEPLOYBOT_LOGBOOK_TICKET` | Change-cause annotation (commented out, reserved for future use) | no | — | env (CI/deploybot) |
| `SVC_TOKEN` | Jenkins service account token for CI credential injection | yes | from Jenkins credentials store | Jenkins credentials (`svc_dcos_token`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `minio.enabled` | Enables embedded MinIO for local/offline trace storage (Helm condition) | false | per-environment (Helm) |
| `metaMonitoring.grafanaAgent.installOperator` | Installs the Grafana Agent Operator for Tempo self-monitoring | false | per-environment (Helm) |
| `rollout_operator.enabled` | Enables progressive rollout of Tempo components | false | per-environment (Helm) |
| `gateway.enabled` | Enables the Tempo nginx gateway for ingestion and query routing | true | global (common.yml) |
| `autoscaling.enabled` (OTel Collector) | Enables HPA autoscaling for the OTel Collector deployment | true | global (common.yml) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `tempo/.meta/deployment/cloud/components/tempo/common.yml` | YAML (Helm values) | Baseline Tempo Helm values: image registry, gRPC limits, gateway, autoscaling, replica counts |
| `tempo/.meta/deployment/cloud/components/tempo/staging-us-central1.yml` | YAML (Helm values) | Staging US GCS bucket and GCP service account overrides for Tempo |
| `tempo/.meta/deployment/cloud/components/tempo/staging-europe-west1.yml` | YAML (Helm values) | Staging EMEA GCS bucket and GCP service account overrides for Tempo |
| `tempo/.meta/deployment/cloud/components/tempo/production-us-central1.yml` | YAML (Helm values) | Production US GCS bucket and GCP service account overrides for Tempo |
| `tempo/.meta/deployment/cloud/components/tempo/production-europe-west1.yml` | YAML (Helm values) | Production EMEA GCS bucket and GCP service account overrides for Tempo |
| `otel-collector/.meta/deployment/cloud/components/collector/common.yml` | YAML (Helm values) | Baseline OTel Collector config: image, autoscaling, receivers, processors, exporters, pipelines |
| `otel-collector/.meta/deployment/cloud/components/collector/staging-us-central1.yml` | YAML (Helm values) | Staging US exporter endpoint overrides (Elastic APM, Thanos, Tempo) |
| `otel-collector/.meta/deployment/cloud/components/collector/staging-europe-west1.yml` | YAML (Helm values) | Staging EMEA exporter endpoint overrides |
| `otel-collector/.meta/deployment/cloud/components/collector/production-us-central1.yml` | YAML (Helm values) | Production US exporter endpoint overrides |
| `otel-collector/.meta/deployment/cloud/components/collector/production-europe-west1.yml` | YAML (Helm values) | Production EMEA exporter endpoint overrides |
| `.deploy_bot.yml` | YAML | Deploy bot configuration — Kubernetes cluster contexts, environments, regions, and deploy commands |
| `Jenkinsfile` | Groovy (Jenkins DSL) | CI pipeline stages: checkout, prepare, validate deploy config, deploy |
| `grafana/dashboards/traces.json` | JSON (Grafana dashboard) | Trace list search dashboard definition querying Tempo |
| `grafana/dashboards/trace_details.json` | JSON (Grafana dashboard) | Trace detail drill-down dashboard definition |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `iam.gke.io/gcp-service-account` (service account annotation) | Binds the Tempo Kubernetes service account to the GCP service account for GCS bucket access via Workload Identity | GKE Workload Identity |
| `svc_dcos_token` (Jenkins credential) | Service account token for CI pipeline authentication | Jenkins credentials store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The following values differ between environments:

| Config Key | Staging US | Staging EMEA | Production US | Production EMEA |
|-----------|-----------|-------------|--------------|----------------|
| GCS bucket (Tempo) | `con-stable-usc1-tempo` | `con-stable-euw1-tempo-emea` | `con-prod-usc1-tempo` | `con-grp-tempo-prod-9957` |
| GCP service account (Tempo) | `con-sa-tempo@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com` | same as staging US | `con-sa-tempo@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com` | same as prod US |
| Elastic APM endpoint (OTel) | `logging-platform-elastic-stack-staging` namespace | same as staging US | `logging-platform-elastic-stack-production` namespace | same as prod US |
| Thanos endpoint (OTel) | `telegraf-staging` namespace | same as staging US | `telegraf-production` namespace | `telegraf-production` namespace |
| Tempo endpoint (OTel) | `tempo-gateway.tempo-staging` | `tempo-gateway.tempo-staging` | `tempo-gateway.tempo-production` | `tempo-gateway.tempo-production` |
| Kubernetes namespace (deploy) | `tempo-staging` | `tempo-staging` | `tempo-production` | `tempo-production` |

Tempo gRPC message size limits (20 MB send/receive) and autoscaling parameters are defined in `common.yml` and apply to all environments unless overridden.
