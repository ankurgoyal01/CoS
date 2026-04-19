---
service: "coffee-to-go"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "db-config"]
---

# Configuration

## Overview

Coffee To Go is configured through environment variables (loaded via `dotenv` from `.env.local` and `.env` files), per-environment JSON config files for the frontend, and a database-backed runtime configuration table (`config`). Critical configuration is validated at startup using Zod schemas -- the server will not start if required values are missing. Feature flags are delivered via cookies and parsed by middleware on each request.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Environment name (development, staging, production) | no | `development` | env |
| `NODE_ENV` | Node.js environment mode | no | `production` | env |
| `HTTP_PORT` | API server port | no | `3000` | env |
| `HOST_PLATFORM` | Hosting platform indicator (docker, other) | no | `docker` | env |
| `DB_URL` | Primary PostgreSQL connection string | yes | | env |
| `DB_URL_RO` | Read-only PostgreSQL connection string | no | Falls back to `DB_URL` | env |
| `APP_POOL_SIZE` | Database connection pool size per pool | no | `10` | env |
| `SSL_REJECT_UNAUTHORIZED` | Enable SSL certificate validation for DB | no | `false` | env |
| `SSL_CA_CERTIFICATE` | Path to SSL CA certificate file | no | | env |
| `GOOGLE_OAUTH_CLIENT_ID` | Google OAuth client ID | yes | | env |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Google OAuth client secret | yes | | env |
| `ALLOWED_EMAIL_DOMAINS` | Comma-separated list of allowed email domains | no | `groupon.com` | env |
| `FRONTEND_URL` | Frontend origin URL for CORS configuration | no | | env |
| `LOG_LEVEL` | Logging level (debug, info, warn, error) | no | `info` | env |
| `DEFAULT_DEALS_LIMIT` | Default number of deals returned | no | `500` | env |
| `DEFAULT_RADIUS` | Default search radius in km | no | `50` | env |
| `DEFAULT_LAT` | Default latitude (Chicago) | no | `41.8781` | env |
| `DEFAULT_LON` | Default longitude (Chicago) | no | `-87.629` | env |
| `GOOGLE_MAPS_API_KEY` | Google Maps API key (injected into frontend config) | yes | | env |
| `MIGRATION_TARGET_DATABASE_URL` | Database URL for running migrations (dbmate) | yes (for migrations) | | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

Feature flags are delivered via the `ff` cookie as a JSON object and parsed by the `featureFlagMiddleware` on each request.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `dev_view` | Switches deal queries to use the development materialized view (`v_deals_cache_dev`) instead of the production view | `false` | per-user (cookie) |

Feature flags are defined in the `@coffee-to-go/common` package and consumed by both frontend (via Zustand store) and backend (via middleware).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `apps/coffee-react/config/production.json` | JSON | Frontend runtime config for production (Google Maps API key, Marker.io project, tracking enabled) |
| `apps/coffee-react/config/staging.json` | JSON | Frontend runtime config for staging (tracking disabled) |
| `.env` / `.env.local` | dotenv | Backend environment variables |

## Runtime Database Configuration

The `config` table in PostgreSQL stores key-value pairs that are read by `ConfigService` with a 10-minute in-memory cache TTL.

| Key | Purpose |
|-----|---------|
| `DEVELOPER_EMAILS` | List of developer email addresses excluded from usage analytics |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GOOGLE_OAUTH_CLIENT_ID` | Google OAuth authentication | env |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Google OAuth authentication | env |
| `DB_URL` | PostgreSQL connection string (contains credentials) | env |
| `DB_URL_RO` | Read-only PostgreSQL connection string | env |
| `GOOGLE_MAPS_API_KEY` | Google Maps JavaScript API key | env |
| `SSL_CA_CERTIFICATE` | Path to TLS certificate for database SSL | env |
| Sentry DSN | Error tracking (hardcoded in logger.ts) | source |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `ENV=development`, `NODE_ENV=development`, query logging enabled in Kysely, Pino logs to stdout only, CORS may be disabled (no `FRONTEND_URL`), `HOST_PLATFORM` may be non-docker for local dev.
- **Staging**: `ENV=staging`, deployed to `staging-us-central1`, tracking disabled in frontend config, Sentry transport active.
- **Production**: `ENV=production`, `NODE_ENV=production`, trust proxy enabled, cross-subdomain cookies on `groupondev.com`, pino-roll log rotation to `/var/groupon/logs/`, Sentry transport active, tracking enabled.
