---
service: "backbeat"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Backbeat is a Ruby Rack/Sidekiq application. Configuration is delivered through environment variables (for connection credentials and runtime tunables) and config files (for Sidekiq queue definitions and application settings). The architecture DSL does not expose specific variable names — values below are inferred from the technology stack and component responsibilities.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumBackbeatPostgres` | yes | none | env |
| `REDIS_URL` | Redis connection URL for `continuumBackbeatRedis` (Sidekiq backend) | yes | none | env |
| `BACKBEAT_HOST` | Hostname/port the Rack API process binds to | yes | none | env |
| `SIDEKIQ_CONCURRENCY` | Number of Sidekiq worker threads | no | Sidekiq default | env |
| `METRICS_HOST` | InfluxDB/Sonoma endpoint for `bbMetricsReporter` | no | none | env |
| `SMTP_HOST` | SMTP relay host for `bbDailyActivityReporter` | no | none | env |
| `SMTP_PORT` | SMTP relay port | no | `25` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed. Confirm exact variable names against the service's environment configuration files.

## Feature Flags

> No evidence found of feature flags in the architecture inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/sidekiq.yml` | YAML | Sidekiq queue definitions, concurrency, and schedule configuration |
| `config/database.yml` | YAML | ActiveRecord database adapter and connection pool settings |
| `config/application.yml` / `config/backbeat.yml` | YAML | Application-level settings (inferred — confirm in source) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | PostgreSQL credentials for workflow state database | env / vault |
| `REDIS_URL` | Redis connection credentials | env / vault |
| `METRICS_API_KEY` | Authentication for Metrics Stack ingestion | env / vault |
| `SMTP_PASSWORD` | SMTP relay authentication | env / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> Operational procedures to be defined by service owner. Standard Continuum platform practice uses environment-specific values injected at deployment time via environment variables, with production secrets managed through a secrets store.
