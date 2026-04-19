---
service: "api-proxy-config"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "helm-values", "k8s-secrets"]
---

# Configuration

## Overview

`api-proxy-config` is configured through a layered system of Helm value files under `.meta/deployment/cloud/`. A `common.yml` defines base settings applied to all deployments; environment- and region-specific override files (e.g., `production-us-central1.yml`, `staging-europe-west1.yml`) merge on top. Secrets are sourced from a separate Git submodule (`api-proxy-secrets`) referenced at `.meta/deployment/cloud/secrets/`. The deployed `apiProxy` application is pointed to its active configuration file via the `CONFIG` environment variable.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CONFIG` | Path to `mainConf.json` loaded by the `apiProxy` runtime at startup (e.g., `conf/production-us-central1/mainConf.json`) | yes | `conf/staging-us-central1/mainConf.json` (dev/staging) | helm (per-environment override) |
| `AINT_DISABLED` | Disables AINT internal monitoring framework; set to `"true"` in non-production and some production environments | no | `"true"` | helm (`common.yml`, per-env override) |
| `INITIAL_RAM_PERCENTAGE` | JVM initial heap as percentage of container memory | no | `"70"` | helm (`common.yml`) |
| `MAX_RAM_PERCENTAGE` | JVM maximum heap as percentage of container memory | no | `"70"` | helm (`common.yml`) |
| `SLEEP_TIME_SECONDS` | Startup sleep delay in seconds before the application begins accepting traffic | no | `"90"` | helm (`common.yml`, per-env override) |
| `MIN_HEAP_SIZE` | JVM minimum heap size | no | `"2G"` | helm (`common.yml`, per-env override) |
| `MAX_HEAP_SIZE` | JVM maximum heap size | no | `"2G"` | helm (`common.yml`, per-env override) |
| `NODE_ENV` | Used by `config_tools/` scripts to switch between `test` and `live` file path resolution modes | no | `live` (implicit) | runtime environment |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No application-level feature flags are configured in this repository. Routing experiments (A/B tests) defined in `routingConf.json` serve as traffic-routing flags and are managed via the `cleanExperiments` CLI tool.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML (Helm values) | Base deployment configuration: scaling (min 3, max 3 default), resource requests, ports (9000 HTTP, 8443 HTTPS, 9001 admin, 8778 Jolokia), health checks, log config |
| `.meta/deployment/cloud/components/app/<env>-<region>.yml` | YAML (Helm values) | Per-environment/region overrides: cloud provider, namespace, min/max replicas, `CONFIG` env var path, Kafka log endpoint |
| `.meta/deployment/cloud/components/telegraf-agent/common.yml` | YAML (Helm values) | Telegraf sidecar base configuration: scaling (min 1, max 30 HPA), CPU resource requests |
| `.meta/deployment/cloud/components/telegraf-agent/<env>-<region>.yml` | YAML (Helm values) | Per-environment Telegraf overrides |
| `.meta/deployment/cloud/test/test-common.yml` | YAML (Helm values) | Test environment deployment overrides |
| `src/main/conf/<env>-<region>/mainConf.json` | JSON | Top-level API Proxy config; references routing, proxy, and client config files |
| `src/main/conf/<env>-<region>/routingConf.json` | JSON | Routing rules: realms, route groups, routes, destinations, experiment layers |
| `src/main/conf/<env>-<region>/proxyConf.json` | JSON | API Proxy proxy-level settings |
| `src/main/conf/<env>-<region>/clientConf.json` | JSON | Client service endpoint configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/cloud/<env>-<region>.yml` | Per-environment Helm secret values injected into the Kubernetes deployment (API keys, TLS certs, etc.) | Git submodule (`api-proxy-secrets` at `git@github.groupondev.com:groupon-api/api-proxy-secrets.git`) |

> Secret values are NEVER documented. Only names and rotation policies are tracked here.

## Per-Environment Overrides

| Environment | Cloud Provider | Regions | `CONFIG` Value | Min Replicas | Max Replicas |
|-------------|---------------|---------|----------------|--------------|--------------|
| `dev` | GCP | us-central1 | `conf/staging-us-central1/mainConf.json` | 1 | 10 (implied) |
| `staging` (NA) | GCP | us-central1 | `conf/staging-us-central1/mainConf.json` | 2 | 12 |
| `staging` (EMEA) | GCP | europe-west1 | `conf/staging-europe-west1/mainConf.json` | 2 | 12 |
| `production` (NA - AWS) | AWS | us-west-1 | `conf/production-us-west-1/mainConf.json` | 12 | 100 |
| `production` (NA - GCP) | GCP | us-central1 | `conf/production-us-central1/mainConf.json` | 12 | 100 |
| `production` (EMEA - AWS) | AWS | eu-west-1 | `conf/production-eu-west-1/mainConf.json` | 12 | 240 |
| `production` (EMEA - GCP) | GCP | europe-west1 | `conf/production-europe-west1/mainConf.json` | 12 | 240 |

Key per-environment differences:
- **Drain timeout**: 30s (common/dev) → 60s (staging) → 90s (production)
- **`AINT_DISABLED`**: `"true"` in dev and some production environments (set explicitly per region)
- **Topology spread constraints**: Enabled in production (zone and node spreading with `ScheduleAnyway`)
- **Hybrid boundary upstream domain**: `api-proxy--internal-us` (NA), `api-proxy--internal-eu` (EMEA)
- **Logging Kafka endpoint**: `kafka-elk-broker-staging.snc1` (dev/staging), `kafka-elk-broker.snc1` (production NA), `kafka-elk-broker.dub1` (production EMEA)
