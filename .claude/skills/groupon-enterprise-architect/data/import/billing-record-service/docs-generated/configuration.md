---
service: "billing-record-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [properties-files, archaius, env-vars, cap-secrets]
---

# Configuration

## Overview

Billing Record Service uses a layered configuration model. Static properties files located in `src/main/conf/` are merged at build time via the `property-maven-plugin` and filtered into the deployable WAR. Netflix Archaius (`archaius-core` 0.7.5) provides dynamic runtime configuration updates. Sensitive credentials (database passwords, PCI-API keys, Braintree credentials, mbus credentials) are injected at deployment time from the `billing-record-service-secrets` repository, managed via `cap-secrets`. Cloud deployments supply additional configuration via Kubernetes environment variables defined in the `.meta/deployment/cloud/components/app/` YAML manifests.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JAVA_OPTS` | JVM tuning: sets active environment profile (`-Denv=<env>`), GC policy, heap sizes (Xms/Xmx), JMX configuration, and log path | yes | `-Denv=production-us-west-1 -XX:+UseParallelGC -Xms1024M -Xmx4096M ...` | Kubernetes env (per-region YAML) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual memory bloat in containerized JVM | yes | `4` | `common.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `messagebus.enabled` | Enables or disables Groupon Message Bus connectivity. Set to `false` for local development to avoid mbus errors. | `true` (production) | per-environment |
| `billingrecord.index.capped` | When `true`, the v3 index endpoint returns only one billing record per purchaser (most recent active). Used to cap response size. | varies by environment | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/conf/config-default.properties` | properties | Default application configuration (including `messagebus.enabled`) |
| `src/main/conf/liquibase.properties` | properties | Liquibase database connection settings per environment |
| `src/main/conf/logback.xml` | XML | Logback logging configuration (Steno JSON format, log paths) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes deployment defaults: image, scaling (min 3 / max 15), resource requests (CPU: 500m, Memory: 3Gi–5Gi), health probes, log config |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EMEA overrides: `cloudProvider: aws`, `region: eu-west-1`, min 4 replicas |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production NA overrides: `cloudProvider: aws`, `region: us-west-1`, min 2 replicas |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP overrides: `cloudProvider: gcp`, `region: us-central1`, min 2 replicas |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP US overrides: `cloudProvider: gcp`, `region: us-central1`, min 1 replica |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging GCP EMEA overrides: `cloudProvider: gcp`, `region: europe-west1` |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging AWS US overrides: `cloudProvider: aws`, `region: us-west-1` |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML | Staging AWS EMEA proxy overrides: `cloudProvider: aws`, `region: us-west-2` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `billing-record-service-secrets` | Database credentials, PCI-API keys, Braintree merchant credentials, mbus credentials | cap-secrets (GitHub: `Intl-Checkout/billing-record-service-secrets`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Local / default**: `messagebus.enabled=false` recommended; `env=default`; runs against local PostgreSQL and Redis via Docker Compose
- **Staging**: `env=staging-{region}` — lower replica counts (1–5), GCP or AWS clusters, promoted automatically from master branch CI builds
- **Production**: `env=production-{region}` — higher replica counts (2–15), JVM heap Xmx 4096M, full mbus and PCI-API connectivity
- **Environment selection**: Controlled by `-Denv=<value>` in `JAVA_OPTS`; Archaius loads the matching properties overlay at runtime
