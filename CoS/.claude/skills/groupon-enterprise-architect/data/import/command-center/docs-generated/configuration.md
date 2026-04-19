---
service: "command-center"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Command Center follows standard Ruby on Rails configuration conventions. Environment-specific settings are managed via environment variables and Rails config files. Database connection parameters, downstream API base URLs, message bus credentials, Salesforce credentials, and object storage credentials are expected to be provided as environment variables, consistent with Continuum platform conventions. Specific variable names are not enumerated in the architecture DSL; the following are inferred from the integration model.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for `continuumCommandCenterMysql` | Yes | None | env |
| `RAILS_ENV` | Rails environment selector (development, staging, production) | Yes | development | env |
| `SECRET_KEY_BASE` | Rails session and cookie encryption key | Yes | None | env / vault |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for `continuumDealCatalogService` HTTP calls | Yes | None | env |
| `DEAL_MANAGEMENT_API_URL` | Base URL for `continuumDealManagementApi` HTTP calls | Yes | None | env |
| `VOUCHER_INVENTORY_SERVICE_URL` | Base URL for `continuumVoucherInventoryService` HTTP calls | Yes | None | env |
| `ORDERS_SERVICE_URL` | Base URL for `continuumOrdersService` HTTP calls | Yes | None | env |
| `M3_PLACES_SERVICE_URL` | Base URL for `continuumM3PlacesService` HTTP calls | Yes | None | env |
| `SALESFORCE_API_URL` | Salesforce REST API base URL | Yes | None | env |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | Yes | None | env / vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | Yes | None | env / vault |
| `MESSAGE_BUS_URL` | Internal MBus connection endpoint | Yes | None | env |
| `S3_BUCKET` | Object storage bucket name for CSV/job artifacts | Yes | None | env |
| `S3_REGION` | Object storage region | Yes | None | env |
| `SMTP_ADDRESS` | SMTP server address for ActionMailer | Yes | None | env |
| `DELAYED_JOB_WORKERS` | Number of Delayed Job worker processes to spawn | No | 1 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

> Specific variable names are inferred from the integration model in `architecture/models/relations.dsl`. Actual variable names are defined in the command-center application repository.

## Feature Flags

> No evidence found. Feature flag configuration is not enumerated in the architecture inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML | Rails database connection configuration (reads `DATABASE_URL`) |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings |
| `config/environments/staging.rb` | Ruby | Staging-specific Rails settings |
| `config/initializers/` | Ruby | Service client initializers, Delayed Job configuration |

> File paths follow standard Ruby on Rails conventions. Actual files are in the command-center application repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SECRET_KEY_BASE` | Rails session encryption | vault / env |
| `SALESFORCE_CLIENT_SECRET` | Salesforce API authentication | vault / env |
| `DATABASE_PASSWORD` | MySQL authentication | vault / env |
| `MESSAGE_BUS_CREDENTIALS` | Internal MBus authentication | vault / env |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | S3 object storage access | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Command Center follows standard Continuum platform environment promotion: development, staging, and production. Downstream API base URLs, database connection strings, message bus endpoints, and S3 bucket names differ per environment. Rails environment-specific config files (`config/environments/*.rb`) control logging verbosity, caching behavior, and email delivery settings per environment.
