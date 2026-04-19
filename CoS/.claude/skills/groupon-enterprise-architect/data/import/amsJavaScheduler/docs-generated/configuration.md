---
service: "amsJavaScheduler"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

AMS Java Scheduler is configured through a combination of environment variables injected by Kubernetes (via Helm chart values in `.meta/deployment/cloud/components/<component>/`) and a YAML run-config file whose path is passed via the `RUN_CONFIG` environment variable. Schedule files bundled inside the JAR provide cron timing for the on-premise deployment model; in cloud deployments, cron timing is managed by the Kubernetes `jobSchedule` field in the Helm values. Each cronjob component (`bcookie`, `universal`, `users`, `sadintegrationcheck`, `usersbatchsad`) has its own `common.yml` (shared config) and per-environment/region `.yml` overrides.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `AMS_TYPE` | Identifies which scheduler job type this pod runs (e.g., `universal`, `users`, `bcookie`, `sadintegrationcheck`, `usersbatchsad`) | yes | none | helm (component `common.yml`) |
| `RUN_CONFIG` | Absolute path to the YAML run configuration file for the active environment and region | yes | none | helm (per-environment `.yml`) |
| `CLASS_TO_RUN` | Fully-qualified class name of the launcher/action to execute for the old-flow dispatch path | yes | none | helm (per-environment `.yml`) |
| `ACTIVE_ENV` | Active environment identifier used to select the correct config context (e.g., `cloud_staging_na`, `cloud_production_na`) | yes | none | helm (per-environment `.yml`) |
| `TIME_OF_RUN` | Cron expression for the job's scheduled trigger time; mirrors the Kubernetes `jobSchedule` field for runtime logging | yes | none | helm (per-environment `.yml`) |
| `BASE_PATH` | Base file system path for AMS log and config directories (on-premise only, e.g., `/var/groupon/ams`) | on-premise only | none | env (on-premise launch command) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found — no feature flag system is referenced in the codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/<component>/common.yml` | YAML | Helm values shared across all environments for a given cronjob component: image, probes, log config, resource requests, `AMS_TYPE` |
| `.meta/deployment/cloud/components/<component>/<env>-<region>.yml` | YAML | Per-environment/region Helm overrides: `deployEnv`, `region`, `namespace`, `jobSchedule`, `RUN_CONFIG`, `CLASS_TO_RUN`, `ACTIVE_ENV`, `TIME_OF_RUN` |
| `amsJavaScheduler/schedules/schedule-na.txt` | Text | NA production cron schedule (on-premise / embedded) |
| `amsJavaScheduler/schedules/schedule-emea.txt` | Text | EMEA production cron schedule (on-premise / embedded) |
| `amsJavaScheduler/schedules/schedule-na-staging.txt` | Text | NA staging cron schedule |
| `amsJavaScheduler/schedules/schedule-emea-staging.txt` | Text | EMEA staging cron schedule |
| `amsJavaScheduler/schedules/schedule-na-uat.txt` | Text | NA UAT cron schedule |
| `amsJavaScheduler/schedules/schedule-emea-uat.txt` | Text | EMEA UAT cron schedule |

## Secrets

> No evidence found of explicitly configured secrets (Vault paths, Kubernetes secrets) in the visible config files. Service-to-service credentials (AMS API auth, SSH keys) are expected to be injected via the Kubernetes cluster or host-level trust mechanisms and are not documented in plaintext config.

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Each Kubernetes CronJob component has a dedicated per-environment YAML file that overrides the shared `common.yml`. Key differences across environments:

| Environment | Region | `jobSchedule` (universal) | Namespace |
|-------------|--------|---------------------------|-----------|
| staging | us-central1 (GCP) | `0 22 * * *` | `ams-staging` |
| staging | europe-west1 (GCP) | varies per component | `ams-staging` |
| production | us-central1 (GCP) | `0 2 * * *` | `ams-production` |
| production | eu-west-1 (AWS) | varies per component | `ams-production` |

Staging environments use `ACTIVE_ENV: cloud_staging_na` or `cloud_staging_emea`; production uses `ACTIVE_ENV: cloud_production_na` or `cloud_production_emea`. The `RUN_CONFIG` path also differs per environment and region, pointing to the appropriate YAML config file on the pod's filesystem.

Log files are written to `/var/groupon/ams/amsJavaScheduler/logs/scheduler.log` and shipped via Filebeat with Kibana source type `audience-scheduler`.
