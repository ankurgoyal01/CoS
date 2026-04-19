---
service: "voucher-inventory-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "feature-flags"]
---

# Configuration

## Overview

The Voucher Inventory Service is configured through a combination of environment variables, Rails configuration files, and runtime feature flags. The service exposes internal APIs for feature flag inspection (`/features`) and configuration reload (`/config/reload`) via the Features & Config API component (`continuumVoucherInventoryApi_featuresAndConfigApi`). Feature flags are evaluated via the Reading Rainbow experimentation service (`continuumReadingRainbow`).

## Environment Variables

> No evidence found in codebase. Specific environment variables are not defined in the architecture DSL. Expected standard Rails/JRuby environment variables include:

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Runtime environment (development, staging, production) | yes | development | env |
| `DATABASE_URL` | Primary database connection string (product DB) | yes | none | env / vault |
| `UNITS_DATABASE_URL` | Units database connection string | yes | none | env / vault |
| `REDIS_URL` | Redis connection URL for caching and Sidekiq | yes | none | env / vault |
| `ACTIVEMQ_BROKER_URL` | ActiveMQ/JMS broker connection URL | yes | none | env / vault |
| `EDW_S3_BUCKET` | S3 bucket for EDW export uploads | yes | none | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

The service integrates with Reading Rainbow (`continuumReadingRainbow`) for feature flag and experiment evaluation. Feature flags gate voucher flow behavior such as:

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Various voucher flow flags | Gate new redemption logic, experimental flows, and rollout of migrated features | Managed via Reading Rainbow | per-feature |

> Specific flag names are not defined in the architecture DSL. The Features & Config API (`/features` endpoint) provides runtime inspection of active flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | Database connection configuration for product DB and units DB |
| `config/application.rb` | ruby | Rails application configuration |
| `config/environments/*.rb` | ruby | Per-environment Rails settings |
| `config/sidekiq.yml` | yaml | Sidekiq worker queue configuration and concurrency |
| `config/initializers/` | ruby | Service client configurations, Redis setup, ActiveMessaging setup |

> File paths are inferred from standard Rails conventions. Actual paths may vary.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials | MySQL authentication for product and units databases | vault / env |
| Redis credentials | ElastiCache authentication | vault / env |
| ActiveMQ credentials | JMS broker authentication | vault / env |
| S3 credentials | AWS credentials for EDW export uploads | vault / env |
| Service auth tokens | Internal service-to-service authentication tokens | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. Standard Rails per-environment configuration is expected:
> - **Development**: Local database connections, single Sidekiq worker, reduced logging
> - **Staging**: AWS RDS and ElastiCache endpoints matching staging infrastructure, full worker concurrency
> - **Production**: Production AWS RDS and ElastiCache endpoints, production ActiveMQ brokers, full scaling, enhanced monitoring and alerting
