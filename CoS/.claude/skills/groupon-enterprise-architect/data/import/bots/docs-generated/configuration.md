---
service: "bots"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, helm-values, vault]
---

# Configuration

## Overview

BOTS is configured through a combination of JTier-standard environment variables, Dropwizard YAML configuration files, and Kubernetes/Helm values injected at deployment time. Secrets (database credentials, external API tokens, OAuth client credentials) are managed via Vault or Kubernetes secrets and injected as environment variables at runtime. Configuration differs per environment (dev, staging, snc1, sac1, dub1).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | BOTS MySQL connection URL for `continuumBotsMysql` | yes | none | env / vault |
| `DATABASE_USER` | BOTS MySQL username | yes | none | vault |
| `DATABASE_PASSWORD` | BOTS MySQL password | yes | none | vault |
| `MESSAGEBUS_BROKER_URL` | Message Bus broker connection string | yes | none | env / helm |
| `GOOGLE_OAUTH_CLIENT_ID` | Google OAuth 2.0 client ID for merchant calendar integration | yes | none | vault |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Google OAuth 2.0 client secret | yes | none | vault |
| `SALESFORCE_API_URL` | Salesforce REST API base URL | yes | none | env / helm |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | yes | none | vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | yes | none | vault |
| `M3_MERCHANT_SERVICE_URL` | Base URL for `continuumM3MerchantService` | yes | none | env / helm |
| `DEAL_MANAGEMENT_URL` | Base URL for `continuumDealManagementService` | yes | none | env / helm |
| `DEAL_CATALOG_URL` | Base URL for `continuumDealCatalogService` | yes | none | env / helm |
| `CALENDAR_SERVICE_URL` | Base URL for `continuumCalendarService` | yes | none | env / helm |
| `VIS_URL` | Base URL for `continuumVoucherInventoryService` | yes | none | env / helm |
| `M3_PLACES_URL` | Base URL for `continuumM3PlacesService` | yes | none | env / helm |
| `CYCLOPS_URL` | Base URL for `cyclops` customer profile service | yes | none | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

> No feature flags were explicitly identified in the repository inventory. Feature-flag events are consumed from the Message Bus by `botsWorkerMbusConsumersComponent`, suggesting runtime flag updates via event-driven configuration.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Dropwizard application configuration (server, logging, database pool, retry settings) |
| `config-${ENV}.yml` | YAML | Per-environment overrides for server port, database pool sizes, and service URLs |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `bots/database/password` | BOTS MySQL database password | vault |
| `bots/google-oauth/client-secret` | Google OAuth 2.0 client secret for calendar integration | vault |
| `bots/salesforce/client-secret` | Salesforce API OAuth client secret | vault |

> Secret values are NEVER documented. Only names and rotation policies are listed.

## Per-Environment Overrides

- **dev / staging**: Reduced database connection pool sizes, mock or sandbox endpoints for Google Calendar and Salesforce, relaxed timeouts for local development
- **snc1 / sac1 (US production)**: Full connection pools, production Google Calendar and Salesforce credentials, production Message Bus brokers
- **dub1 (EU production)**: Same as US production configuration with EU-region database endpoints and Message Bus brokers to satisfy data residency requirements; GDPR erasure processing is active
