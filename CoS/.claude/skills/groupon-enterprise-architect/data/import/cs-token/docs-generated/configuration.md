---
service: "cs-token"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

CS Token Service uses the `config` gem for YAML-based settings management. A per-environment YAML file is selected at runtime via the `CONFIG_FILE` environment variable (e.g., `production-us-central1`). Files are located at `config/settings/cloud/<CONFIG_FILE>.yml`. Secrets are injected as environment variables and interpolated into YAML via ERB. There is no Consul, Vault, or Helm-values integration visible in the codebase.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Rails environment mode | yes | `production` | env (Conveyor Cloud deployment config) |
| `CONFIG_FILE` | Selects the per-environment settings YAML file (e.g., `production-us-central1`) | yes | none | env (Conveyor Cloud deployment config) |
| `SECRET_KEY_BASE` | Rails signed-cookie secret key base | yes | none | env |
| `TOKEN_ENCRYPTION_CIPHER_SECRET` | AES-256-GCM encryption key for token strings | yes (when encryption enabled) | empty string in production | env |
| `TOKEN_ENCRYPTION_CIPHER_IV` | AES-256-GCM initialization vector | yes (when encryption enabled) | empty string in production | env |
| `CYCLOPS_X_API_KEY` | API key accepted from the Cyclops service for token creation | yes | empty string | env |
| `APPOPS_X_API_KEY` | API key accepted from the AppOps service for token creation | yes | empty string | env |
| `TLS_REDIS_PASSWORD` | TLS password for Redis connection (EMEA production) | conditional | empty string | env |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default (dev) | Default (production) |
|------|---------|---------------|---------------------|
| `feature_flags.token_encryption_enabled` | Enables AES-256-GCM encryption of token keys before Redis storage | `false` | `true` |
| `feature_flags.api_key_authentication_for_token_creation_enabled` | Requires `X-API-KEY` header on `POST /token` | `true` | `true` |
| `feature_flags.client_id_validation_for_tokenizer_enabled` | Requires `client_id` query param on `GET /verify_auth` | `true` | `false` |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/settings/development.yml` | YAML + ERB | Development defaults for Redis, encryption keys, feature flags, supported methods |
| `config/settings/test.yml` | YAML + ERB | Test environment settings |
| `config/settings/cloud/production-us-central1.yml` | YAML + ERB | Production NA (GCP us-central1) overrides |
| `config/settings/cloud/production-eu-west-1.yml` | YAML + ERB | Production EMEA (AWS eu-west-1) overrides |
| `config/settings/cloud/production-europe-west1.yml` | YAML + ERB | Production EMEA (GCP europe-west1) overrides |
| `config/settings/cloud/staging-us-central1.yml` | YAML + ERB | Staging NA (GCP us-central1) overrides |
| `config/settings/cloud/staging-us-west-1.yml` | YAML + ERB | Staging NA (AWS us-west-1) overrides |
| `config/settings/cloud/staging-us-west-2.yml` | YAML + ERB | Staging NA (AWS us-west-2) overrides |
| `config/settings/cloud/staging-europe-west1.yml` | YAML + ERB | Staging EMEA (GCP europe-west1) overrides |
| `config/docker/unicorn_rails.conf` | Ruby | Unicorn server configuration (workers, ports) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Conveyor Cloud base deployment config (replicas, ports, resources) |
| `.meta/deployment/cloud/components/app/<env>.yml` | YAML | Per-environment Conveyor Cloud overrides (VIP, replicas, resources) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `TOKEN_ENCRYPTION_CIPHER_SECRET` | AES-256-GCM token encryption key | env var (injected by Conveyor Cloud secrets management) |
| `TOKEN_ENCRYPTION_CIPHER_IV` | AES-256-GCM IV | env var |
| `SECRET_KEY_BASE` | Rails signed-cookie secret | env var |
| `CYCLOPS_X_API_KEY` | Cyclops API key for token creation auth | env var |
| `APPOPS_X_API_KEY` | AppOps API key for token creation auth | env var |
| `TLS_REDIS_PASSWORD` | Redis TLS password (EMEA) | env var |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Development | Staging | Production (US) | Production (EU) |
|---------|-------------|---------|-----------------|-----------------|
| `tokenizer_redis.host` | `localhost` | GCP Memorystore (stable) | GCP Memorystore (prod) | AWS ElastiCache / Redis |
| `tokenizer_redis.ssl` | `false` | `false` | `true` | `true` |
| `tokenizer_redis.test_enabled` | `true` | `true` | (not set / false) | `false` |
| `token_encryption_enabled` | `false` | `true` | `true` | `true` |
| `client_id_validation_for_tokenizer_enabled` | `true` | `false` | `false` | `false` |
| `supported_methods` | Subset (8 methods) | Full set (15+ methods) | Full set | Full set |
| `tokenizer_clients` | `a6d32e26aeb653a5-cyclops` | `cyclops`, `lazlo`, `appops` | `lazlo`, `appops` | `lazlo`, `appops` |

Supported token methods map logical action names to Lazlo API method strings. For example, `view_voucher` maps to `["getGrouponsIndex", "getGroupon", "updateGroupon", "grouponBarcodeImage"]`. Token expiration defaults to 5 minutes; select methods override this (e.g., `issue_refund` and `issue_bucks` use 15 minutes).
