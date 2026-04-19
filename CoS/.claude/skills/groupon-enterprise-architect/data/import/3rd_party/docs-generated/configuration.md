---
service: "online_booking_3rd_party"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

`online_booking_3rd_party` is configured primarily through environment variables following the Rails 12-factor convention. Database connections, external service URLs, provider API credentials, and message bus configuration are all supplied via environment. Rails environment-specific config files (`config/environments/`) provide framework-level overrides.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for primary datastore | yes | none | env |
| `REDIS_URL` | Redis connection string for Resque queues | yes | none | env |
| `MEMCACHE_SERVERS` | Memcached server addresses for Dalli cache | yes | none | env |
| `MESSAGE_BUS_URL` | STOMP broker URL for JMS messaging | yes | none | env |
| `MESSAGE_BUS_USERNAME` | Message Bus authentication username | yes | none | env |
| `MESSAGE_BUS_PASSWORD` | Message Bus authentication password | yes | none | env |
| `APPOINTMENTS_ENGINE_URL` | Base URL for Appointment Engine API | yes | none | env |
| `AVAILABILITY_ENGINE_URL` | Base URL for Availability Engine API | yes | none | env |
| `USERS_SERVICE_URL` | Base URL for Users Service API | yes | none | env |
| `DEAL_CATALOG_URL` | Base URL for Deal Catalog API | yes | none | env |
| `DEAL_MANAGEMENT_API_URL` | Base URL for Deal Management API | yes | none | env |
| `CALENDAR_SERVICE_URL` | Base URL for Calendar Service API | yes | none | env |
| `VOUCHER_INVENTORY_URL` | Base URL for Voucher Inventory API | yes | none | env |
| `ORDERS_SERVICE_URL` | Base URL for Orders Service API | yes | none | env |
| `RAILS_ENV` | Rails environment (production, staging, development) | yes | development | env |
| `SECRET_KEY_BASE` | Rails secret key for session/cookie signing | yes | none | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found — no feature flag system identified in inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | ActiveRecord MySQL connection configuration per environment |
| `config/resque.yml` | yaml | Resque queue and Redis connection configuration |
| `config/initializers/dalli.rb` | ruby | Memcached/Dalli cache store initialization |
| `config/environments/production.rb` | ruby | Production-specific Rails framework settings |
| `config/environments/staging.rb` | ruby | Staging-specific Rails framework settings |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | MySQL credentials embedded in connection string | env |
| `MESSAGE_BUS_PASSWORD` | Message Bus broker authentication | env |
| `SECRET_KEY_BASE` | Rails cookie/session signing key | env |
| Provider API tokens | Per-provider OAuth/API keys for external scheduling systems | mysql (access_tokens table) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses local MySQL, Redis, and Memcached; message bus typically stubbed or pointed at dev broker
- **Staging**: Full integration with staging instances of all internal Continuum services; provider API credentials point to sandbox/test accounts
- **Production**: Full integration with production services; provider API credentials are live and managed per-provider
