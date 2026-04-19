---
service: "contract_service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets, raptor]
---

# Configuration

## Overview

Contract Service is configured through a combination of environment variables injected at container startup, YAML config files in the `config/` directory, and Kubernetes secrets managed via the Raptor secrets tooling. Database credentials are resolved at runtime via the `RollerHostConfig` library, which reads from the Groupon-internal host configuration system. Per-environment overrides are provided through separate YAML files under `.meta/deployment/cloud/components/app/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Rails environment name (development, staging, production) | yes | none | env / helm |
| `DB_HOST` | MySQL database hostname | yes | `localhost` (dev) | env / k8s-secret |
| `DB_NAME` | MySQL database name | yes | `contract_service_development` (dev) | env / helm |
| `RAILS_LOG_PATH` | Directory for application log files | no | `/var/groupon/logs` | helm |
| `RAILS_LOG_FILE` | Application log file path | no | `/var/groupon/logs/steno.log` | helm |
| `RAILS_LOG_TO_STDOUT` | Enable logging to stdout (empty string = disabled) | no | `""` | helm |
| `DEPLOY_SERVICE` | Service identifier injected by the deploy platform | no | none | helm |
| `DEPLOY_COMPONENT` | Component identifier (e.g., `app`) | no | none | helm |
| `DEPLOY_ENV` | Deployment environment label | no | none | helm |
| `DEPLOY_NAMESPACE` | Kubernetes namespace name | no | none | k8s downward API |
| `TELEGRAF_URL` | Telegraf metrics endpoint for Wavefront emission | no | none | helm |
| `TELEGRAF_METRICS_ATOM` | Current deployment SHA for metrics tagging | no | none | helm |
| `DEPLOYMENT_ENV` | Human-readable deployment environment label (e.g., `Conveyor_Cloud`) | no | none | helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No feature flag system (LaunchDarkly, Flipper, etc.) is configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML (ERB) | Database adapter, pool, timeout, and host configuration per environment; reads from `RollerHostConfig` for non-dev environments |
| `config/app.yml` | YAML | Application-level configuration (contents are minimal) |
| `config/environments/production.rb` | Ruby | Rails production-environment settings |
| `config/environments/staging.rb` | Ruby | Rails staging/test-environment settings |
| `config/environments/development.rb` | Ruby | Rails development-environment settings |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config: service ID (`cicero`), health check path (`/status`), HPA target, Steno source type, log paths, Rails port (8080) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production overrides: GCP us-central1, namespace `cicero-production-sox`, replicas 2–4, CPU 300m–700m, memory 500Mi–1Gi |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging overrides: GCP us-central1, namespace `cicero-staging-sox`, replicas 1–2, CPU 300m–700m, memory 500Mi–1Gi |
| `.meta/.raptor.yml` | YAML | Raptor configuration: component `app`, archetype `rails`, secrets path `.meta/deployment/cloud/secrets` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database password | MySQL authentication credential for the contract service database | k8s-secret (via Raptor secrets submodule) |
| TLS identity certificate | mTLS client certificate for Hybrid Boundary (Envoy) | k8s-secret (`cicero-{env}-tls-identity`) |

> Secret values are NEVER documented. Only names and rotation policies are listed. Secret rotation follows the Raptor secrets submodule update process documented in RUNBOOK.md: pull latest secrets SHA, merge, deploy (secrets-only deploy required before any other changes).

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| Namespace | `cicero-staging-sox` | `cicero-production-sox` |
| Min replicas | 1 | 2 |
| Max replicas | 2 | 4 |
| DB host | `cicero-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `cicero-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| DB name | `contract_service` | `contract_service_production` |
| `RAILS_ENV` | `staging` | `production` |
| `DEPLOYMENT_ENV` | `Conveyor_Cloud` | `Conveyor_Cloud` |
| GCP VPC | `stable` | `prod` |
