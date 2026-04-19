---
service: "merchant-preview"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

Merchant Preview is a Ruby on Rails application. Configuration is expected to follow standard Rails conventions using environment variables for secrets and integration endpoints. No external config store (Consul, Vault, Helm values) is referenced in the architecture model.

## Environment Variables

> No evidence found in codebase for specific environment variable names. The following are inferred from the integration landscape documented in the architecture model.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for `continuumMerchantPreviewDatabase` | yes | none | env |
| `SALESFORCE_USERNAME` | Salesforce API username for databasedotcom client | yes | none | env |
| `SALESFORCE_PASSWORD` | Salesforce API password for databasedotcom client | yes | none | env |
| `SALESFORCE_SECURITY_TOKEN` | Salesforce security token for databasedotcom client | yes | none | env |
| `SMTP_HOST` | SMTP relay hostname for ActionMailer delivery | yes | none | env |
| `SMTP_PORT` | SMTP relay port | yes | none | env |
| `SMTP_USERNAME` | SMTP relay authentication username | no | none | env |
| `SMTP_PASSWORD` | SMTP relay authentication password | no | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for the Deal Catalog Service HTTP client | yes | none | env |
| `RAILS_ENV` | Rails environment (development/staging/production) | yes | development | env |
| `SECRET_KEY_BASE` | Rails session/cookie signing secret | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase for feature flag system or specific flags.

## Config Files

> No evidence found in codebase for specific named configuration files beyond standard Rails conventions.

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | Rails database connection configuration |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings |
| `config/initializers/` | Ruby | Library and integration initializers |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SALESFORCE_PASSWORD` | Salesforce API authentication | env |
| `SALESFORCE_SECURITY_TOKEN` | Salesforce API authentication | env |
| `SECRET_KEY_BASE` | Rails session signing | env |
| `SMTP_PASSWORD` | SMTP relay authentication | env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase for specific per-environment configuration differences. Standard Rails environment conventions apply: `RAILS_ENV=development`, `RAILS_ENV=staging`, `RAILS_ENV=production`.
