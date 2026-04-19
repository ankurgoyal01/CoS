---
service: "forex-ng"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Forex NG is configured through a layered YAML configuration system provided by JTier/Dropwizard. The base configuration is defined in `src/main/resources/config/development.yml`. Per-environment overrides are provided in `src/main/resources/config/cloud/{env}.yml` (cloud/Kubernetes deployments) and `src/main/resources/config/snc1/{env}.yml` (legacy datacenter deployments). The active config file is selected at runtime via the `JTIER_RUN_CONFIG` environment variable. AWS credentials are injected via Kubernetes pod-level environment variables using Web Identity Token File credentials.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the environment-specific YAML config file to load at startup | yes | `development.yml` (via JTier default) | helm / deployment manifest |
| `JTIER_RUN_CMD` | The Dropwizard command to execute. Set to `refresh-rates` for cron-job pods; omitted for the long-running HTTP service | yes (cron pods) | none | `.meta/deployment/cloud/components/cron-job/common.yml` |
| `FOREXS3_S3_BUCKET_NAME` | Name of the AWS S3 bucket used to store forex rate files | yes (cloud) | none | Kubernetes secret / environment block |
| `AWS_REGION` | AWS region for S3 client. Falls back to `us-west-2` if unset | no | `us-west-2` | deployment manifest / helm |
| `AWS_DEFAULT_REGION` | AWS default region (used alongside `AWS_REGION`) | no | none | deployment manifest |
| `AWS_ROLE_ARN` | ARN of the IAM role to assume via web identity federation | yes (cloud) | none | Kubernetes IRSA / pod annotation |
| `AWS_WEB_IDENTITY_TOKEN_FILE` | Path to the projected service account token file for IRSA authentication | yes (cloud) | none | Kubernetes projected volume |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. The service uses a `dataStore` config key to switch between `inmemory` (dev) and `awss3` (production) storage backends, but this is a config file setting, not a runtime feature flag.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Base development configuration; inmemory data store; limited currency list; Quartz every 2 minutes |
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | Production cloud override for AWS us-west-1; S3 data store; 46 currencies; Quartz every 5 minutes; concurrentFreq=10 |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | Production cloud override for AWS eu-west-1; S3 data store; 46 currencies |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production cloud override for GCP us-central1; S3 data store; cross-cloud AWS-GCP role config |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | Production cloud override for GCP europe-west1; S3 data store |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | Staging cloud override; S3 data store; Quartz job disabled (commented out) |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | Staging cloud override for us-west-2 |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | Staging cloud override for GCP europe-west1 |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging cloud override for GCP us-central1 |
| `src/main/resources/config/snc1/production.yml` | YAML | Legacy snc1 datacenter production override; maxThreads/minThreads=500 |
| `src/main/resources/config/snc1/staging.yml` | YAML | Legacy snc1 datacenter staging override |
| `src/main/resources/config/snc1/uat.yml` | YAML | Legacy snc1 datacenter UAT override |
| `src/main/resources/metrics.yml` | YAML | Metrics reporter config; Telegraf destination URL and flush interval (10s) |
| `.meta/deployment/cloud/components/cron-job/common.yml` | YAML | Shared Kubernetes cron job definition; job schedule `*/11 * * * *`; CPU 300m, Memory 1Gi/2Gi |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `AWS_ROLE_ARN` | IAM role ARN for AWS STS web identity token credential exchange | Kubernetes pod annotation / IRSA |
| `AWS_WEB_IDENTITY_TOKEN_FILE` | Projected service account token for IRSA authentication | Kubernetes projected volume |
| `netsuiteRetroClient.authenticationOptions[h]` | NetSuite scriptlet authentication token (`h=590457ab4ae5f6a25951`) | YAML config (not rotated via vault — value is static in config) |

> Secret values are NEVER documented. Only names and rotation policies are noted here.

## Per-Environment Overrides

### Key configuration differences by environment

| Setting | Development | Staging (cloud) | Production (cloud) |
|---------|-------------|-----------------|-------------------|
| `dataStore` | `inmemory` | `awss3` | `awss3` |
| `dataProvider` | `netsuit` | `netsuit` | `netsuit` |
| Currency count | 7 (AED, ARS, AUD, USD, EUR, INR, CAD) | 46 | 46 |
| Quartz cron | `0 */2 * * * ?` (every 2 min) | Disabled (commented out in staging-us-west-1) | `0 */5 * * * ?` (every 5 min, service config); overridden to `*/11 * * * *` by Kubernetes cron job schedule |
| `netsuite.concurrentFreq` | 3 | 10 | 10 |
| `netsuite.maxRetryCount` | 2 | 2 | 2 |
| `server.maxThreads` | 50 | 50 | 50 (cloud) / 500 (snc1 legacy) |
| S3 bucket | Not applicable | Set via `FOREXS3_S3_BUCKET_NAME` | Set via `FOREXS3_S3_BUCKET_NAME` |
| Netsuite URL | `https://1202613.extforms.netsuite.com/` | `https://1202613.extforms.netsuite.com/` | `https://1202613.extforms.netsuite.com/` |

### Notes

- In staging (cloud), the Quartz in-process scheduler is disabled. Rate refresh in staging is driven exclusively by the Kubernetes cron job executing the `refresh-rates` CLI command.
- Production cloud environments deploy as Kubernetes cron jobs (`component: cron-job`) on an `*/11 * * * *` schedule, with the HTTP server component managed separately.
- GCP environments (us-central1, europe-west1) use cross-cloud IRSA via `gcpServiceAccount` and `amazonAwsRoleArn` annotations to access AWS S3.
