---
service: "online_booking_api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The service is configured via environment variables injected at runtime and YAML config files embedded in the container image at build time. Service discovery client configuration (`service_discovery_client.yml`) and Zendesk credentials (`config/zendesk.yml`) are injected from versioned cloud config files during Docker image build. Per-environment values for downstream service base URLs are managed through the `service_discovery_client_cloud.yml` file which selects the appropriate stanza based on `RAILS_ENV`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RAILS_ENV` | Rails environment name; selects the correct service discovery config stanza (e.g., `production`, `staging-us-central1`) | yes | none | env (Conveyor/Kubernetes) |
| `RAILS_MAX_THREADS` | Number of Puma worker threads | yes | none | `common.yml` (set to `10`) |
| `RAILS_LOG_TO_STDOUT` | Routes Rails logs to stdout for container log collection | yes | `true` | `.ci/Dockerfile` |
| `DEPLOYMENT_ENV` | Identifies the deployment platform (e.g., `Conveyor_Cloud`) for internal tooling | no | none | env (Conveyor/Kubernetes) |
| `DEAL_CATALOG_CLIENT_ID` | `clientId` parameter for Deal Catalog API authentication | yes | none | env (secret) |
| `PLACE_SERVICE_CLIENT_ID` | `client_id` parameter for M3 Place Read Service authentication | yes | none | env (secret) |
| `USERS_SERVICE_HEADERS_X_API_KEY` | `X-Api-Key` header value for Users Service authentication | yes | none | env (secret) |
| `VOUCHER_INVENTORY_CLIENT_ID` | `clientId` parameter for Voucher Inventory Service authentication | yes | none | env (secret) |
| `GEM_HOME` | RubyGems home directory for bundled gems in container | yes | `/usr/local/bundle` | `.ci/Dockerfile` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase. No feature flag system (LaunchDarkly, Flipper, etc.) is present. Option-level booking flags (`active`, `g3`, `pre_bookable`, etc.) are stored in and fetched from the downstream `continuumAvailabilityEngine`/`continuumCalendarService`.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `service_discovery_client.yml` | YAML | Maps `RAILS_ENV` to base URLs, timeouts, and auth params for all eight downstream service clients; injected from `.meta/deployment/cloud/config/service_discovery_client_cloud.yml` at container build time |
| `config/zendesk.yml` | YAML | Supplies `clientId` and `hmacAuthToken` for the HMAC authentication scheme; injected from `.meta/deployment/cloud/config/zendesk_cloud.yml` at container build time |
| `config/application.rb` | Ruby | Core Rails application configuration — log level, middleware stack, cache settings |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment values: replica counts, thread count, memory/CPU requests, image name, log config |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP us-central1 overrides: min 2 / max 20 replicas, VIP hostname |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP us-central1 overrides: min 1 / max 1 replica, VIP hostname |
| `config/logrotate` | Logrotate | Log rotation config for OBAPI logs; runs every 15 minutes via cron in the container |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DEAL_CATALOG_CLIENT_ID` | Authenticates requests to Deal Catalog service | env (Kubernetes secret / Conveyor) |
| `PLACE_SERVICE_CLIENT_ID` | Authenticates requests to M3 Place Read service | env (Kubernetes secret / Conveyor) |
| `USERS_SERVICE_HEADERS_X_API_KEY` | Authenticates requests to Users Service; also serves as the Zendesk `hmacAuthToken` | env (Kubernetes secret / Conveyor) |
| `VOUCHER_INVENTORY_CLIENT_ID` | Authenticates requests to Voucher Inventory service | env (Kubernetes secret / Conveyor) |

> Secret values are NEVER documented. Only names and purposes.

## Per-Environment Overrides

| Environment | `RAILS_ENV` value | Notable Differences |
|-------------|-------------------|---------------------|
| Production (snc1) | `production` | Base URLs point to `.snc1` VIPs; 2–20 replicas |
| Production (sac1) | `sac_production` | Base URLs point to `.sac1` VIPs |
| Production (dub1 / EMEA) | `emea_production` | Base URLs point to `.dub1` VIPs; notifications URL set to `not-applicable` |
| Production (GCP us-central1) | `production-us-central1` | Base URLs point to cloud service-discovery DNS; 2–20 replicas |
| Production (GCP europe-west1) | `production-europe-west1` | Base URLs point to cloud service-discovery DNS |
| Staging (snc1) | `staging` | Base URLs point to `-staging-vip.snc1` hostnames |
| Staging (EMEA staging) | `emea_staging` | Base URLs point to EMEA staging VIPs; notifications `not-applicable` |
| Staging (GCP us-central1) | `staging-us-central1` | Base URLs point to `*.staging.service` DNS; 1 replica; request timeouts extended to 30s |
| UAT | `uat` | Base URLs point to UAT VIPs |
