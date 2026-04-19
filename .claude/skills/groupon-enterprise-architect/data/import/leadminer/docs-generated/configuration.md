---
service: "leadminer"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Leadminer uses standard Rails configuration conventions. Service URLs and credentials for downstream M3 services are expected to be provided via environment variables or Rails config files. The `sonoma-metrics` and `sonoma-logger` libraries are configured through Sonoma platform conventions. Specific variable names are not discoverable from the inventory alone — names below reflect the integration landscape.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Sets the Rails execution environment (development, staging, production) | yes | `development` | env |
| `SECRET_KEY_BASE` | Rails session cookie signing key | yes | none | env / vault |
| `M3_CLIENT_BASE_URL` | Base URL for m3_client service API calls | yes | none | env |
| `M3_CLIENT_API_KEY` | Authentication credential for M3 service API | yes | none | env / vault |
| `CONTROL_ROOM_URL` | Base URL for Control Room authentication service | yes | none | env |
| `SALESFORCE_API_URL` | Base URL for Salesforce REST API integration | no | none | env |
| `SALESFORCE_API_TOKEN` | Authentication token for Salesforce API | no | none | vault |
| `GEO_DETAILS_SERVICE_URL` | Base URL for GeoDetails service | yes | none | env |
| `TAXONOMY_SERVICE_URL` | Base URL for Taxonomy service | yes | none | env |
| `SONOMA_METRICS_HOST` | Host endpoint for Sonoma metrics reporting | no | none | env |
| `SONOMA_LOG_LEVEL` | Log verbosity level for sonoma-logger | no | `info` | env |
| `DATABASE_URL` | Not applicable — service has no local DB | no | none | — |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/application.rb` | Ruby | Rails application configuration and middleware setup |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings |
| `config/environments/staging.rb` | Ruby | Staging-specific Rails settings |
| `config/environments/development.rb` | Ruby | Development-specific Rails settings |
| `config/initializers/` | Ruby | Per-library initialization (metrics, logger, m3_client setup) |
| `Gemfile` | Ruby DSL | Dependency manifest |
| `Gemfile.lock` | Text | Locked dependency versions (Bundler 1.17.2) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SECRET_KEY_BASE` | Rails session signing key | vault / env |
| `M3_CLIENT_API_KEY` | API authentication for M3 backend services | vault |
| `SALESFORCE_API_TOKEN` | Salesforce REST API authentication | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local service URLs; relaxed authentication; debug logging enabled
- **Staging**: Points to staging instances of all M3 backend services and Control Room; mirrors production config minus live credentials
- **Production**: Full credentials; production M3 service URLs; metrics and structured logging fully enabled via `sonoma-metrics` and `sonoma-logger`
