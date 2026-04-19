---
service: "users-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Users Service is configured through environment variables and config files committed to the repository. Database and Redis connections, external service URLs, and credentials are provided via environment variables. Worker pool sizes and message bus topic subscriptions are configured in YAML files. Secrets (database passwords, OAuth credentials, encryption keys) are injected at runtime from a secrets store and never hardcoded.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for `continuumUsersDb` | yes | none | env / vault |
| `REDIS_URL` | Redis connection string for `continuumUsersRedis` | yes | none | env / vault |
| `IDENTITY_SERVICE_URL` | Base URL for `continuumUsersIdentityService` | yes | none | env |
| `IDENTITY_SERVICE_API_KEY` | API key for Identity Service requests | yes | none | vault |
| `ROCKETMAN_URL` | Base URL for `continuumUsersRocketman` OTP service | yes | none | env |
| `ROCKETMAN_API_KEY` | Credential for Rocketman OTP delivery | yes | none | vault |
| `MAILMAN_URL` | Base URL / SMTP config for `continuumUsersMailService` | yes | none | env |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID for token validation | yes | none | vault |
| `FACEBOOK_APP_ID` | Facebook app ID for Graph API token validation | yes | none | vault |
| `FACEBOOK_APP_SECRET` | Facebook app secret | yes | none | vault |
| `APPLE_CLIENT_ID` | Apple Sign In client identifier | yes | none | vault |
| `JWT_SECRET` | Signing secret for JWT session and continuation tokens | yes | none | vault |
| `ATTR_ENCRYPTED_KEY` | Encryption key for `attr_encrypted` sensitive fields | yes | none | vault |
| `ELASTIC_APM_SERVICE_NAME` | Service name reported to Elastic APM | no | `users-service` | env |
| `ELASTIC_APM_SERVER_URL` | Elastic APM server endpoint | no | none | env |
| `SONOMA_METRICS_HOST` | InfluxDB/Sonoma metrics endpoint | no | none | env |
| `RAILS_ENV` / `RACK_ENV` | Runtime environment (development, staging, production) | yes | `development` | env |
| `PUMA_WORKERS` | Number of Puma worker processes | no | `2` | env |
| `PUMA_THREADS` | Puma thread pool size | no | `5` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Identity Service integration flag | Enables delegation of account operations to `continuumUsersIdentityService` | disabled | per-environment |

> Feature flag mechanism uses Redis-backed Cache Client (`continuumUsersServiceApi_cacheClient`). Specific flag names are defined in service configuration and are not fully enumerable from the architecture inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/resque-pool.yml` | YAML | Defines Resque worker pool sizes and queue assignments for `continuumUsersResqueWorkers` |
| `config/messagebus.yml` | YAML | Defines GBus topic subscriptions for `continuumUsersMessageBusConsumer` |
| `config/database.yml` | YAML | ActiveRecord database connection configuration per environment |
| `config/puma.rb` | Ruby | Puma web server configuration (workers, threads, bind address) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_PASSWORD` | MySQL password for `continuumUsersDb` | vault |
| `REDIS_PASSWORD` | Redis authentication for `continuumUsersRedis` | vault |
| `JWT_SECRET` | JWT token signing key | vault |
| `ATTR_ENCRYPTED_KEY` | Attribute encryption key for sensitive model fields | vault |
| `IDENTITY_SERVICE_API_KEY` | Service credential for Identity Service | vault |
| `ROCKETMAN_API_KEY` | Credential for Rocketman OTP service | vault |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth credentials | vault |
| `FACEBOOK_APP_ID` / `FACEBOOK_APP_SECRET` | Facebook Graph API credentials | vault |
| `APPLE_CLIENT_ID` / `APPLE_PRIVATE_KEY` | Apple Sign In credentials | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local database and Redis instances; OAuth credentials may point to sandbox apps; Elastic APM and Sonoma metrics typically disabled
- **Staging**: Connected to staging instances of Identity Service and Rocketman; real OAuth app credentials with restricted scopes; metrics enabled pointing to staging InfluxDB
- **Production**: Full credentials and live OAuth apps; Elastic APM and Sonoma metrics fully enabled; Puma and Resque pool sizes tuned for production load
