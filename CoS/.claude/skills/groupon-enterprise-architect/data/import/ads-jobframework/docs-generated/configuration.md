---
service: "ads-jobframework"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

ads-jobframework is configured via environment-specific HOCON config files (`application_{env}.conf`) bundled into the assembled JAR at build time. The active profile is selected at YARN job submission time via the `env` environment variable (values: `local`, `staging`, `prod`). Job-specific parameters (dates, flags, bucket names) are passed as command-line `--option` flags to each Spark job via the CDE jobframework argument parser (`args4j`).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Selects which `application_{env}.conf` profile to load | yes | `local` | env (YARN submit: `--conf spark.yarn.appMasterEnv.env=prod`) |
| `SPARK_HOME` | Path to local Spark installation for job submission | yes (local) | `/var/groupon/spark-2.4.0` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

The following job-level flags are passed at invocation time via `--option` arguments:

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `--isCitrusReportEnabled` | Enables/disables live CitrusAd HTTP callback posting for impression and click jobs | `""` (must be set) | per-job |
| `--isSLCitrusAdExceptionReportEmailJobEnabled` | Enables/disables the exception report email job | `""` (must be set) | per-job |
| `--isUnderReportNotificationEnabled` | Enables under-report email attachment in the exception report job | `""` (must be set) | per-job |
| `--isOverReportNotificationEnabled` | Enables over-report email attachment in the exception report job | `""` (must be set) | per-job |
| `--delay` | Number of hours to look back for click data in `CitrusAdClicksReportJob` | `""` (must be set) | per-job |
| `--skipAlert` | Passed on command line to suppress PagerDuty alerting (from README) | — | per-job |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/application_local.conf` | HOCON | Local development overrides; Spark master `local[8]` |
| `src/main/resources/application_dev.conf` | HOCON | Dev environment config; staging MySQL and GCS bucket |
| `src/main/resources/application_staging.conf` | HOCON | Staging environment config; stable cluster MySQL and GCS |
| `src/main/resources/application_prod.conf` | HOCON | Production config; prod MySQL, prod GCS bucket, prod Telegraf |
| `src/main/resources/log4j_{env}.properties` | Properties | Log4j logging configuration per environment |

## Secrets

> Secret values are NEVER documented. Only names and rotation policies.

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `feeds.secretKey` | HMAC-SHA256 key for hashing customer IDs and session IDs in feed export jobs | Config file (bundled JAR) |
| `mysql.password` | MySQL `ad_inv_serv` user password | Config file (bundled JAR) |
| `teraData.tdPassword` | Teradata user password (encrypted) | Config file (bundled JAR) |
| `app.pager` | PagerDuty alert email (`ad-inventory@groupon.pagerduty.com` in prod) | Config file |

## Per-Environment Overrides

| Config Key | local | staging | prod |
|------------|-------|---------|------|
| `spark.master` | `local[8]` | `yarn` | `yarn` |
| `mysql.jdbcUrl` | `...stable.gcp.groupondev.com:3306?useSSL=false` | `...stable.gcp.groupondev.com:3306` | `...production-db.gds.prod.gcp.groupondev.com:3306` |
| `mysql.db` | `ad_inv_serv_stg` | `ad_inv_serv_stg` | `ad_inv_serv_prod` |
| `hive.db` | `ai_reporting` | `ai_reporting` | `ad_reporting_na_prod` |
| `hive.amsDb` | `ams_staging` | `ams_staging` | `ams` |
| `gcp.bucket_name` | `grpn-dnd-dev-analytics-grp-ai-reporting` | `grpn-dnd-stable-analytics-grp-ai-reporting` | `grpn-dnd-prod-analytics-grp-ai-reporting` |
| `metrics.metrics_endpoint` | `http://telegraf.general.sandbox.gcp.groupondev.com` | `http://telegraf.default.staging.stable...` | `http://telegraf.default.prod.us-central1.gcp.groupondev.com` |
| `metrics.metrics_tags_env` | `local` | `stable` | `prod` |
| `mail.host` | `stable-smtp-uswest2.groupondev.com` | `stable-smtp-uswest2.groupondev.com` | `smtp-uswest2.groupondev.com` |
| `app.pager` | `noreply@groupon.com` | `noreply@groupon.com` | `ad-inventory@groupon.pagerduty.com` |
| `uplift.US.db` | `ai_reporting` | `ai_reporting` | `ai_reporting_na` |
