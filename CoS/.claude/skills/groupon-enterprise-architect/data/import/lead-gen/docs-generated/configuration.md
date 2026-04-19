---
service: "lead-gen"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, vault, n8n-credentials]
---

# Configuration

## Overview

LeadGen Service is configured via environment variables for service-level settings and external provider connectivity. Secrets (API keys, OAuth credentials) are stored in a secrets manager (Vault or Kubernetes secrets). The n8n workflow engine maintains its own credential store for workflow-level integrations. Feature flags control pipeline behavior such as enrichment sources and outreach provider selection.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | JDBC connection string for leadGenDb (PostgreSQL) | yes | none | env |
| `APIFY_API_URL` | Base URL for Apify Cloud API | yes | none | env |
| `APIFY_API_TOKEN` | API token for Apify authentication | yes | none | vault |
| `INFER_PDS_URL` | Base URL for inferPDS enrichment service | yes | none | env |
| `MERCHANT_QUALITY_URL` | Base URL for merchantQuality scoring service | yes | none | env |
| `MAILGUN_API_URL` | Mailgun API base URL | yes | none | env |
| `MAILGUN_API_KEY` | Mailgun API key for email sending | yes | none | vault |
| `MAILGUN_DOMAIN` | Mailgun sender domain | yes | none | env |
| `SALESFORCE_INSTANCE_URL` | Salesforce REST API instance URL | yes | none | env |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | yes | none | vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | yes | none | vault |
| `SALESFORCE_USERNAME` | Salesforce integration user | yes | none | vault |
| `SALESFORCE_PASSWORD` | Salesforce integration user password | yes | none | vault |
| `N8N_BASE_URL` | n8n workflow engine base URL | yes | none | env |
| `N8N_WEBHOOK_SECRET` | Shared secret for n8n webhook callbacks | yes | none | vault |
| `SERVICE_AUTH_TOKEN` | Token for service-to-service authentication on internal endpoints | yes | none | vault |
| `LOG_LEVEL` | Application log level | no | INFO | env |
| `SCRAPE_BATCH_SIZE` | Number of leads per Apify scraping batch | no | 100 | env |
| `ENRICHMENT_CONCURRENCY` | Max concurrent enrichment requests | no | 10 | env |
| `OUTREACH_DAILY_LIMIT` | Maximum outreach emails per day | no | 500 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `ENABLE_PDS_ENRICHMENT` | Enable/disable PDS inference enrichment step | true | global |
| `ENABLE_QUALITY_ENRICHMENT` | Enable/disable merchant quality score enrichment step | true | global |
| `ENABLE_OUTREACH` | Master switch for email outreach campaigns | true | global |
| `ENABLE_CRM_SYNC` | Master switch for Salesforce sync | true | global |
| `ENABLE_INBOX_WARMUP` | Enable inbox warmup sequences before production outreach | true | global |
| `OUTREACH_PROVIDER` | Select outreach provider (mailgun or bird) | mailgun | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `application.yml` | yaml | Spring Boot application configuration (server, datasource, logging) |
| `application-{profile}.yml` | yaml | Profile-specific overrides (dev, staging, production) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `apify-api-token` | Apify Cloud API authentication | vault |
| `mailgun-api-key` | Mailgun email sending authentication | vault |
| `salesforce-oauth-credentials` | Salesforce OAuth client credentials and user credentials | vault |
| `n8n-webhook-secret` | Shared secret for securing n8n webhook callbacks | vault |
| `service-auth-token` | Internal service-to-service authentication token | vault |
| `database-credentials` | PostgreSQL connection credentials for leadGenDb | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **dev**: Points to local or dev instances of Apify, PDS, quality scoring. Outreach disabled by default (`ENABLE_OUTREACH=false`). CRM sync targets a Salesforce sandbox
- **staging**: Full pipeline enabled with staging instances of all external providers. Outreach uses a test Mailgun domain. Salesforce sandbox is used
- **production**: Full pipeline enabled with production credentials for all external providers. Outreach daily limit enforced. Salesforce production instance used. Inbox warmup enabled before new sender domains go live
