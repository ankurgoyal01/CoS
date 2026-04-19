---
service: "bynder-integration-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The bynder-integration-service follows the JTier/Dropwizard configuration pattern. Application configuration is provided through a YAML config file (`config.yml`) with environment-specific values injected via environment variables at runtime. Secrets such as Bynder OAuth credentials, database passwords, and service API keys are never stored in the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `BYNDER_PORTAL_URL` | Base URL of the Bynder portal for SDK initialization | yes | none | env |
| `BYNDER_OAUTH_CLIENT_ID` | OAuth client ID for Bynder API authentication | yes | none | env |
| `BYNDER_OAUTH_CLIENT_SECRET` | OAuth client secret for Bynder API authentication | yes | none | env |
| `DATABASE_URL` | MySQL connection string for `continuumBynderIntegrationMySql` | yes | none | env |
| `DATABASE_USER` | MySQL database username | yes | none | env |
| `DATABASE_PASSWORD` | MySQL database password | yes | none | env |
| `IMAGE_SERVICE_URL` | Base URL of the Continuum Image Service | yes | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL of the Deal Catalog Service | yes | none | env |
| `TAXONOMY_SERVICE_URL` | Base URL of the Taxonomy Service | yes | none | env |
| `KEYWORDS_MODEL_API_URL` | Base URL of the Keywords Model API | yes | none | env |
| `MESSAGE_BUS_URL` | Message bus connection URL | yes | none | env |
| `MESSAGE_BUS_USERNAME` | Message bus authentication username | yes | none | env |
| `MESSAGE_BUS_PASSWORD` | Message bus authentication password | yes | none | env |
| `SERVICE_ENV` | Deployment environment (development, staging, production) | yes | development | env |
| `PORT` | HTTP port for the Dropwizard application | no | 8080 | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Main Dropwizard application configuration (server, database, logging, message bus, external service URLs) |
| `pom.xml` | xml | Maven build configuration and dependency management |
| Quartz job config (within `config.yml` or separate) | yaml | Cron expressions for scheduled image pull and taxonomy sync jobs |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `BYNDER_OAUTH_CLIENT_SECRET` | Bynder OAuth client secret for API access | No evidence found in codebase. |
| `DATABASE_PASSWORD` | MySQL database password | No evidence found in codebase. |
| `MESSAGE_BUS_PASSWORD` | Message bus authentication password | No evidence found in codebase. |
| `SERVICE_API_CREDENTIALS` | Credentials for downstream service-to-service calls | No evidence found in codebase. |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The service uses Dropwizard's standard YAML config file with environment variable substitution. Quartz cron expressions for scheduled jobs differ between environments (e.g., higher frequency in production). The `SERVICE_ENV` variable controls environment-specific behavior. Database connection pool sizes and message bus topic names may differ between staging and production.
