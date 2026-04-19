---
service: "regulatory-consent-log"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

The service is configured through a combination of environment variables (injected by Kubernetes via the Raptor/Conveyor deployment system), a per-environment YAML config file (referenced by `JTIER_RUN_CONFIG`), and Kubernetes secrets (accessed via the `.meta/deployment/cloud/secrets` path). The two runtime components (API and Worker) use the same Docker image but are differentiated by the `ENABLE_API` and `ENABLE_UTILITY` environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENABLE_API` | Activates the REST API (app component) | Yes | `"true"` (app), `"false"` (util) | helm / deployment YAML |
| `ENABLE_UTILITY` | Activates the Utility Worker (util component) | Yes | `"false"` (app), `"true"` (util) | helm / deployment YAML |
| `JTIER_RUN_CONFIG` | Path to the per-environment JTier YAML config file | Yes | (no default; must be set per env) | helm / deployment YAML |
| `HEAP_SIZE` | JVM heap size for the process | No | `"2048m"` (production) | deployment YAML (production envs) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here. Database credentials, Redis passwords, API keys, and JWT signing secrets are injected via Kubernetes secrets at `.meta/deployment/cloud/secrets`.

## Feature Flags

> No evidence found in codebase for runtime feature flags beyond `ENABLE_API` and `ENABLE_UTILITY`.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development JTier configuration (referenced by `development.yml` at repo root) |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | Staging US-Central1 run configuration (mounted at runtime) |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | Production US-Central1 run configuration (mounted at runtime) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config for the API (app) component |
| `.meta/deployment/cloud/components/util/common.yml` | YAML | Common Kubernetes deployment config for the Worker (util) component |
| `.meta/deployment/cloud/components/app/{env}-{region}.yml` | YAML | Per-environment overrides for the API component |
| `.meta/deployment/cloud/components/util/{env}-{region}.yml` | YAML | Per-environment overrides for the Worker component |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets` (directory) | Contains secrets for DaaS Postgres credentials, Redis password, MBus credentials, Transcend API keys, Lazlo API keys, JWT signing keys | k8s-secret (Raptor-managed) |

> Secret values are NEVER documented. Only names and rotation policies are listed here. Rotation is managed by the Groupon platform secrets management process.

## Per-Environment Overrides

| Environment | Component | Key Differences |
|-------------|-----------|----------------|
| `staging-us-central1` | app | `minReplicas: 1`, `maxReplicas: 2`; VIP: `regulatory-consent-log.us-central1.conveyor.stable.gcp.groupondev.com`; `JTIER_RUN_CONFIG` points to `staging-us-central1.yml` |
| `production-us-central1` | app | `minReplicas: 5`, `maxReplicas: 30`; VIP: `regulatory-consent-log.us-central1.conveyor.prod.gcp.groupondev.com`; `JTIER_RUN_CONFIG` points to `production-us-central1.yml`; `HEAP_SIZE: "2048m"`; CPU limit `700m`; memory limit `5Gi` |
| All environments | app | HTTP port `8080`, admin port `8081`; VPA enabled; APM enabled; heartbeat path `/var/groupon/jtier/heartbeat.txt` |
| All environments | util | `ENABLE_API: "false"`, `ENABLE_UTILITY: "true"`; `minReplicas: 3`, `maxReplicas: 3`; memory `500Mi`; rolling deploy `maxSurge: 25%`, `maxUnavailable: 0` |
| Production | app | Base CPU request `300m`, limit `700m`; base memory request `3Gi`, limit `5Gi` |
| Staging | app | No CPU/memory overrides from common (uses common defaults: CPU `300m`, memory `1000Mi`/`1000Mi`) |
