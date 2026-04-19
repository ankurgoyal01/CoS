---
service: "b2b-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secrets]
---

# Configuration

## Overview

The RBAC UI is configured via environment variables injected at deployment time through Helm values (via `cmf-generic-api` chart) and Kubernetes secrets loaded from a separate secrets submodule (`b2b-ui-secrets`). Static defaults are defined in `apps/rbac-ui/vpcs.config.json`. Per-environment overrides are defined in `.meta/deployment/cloud/components/app/staging-us-central1.yml` and `production-us-central1.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NEXT_PUBLIC_ENV` | Identifies the runtime environment (`staging` or `production`) | yes | — | helm |
| `NEXT_PUBLIC_RBAC_CLIENT_ID` | OAuth2-style client ID for RBAC API authentication (per-environment) | yes | — | helm |
| `JTIER_RUN_CONFIG` | Path to the environment-specific Kubernetes secrets YAML file | yes | — | helm |
| `LOG_TO_STDOUT` | When `true`, directs log output to stdout rather than log files | yes | `true` | helm |
| `NEXT_TELEMETRY_DISABLED` | Disables Next.js anonymous telemetry collection | yes | `1` | helm |
| `PORT` | HTTP port the Next.js server listens on | yes | `8080` | helm |
| `VPCS_PROFILE_AUTOLOAD` | Enables automatic loading of the VPCS environment profile | yes | `true` | `.env/base.profile` |
| `NEXT_PUBLIC_ENVIRONMENT` | Used by `@vpcs/grpn-next-logging` to tag log entries with the runtime environment | yes | — | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase for a dedicated feature flag system. Environment-specific behavior is controlled via the `NEXT_PUBLIC_ENV` variable.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `apps/rbac-ui/vpcs.config.json` | JSON | Application-level defaults for UMAPI client, logging endpoint, middleware handlers, and app name |
| `libs/vpcs/core/grpn-next-logging/src/lib/vpcs.config.defaults.json` | JSON | Default logging endpoint (`/api/vpcs/metrics`) and environment tag for the logging library |
| `libs/vpcs/core/grpn-request-middleware/src/lib/vpcs.config.defaults.json` | JSON | Default middleware handlers: Akamai bot-detection redirect to `/botland`, geolocation handler |
| `libs/vpcs/core/grpn-suboptimal/src/lib/vpcs.config.defaults.json` | JSON | Performance optimization API endpoint (`/api/optimize`) and tracky log config |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment config: service ID, image, scaling, log config, resource requests |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging-specific overrides: GCP project, namespace, env vars, scaling (1-2 replicas) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production-specific overrides: GCP project, namespace, env vars, scaling (1-4 replicas), resource limits |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `JTIER_RUN_CONFIG` (staging) | Points to `.meta/deployment/cloud/secrets/cloud/staging-us-central1.yml` | k8s-secret (submodule: `b2b-ui-secrets`) |
| `JTIER_RUN_CONFIG` (production) | Points to `.meta/deployment/cloud/secrets/cloud/production-us-central1.yml` | k8s-secret (submodule: `b2b-ui-secrets`) |
| UMAPI client secret | Authenticates the UMAPI client for identity operations | k8s-secret (submodule: `b2b-ui-secrets`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| `NEXT_PUBLIC_ENV` | `staging` | `production` |
| `NEXT_PUBLIC_RBAC_CLIENT_ID` | `91e489c2caa8471d8550c7f7908ad94a_rbacui` | `eba46ce755364188bf62de909c0d6811_rbacui` |
| Namespace | `rbac-ui-staging-sox` | `rbac-ui-production-sox` |
| Max replicas | 2 | 4 |
| CPU limit (main) | 1000m | 2000m |
| Memory limit (main) | 500Mi | 2Gi |
| Kubernetes cluster | `gcp-stable-us-central1` | `gcp-production-us-central1` |
