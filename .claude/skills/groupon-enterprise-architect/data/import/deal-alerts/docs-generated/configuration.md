---
service: "deal-alerts"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files"]
---

# Configuration

## Overview

Deal Alerts is configured primarily through environment variables for the web app and database packages, and through n8n credential stores for workflow integrations. The web app uses a `.env` file loaded by Next.js, while the database package uses a `.env` file loaded by dbmate. Feature configuration (monitored fields, severity matrices, alert-action mappings, templates) is managed through the database and the admin API.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for the web app | yes | none | env |
| `NEXT_PUBLIC_SERVER_URL` | Public URL of the web app (used by client-side RPC) | no | `window.location.origin` | env |
| `GOOGLE_CLIENT_ID` | Google OAuth2 client ID for BetterAuth SSO | yes | none | env |
| `GOOGLE_CLIENT_SECRET` | Google OAuth2 client secret for BetterAuth SSO | yes | none | env |
| `NODE_ENV` | Runtime environment (controls Kysely query logging) | no | `development` | env |
| `SKIP_ENV_VALIDATION` | Skip environment validation during Docker build | no | unset | env |
| `INTROSPECTION_DATABASE_URL` | Database URL used by kysely-codegen for type generation | no | none | env |
| `PORT` | HTTP port for the production server | no | `3000` | env |
| `HOSTNAME` | Bind address for the production server | no | `0.0.0.0` | env |

## Feature Flags

> Feature flags are not managed through environment variables. Instead, operational configuration is stored in the database and managed through the admin API:

| Configuration | Purpose | Managed via |
|--------------|---------|------------|
| Monitored Fields | Controls which deal fields trigger delta computation (field/option scope) | Admin API: `monitored_fields.create/delete` |
| Severity Matrices | GP30-based severity thresholds per alert type (low/medium/high/critical) | Admin API: `severityMatrix.upsert` |
| Alert Action Maps | Maps alert types to action types with severity filters and priority ordering | Admin API: `actionMaps.create/update/reorder` |
| Message Templates | SMS and chat message templates with variable substitution | Admin API: `templates.create/update/delete` |
| Muted Alerts | Per-account/opportunity mute rules with expiration | Admin API: `mutedAlerts.create/delete` |
| Summary Email Exclusions | Opt-out records for daily summary emails | Database records |
| Region Business Hours | Per-region business hours for notification scheduling | Database records |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `apps/web/.env` | dotenv | Web app environment variables (DATABASE_URL, Google OAuth, etc.) |
| `packages/db/.env` | dotenv | Database migration connection string |
| `apps/web/next.config.ts` | TypeScript | Next.js configuration (standalone output, useCache experimental) |
| `turbo.json` | JSON | Turborepo task configuration for build, dev, lint, check-types |
| `biome.jsonc` | JSONC | Biome formatter/linter configuration (via Ultracite) |
| `pnpm-workspace.yaml` | YAML | pnpm workspace definition (apps/*, packages/*, tools/*) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | PostgreSQL connection credentials | env file |
| `GOOGLE_CLIENT_ID` | Google OAuth2 client identifier | env file |
| `GOOGLE_CLIENT_SECRET` | Google OAuth2 client secret | env file |
| Salesforce OAuth credentials | Salesforce API authentication | n8n credential store |
| Twilio Account SID + Auth Token | Twilio SMS API authentication | n8n credential store |
| BigQuery service account key | BigQuery API authentication | n8n credential store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Kysely logs all SQL queries (`NODE_ENV !== 'production'`). Web app runs on port 3001 with Turbopack hot reload. Database uses local PostgreSQL.
- **Production**: Standalone Next.js output deployed in Docker container. Kysely query logging disabled. Connection pool max 10, idle timeout 30s, connection timeout 5s. Runs behind Docker with port 3000.
- **Docker build**: `SKIP_ENV_VALIDATION=1` is set during the build stage to prevent env var validation failures.
