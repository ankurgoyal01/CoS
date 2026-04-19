---
service: "giftcard_service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The Giftcard Service is configured through a combination of environment variables (injected via Helm/Kubernetes at deploy time) and YAML config files committed to the repository. Environment variables supply secrets and per-environment host addresses. YAML config files define First Data merchant credentials, currency mappings, Deal Catalog settings, and database connection settings with per-environment overrides. The `RAILS_ENV` variable selects the active YAML config block.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Selects Rails environment and YAML config profile (e.g., `production-us-central1`) | yes | — | helm |
| `ORDERS_API` | Hostname for the Orders Service API (e.g., `orders--rw.production.service`) | yes | `orders-uat-mongrel-vip.snc1` | helm |
| `DB_HOST` | MySQL database host | yes | — | helm |
| `DB_NAME` | MySQL database name | yes | — | helm |
| `DB_USER` | MySQL database username | yes | — | helm |
| `DB_PASSWORD` | MySQL database password | yes | — | k8s-secret |
| `DEPLOYMENT_ENV` | Identifies deployment platform (e.g., `Conveyor_Cloud`) | no | — | helm |
| `RACK_ENV` | Rack environment (used by entrypoint to run migrations in test mode) | no | — | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `mock` (in `config/first_data.yml`) | When `true`, substitutes `FirstData::GiftCardMock` for the real First Data integration | `true` (non-production), `false` (production) | per-environment |
| `distribution_region_code_check` (in `config/deal_catalog_service.yml`) | When `true`, enforces matching between the deal's `distributionRegionCodes` and the redemption country code | `false` (NA staging), `true` (EMEA staging and production) | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/app.yml` | YAML | Service name and Orders API host default (`orders_host`) |
| `config/first_data.yml` | YAML | First Data merchant credentials, Datawire service URL settings, timeout, mock flag, encryption key — per environment |
| `config/database.yml` | YAML | MySQL adapter settings (pool, timeouts, reconnect) and environment variable references for host/credentials |
| `config/deal_catalog_service.yml` | YAML | Deal Catalog Service host URL, client ID, primary deal service category IDs, and distribution region code check flag — per environment |
| `config/currency.yml` | YAML | Mapping of country codes to currency codes and First Data currency codes (ISO 4217 numeric); separate NA and EMEA mapping groups |
| `config/environments/production.rb` | Ruby | Production-specific Rails settings |
| `config/environments/development.rb` | Ruby | Development-specific Rails settings |
| `config/environments/test.rb` | Ruby | Test-specific Rails settings |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL database password | k8s-secret |
| First Data `auth` | Merchant auth string (`merchant_id\|terminal_id`) for Datawire API | `config/first_data.yml` (per-env, managed via `cap-secrets`) |
| First Data `working_key` | Encryption key for SVDOT constructor | `config/first_data.yml` |
| First Data `datawire_id` | Registered DID for Datawire service discovery | `config/first_data.yml` |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development / Test**: First Data `mock: true`; dummy auth values; connects to Docker-compose MySQL via `DB_*` env vars
- **Staging (NA)**: `staging-us-central1` and `staging-us-west-1` — mock First Data; NA currency mappings (USD); connects to `giftcard-service-rw-na-staging-db.gds.stable.gcp.groupondev.com`
- **Staging (EMEA)**: `staging-europe-west1` — real First Data via `https://staging1.datawire.net/sd`; EMEA currency mappings (EUR, GBP); distribution region code check enabled
- **Production (NA)**: `production-us-central1`, `production-us-west-1` — real First Data; `merchant_id: 99032999997`; NA currency mappings; connects to `giftcard-service-rw-na-production-db.gds.prod.gcp.groupondev.com`; `DB_NAME: giftcard_prod`
- **Production (EMEA)**: `production-eu-west-1`, `production-europe-west1` — real First Data; same merchant credentials; EMEA currency mappings; connects to `giftcard-prod-rw-emea-production-db.gds.prod.gcp.groupondev.com`; distribution region code check enabled
