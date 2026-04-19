---
service: "sem-gtm"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, kustomize-overlays]
---

# Configuration

## Overview

`sem-gtm` is configured through environment variables injected at deployment time via Helm chart values (`cmf-generic-api` chart, version 3.89.0). Environment-specific overrides are layered through Kustomize overlays under `.meta/kustomize/overlays/{tagging,preview}/{staging,production}/`. The two sub-services (tagging and preview) have independent configuration files under `.meta/deployment/cloud/components/{tagging,preview}/`. Sensitive values such as `CONTAINER_CONFIG` contain encoded credentials and are defined in the common Helm values files — they are not stored in a separate secrets manager based on available evidence.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CONTAINER_CONFIG` | Encoded GTM container ID and authorization token linking the server to the correct GTM workspace | yes | None | helm (common.yml for each component) |
| `RUN_AS_PREVIEW_SERVER` | When set to `"true"`, starts the container in preview server mode instead of tagging server mode | yes (preview only) | Not set (tagging mode) | helm (preview/common.yml) |
| `PREVIEW_SERVER_URL` | URL of the preview server instance, used by the tagging server to redirect debug sessions | yes (tagging only) | `https://gtm.groupon.com/preview/` | helm (tagging/common.yml) |

> IMPORTANT: `CONTAINER_CONFIG` contains encoded credentials. The actual value is never documented here. Refer to `.meta/deployment/cloud/components/*/common.yml` for the encoded placeholder and rotate via the GTM console.

## Feature Flags

> No evidence found in codebase of feature flags or runtime toggle systems.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/tagging/common.yml` | YAML (Helm values) | Common configuration for the tagging server (env vars, scaling, probes, resources) |
| `.meta/deployment/cloud/components/tagging/production-us-central1.yml` | YAML (Helm values) | Production region overrides for tagging server (cloud provider, VIP) |
| `.meta/deployment/cloud/components/tagging/staging-us-central1.yml` | YAML (Helm values) | Staging region overrides for tagging server |
| `.meta/deployment/cloud/components/preview/common.yml` | YAML (Helm values) | Common configuration for the preview server (env vars, scaling, probes, resources) |
| `.meta/deployment/cloud/components/preview/production-us-central1.yml` | YAML (Helm values) | Production region overrides for preview server (cloud provider, VIP) |
| `.meta/deployment/cloud/components/preview/staging-us-central1.yml` | YAML (Helm values) | Staging region overrides for preview server |
| `.meta/kustomize/base/kustomization.yaml` | YAML (Kustomize) | Base kustomization referencing all.yaml |
| `.meta/kustomize/overlays/tagging/production/kustomization.yaml` | YAML (Kustomize) | Tagging production overlay (applies clean-deployment.yml patch) |
| `.meta/kustomize/overlays/tagging/staging/kustomization.yaml` | YAML (Kustomize) | Tagging staging overlay |
| `.meta/kustomize/overlays/preview/production/kustomization.yaml` | YAML (Kustomize) | Preview production overlay |
| `.meta/kustomize/overlays/preview/staging/kustomization.yaml` | YAML (Kustomize) | Preview staging overlay |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `CONTAINER_CONFIG` | Encoded GTM container authorization credentials | Helm values (encoded inline); rotation requires GTM console access |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging** (`gcp-stable-us-central1`, namespace `sem-gtm-staging`): Uses `stable` VPC; no scaling overrides from common defaults.
- **Production** (`gcp-production-us-central1`, namespace `sem-gtm-production`):
  - Tagging server VIP: `sem-gtm.us-central1.conveyor.prod.gcp.groupondev.com`
  - Preview server VIP: `sem-gtm--preview.us-central1.conveyor.prod.gcp.groupondev.com`
  - Uses `prod` VPC.
- Both environments share the same `CONTAINER_CONFIG` value per common.yml; environment-specific config is limited to cloud provider metadata and VIP endpoints.
