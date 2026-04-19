---
service: "crossplane"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["helm-values", "kubernetes-secrets", "kubernetes-configmap"]
---

# Configuration

## Overview

Crossplane is configured entirely through Helm values files (`values.yaml`, plus per-environment overrides in `gcp-resources/<env>/crossplane-values.yaml`) and Kubernetes custom resources (ProviderConfig, Composition, XRD). There are no application-level environment variable files; runtime configuration is injected by the Helm chart into pod environment variables at deploy time.

## Environment Variables

The following environment variables are injected into the Crossplane controller and RBAC Manager pods by the Helm chart templates:

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GOMAXPROCS` | Sets Go max CPU threads from the pod's CPU limit | yes | Derived from `resourcesCrossplane.limits.cpu` | helm (resourceFieldRef) |
| `GOMEMLIMIT` | Sets Go memory limit from the pod's memory limit | yes | Derived from `resourcesCrossplane.limits.memory` | helm (resourceFieldRef) |
| `POD_NAMESPACE` | Injects the deployment namespace into the controller | yes | Derived from `metadata.namespace` | helm (fieldRef) |
| `POD_SERVICE_ACCOUNT` | Injects the service account name into the controller | yes | Derived from `spec.serviceAccountName` | helm (fieldRef) |
| `LEADER_ELECTION` | Enables/disables controller leader election | yes | `true` | helm (`values.leaderElection`) |
| `WEBHOOK_SERVICE_NAME` | Webhook service name (when webhooks enabled) | conditional | `crossplane-webhooks` | helm (webhooks.enabled=true) |
| `WEBHOOK_SERVICE_NAMESPACE` | Namespace for the webhook service | conditional | Derived from pod namespace | helm (webhooks.enabled=true) |
| `WEBHOOK_SERVICE_PORT` | Webhook service port during init | conditional | `9443` | helm (webhooks.enabled=true) |
| `WEBHOOK_PORT` | Webhook server listen port (runtime) | conditional | `9443` | helm (webhooks.port override) |
| `WEBHOOK_ENABLED` | Disables webhooks when set to `false` | conditional | n/a | helm (webhooks.enabled=false) |
| `METRICS_PORT` | Metrics server listen port | conditional | `8080` | helm (metrics.enabled=true) |
| `HEALTH_PROBE_PORT` | Readyz server listen port | conditional | `8081` | helm (readiness.port override) |
| `TLS_CA_SECRET_NAME` | K8s Secret name for TLS CA cert | yes | `crossplane-root-ca` | helm (hardcoded) |
| `TLS_SERVER_SECRET_NAME` | K8s Secret name for TLS server cert | yes | `crossplane-tls-server` | helm (hardcoded) |
| `TLS_CLIENT_SECRET_NAME` | K8s Secret name for TLS client cert | yes | `crossplane-tls-client` | helm (hardcoded) |
| `TLS_SERVER_CERTS_DIR` | Mount path for TLS server cert files | yes | `/tls/server` | helm (hardcoded) |
| `TLS_CLIENT_CERTS_DIR` | Mount path for TLS client cert files | yes | `/tls/client` | helm (hardcoded) |
| `CA_BUNDLE_PATH` | Path to custom CA bundle (if configured) | conditional | `/certs/<key>` | helm (registryCaBundleConfig.key) |
| `AUTOMATIC_DEPENDENCY_DOWNGRADE_ENABLED` | Enables automatic provider package dependency downgrade | conditional | not set | helm (packageManager.enableAutomaticDependencyDowngrade) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `webhooks.enabled` | Enables Kubernetes admission webhooks for Crossplane and provider resources | `true` | global |
| `leaderElection` | Enables leader election for the Crossplane controller pod | `true` | global |
| `rbacManager.deploy` | Deploys the RBAC Manager pod alongside the main controller | `true` | global |
| `rbacManager.leaderElection` | Enables leader election for the RBAC Manager pod | `true` | global |
| `metrics.enabled` | Exposes Prometheus metrics on port 8080 (adds scrape annotations) | `false` | global |
| `packageManager.enableAutomaticDependencyDowngrade` | Allows automatic provider package dependency version downgrades | `false` | global |
| `rbacManager.skipAggregatedClusterRoles` | Skips installing aggregated Crossplane ClusterRoles | `false` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `values.yaml` | YAML | Default Helm values for the Crossplane chart (image, replicas, resources, security contexts, webhooks, RBAC) |
| `gcp-resources/dev/crossplane-values.yaml` | YAML | Dev environment Helm values override (same as default for most settings) |
| `gcp-resources/staging/crossplane-values.yaml` | YAML | Staging environment Helm values override |
| `gcp-resources/prod/crossplane-values.yaml` | YAML | Production environment Helm values override |
| `gcp-resources/dev/xrd-bucket.yaml` | YAML | CompositeResourceDefinition for `xbuckets.gcp-storages.groupon.com` (dev) |
| `gcp-resources/staging/xrd-bucket.yaml` | YAML | CompositeResourceDefinition for `xbuckets.gcp-storages.groupon.com` (staging) |
| `gcp-resources/prod/xrd-bucket.yaml` | YAML | CompositeResourceDefinition for `xbuckets.gcp-storages.groupon.com` (prod) |
| `gcp-resources/dev/composition-bucket-dev.yaml` | YAML | Composition mapping XBucket to GCS Bucket (dev) |
| `gcp-resources/staging/composition-bucket-staging.yaml` | YAML | Composition mapping XBucket to GCS Bucket (staging) |
| `gcp-resources/prod/composition-bucket-prod.yaml` | YAML | Composition mapping XBucket to GCS Bucket (production) |
| `gcp-resources/dev/providerConfig-conveyor-dev.yaml` | YAML | ProviderConfig binding `gcp-provider-dev` to project `prj-grp-conveyor-dev-7a6c` |
| `gcp-resources/staging/providerConfig-conveyor-staging.yaml` | YAML | ProviderConfig binding `gcp-provider-staging` to project `prj-grp-conveyor-stable-251d` |
| `gcp-resources/prod/providerConfig-conveyor-prod.yaml` | YAML | ProviderConfig binding `gcp-provider-production` to project `prj-grp-conveyor-prod-8dde` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `sa-conveyor-dev` (key: `creds`) | GCP service account JSON key for dev project `prj-grp-conveyor-dev-7a6c` | k8s-secret (namespace: `crossplane-staging`) |
| `sa-conveyor-staging` (key: `creds`) | GCP service account JSON key for staging project `prj-grp-conveyor-stable-251d` | k8s-secret (namespace: `crossplane-staging`) |
| `sa-conveyor-production` (key: `creds`) | GCP service account JSON key for production project `prj-grp-conveyor-prod-8dde` | k8s-secret (namespace: `crossplane-production`) |
| `crossplane-root-ca` | TLS CA certificate for Crossplane internal mTLS; populated by init container | k8s-secret |
| `crossplane-tls-server` | TLS server certificate for the Crossplane webhook and controller TLS; populated by init container | k8s-secret |
| `crossplane-tls-client` | TLS client certificate for Crossplane provider communication; populated by init container | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

All three environment values files (`dev`, `staging`, `prod`) share identical Helm values (matching the base `values.yaml` defaults). The key differences per environment are in Kubernetes resource manifests rather than Helm values:

| Setting | Dev | Staging | Production |
|---------|-----|---------|------------|
| GCP Project ID | `prj-grp-conveyor-dev-7a6c` | `prj-grp-conveyor-stable-251d` | `prj-grp-conveyor-prod-8dde` |
| ProviderConfig name | `gcp-provider-dev` | `gcp-provider-staging` | `gcp-provider-production` |
| Composition name | `gcp-bucket-composition-dev` | `gcp-bucket-composition-staging` | `gcp-bucket-composition-production` |
| Crossplane namespace | `crossplane-staging` (dev credentials) | `crossplane-staging` | `crossplane-production` |
| DeploymentRuntimeConfig | Not defined (dev uses root-level files) | `skip-probe` (deployment-runtime-config.yaml) | `skip-probe` (deployment-runtime-config.yaml) |
| `com.groupon.conveyor.policies/skip-probes` annotation | `"true"` | `"true"` | `"true"` |
