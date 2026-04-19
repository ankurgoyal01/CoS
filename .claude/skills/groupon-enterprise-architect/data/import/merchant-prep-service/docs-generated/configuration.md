---
service: "merchant-prep-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, yaml-config-files, vault-secrets]
---

# Configuration

## Overview

The Merchant Preparation Service uses the JTier configuration framework, which merges a YAML application config file with environment variable overrides. The active config file is selected via the `JTIER_RUN_CONFIG` environment variable, which points to the environment-specific YAML file bundled in the Docker image (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`). Secrets (Salesforce credentials, Adobe Sign tokens, database passwords) are injected via Vault-sourced Kubernetes secrets at deploy time, referenced by the `.meta/deployment/cloud/secrets` path.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML configuration file | yes | none | env (set per deploy target) |
| `OTEL_SDK_DISABLED` | Disables OpenTelemetry tracing if `true` | no | `true` (Dockerfile default) | env |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP endpoint for OpenTelemetry trace export | no | none | env (set per environment) |
| `OTEL_RESOURCE_ATTRIBUTES` | OpenTelemetry resource attributes including `service.name=mx-merchant-preparation` | no | none | env |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual memory explosion in containers | no | 4 | env |
| `MIN_RAM_PERCENTAGE` | JVM minimum heap as a percentage of container memory | no | 70.0 | env |
| `MAX_RAM_PERCENTAGE` | JVM maximum heap as a percentage of container memory | no | 70.0 | env |
| `JMX_HOST` | JMX listening host | no | `127.0.0.1` | env |
| `JAVA_OPTS` | JVM startup options (includes OpenTelemetry `-javaagent` path) | no | set in Dockerfile | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `isInternalUser` | Passed as a query parameter on several endpoints to control feature flag visibility and behaviour for Groupon internal users vs. external merchants | false | per-request |
| `isOldMerchant` | Query parameter controlling which onboarding checklist variant to display | false | per-request |
| `companyLegalNameEnabledCountries` | Set of country codes where company legal name fields are active | configured in YAML | global |
| `firstYearAnniversaryEnabledCountries` | Set of country codes where first-year anniversary features are enabled | configured in YAML | global |
| `onboardingEligibilityDate` | Date threshold controlling merchant eligibility for new onboarding flows | configured in YAML | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment parameters (replicas, ports, resource requests, HPA, APM, hybrid boundary config) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP US Central1 overrides (namespace, scaling, env vars) |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production GCP Europe West1 overrides |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production AWS EU West 1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP US Central1 overrides |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging GCP Europe West1 overrides |
| `.deploy_bot.yml` | YAML | DeployBot pipeline target definitions (clusters, contexts, deploy commands) |
| `Jenkinsfile` | Groovy DSL | Jenkins CI pipeline configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Salesforce OAuth2 credentials (`username`, `password`, `client_id`, `client_secret`) | Authentication with Salesforce REST API | Vault (injected via `.meta/deployment/cloud/secrets`) |
| Adobe Sign OAuth2 credentials (`client_id`, `client_secret`, `refresh_token`) | Authentication with Adobe Sign API | Vault |
| TinCheck credentials (`userLogin`, `userPassword`) | Authentication with legacy TinCheck SOAP service | Vault |
| PostgreSQL connection credentials (primary DB) | `daas_postgres` database access | Vault / DaaS |
| MBUS credentials | Message bus producer authentication | Vault |
| `clientIdAuth.clientIds` | Allowed client IDs and their roles for API authentication | YAML config (roles) / Vault (secrets) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging**: `JTIER_RUN_CONFIG` points to `staging-us-central1.yml` or `staging-europe-west1.yml`; min replicas = 1, max replicas = 2; OTLP endpoint points to `tempo-staging`.
- **Production (US)**: `JTIER_RUN_CONFIG` points to `production-us-central1.yml`; min replicas = 2, max replicas = 15; OTLP endpoint points to `tempo-production`; namespace = `mx-merchant-preparation-production-sox`.
- **Production (EU)**: `JTIER_RUN_CONFIG` points to `production-europe-west1.yml` or AWS `production-eu-west-1.yml`; same scaling bounds as US production.
- OpenTelemetry is disabled by default in the Docker image (`OTEL_SDK_DISABLED=true`) and explicitly re-enabled per environment via deployment YAML (`OTEL_SDK_DISABLED: false`).
