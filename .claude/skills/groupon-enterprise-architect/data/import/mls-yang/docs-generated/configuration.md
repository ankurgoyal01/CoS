---
service: "mls-yang"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

mls-yang uses layered YAML configuration files, with environment-specific overrides selected at runtime via the `JTIER_RUN_CONFIG` environment variable. Base configuration is in `src/main/resources/config/development.yml`; production overrides live in `src/main/resources/config/cloud/production-us-central1.yml`. Secrets (database passwords, Kafka credentials, Hive passwords) are injected as environment variables referenced using `${VAR_NAME}` substitution in the YAML. Kubernetes deployment configuration is managed via `.meta/deployment/cloud/components/worker/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Selects the active config file path at runtime | yes | (none) | env / Kubernetes `envVars` |
| `YANG_DB_APP_PASSWORD` | Application password for `yangDb` PostgreSQL connection | yes | (none) | k8s-secret / vault |
| `YANG_DB_DBA_PASSWORD` | DBA password for `yangDb` PostgreSQL connection | yes | (none) | k8s-secret / vault |
| `RIN_DB_APP_PASSWORD` | Application password for `rinDb` PostgreSQL connection | yes | (none) | k8s-secret / vault |
| `RIN_DB_DBA_PASSWORD` | DBA password for `rinDb` PostgreSQL connection | yes | (none) | k8s-secret / vault |
| `HISTORY_DB_APP_PASSWORD` | Application password for `historyDb` PostgreSQL connection | yes | (none) | k8s-secret / vault |
| `HISTORY_DB_DBA_PASSWORD` | DBA password for `historyDb` PostgreSQL connection | yes | (none) | k8s-secret / vault |
| `DEAL_INDEX_DB_APP_PASSWORD` | Application password for `dealIndexDb` PostgreSQL connection | yes | (none) | k8s-secret / vault |
| `GDOOP_HIVE_PASSWORD` | Password for `svc_mx_merchant` Hive (Janus/gdoop) JDBC connection | yes | (none) | k8s-secret / vault |
| `CEREBRO_HIVE_PASSWORD` | Password for `svc_mx_merchant` Cerebro Hive JDBC connection | yes | (none) | k8s-secret / vault |
| `DC_CLIENT_ID` | Deal Catalog API client ID for authentication | yes | (none) | k8s-secret / vault |
| `MALLOC_ARENA_MAX` | JVM malloc arena tuning to prevent vmem explosion | no | `4` | Kubernetes `envVars` in common.yml |
| `OTEL_SDK_DISABLED` | Disable/enable OpenTelemetry SDK | no | `false` | Kubernetes `envVars` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP exporter endpoint for tracing | no | `http://otel-collector-opentelemetry-collector.tempo-production:4318` | Kubernetes `envVars` |
| `OTEL_RESOURCE_ATTRIBUTES` | OpenTelemetry resource attributes | no | `service.name=mls-yang` | Kubernetes `envVars` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `commandHandlers.*.enabled` | Per-topic enable/disable of each Kafka command handler | `false` (dev), `true` (production, per topic) | per-environment |
| `yangHistoryEventConfig.saveHistoryEventInHistoryService` | Whether `HistoryCreationHandler` writes to the dedicated `historyDb` | `false` (dev), `true` (production) | global |
| `yangHistoryEventConfig.typesWhitelist` | List of `HistoryEvent` types also written to `yangDb` (e.g. `DEAL_CAP_RAISE_EVENT`) | `["DEAL_CAP_RAISE_EVENT"]` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development defaults; all Kafka handlers disabled |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | GCP production overrides — Kafka SSL, production DB hosts, Hive URLs, Quartz triggers |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | GCP staging overrides |
| `src/main/resources/config/snc1/production.yml` | YAML | Legacy snc1 production configuration |
| `src/main/resources/config/snc1/staging.yml` | YAML | Legacy snc1 staging configuration |
| `src/main/resources/config/snc1/uat.yml` | YAML | Legacy snc1 UAT configuration |
| `src/main/resources/config/sac1/production.yml` | YAML | Legacy sac1 production configuration |
| `src/main/resources/metrics.yml` | YAML | Metrics reporter destination URL and flush frequency |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Kubernetes worker deployment base config (replicas, ports, APM, logging) |
| `.meta/deployment/cloud/components/worker/production-us-central1.yml` | YAML | Production-specific Kubernetes resource limits (CPU, memory) |
| `.meta/deployment/cloud/components/worker/staging-us-central1.yml` | YAML | Staging-specific Kubernetes resource limits |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `YANG_DB_APP_PASSWORD` | Yang primary DB application user password | k8s-secret (`.meta/deployment/cloud/secrets`) |
| `YANG_DB_DBA_PASSWORD` | Yang primary DB DBA user password | k8s-secret |
| `RIN_DB_APP_PASSWORD` | RIN DB application user password | k8s-secret |
| `RIN_DB_DBA_PASSWORD` | RIN DB DBA user password | k8s-secret |
| `HISTORY_DB_APP_PASSWORD` | History DB application user password | k8s-secret |
| `HISTORY_DB_DBA_PASSWORD` | History DB DBA user password | k8s-secret |
| `DEAL_INDEX_DB_APP_PASSWORD` | Deal Index DB application user password | k8s-secret |
| `GDOOP_HIVE_PASSWORD` | Janus/gdoop Hive service account password | k8s-secret |
| `CEREBRO_HIVE_PASSWORD` | Cerebro Hive service account password | k8s-secret |
| `DC_CLIENT_ID` | Deal Catalog API client ID | k8s-secret |
| Kafka SSL keystores | `/var/groupon/jtier/kafka.client.keystore.jks`, `truststore.jks` | Volume-mounted certificate (`client-certs` volume) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: All Kafka command handlers are `enabled: false` to prevent accidental consumption. Database hosts point to staging RDS/GDS instances. Hive URL points to legacy snc1 staging server. Quartz batch jobs are defined but most triggers are commented out.
- **Staging (GCP)**: Kafka handlers enabled with `group.id: mls_yang-staging-snc1` (from staging config). Database hosts on `*.gds.stable.gcp.groupondev.com`. Hive URL points to analytics staging. Some Quartz jobs (`InventoryProductsImport`, `RefundRateImport`, `DealDailyBackfill`) are defined but not triggered.
- **Production (GCP us-central1)**: All Kafka handlers enabled with SSL. Database hosts on `*.gds.prod.gcp.groupondev.com`. Production Hive URLs with SSL and HTTP transport mode. All Quartz triggers active including inventory, refund rate, and daily backfill. `saveHistoryEventInHistoryService: true`.
- **Legacy (snc1/sac1)**: Configuration files remain for on-premise colos; base URLs defined in `.service.yml` for `mls-yang-app1.snc1:8080` and `mls-yang-app1.sac1:8080`.
