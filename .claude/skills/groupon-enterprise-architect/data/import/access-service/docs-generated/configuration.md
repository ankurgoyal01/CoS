---
service: "mx-merchant-access"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, vault]
---

# Configuration

## Overview

The Merchant Access Service is configured through a combination of environment variables (injected at container startup), per-environment Java properties files (mounted at a path determined by `APPLICATION_PROPERTIES_FILE`), and Kubernetes Helm values (defined in `.meta/deployment/cloud/components/app/*.yml`). Secrets (database credentials, MBus credentials, API keys) are injected from a separate secrets volume at `.meta/deployment/cloud/secrets/mas/` and are never stored in the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PROFILE` | Selects the platform profile (`us` or `emea`); controls which configuration branch the app loads | yes | — | helm |
| `APPLICATION_PROPERTIES_FILE` | Absolute path to the per-environment Java properties file mounted in the container | yes | — | helm |
| `JVM_PROCESS_NAME` | JVM process name label used in metrics and logs (e.g., `mas_us`, `mas_emea`) | yes | — | helm |
| `APP_INSTANCE_KEY` | Unique instance key for metrics tagging (e.g., `production-app2-us-central1`) | yes | — | helm |
| `APP_INSTANCE_ENV` | Deployment environment name for metrics (`production`, `staging`) | yes | — | helm |
| `APPLICATION_LOG_DIR` | Directory where Tomcat writes application logs | yes | `/var/groupon/tomcat/logs/` | helm |
| `JAVA_UTIL_LOGGING_CONFIG_FILE` | Path to JUL logging config for Tomcat internals | yes | `/usr/local/tomcat/conf/logging.properties` | helm |
| `JAVA_UTIL_LOGGING_MANAGER` | JUL log manager class | yes | `org.apache.juli.ClassLoaderLogManager` | helm |
| `APPLICATION_TEMP_DIR` | Temp directory for JVM / Tomcat | yes | `/usr/local/tomcat/temp` | helm |
| `MEMORY_OPTS` | JVM heap settings passed into `CATALINA_OPTS` (e.g., `-Xmx6G`) | yes | — | helm |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent vmem explosion in containers | no | `4` | helm (common.yml) |
| `OTEL_SDK_DISABLED` | Disables OpenTelemetry SDK when `true`; `false` in staging to enable tracing | no | `true` (production) | helm |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP endpoint for trace export (used in staging) | no | — | helm (staging only) |
| `OTEL_RESOURCE_ATTRIBUTES` | OpenTelemetry resource attributes (e.g., `service.name=access-service`) | no | — | helm (staging only) |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `mbus.enabled` | Enables or disables MBus consumer beans; disabling prevents all event processing | — | per-environment (properties file) |
| `mas.ehcache_enabled` | Enables the EhCache in-process cache manager; when false, a no-op cache is used | — | per-environment (properties file) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment defaults (replicas, probes, resources, ports, log config) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US Central1 (GCP) overrides |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU West-1 (AWS) overrides |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production Europe West-1 (GCP) overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US Central1 (GCP) overrides |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging Europe West-1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML | Staging US West-2 overrides |
| `access-webapp/src/main/docker/setenv.sh` | Shell | Assembles `CATALINA_OPTS` from env vars at container startup |
| `access-infrastructure/src/main/envs/*/liquibase.properties` | Properties | Liquibase DB connection per environment (default, dev, prod, stg-emea, stg-us) |
| `mas.basic_auth.consumers` (properties file key) | Properties | Comma-separated `user:pass` pairs for Basic Auth consumers of the future_contact endpoint |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/mas/` | Database credentials (username/password), MBus credentials, API key values | k8s-secret (Helm secrets volume) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Production US** (`production-us-central1.yml`, `PROFILE=us`): 2–15 replicas, 1400m–2000m CPU, 6–8 Gi memory, `-Xmx6G`
- **Production EU/EMEA** (`production-eu-west-1.yml`, `PROFILE=emea`): 2–15 replicas, 700m–1000m CPU, 2–4 Gi memory, RAM percentage JVM flags
- **Staging** (`staging-us-central1.yml`, `PROFILE=us`): 1–2 replicas, 700m–1000m CPU, 3–4 Gi memory, `-Xmx2G`; OpenTelemetry export enabled; `OTEL_SDK_DISABLED=false`
- **Dev/local**: Run via `mvn tomcat7:run -Dprofile=us-dev`; uses `access-infrastructure/src/main/envs/dev/liquibase.properties`
