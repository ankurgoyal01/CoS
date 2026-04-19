---
service: "gpapi"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

gpapi uses the `config` gem (v3.1.1) for multi-environment configuration file management, supplemented by environment variables for secrets and deployment-specific values. Configuration files are organized under `config/settings/` with per-environment overrides (development, staging, production). Secrets such as API keys, OAuth credentials, and database URLs are injected via environment variables and never committed to the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumGpapiDb` | yes | none | env |
| `RAILS_ENV` | Rails environment selector (development, staging, production) | yes | `development` | env |
| `SECRET_KEY_BASE` | Rails session encryption key | yes | none | env |
| `GOOGLE_RECAPTCHA_PROJECT_ID` | Google Cloud project for reCAPTCHA Enterprise | yes | none | env |
| `GOOGLE_RECAPTCHA_SITE_KEY` | reCAPTCHA Enterprise site key | yes | none | env |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Google Cloud service account JSON key file | yes | none | env |
| `AWS_ACCESS_KEY_ID` | AWS IAM access key for S3 file operations | yes | none | env |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key for S3 file operations | yes | none | env |
| `AWS_S3_BUCKET` | Target S3 bucket name for external file uploads | yes | none | env |
| `NETSUITE_WEBHOOK_SECRET` | Secret token for validating inbound NetSuite webhook requests | yes | none | env |
| `PUMA_WORKERS` | Number of Puma worker processes | no | `2` | env |
| `PUMA_THREADS` | Puma thread pool range (min:max) | no | `1:5` | env |
| `ELASTIC_APM_SERVICE_NAME` | Service name reported to Elastic APM | no | `gpapi` | env |
| `ELASTIC_APM_SERVER_URL` | Elastic APM server endpoint | no | none | env |
| `RAILS_LOG_LEVEL` | Log verbosity level | no | `info` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No dedicated feature flag system is identified in the inventory. Vendor-level feature capabilities are stored in the `features` table in `continuumGpapiDb`.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/settings.yml` | YAML | Base configuration shared across all environments |
| `config/settings/development.yml` | YAML | Development environment overrides |
| `config/settings/staging.yml` | YAML | Staging environment overrides |
| `config/settings/production.yml` | YAML | Production environment overrides |
| `config/database.yml` | YAML | ActiveRecord database connection configuration |
| `config/puma.rb` | Ruby | Puma server configuration (workers, threads, port) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | PostgreSQL connection credentials for `continuumGpapiDb` | env |
| `SECRET_KEY_BASE` | Rails encrypted session and cookie signing | env |
| `GOOGLE_APPLICATION_CREDENTIALS` | Google Cloud service account for reCAPTCHA Enterprise | env |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | AWS IAM credentials for S3 access | env |
| `NETSUITE_WEBHOOK_SECRET` | NetSuite inbound webhook validation | env |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **Development**: Uses local PostgreSQL instance; reCAPTCHA and S3 may be mocked or use test credentials; Elastic APM disabled or pointed at local collector
- **Staging**: Uses staging PostgreSQL instance; reCAPTCHA Enterprise uses a staging site key; S3 bucket is a non-production bucket; NetSuite webhook uses a staging endpoint secret
- **Production**: Uses production PostgreSQL with connection pooling; all secrets are live; Elastic APM reports to the production APM cluster; Puma workers tuned for production load
