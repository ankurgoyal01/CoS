---
service: "expy-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Expy Service is a JTier (Dropwizard) service and follows the standard JTier configuration pattern: a YAML config file (typically `config.yml`) is loaded at startup and can reference environment variables for secrets and environment-specific overrides. The service uses `jtier-daas-mysql` for MySQL connectivity, `jtier-quartz-bundle` for scheduler setup, and `jtier-retrofit` for HTTP client factory configuration — all of which are configured through the JTier YAML config structure.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` / JDBC datasource config | MySQL connection string for `continuumExpyMySql` | yes | none | env / JTier config |
| `DATABASE_USER` | MySQL username | yes | none | env / vault |
| `DATABASE_PASSWORD` | MySQL password | yes | none | env / vault |
| `AWS_ACCESS_KEY_ID` | AWS credential for S3 SDK (Optimizely and Groupon buckets) | yes | none | env / IAM |
| `AWS_SECRET_ACCESS_KEY` | AWS secret for S3 SDK | yes | none | env / IAM |
| `OPTIMIZELY_S3_BUCKET` | Optimizely-owned S3 bucket name for datafile reads | yes | none | env |
| `GROUPON_S3_BUCKET` | Groupon-owned S3 bucket name for datafile backup writes | yes | none | env |
| `OPTIMIZELY_API_BASE_URL` | Base URL for Optimizely REST API | yes | none | env / config |
| `OPTIMIZELY_DATA_LISTENER_URL` | URL for Optimizely Data Listener | yes | none | env / config |
| `CANARY_API_BASE_URL` | Base URL for Canary API | yes | none | env / config |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

> Exact variable names are inferred from the service summary and JTier conventions. Confirm specific names with the Optimize team (optimize@groupon.com).

## Feature Flags

> No evidence found in the architecture model for service-level feature flags beyond what is managed via the Expy API itself (i.e., the service manages Optimizely flags for other services, but does not expose its own internal toggle mechanism).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Primary JTier/Dropwizard application configuration — database pool, HTTP server, Quartz scheduler, Retrofit client settings |
| `config-{env}.yml` | YAML | Per-environment configuration overrides (dev, staging, production) — standard JTier pattern |

> Exact file paths are not defined in the architecture model. Confirm with the Optimize team.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| MySQL credentials | Authentication to `continuumExpyMySql` | vault / k8s-secret |
| AWS IAM credentials | Authentication to AWS S3 (Optimizely and Groupon buckets) | env / IAM role |
| Optimizely API credentials | Authentication to Optimizely REST API | vault / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Standard JTier pattern: the base `config.yml` defines shared settings; environment-specific overrides (database URLs, external service endpoints, S3 bucket names) are injected via environment variables or a per-environment config file at deployment time. The Quartz job schedule cadence (datafile refresh interval, S3 copy timing) may also differ between dev and production environments.
