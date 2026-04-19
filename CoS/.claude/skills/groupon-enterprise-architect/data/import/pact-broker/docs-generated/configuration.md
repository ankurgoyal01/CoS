---
service: "pact-broker"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, secrets-submodule]
---

# Configuration

## Overview

Pact Broker is configured entirely through environment variables injected at deployment time. Non-secret variables are declared in the Helm values file (`.meta/deployment/cloud/components/app/staging-us-central1.yml`). Secret values (database password, basic-auth credentials) are injected from a Git submodule (`pact-broker-secrets`) managed via the [QA/pact-broker-secrets](https://github.groupondev.com/QA/pact-broker-secrets) repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PACT_BROKER_DATABASE_HOST` | PostgreSQL hostname | yes | `pact_broker-rw-na-staging-pg-db.gds.stable.gcp.groupondev.com` (staging) | helm |
| `PACT_BROKER_DATABASE_NAME` | PostgreSQL database name | yes | `pact_broker_stg` (staging) | helm |
| `PACT_BROKER_DATABASE_USERNAME` | PostgreSQL database user | yes | `pact_broker_stg_dba` (staging) | helm |
| `PACT_BROKER_DATABASE_PASSWORD` | PostgreSQL database password | yes | none | secrets-submodule |
| `PACT_BROKER_LOG_FORMAT` | Log output format | yes | `json` | helm |
| `PACT_BROKER_LOG_STREAM` | Log output stream destination | yes | `file` | helm |
| `PACT_BROKER_ALLOW_PUBLIC_READ` | Allow unauthenticated read access to the API | yes | `true` | helm |
| `PACT_BROKER_BASIC_AUTH_USERNAME` | Admin username for write-protected API endpoints | yes | `admin_pact_broker` | helm |
| `PACT_BROKER_BASIC_AUTH_PASSWORD` | Admin password for write-protected API endpoints | yes | none | secrets-submodule |
| `PACT_BROKER_WEBHOOK_HOST_WHITELIST` | Space-separated list of hosts allowed as webhook targets | yes | `github.groupondev.com github.com` | helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

> No evidence found in codebase. No feature flag system is configured. Runtime behaviour is controlled entirely by environment variables.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Helm values — resource limits, replicas, env vars, probes for staging/us-central1 |
| `.meta/deployment/cloud/scripts/deploy.sh` | Shell | Helm template + krane deploy script |
| `.deploy_bot.yml` | YAML | Deploybot target definitions and Kubernetes cluster/context mapping |
| `Jenkinsfile` | Groovy (Jenkins DSL) | CI pipeline definition using `java-pipeline-dsl` shared library |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `PACT_BROKER_DATABASE_PASSWORD` | PostgreSQL authentication | `pact-broker-secrets` Git submodule + 1Password |
| `PACT_BROKER_BASIC_AUTH_PASSWORD` | Pact Broker admin API write access | `pact-broker-secrets` Git submodule + 1Password |

> Secret values are NEVER documented. Secrets are stored in the [QA/pact-broker-secrets](https://github.groupondev.com/QA/pact-broker-secrets) repository (a Git submodule of this repo at `.meta/deployment/cloud/secrets`) and mirrored to [1Password](https://groupon.1password.com/) under the "Pact Broker" item.

## Per-Environment Overrides

- **Staging (us-central1)**: Fully configured via `.meta/deployment/cloud/components/app/staging-us-central1.yml`. Database host ends in `.gds.stable.gcp.groupondev.com`. 2 replicas (min and max).
- **Production**: No production-specific config file is present in this repository. Per the README, infrastructure details (including production config) are documented in the [QA Tribe Confluence — Pact Broker Infrastructure](https://groupondev.atlassian.net/wiki/spaces/QAT/pages/82222252147/Pact+Broker+-+Infrastructure) page.

## Logging

| Variable | Value | Purpose |
|----------|-------|---------|
| `PACT_BROKER_LOG_FORMAT` | `json` | Structured JSON log output |
| `PACT_BROKER_LOG_STREAM` | `file` | Logs written to file (collected by log agent) |
| Log file path | `/pact_broker/log/pact_broker.log` | Application log file location |
| Log source type | `pact-broker` | Source type label for log aggregation |
