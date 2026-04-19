---
service: "barcode-service-app"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Barcode Service is configured through a combination of JTier YAML configuration files (one per deployment environment, mounted at a well-known path), environment variables injected at pod startup, and Kubernetes Helm-style values defined in the `.meta/deployment/cloud/components/app/` directory. Configuration follows the JTier convention: the `JTIER_RUN_CONFIG` environment variable points to the active YAML config file for the running environment.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier runtime YAML config file for this environment/region | Yes | None | Kubernetes env (per-environment override YAML) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent virtual memory explosion in containers; tuned to prevent OOM kills | No | `4` | Helm values (`common.yml`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase for application-level feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development JTier runtime configuration |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes/Helm deployment values: image, scaling, ports, resource requests, log config |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production US West 1 overrides: cloud provider, region, VPC, replica bounds, `JTIER_RUN_CONFIG` path |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU West 1 overrides |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP US Central 1 overrides |
| `.meta/deployment/cloud/components/app/production-us-west-2.yml` | YAML | Production US West 2 overrides |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production GCP Europe West 1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging US West 1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML | Staging US West 2 overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP US Central 1 overrides |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging GCP Europe West 1 overrides |
| `.meta/deployment/cloud/components/app/rde-dev-us-west-2.yml` | YAML | RDE dev environment overrides |
| `.meta/deployment/cloud/components/app/rde-staging-us-west-2.yml` | YAML | RDE staging overrides |
| `.meta/deployment/cloud/components/app/dev-us-central1.yml` | YAML | Dev US Central 1 overrides |

## Secrets

> No evidence found in codebase for application-managed secrets. The `.meta/.raptor.yml` declares `secret_path:` with no value, confirming the service does not require Vault secrets. This is consistent with the service being non-SOX, non-PCI.

## Per-Environment Overrides

- **Common (all environments)**: `minReplicas: 2`, `maxReplicas: 15`, `httpPort: 8080`, `admin-port: 8081`, `jmx-port: 8009`, CPU request `1000m`, memory request/limit `500Mi`, `MALLOC_ARENA_MAX: 4`
- **Staging**: `minReplicas: 1`, `maxReplicas: 2`; `JTIER_RUN_CONFIG` points to staging-specific YAML; `filebeat.volumeType: low`
- **Production (US)**: `minReplicas: 2`, `maxReplicas: 15`; `JTIER_RUN_CONFIG` points to production region-specific YAML; `filebeat.volumeType: medium`
- **Production (EU)**: Same replica bounds as production US; deployed to `eu-west-1` / `europe-west1` clusters

### Application-level configuration

The `BarcodeServiceConfiguration` class exposes one application-specific field:

| Field | Purpose | Source |
|-------|---------|--------|
| `minBarcodeHeight` | Minimum allowed barcode height in pixels; enforced by Barcode Size Policy | JTier YAML config file |
