---
service: "gazebo"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Gazebo is configured primarily through environment variables injected at runtime. Rails-standard configuration files (`config/database.yml`, `config/redis.yml`, etc.) are used for local and CI environments, with production values supplied via environment variables. Feature flags are managed at runtime through the Flipper gem backed by Redis, accessible via the `/flipper` admin UI. Sensitive credentials (database passwords, Salesforce OAuth keys, New Relic license key) are provided as environment variables and must never be committed to source control.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Sets the Rails application environment | yes | `development` | env |
| `RAILS_LOG_TO_STDOUT` | Directs Rails logs to stdout for container log aggregation | no | unset | env |
| `UNICORN_WORKERS` | Number of Unicorn worker processes to spawn | yes | none | env |
| `UNICORN_PID` | Path to the Unicorn PID file | no | default Unicorn path | env |
| `DATABASE_URL` | MySQL connection URL (or individual host/port/name/user/password vars) | yes | none | env |
| `REDIS_URL` | Redis connection URL for session and cache store | yes | none | env |
| `SALESFORCE_CLIENT_ID` | OAuth client ID for Salesforce API access | yes | none | env |
| `SALESFORCE_CLIENT_SECRET` | OAuth client secret for Salesforce API access | yes | none | env |
| `MESSAGEBUS_*` | Message Bus connection configuration (host, credentials, topic prefixes) | yes | none | env |
| `NEWRELIC_LICENSE_KEY` | New Relic APM license key | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Managed via Flipper UI at `/flipper` | Progressive rollout and A/B testing of editorial features | Feature-dependent | global / per-actor |

Flags are stored in MySQL (`feature_flags` table) and cached in Redis. The Flipper admin UI at `/flipper` allows authorized users to enable, disable, or partially roll out features without a deployment.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | MySQL connection configuration per Rails environment |
| `config/redis.yml` | yaml | Redis connection configuration per Rails environment |
| `config/unicorn.rb` | ruby | Unicorn HTTP server tuning (workers, timeouts, PID path) |
| `config/application.rb` | ruby | Rails application-level configuration |
| `config/environments/production.rb` | ruby | Production-specific Rails overrides |
| `Gemfile` | ruby | Ruby dependency manifest |
| `package.json` | json | Node.js/npm dependency manifest for frontend build |
| `Gulpfile.js` | javascript | Gulp frontend build task definitions |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth application client ID | env / k8s-secret |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth application client secret | env / k8s-secret |
| `DATABASE_URL` (or password component) | MySQL authentication credential | env / k8s-secret |
| `NEWRELIC_LICENSE_KEY` | New Relic APM authentication | env / k8s-secret |
| `MESSAGEBUS_*` credentials | Message Bus authentication | env / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **development**: Local database and Redis connections; Salesforce sandbox credentials; Message Bus pointed at dev broker; feature flags default off; `RAILS_ENV=development`
- **staging**: Staging MySQL and Redis instances; Salesforce sandbox or staging org; staging Message Bus broker; mirrors production configuration for pre-production validation; `RAILS_ENV=staging`
- **production**: Production MySQL cluster; production Redis; production Salesforce org; production Message Bus; New Relic APM active; `RAILS_ENV=production`, `RAILS_LOG_TO_STDOUT=true`
