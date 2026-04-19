---
service: "bookingtool"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, aws-secrets-manager]
---

# Configuration

## Overview

The Booking Tool is configured through environment variables injected at runtime in Kubernetes, supplemented by PHP configuration files for locale-specific and application-level settings. Secrets (database credentials, API keys, JWT signing keys) are managed through AWS Secrets Manager and injected as environment variables. Capistrano deployment scripts may carry environment-specific overrides per deployment stage.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | MySQL host for primary database connection | yes | — | env / helm |
| `DB_PORT` | MySQL port | yes | 3306 | env / helm |
| `DB_NAME` | MySQL database name | yes | — | env / helm |
| `DB_USER` | MySQL username | yes | — | aws-secrets-manager |
| `DB_PASSWORD` | MySQL password | yes | — | aws-secrets-manager |
| `REDIS_HOST` | Redis host for session and cache | yes | — | env / helm |
| `REDIS_PORT` | Redis port | yes | 6379 | env / helm |
| `SALESFORCE_BASE_URL` | Salesforce REST API base URL | yes | — | env / helm |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | yes | — | aws-secrets-manager |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | yes | — | aws-secrets-manager |
| `ZENDESK_SUBDOMAIN` | Zendesk subdomain for API calls | yes | — | env / helm |
| `ZENDESK_API_TOKEN` | Zendesk API authentication token | yes | — | aws-secrets-manager |
| `ROCKETMAN_BASE_URL` | Rocketman V2 email service base URL | yes | — | env / helm |
| `JWT_SECRET_KEY` | Secret key for JWT signing/verification | yes | — | aws-secrets-manager |
| `INFLUXDB_HOST` | InfluxDB metrics host | no | — | env / helm |
| `INFLUXDB_DATABASE` | InfluxDB database name for metrics | no | — | env / helm |
| `OKTA_CLIENT_ID` | Okta OAuth client ID for admin auth | yes | — | aws-secrets-manager |
| `OKTA_CLIENT_SECRET` | Okta OAuth client secret | yes | — | aws-secrets-manager |
| `OKTA_ISSUER` | Okta issuer URL | yes | — | env / helm |
| `AWS_REGION` | AWS region for SDK calls | yes | eu-west-1 | env / helm |
| `APP_ENV` | Application environment (dev/staging/prod) | yes | — | env / helm |
| `APP_LOCALE` | Default application locale | yes | — | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here.

## Feature Flags

> No evidence found of a feature flag system in the service inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `composer.json` | JSON | PHP dependency manifest; defines all library versions |
| `Capfile` / `config/deploy.rb` | Ruby/DSL | Capistrano deployment configuration and stage definitions |
| `config/deploy/<env>.rb` | Ruby | Per-environment Capistrano overrides (servers, branch, settings) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_USER` / `DB_PASSWORD` | MySQL database credentials | aws-secrets-manager |
| `SALESFORCE_CLIENT_ID` / `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth credentials | aws-secrets-manager |
| `ZENDESK_API_TOKEN` | Zendesk API access token | aws-secrets-manager |
| `JWT_SECRET_KEY` | JWT signing key for service-to-service auth | aws-secrets-manager |
| `OKTA_CLIENT_ID` / `OKTA_CLIENT_SECRET` | Okta admin authentication credentials | aws-secrets-manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local environment variables; may use local MySQL and Redis instances; Salesforce sandbox endpoint
- **Staging**: Kubernetes-injected environment variables pointing to staging MySQL, staging Salesforce sandbox, staging Rocketman; reduced replica count
- **Production**: Kubernetes-injected environment variables in `eu-west-1`; full replica set; production Salesforce, Zendesk, and Rocketman endpoints; AWS Secrets Manager as the secrets source
- **Locale-specific**: `APP_LOCALE` drives locale-specific business rules (bank holidays, date formats, locale-specific deal catalog queries) across UK, US, AU, FR, DE, ES, NL, IT, PL, BE, IE, and AE
