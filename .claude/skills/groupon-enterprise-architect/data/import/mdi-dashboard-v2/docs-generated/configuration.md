---
service: "mdi-dashboard-v2"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

mdi-dashboard-v2 is configured via environment variables injected at deploy time (Napistrano VM-based deployment) and static config files bundled with the application. The itier-server framework provides a structured configuration loading mechanism. Environment-specific values (database credentials, service URLs, API tokens) are supplied as environment variables; non-sensitive defaults (port, log level) may be provided in config files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for Sequelize | yes | none | env |
| `NODE_ENV` | Runtime environment (`development`, `staging`, `production`) | yes | `development` | env |
| `PORT` | HTTP port the Express server listens on | no | `3000` | env |
| `MARKETING_DEAL_SERVICE_URL` | Base URL for the Marketing Deal Service | yes | none | env |
| `RELEVANCE_API_URL` | Base URL for the Relevance API | yes | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for the Deal Catalog Service | yes | none | env |
| `VOUCHER_INVENTORY_SERVICE_URL` | Base URL for the Voucher Inventory Service | yes | none | env |
| `TAXONOMY_SERVICE_URL` | Base URL for the Taxonomy Service | yes | none | env |
| `DEALS_CLUSTER_API_URL` | Base URL for the Deals Cluster API | yes | none | env |
| `MDS_FEED_SERVICE_URL` | Base URL for the MDS Feed Service | yes | none | env |
| `API_PROXY_URL` | Base URL for the API Proxy | yes | none | env |
| `SALESFORCE_API_URL` | Base URL for the Salesforce REST API | yes | none | env |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth2 client ID | yes | none | env |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth2 client secret | yes | none | env |
| `JIRA_HOST` | JIRA instance hostname | yes | none | env |
| `JIRA_USERNAME` | JIRA API username | yes | none | env |
| `JIRA_PASSWORD` | JIRA API password or token | yes | none | env |
| `SESSION_SECRET` | Secret used to sign itier-user-auth session cookies | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found of a feature flag system (LaunchDarkly, Consul, etc.) configured for this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/default.json` | JSON | Default application configuration (port, log level, service names) loaded by itier-server |
| `config/production.json` | JSON | Production environment overrides for non-secret configuration values |
| `config/staging.json` | JSON | Staging environment overrides for non-secret configuration values |
| `config/development.json` | JSON | Development environment overrides |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | PostgreSQL credentials for mdiDashboardPostgres | env (injected by Napistrano) |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth2 secret for CRM integration | env (injected by Napistrano) |
| `JIRA_PASSWORD` | JIRA API credential for ticket creation | env (injected by Napistrano) |
| `SESSION_SECRET` | Signs itier-user-auth session cookies | env (injected by Napistrano) |

> Secret values are NEVER documented. Only names and rotation policies are recorded here.

## Per-Environment Overrides

- **Development**: Uses local PostgreSQL instance; service URLs point to local stubs or staging environments; `NODE_ENV=development`.
- **Staging**: Connects to staging instances of all Continuum services; deployed to a dedicated staging datacenter.
- **Production**: Connects to production instances of all Continuum services; deployed across snc1, sac1, and dub1 datacenters; secrets injected by Napistrano at deploy time.
