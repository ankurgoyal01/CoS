---
service: "afl-3pgw"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

AFL-3PGW is configured through environment-specific YAML files (one per deployment environment/region) loaded at startup via the `JTIER_RUN_CONFIG` environment variable. Secrets (database credentials, API tokens, CJ signatures) are injected as Kubernetes secrets and mapped to environment variables. Non-secret runtime tunables are passed as plain environment variables set in the deployment configuration files under `.meta/deployment/cloud/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the environment-specific YAML config file loaded at startup | yes | None | helm / k8s deployment env |
| `DAAS_APP_USERNAME` | MySQL database username for the service's own database | yes | None | k8s-secret |
| `DAAS_APP_PASSWORD` | MySQL database password for the service's own database | yes | None | k8s-secret |
| `DEPLOY_SERVICE` | Deployment identifier — service name (`afl-3pgw`) injected by deployment template | yes | None | k8s deployment template |
| `DEPLOY_COMPONENT` | Deployment identifier — component name (`app`) injected by deployment template | yes | None | k8s deployment template |
| `DEPLOY_INSTANCE` | Deployment identifier — instance name (`default`) injected by deployment template | yes | None | k8s deployment template |
| `DEPLOY_ENV` | Runtime environment name (`staging` or `production`) | yes | None | k8s deployment template |
| `DEPLOY_NAMESPACE` | Kubernetes namespace, injected from pod metadata | yes | None | k8s fieldRef |
| `TELEGRAF_METRICS_ATOM` | SHA of current deployment for Telegraf metrics tagging | yes | None | k8s deployment template |
| `TELEGRAF_URL` | URL of the local Telegraf metrics endpoint | yes | None | k8s deployment template |
| `MALLOC_ARENA_MAX` | Tunes glibc memory arena count to prevent virtual memory explosion | no | `4` | `common.yml` envVars |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `mbusEnabled` | Enables or disables MBUS topic consumption; when `false`, the service runs in job-only mode | `true` | global |
| `outputType` (CJ) | Controls CJ adapter mode: `http` (live submissions) or `logging` (dry-run, log-only) | `http` | global |
| `outputType` (Awin) | Controls Awin adapter mode: `http` (live submissions) or `logging` (dry-run, log-only) | `http` | global |

> These flags are set in the environment YAML config files, not as environment variables. They are part of the `cj` and `awin` YAML configuration blocks.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration (DB, MBUS, CJ, Awin, Quartz, client URLs) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared deployment config (image, scaling, ports, resource requests) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging environment overrides (region, VPC, scaling, VIP URL) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US overrides (region, VPC, scaling, VIP URL, VPA) |
| `.meta/deployment/cloud/components/app/template/config/framework-defaults.yml` | YAML | JTier framework-level defaults for probes, HPA, logging, sidecars |

### Key YAML Configuration Blocks

The main application configuration file (e.g., `development.yml`) includes the following top-level blocks mapped by `Afl3pgwConfiguration`:

| Block | Purpose |
|-------|---------|
| `db` | MySQL DaaS connection config (`DAAS_APP_USERNAME`/`DAAS_APP_PASSWORD` injected as env vars) |
| `quartz` | Quartz scheduler configuration (MySQL-backed clustering, job schedule definitions) |
| `cj` | Commission Junction parameters: signature, CID, platform event type codes, accounts per brand/vertical |
| `awin` | Awin configuration: token, output type, advertiser IDs map, conversion base URL, supported brands/countries, threshold period |
| `mbus` | MBUS connection configuration (broker URL, topic, consumer settings) |
| `mbusEnabled` | Boolean flag to enable/disable MBUS consumption |
| `cjClient` | Retrofit config for CJ S2S endpoint |
| `cjGraphQlClient` | Retrofit config for CJ GraphQL endpoint |
| `cjRestatementClient` | Retrofit config for CJ restatement API |
| `orderServiceClient` | Retrofit config for internal Orders Service |
| `mdsClient` | Retrofit config for Marketing Deal Service |
| `incentiveServiceClient` | Retrofit config for Incentive Service |
| `awinClient` | Retrofit config for Awin REST API |
| `awinConversionClient` | Retrofit config for Awin conversion/tracking API |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_USERNAME` | MySQL username for `afl_3pgw_production` database | k8s-secret (via DaaS) |
| `DAAS_APP_PASSWORD` | MySQL password for `afl_3pgw_production` database | k8s-secret (via DaaS) |
| CJ signature | Shared secret for CJ S2S request authentication (in `cj.params.signature` YAML block) | k8s-secret (via afl-3pgw-secrets git submodule) |
| Awin token | Bearer token for Awin REST API authentication (in `awin.token` YAML block) | k8s-secret (via afl-3pgw-secrets git submodule) |

> All secrets are stored in the `afl-3pgw-secrets` git submodule (`.gitmodules`). Secret values are NEVER documented here.

## Per-Environment Overrides

| Environment | JTIER_RUN_CONFIG | Region | Replicas | VIP |
|-------------|-----------------|--------|----------|-----|
| Staging | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | us-central1 (stable GCP) | 1–2 | `afl-3pgw.us-central1.conveyor.stable.gcp.groupondev.com` |
| Production US | `/var/groupon/jtier/config/cloud/production-us-central1.yml` | us-central1 (prod GCP) | 2–5 | `afl-3pgw.us-central1.conveyor.prod.gcp.groupondev.com` |

> Production EMEA (EU-WEST-1) uses a separate MySQL endpoint (`afl-3pgw-rw-emea-production-db.gds.prod.gcp.groupondev.com`) and region-specific CJ account parameters. Deployment targets for EMEA are managed via separate deploy configurations not present in the NA cloud components folder.
