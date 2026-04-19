---
service: "user-behavior-collector"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

User Behavior Collector is configured via Groupon's internal `app-config` library (`com.groupon.common.app_config.AppConfig`), which loads properties from environment-specific configuration files. The active environment is set via the `ACTIVE_ENV` system property (or the `--suffix` CLI argument for the Spark sub-job). Secrets such as database password are stored in a private git submodule referenced at clone time. Metrics configuration relies on the `env` environment variable read directly from the OS environment.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ACTIVE_ENV` | Sets active environment for `app-config` property resolution (`production`, `production_emea`, `staging`, `uat`, `development`) | yes | None | env / cron script / `--suffix` CLI arg |
| `env` | Tags metrics measurements with the running environment | no | None | env (OS) |
| `custom.logpath` | Directory where `production.log` and `stderr.log` are written | yes | None | JVM system property (`-Dcustom.logpath`) |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `-skipUpdateHistoryData` | Skips the Spark pipeline step (deal views / purchases from Kafka) | off | per-run (CLI arg) |
| `-skipUpdateDealinfo` | Skips the deal info refresh step (GAPI/Deal Catalog/Redis) | off | per-run (CLI arg) |
| `-skipPublishAudience` | Skips the audience publishing step | off | per-run (CLI arg) |
| `-skipUpdateWishList` | Skips the wishlist update step | off | per-run (CLI arg) |
| `-skipViewPurchase` | Within the Spark job, skips processing deal view and purchase records (used post-migration to realtime pipeline) | off | per-run (CLI arg) |
| `-updateWishlistOnly` | Runs only the wishlist update step | off | per-run (CLI arg) |
| `-publishAudienceOnly` | Runs only the audience publishing step | off | per-run (CLI arg) |
| `-updateHistoricalDataAndDealInfoOnly` | Runs only the Spark and deal info steps | off | per-run (CLI arg) |
| `-fastBackfill` | Within Spark job, skips writing search, rating, and email-open intermediate files | off | per-run (Spark CLI arg) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `app-config` environment properties | properties | Loaded by `AppConfig`; keys include `gdoop_host`, `cerebro_host`, `cerebro_folder`, `ec.countries`, `ec.regions`, `gapi.clientId`, `audience.aws.host`, `deal_view_notification.db.url`, `deal_view_notification.db.url_readonly`, `deal_view_notification.db.username`, `deal_view_notification.db.password`, `database.persistence_unit`, `telegraf.endpoint`, audience ID keys per country |
| `cron/production/user-behavior-collector-na` | cron | NA production cron schedule for all 4 batch jobs |
| `cron/production/user-behavior-collector-emea` | cron | EMEA production cron schedule |
| `cron/staging/user-behavior-collector-na.cron` | cron | NA staging cron schedule |
| `cron/staging/user-behavior-collector-emea` | cron | EMEA staging cron schedule |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `deal_view_notification.db.password` | PostgreSQL database password for `deal_view_notification` DB | Private git submodule (linked at clone time; see README) |
| `deal_view_notification.db.username` | PostgreSQL database username | `app-config` properties |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **NA production** (`ACTIVE_ENV=production`): Host `emerging-channels-utility3.snc1`; JAR at `/var/groupon/user-behavior-collector/`; logs at `/var/groupon/log/user-behavior-collector/`; cron at `/etc/cron.d/user-behavior-collector`
- **EMEA production** (`ACTIVE_ENV=production-emea`): Host `emerging-channels-emea4.snc1`; same JAR/log paths; separate cron schedule; includes `cleanupDB` cron (daily 02:00 UTC)
- **NA staging** (`ACTIVE_ENV=staging`): Host `targeted-deal-message-app1-staging.snc1`
- **EMEA staging** (`ACTIVE_ENV=staging-emea`): Host `emerging-channels-emea1.snc1`
- **EMEA region** sets `ec.regions=EMEA` which changes GAPI endpoint to `/api/mobile/{country}/deals/{dealID}` and uses EMEA-specific DB queries (`getDealViewAudienceInfoEMEA`, `getDealViewAudienceInfoForAudienceEMEA`, `getWebTouchAudienceInfoForAudienceEMEA`)
