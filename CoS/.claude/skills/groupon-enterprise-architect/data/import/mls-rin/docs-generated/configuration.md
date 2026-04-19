---
service: "mls-rin"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

MLS RIN is configured through a layered YAML file system managed by the JTier framework. The active configuration file is selected at runtime via the `JTIER_RUN_CONFIG` environment variable, which points to an environment- and region-specific YAML file (e.g., `production-us-central1.yml`). A base `development.yml` file (`src/main/resources/config/development.yml`) is used for local development. Secrets are stored as Kubernetes secrets via the `mls-secrets` submodule at `.meta/deployment/cloud/secrets/`. Non-secret environment variables are defined in the cloud deployment YAML files under `.meta/deployment/cloud/components/app/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML configuration file | yes | (none) | env (set per deployment target) |
| `MIN_RAM_PERCENTAGE` | JVM minimum RAM percentage for heap sizing | no | `75.0` | `.meta/deployment/cloud/components/app/common.yml` |
| `MAX_RAM_PERCENTAGE` | JVM maximum RAM percentage for heap sizing | no | `75.0` | `.meta/deployment/cloud/components/app/common.yml` |
| `MALLOC_ARENA_MAX` | Limit malloc arenas to prevent vmem explosion / OOM kills | no | `4` | `.meta/deployment/cloud/components/app/common.yml` |
| `JMX_HOST` | JMX bind host for monitoring | no | `127.0.0.1` | `.meta/deployment/cloud/components/app/common.yml` |
| `OTEL_SDK_DISABLED` | Disable/enable OpenTelemetry SDK | no | `true` (Docker default); `false` in cloud envs | `Dockerfile`, env-specific YAML |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OpenTelemetry collector endpoint URL | no | (none) | env-specific YAML |
| `OTEL_RESOURCE_ATTRIBUTES` | OTel resource attributes (e.g., `service.name=mls-rin`) | no | `service.name=mls-rin` | env-specific YAML |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disable APM TLS cert verification | no | `false` | `production-us-central1.yml` |
| `JAVA_OPTS` | JVM startup options (includes OTel javaagent path) | no | (set in Dockerfile) | `Dockerfile` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `activeRegion` | Configures service region mode (`NAM` or `INTL`) to enable region-specific logic | set per environment | per-region |
| `customerLocationFlowForEMEA` | Enables customer location flow for EMEA region | `false` | per-region |
| `fisFeatures.useMlsForVoucherGraphs` | Controls whether MLS local data or FIS is used for voucher graph data | configured per env | global |
| `unitSearch.fisSpecificFeatures` | Per-inventory-service feature flags (enabled, hasRedemption, canRedeem, canAttachOverspend, needsProductsInQuery, etc.) | per IS | per-isid |
| `unitSearch.countrySpecificFeatures` | Per-country feature toggles (customerDetailsVisible, priceEnabledCountry) | per country | per-country |
| `modules.merchantRisk` | Enables merchant risk module when present | Optional (absent = disabled) | global |
| `modules.yangService` | Enables Yang DB module when present | Optional (absent = disabled) | global |
| `fisFeatures.dealList.tpisUnitCountsEnabled` | Enables unit counts via TPIS inventory service | configured per env | per-isid |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration (pointed to by `development.yml` symlink at repo root) |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production GCP US Central 1 configuration |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | Production AWS EU West 1 configuration |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | Production GCP Europe West 1 configuration |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging GCP US Central 1 configuration |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | Staging GCP Europe West 1 configuration |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | Staging AWS US West 2 configuration |
| `development-eu.yml` | YAML | Local EU development config symlink |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config (resources, probes, log config) |
| `doc/swagger/swagger.yaml` | YAML | OpenAPI 2.0 spec |
| `src/main/resources/apis/server-unit-search.yaml` | YAML | Unit search API server stub spec (code-generated) |
| `src/main/resources/apis/server-insights.yaml` | YAML | Insights API server stub spec (code-generated) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials (per DB: deal index, history, metrics, unit index, yang) | PostgreSQL connection credentials for each read model | k8s-secret (mls-secrets submodule at `.meta/deployment/cloud/secrets/`) |
| Client ID credentials | Client IDs and role mappings for auth (`clientIdAuth.clientIds`) | k8s-secret |
| Downstream service credentials / tokens | HTTP client authentication tokens for mana, dealCatalog, orders, etc. | k8s-secret |
| FIS client credentials | Credentials for FIS (Federated Inventory Service) client | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Local / Development**: Uses `development.yml` pointing to staging databases via SOCKS proxy (`ssh -D9999`); VIS, GLive, and Getaways clients may be optional/disabled
- **Staging (us-central1)**: `JTIER_RUN_CONFIG=/var/groupon/jtier/config/cloud/staging-us-central1.yml`; 2–3 replicas; CPU 1000m–2000m; Memory 4Gi–8Gi; OTel enabled pointing to `tempo-staging`
- **Staging (europe-west1)**: Separate YAML for EU staging config
- **Production (us-central1 / GCP)**: `JTIER_RUN_CONFIG=/var/groupon/jtier/config/cloud/production-us-central1.yml`; 3–16 replicas; CPU 1200m–2000m; Memory 4Gi–8Gi; OTel enabled pointing to `tempo-production`; `activeRegion=NAM`
- **Production (eu-west-1 / AWS)**: `JTIER_RUN_CONFIG=/var/groupon/jtier/config/cloud/production-eu-west-1.yml`; 3–16 replicas; CPU 120m–2000m; Memory 4Gi–8Gi; `activeRegion=INTL`
- **On-premises (snc1/sac1/dub1)**: Legacy Capistrano-based deployment; config applied via JTier service framework at startup
