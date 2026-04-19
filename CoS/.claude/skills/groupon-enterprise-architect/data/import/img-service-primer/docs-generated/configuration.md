---
service: "img-service-primer"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secrets]
---

# Configuration

## Overview

Image Service Primer is configured through a combination of JTier YAML config files (injected per environment via the `JTIER_RUN_CONFIG` environment variable), Helm values files (`.meta/deployment/cloud/components/`), and Kubernetes secrets. Non-secret runtime behavior (parallelism, which caches to hit, transformation codes, country list) is controlled via the JTier YAML config. Secrets (database credentials, cloud storage credentials, Akamai signing keys) are injected via Kubernetes secret mounts.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the environment-specific JTier YAML config file | Yes | None | Helm env-var (per environment override) |
| `JTIER_RUN_CMD` | Override command used by the video-transformer cron job component | Yes (cron only) | None | Helm env-var (`video-transformer --`) |
| `IS_CRON_JOB` | Marks the container as a cron job (video-transformer component) | Yes (cron only) | None | Helm env-var (`true`) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual memory explosion in containers | No | Calculated as 8x CPU cores | Helm common config (`4`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

The following runtime behavior switches are passed in the JTier YAML config and can be overridden on a per-request basis via the `ExecutionConfiguration` object in the API body:

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `defaultConfiguration.hitAkamai` | Whether the Akamai CDN should be warmed during a priming run | `true` | per-run |
| `defaultConfiguration.hitLocalCaches` | Whether GIMS local caches should be hit | `true` | per-run |
| `defaultConfiguration.hitOriginalImages` | Whether the original (un-transformed) image should be fetched | `true` | per-run |
| `defaultConfiguration.hitProcessedImages` | Whether transformed image variants should be fetched | `true` | per-run |
| `defaultConfiguration.skipDistroWindowCheck` | Skip the 24-hour distribution window filter | `false` | per-run |
| `defaultConfiguration.skipNonScheduledDeals` | Skip deals not in `scheduled` state | `true` | per-run |
| `defaultConfiguration.distroWindowInDays` | Distribution window look-ahead in days | `1` | per-run |
| `rxConfig.schedulers.imageService.threadCount` | Concurrency limit for GIMS preload requests | Configured per environment | global |
| `rxConfig.schedulers.dealCatalog.threadCount` | Concurrency limit for deal-catalog requests | Configured per environment | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes deployment common config — ports, scaling, resource requests, health probe paths |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | GCP production (us-central1) overrides — scaling (1–2 replicas), memory (4Gi/8Gi), CPU |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | AWS production (us-west-1) overrides — scaling (1–2 replicas), memory (2300Mi/8Gi) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | GCP staging (us-central1) overrides — scaling (1 replica), memory (1500Mi/3Gi) |
| `.meta/deployment/cloud/components/video-transformer/common.yml` | YAML | Video-transformer CronJob config — schedule (`*/5 * * * *`), 10-minute deadline, resource limits |
| `src/main/docker/Dockerfile` | Dockerfile | Production image; installs FFmpeg on top of `jtier/prod-java11-jtier:3` base |
| `.ci/Dockerfile` | Dockerfile | CI build image; uses `jtier/dev-java11-maven:2023-12-19-609aedb` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials (MySQL) | JDBI3 connection to `continuumImageServicePrimerDb` | k8s-secret (cloud secrets via RAPT) |
| GCS service account credentials | Authentication for GCSClient to download/read media from GCS buckets | k8s-secret |
| AWS credentials | Authentication for AWS S3 SDK to upload video payloads and delete assets | k8s-secret |
| Akamai EdgeGrid signing keys | Request signing for Akamai cache fetch and purge calls | k8s-secret |

> Secret values are NEVER documented. Secret configuration is managed via the `raptor-cli` tool and Kubernetes secret mounts at `.meta/deployment/cloud/secrets/cloud/`.

## Per-Environment Overrides

| Environment | Cloud | Region | Notable Overrides |
|-------------|-------|--------|-------------------|
| `staging-us-central1` | GCP | us-central1 | 1 replica max; 1500Mi RAM; JTIER_RUN_CONFIG points to staging config |
| `production-us-central1` | GCP | us-central1 | 1–2 replicas; 4Gi request / 8Gi limit RAM; JTIER_RUN_CONFIG points to prod config |
| `production-us-west-1` | AWS | us-west-1 | 1–2 replicas; 2300Mi request / 8Gi limit RAM; JTIER_RUN_CONFIG points to prod config |
| `production-eu-west-1` | AWS | eu-west-1 | Same base config as us-west-1; EU traffic target |

The video-transformer cron job runs every 5 minutes with a `Forbid` concurrency policy and a 10-minute active deadline (`activeDeadlineSeconds: 600`).
