---
service: "grouponlive-inventory-service-jtier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, vault]
---

# Configuration

## Overview

The service is configured through YAML config files loaded at startup (one per environment, referenced via the `JTIER_RUN_CONFIG` environment variable) and environment variable substitution for secrets. Non-secret values are embedded directly in the YAML files under `src/main/resources/config/cloud/`. Secrets (partner API credentials, database passwords) are injected as environment variables at runtime via the deployment platform's secret management (`.meta/deployment/cloud/secrets` path referenced in `.meta/.raptor.yml`). Redis and MySQL connection details are also specified in the per-environment YAML files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file to load at startup | Yes | None | env (set by deployment platform per environment) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables TLS cert verification for Elastic APM agent in GCP environments | No | `false` | env (deployment YAML) |
| `MALLOC_ARENA_MAX` | Limits glibc malloc arenas to prevent virtual memory explosion in containers | No | `4` | env (common deployment YAML) |
| `DB_APP_USERNAME` | MySQL application user username | Yes | None | vault / secret store |
| `DB_APP_PASSWORD` | MySQL application user password | Yes | None | vault / secret store |
| `PV_API_ID` | Provenue API identifier used in OAuth authentication headers | Yes | None | vault / secret store |
| `PV_API_KEY` | Provenue API key used in OAuth HMAC signing | Yes | None | vault / secret store |
| `PV_ENCRYPTION_KEY` | Provenue encryption key for token generation | Yes | None | vault / secret store |
| `TC_NON_FIT_USER_NAME` | Telecharge non-FIT (standard seating) username | Yes | None | vault / secret store |
| `TC_NON_FIT_PASSWORD` | Telecharge non-FIT password | Yes | None | vault / secret store |
| `TC_FIT_USER_NAME` | Telecharge FIT (flexible inventory ticketing) username | Yes | None | vault / secret store |
| `TC_FIT_PASSWORD` | Telecharge FIT password | Yes | None | vault / secret store |
| `AX_API_KEY` | AXS API key | Yes | None | vault / secret store |
| `AX_CLIENT_ID` | AXS OAuth client ID | Yes | None | vault / secret store |
| `AX_CLIENT_SECRET` | AXS OAuth client secret | Yes | None | vault / secret store |
| `AX_MOBILE_PASSWORD` | AXS mobile password | Yes | None | vault / secret store |
| `TM_API_KEY` | Ticketmaster API key | Yes | None | vault / secret store |
| `TM_SECRET` | Ticketmaster API secret | Yes | None | vault / secret store |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase.

No runtime feature flags system (e.g., LaunchDarkly, Unleash) is present. Environment-level behaviour differences are controlled via the per-environment YAML config files.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Full service configuration for staging (GCP us-central1); includes server threads, logging, Retrofit client URLs, Redis, Quartz jobs, MySQL host |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Full service configuration for production (GCP us-central1); identical structure to staging with production endpoints and DB hosts |
| `src/main/resources/metrics.yml` | YAML | Metrics reporting configuration |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_APP_USERNAME` / `DB_APP_PASSWORD` | MySQL database authentication | Deployment secrets (`.meta/deployment/cloud/secrets`) |
| `PV_API_ID` / `PV_API_KEY` / `PV_ENCRYPTION_KEY` | Provenue API authentication | Deployment secrets |
| `TC_NON_FIT_USER_NAME` / `TC_NON_FIT_PASSWORD` | Telecharge non-FIT authentication | Deployment secrets |
| `TC_FIT_USER_NAME` / `TC_FIT_PASSWORD` | Telecharge FIT authentication | Deployment secrets |
| `AX_API_KEY` / `AX_CLIENT_ID` / `AX_CLIENT_SECRET` / `AX_MOBILE_PASSWORD` | AXS API authentication | Deployment secrets |
| `TM_API_KEY` / `TM_SECRET` | Ticketmaster API authentication | Deployment secrets |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Config Key | Staging | Production |
|-----------|---------|------------|
| `mysql.host` | `grouponlive-inventory-service-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `grouponlive-inventory-service-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| `mysql.database` | `glive_inventory_staging` | `glive_inventory_production` |
| `redis.endpoint` | `glive-inventory-memorystore.us-central1.caches.stable.gcp.groupondev.com:6379` | `glive-inventory-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379` |
| `retrofitClients.provenue.url` | `https://sandbox.pvapi.provenue.com/` | `https://prod.pvapi.provenue.com/` |
| `retrofitClients.telecharge.url` | `https://eapiqa.dqbroadwayinbound.com/BIWSRest.svc/` | `https://eapi.broadwayinbound.com/BIWSRest.svc/` |
| `retrofitClients.axs.url` | `https://app.axs.com/` | `https://api.veritix.com/` |
| `retrofitClients.ticketmaster.url` | `http://ticketmaster-placeholder.com/` | `https://app.ticketmaster.com/` |
| `retrofitClients.gliveInventoryRails.url` | `http://grouponlive-inventory-service.staging.service/` | `http://grouponlive-inventory-service.production.service/` |
| Server thread pool (`maxThreads`) | 50 | 50 |
| Quartz thread pool (`threadCount`) | 50 | 50 |
