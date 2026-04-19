---
service: "s2s"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

S2S is a Dropwizard/JTier service. Configuration is delivered through JTier's standard mechanism — YAML config files with environment-specific overrides, supplemented by environment variables for secrets and environment-specific endpoints. Kafka consumer topics, partner API credentials, database connection strings, and Quartz job schedules are the primary configurable dimensions.

> Deployment configuration is managed externally (JTier deployment system). Refer to the SEM/Display Engineering team for environment-specific config files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `FACEBOOK_API_ACCESS_TOKEN` | Access token for Facebook CAPI submissions | yes | none | env / secret store |
| `GOOGLE_ADS_CLIENT_ID` | OAuth2 client ID for Google Ads API | yes | none | env / secret store |
| `GOOGLE_ADS_CLIENT_SECRET` | OAuth2 client secret for Google Ads API | yes | none | env / secret store |
| `GOOGLE_ADS_REFRESH_TOKEN` | OAuth2 refresh token for Google Ads API | yes | none | env / secret store |
| `GOOGLE_ADS_DEVELOPER_TOKEN` | Developer token for Google Ads API | yes | none | env / secret store |
| `TIKTOK_ACCESS_TOKEN` | Access token for TikTok Ads API | yes | none | env / secret store |
| `REDDIT_CLIENT_ID` | Client ID for Reddit Ads API | yes | none | env / secret store |
| `REDDIT_CLIENT_SECRET` | Client secret for Reddit Ads API | yes | none | env / secret store |
| `DATABREAKER_API_URL` | Base URL for DataBreaker SaaS API | yes | none | env |
| `DATABREAKER_API_TOKEN` | API token for DataBreaker (obtained at runtime) | yes | none | env / secret store |
| `POSTGRES_URL` | JDBC URL for S2S operational Postgres (`continuumS2sPostgres`) | yes | none | env |
| `POSTGRES_USER` | Username for S2S Postgres | yes | none | env / secret store |
| `POSTGRES_PASSWORD` | Password for S2S Postgres | yes | none | env / secret store |
| `TERADATA_JDBC_URL` | JDBC URL for Teradata EDW (`continuumS2sTeradata`) | yes | none | env |
| `TERADATA_USER` | Username for Teradata EDW | yes | none | env / secret store |
| `TERADATA_PASSWORD` | Password for Teradata EDW | yes | none | env / secret store |
| `CEREBRO_DB_URL` | JDBC URL for Cerebro reference DB (`continuumS2sCerebroDb`) | yes | none | env |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker addresses for `continuumS2sKafka` | yes | none | env |
| `KAFKA_CONSUMER_GROUP` | Kafka consumer group ID for S2S consumers | yes | none | env |
| `MBUS_CONNECTION_URL` | MBus broker connection URL for `continuumS2sMBus` | yes | none | env |
| `CONSENT_SERVICE_URL` | Base URL for Consent Service (`continuumConsentService`) | yes | none | env |
| `MDS_SERVICE_URL` | Base URL for Merchant Data Service (`continuumMdsService`) | yes | none | env |
| `PRICING_API_URL` | Base URL for Pricing API (`continuumPricingApi`) | yes | none | env |
| `ORDERS_SERVICE_URL` | Base URL for Orders Service (`continuumOrdersService`) | yes | none | env |
| `SMTP_HOST` | SMTP host for email notifications | yes | none | env |
| `SMTP_USER` | SMTP username | yes | none | env / secret store |
| `SMTP_PASSWORD` | SMTP password | yes | none | env / secret store |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

> No evidence found of a feature flag system in the architecture model. Runtime log level adjustments are available via the `/logs` endpoint.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Dropwizard/JTier main application configuration: server settings, database pools, Kafka consumer configuration, Quartz job schedules |
| `config-{env}.yml` | YAML | Per-environment overrides for endpoints, credentials references, and feature toggles |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Facebook API access token | Authenticate S2S with Facebook CAPI | env / secret store |
| Google Ads OAuth2 credentials | Authenticate S2S with Google Ads API | env / secret store |
| TikTok access token | Authenticate S2S with TikTok Ads API | env / secret store |
| Reddit client credentials | Authenticate S2S with Reddit Ads API | env / secret store |
| DataBreaker API token | Authenticate S2S with DataBreaker SaaS | env / secret store |
| Postgres credentials | Authenticate S2S with operational Postgres | env / secret store |
| Teradata credentials | Authenticate S2S with Teradata EDW | env / secret store |
| SMTP credentials | Authenticate S2S SMTP email sending | env / secret store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development / staging**: Partner API endpoints pointed to sandbox/test environments; Kafka topics use non-production prefixes; Teradata queries scoped to smaller datasets.
- **Production**: Live partner API endpoints; full Janus Tier2/Tier3 Kafka topics; production Teradata EDW.
- JTier deployment system manages environment-specific config file selection at startup.
