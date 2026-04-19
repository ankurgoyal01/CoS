---
service: "breakage-reduction-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [cson-config-files, env-vars, helm-values]
---

# Configuration

## Overview

BRS uses `keldor` and `keldor-config` for multi-layer CSON configuration. Configuration is layered: `config/base.cson` provides defaults, `config/node-env/{NODE_ENV}.cson` applies environment-tier overrides, and `config/stage/{stage-region}.cson` applies per-deployment overrides (e.g., production-us-central1, staging-us-west-2). At runtime, the `KELDOR_CONFIG_SOURCE` environment variable selects the service base URL resolution mode (`{staging}` or `{production}`). Secrets (Redis password, API keys) are referenced in config files by name; actual values are injected at deploy time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Selects the node environment tier (development, test, production) | yes | none | env |
| `KELDOR_CONFIG_SOURCE` | Overrides the base URL resolution source for service clients (`{staging}` or `{production}`) | yes | none | helm / deploy config |
| `NODE_OPTIONS` | Node.js runtime flags (e.g., `--max-old-space-size=1024`) | no | none | helm / deploy config |
| `PORT` | HTTP server port | yes | `8000` | helm / deploy config |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O | no | `75` | helm / deploy config |
| `DEPLOY_REGION` | Cloud region identifier used for region-specific logic (e.g., US vs EMEA Redis, Canada/US deal routing) | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

Feature flags are defined in `config/base.cson` under the `feature_flags` key and overridden per stage config. They are evaluated at runtime via `itier-feature-flags`.

| Flag | Purpose | Default (base) | Scope |
|------|---------|----------------|-------|
| `customer_authority_attributes` | Enables AMS customer authority attribute fetching for eligibility | `true` | global |
| `feature_flag_switcher` | Enables the Keldor feature-flag switcher | `true` | global |
| `anytime_sending` | Allows notifications outside daytime window | `false` | global |
| `daytime_open` | Start of notification delivery window | `00:00` (base) / `8:00` (production) | per-environment |
| `daytime_close` | End of notification delivery window | `23:59` (base) / `21:00` (production) | per-environment |
| `delay_soon_notifications` | Delays notifications that are close to firing | `false` (base) / `true` (production) | per-environment |
| `e_minus_21_day` | Day of week for the expiration-minus-21-day notification | `Tuesday` (base) / `Friday` (production) | per-environment |
| `expiration-extension-notifications` | Enables expiration extension notification workflows | `true` | global |
| `expiration-extension-begin` | Days relative to expiration that the EE window opens | `-21` | global |
| `expiration-extension-end` | Days relative to expiration that the EE window closes | `21` | global |
| `show_modal` | Enables modal action in next-actions responses | `true` | global |
| `max_next_check_at_offset` | Maximum offset (seconds) for next-check scheduling | `0` (base) / `3600` (production) | per-environment |
| `query_country_switcher` | Enables country-based query routing | `true` | global |
| `post_first_purchase_welcome_email` | Enables first-purchase welcome email workflow | `false` | global |
| `new_gifting_feature` | Enables new gifting notification flows | `false` (base) / `true` (production) | per-environment |
| `reminder_countries_email` | Countries eligible for email reminders | US only (base); all major markets in production | per-environment |
| `reminder_countries_push` | Countries eligible for push reminders | US only (base); all major markets in production | per-environment |
| `bia_eligibility_window_days` | Buy-it-again eligibility window in days | `1` | global |
| `tradein_purchase_window` | Trade-in purchase window in hours/days | `2` (base) / `24` (production) | per-environment |
| `ttd_pass_valid_days` | Things-to-do pass validity window in days | `90` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base defaults for all environments: feature flags, Redis, service client base URLs, action types, localization |
| `config/node-env/development.cson` | CSON | Local development overrides |
| `config/node-env/development_emea.cson` | CSON | Local EMEA development overrides |
| `config/node-env/development_us.cson` | CSON | Local US development overrides |
| `config/node-env/production.cson` | CSON | Production node-env overrides |
| `config/node-env/test.cson` | CSON | Test environment overrides |
| `config/stage/production.cson` | CSON | Production stage overrides (Redis hosts, service base URLs, child processes, feature flag production values) |
| `config/stage/production-eu-west-1.cson` | CSON | Production EU-West-1 region overrides |
| `config/stage/production-us-central1.cson` | CSON | Production US-Central1 region overrides |
| `config/stage/staging.cson` | CSON | Staging stage overrides |
| `config/stage/staging-us-west-2.cson` | CSON | Staging US-West-2 overrides |
| `.deploy-configs/values.yaml` | YAML | Helm values (filebeat resource limits, steno log config) |
| `.deploy-configs/production-us-west-1.yml` | YAML | Napistrano deploy config for production US-West-1 |
| `.deploy-configs/production-eu-west-1.yml` | YAML | Napistrano deploy config for production EU-West-1 |
| `.deploy-configs/staging-us-west-1.yml` | YAML | Napistrano deploy config for staging US-West-1 |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `serviceClient.userService.apiKey` | API key for Users Service authentication | Config file (value injected at deploy) |
| `serviceClient.vis.admin_user_id` | Admin user ID for VIS admin operations | Config file |
| `serviceClient.globalDefaults.clientId` | Default OAuth client ID for API proxy calls | Config file |
| `server.secret` | Session secret for I-Tier server | Config file (value injected at deploy) |
| Redis password | Redis connection authentication (production) | Config file (value injected at deploy) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses staging VIPs for all service clients; steno logs written to file; feature flags at base defaults
- **Staging**: `KELDOR_CONFIG_SOURCE={staging}`; Redis on `redis-10130.snc1.raas-shared3-staging.grpn`; 3–5 replicas; daytime window is 00:00–23:59 (permissive)
- **Production**: `KELDOR_CONFIG_SOURCE={production}`; Redis on region-specific hosts (US vs EMEA); 3–12 replicas; daytime window is 08:00–21:00; delay-soon-notifications enabled; expanded country eligibility for reminders; new gifting feature enabled; `max_next_check_at_offset=3600`
- **Catfood** (production-canary): Uses production cloud deploy env with `keldor_feature_flags__feature_flag_switcher=true`
