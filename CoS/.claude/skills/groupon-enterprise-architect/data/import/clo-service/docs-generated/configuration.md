---
service: "clo-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

CLO Service is configured primarily through environment variables injected at runtime. Secrets (card network credentials, Salesforce OAuth tokens, database passwords) are managed outside the codebase and injected as environment variables. Rails environment-specific config files (`config/environments/`) provide per-environment application settings. Sidekiq scheduler configuration defines recurring job schedules. The `ar-octopus` shard configuration maps database connections.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for primary CLO database | yes | none | env |
| `REDIS_URL` | Redis connection URL for Sidekiq queues, locks, and cache | yes | none | env |
| `RAILS_ENV` | Rails environment (production, staging, development) | yes | development | env |
| `SECRET_KEY_BASE` | Rails secret key for session and cookie signing | yes | none | env / vault |
| `VISA_API_KEY` | Visa CLO API authentication credential | yes | none | vault |
| `VISA_API_SECRET` | Visa CLO API secret | yes | none | vault |
| `MASTERCARD_API_KEY` | Mastercard CLO API authentication credential | yes | none | vault |
| `MASTERCARD_API_SECRET` | Mastercard CLO API secret | yes | none | vault |
| `AMEX_API_CREDENTIALS` | Amex SOAP/REST API credentials | yes | none | vault |
| `REWARDS_NETWORK_API_KEY` | Rewards Network REST API key | yes | none | vault |
| `SALESFORCE_CLIENT_ID` | Salesforce connected app client id for Restforce OAuth2 | yes | none | vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce connected app client secret | yes | none | vault |
| `SALESFORCE_USERNAME` | Salesforce API username | yes | none | vault |
| `SALESFORCE_PASSWORD` | Salesforce API password + security token | yes | none | vault |
| `MESSAGE_BUS_URL` | Message Bus broker connection URL | yes | none | env / vault |
| `PUMA_WORKERS` | Number of Puma worker processes | no | 2 | env |
| `SIDEKIQ_CONCURRENCY` | Number of Sidekiq threads per worker process | no | 5 | env |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in the architecture inventory for named feature flags or a feature flag management system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML | ActiveRecord database connection configuration per environment |
| `config/redis.yml` | YAML | Redis connection configuration (redis-rails) |
| `config/sidekiq.yml` | YAML | Sidekiq queue definitions and concurrency settings |
| `config/schedule.yml` | YAML | sidekiq-scheduler recurring job definitions |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings |
| `config/environments/staging.rb` | Ruby | Staging-specific Rails settings |
| `config/initializers/message_bus.rb` | Ruby | Message Bus client initialization and topic subscription setup |
| `config/shards.yml` | YAML | ar-octopus database shard configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `VISA_API_KEY` / `VISA_API_SECRET` | Visa CLO API authentication | vault |
| `MASTERCARD_API_KEY` / `MASTERCARD_API_SECRET` | Mastercard CLO API authentication | vault |
| `AMEX_API_CREDENTIALS` | Amex network API credentials | vault |
| `REWARDS_NETWORK_API_KEY` | Rewards Network API authentication | vault |
| `SALESFORCE_CLIENT_ID` / `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth2 connected app credentials | vault |
| `DATABASE_URL` | PostgreSQL connection string with credentials | vault |
| `SECRET_KEY_BASE` | Rails session signing secret | vault |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **Production**: Full card network integrations active; Puma and Sidekiq concurrency tuned for production load; Salesforce production org; all Message Bus topics live
- **Staging**: Card network integrations may use sandbox/test endpoints; reduced concurrency; Salesforce sandbox org; Message Bus topics may be prefixed or isolated
- **Development**: Card network integrations stubbed or disabled; local PostgreSQL and Redis; Message Bus may be mocked
