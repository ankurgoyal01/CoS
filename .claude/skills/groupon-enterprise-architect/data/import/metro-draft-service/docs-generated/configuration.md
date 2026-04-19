---
service: "metro-draft-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Metro Draft Service follows JTier/Dropwizard configuration conventions. Primary configuration is supplied via YAML config files (standard Dropwizard pattern) with environment-specific overrides injected as environment variables at deployment time. Database connections, service URLs, message bus settings, and secrets (Salesforce credentials, Slack webhook, API keys) are externalized from the codebase. No evidence of Consul or Vault integration is present in the architecture model; confirm secret management approach with the Metro Team.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` / JTier DB config | Primary PostgreSQL (`continuumMetroDraftDb`) connection string | yes | none | env / JTier config |
| `MCM_DATABASE_URL` | MCM PostgreSQL (`continuumMetroDraftMcmPostgres`) connection string | yes | none | env / JTier config |
| `COVID_DATABASE_URL` | Covid Safety Program PostgreSQL (`continuumCovidSafetyProgramPostgres`) connection string | yes | none | env / JTier config |
| `REDIS_URL` | Redis (`continuumMetroDraftRedis`) connection string | yes | none | env / JTier config |
| `MBUS_*` | MBus (`continuumMetroDraftMessageBus`) broker and topic configuration | yes | none | env / JTier config |
| `SALESFORCE_*` | Salesforce API credentials (endpoint, username, password/token) | yes | none | env / secrets |
| `ELASTICSEARCH_URL` | ElasticSearch endpoint for search indexing and queries | yes | none | env |
| `SLACK_WEBHOOK_URL` | Slack webhook URL for operational notifications | no | none | env / secrets |
| `DMAPI_URL` | Deal Management Service (DMAPI) base URL | yes | none | env / JTier config |
| `MDS_URL` | Marketing Deal Service base URL | yes | none | env / JTier config |
| `DEAL_CATALOG_URL` | Deal Catalog Service base URL | yes | none | env / JTier config |
| `RBAC_URL` | RBAC Service base URL | yes | none | env / JTier config |
| `INFER_PDS_URL` | Infer PDS Service base URL | yes | none | env / JTier config |
| `GENAI_URL` | GenAI Service base URL | yes | none | env / JTier config |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Rainbow experiment flags | Controls A/B experiments and feature rollouts via `continuumRainbowService` | Varies per experiment | per-tenant / per-region |

> Additional feature flags may be managed via Redis cache (`continuumMetroDraftRedis`). Confirm flag names and scopes with the Metro Team.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (or JTier equivalent) | YAML | Dropwizard application config — server, logging, database pools, service URLs |
| `quartz.properties` | Properties | Quartz scheduler job configuration (job intervals, thread pool size) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Salesforce credentials | Authentication for Salesforce SOAP API (deal scores, contracts, documents) | env / secrets manager |
| Slack webhook URL | Webhook endpoint for operational Slack notifications | env / secrets manager |
| Database passwords | PostgreSQL connection credentials for all three databases | env / secrets manager |
| MBus credentials | MBus broker authentication | env / secrets manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development / local**: JTier config files with local database and stub service URLs; Salesforce and Slack typically disabled or pointed at sandboxes
- **Staging**: Full integration with staging instances of all Continuum services; Salesforce sandbox
- **Production**: Live credentials for all integrations; Salesforce production; full MBus topic bindings active

Confirm exact per-environment config management with the Metro Team (metro-dev-blr@groupon.com).
