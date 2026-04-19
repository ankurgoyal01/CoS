---
service: "getaways-payment-reconciliation"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, jtier-config-yaml, k8s-secrets]
---

# Configuration

## Overview

The service is configured through a combination of environment variables (injected by Kubernetes/Deploybot) and a JTier YAML config file whose path is passed via the `JTIER_RUN_CONFIG` environment variable. Secrets (database credentials, Gmail OAuth2 credentials, Accounting Service API token) are stored in Kubernetes secrets and mounted into the container. Non-secret values are defined in `.meta/deployment/cloud/components/` YAML overlays.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the JTier YAML config file for the current environment | yes | none | env (k8s overlay) |
| `POD_ROLE` | Distinguishes `app` pod (HTTP API) from `worker` pod (scheduled jobs) | yes | none | env (common.yml) |
| `MALLOC_ARENA_MAX` | Limits memory arena count to prevent JVM virtual memory explosion | yes | `4` | env (common.yml) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables APM TLS cert verification (internal CA) | yes | `"false"` | env (common.yml) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `isAccountingServiceEnabled` | Enables or disables calls to the Accounting Service API during payment processing | Configured per environment in JTier YAML | per-environment |
| `workerIsActive` | Enables or disables the email reader scheduled worker (invoice import) | Configured per environment in JTier YAML | per-environment |
| `reconciliationWorkerIsActive` | Enables or disables the reconciliation scheduled worker | Configured per environment in JTier YAML | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | App pod default resource limits, logging, port config |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | App pod production scaling (2–15 replicas), probes, APM |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | App pod staging config (1 replica, staging APM) |
| `.meta/deployment/cloud/components/app/dev-us-central1.yml` | YAML | App pod dev config (1–2 replicas) |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Worker pod default resource limits, logging, ports |
| `.meta/deployment/cloud/components/worker/production-us-central1.yml` | YAML | Worker pod production config (1 replica, 1000Mi limit, APM) |
| `.meta/deployment/cloud/components/worker/production-eu-west-1.yml` | YAML | Worker pod EU production config |
| `.deploy_bot.yml` | YAML | Deploybot pipeline targets and Kubernetes cluster/context mapping |
| `doc/schema.yaml` | OpenAPI 3.0 | API schema |
| JTier run config (injected via `JTIER_RUN_CONFIG`) | YAML | MySQL connection, MBus config, worker periods/delays, Accounting Service config, notification config, Gmail credentials reference |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `mysql.MYSQL_APP_USERNAME` / `mysql.MYSQL_APP_PASSWORD` | MySQL application credentials | k8s-secret (`.meta/deployment/cloud/secrets`) |
| `gmail.client_id` / `gmail.client_secret` / `gmail.refresh_token` | Gmail OAuth2 credentials for IMAP/SMTP access | k8s-secret (via config YAML secret strings) |
| `accountingServiceClient.apiToken` | `as_api_token` header value for Accounting Service API | k8s-secret |
| `accountingServiceClient.vendorExpediaUSD/EUR/GBP` | Vendor IDs per currency for Accounting Service | k8s-secret / config YAML |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **dev** (`dev-us-central1`): 1–2 replicas; `JTIER_RUN_CONFIG` points to `cloud/dev-us-central1.yml`; no APM endpoint defined
- **staging** (`staging-us-central1`): 1 replica; `JTIER_RUN_CONFIG` points to `cloud/staging-us-central1.yml`; APM endpoint is the staging Elastic stack
- **production US** (`production-us-central1`): App pod 2–15 replicas; worker pod 1 replica; `JTIER_RUN_CONFIG` points to `cloud/production-us-central1.yml`; APM endpoint is the production Elastic stack; worker memory limit raised to 1000Mi
- **production EU** (`production-eu-west-1`): Separate worker pod config for EU region
