---
service: "EC_StreamJob"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["cli-args", "hardcoded-constants"]
---

# Configuration

## Overview

EC_StreamJob is configured entirely through two mandatory command-line arguments passed at `spark-submit` time, plus a small set of hardcoded constants in `RealTimeJob.scala`. There is no external config file, no environment variable injection, no Consul/Vault integration, and no config-manager hook (explicitly disabled in `Capfile` via `set :use_config_manager, false`).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SPARK_HOME` | Path to Spark 2.0.1 installation on dub1 cluster | Yes (dub1 only) | `/var/groupon/spark-2.0.1` | Set manually on EMEA cluster host before spark-submit; not needed on snc1 where 2.0.1 is the default |
| `USER` | Operating system user for Capistrano deployment SSH | Yes (deploy only) | Current OS user | Shell environment; overridden to `svc_emerging_channel` for production deploys |
| `ACTIVE_ENV` | Used by crontab for the `user-behavior-collector` sidecar task | Yes (cron only) | `production` | Set in `/etc/cron.d/user-behavior-collector` via Capistrano `crontab` task |

## Feature Flags

> No evidence found in codebase. No feature-flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `Capfile` | Ruby DSL (Capistrano) | Deployment targets, Nexus artifact coordinates, Spark job-submitter host mappings, Slack deploy notifications |
| `Gemfile` / `Gemfile.lock` | Ruby Bundler | Ruby deployment toolchain dependencies |

## Runtime Parameters (CLI Arguments)

The `RealTimeJob.main()` method requires exactly three positional arguments at launch:

| Position | Name | Valid Values | Purpose |
|----------|------|-------------|---------|
| `args(0)` | `colo` | `NA` or `EMEA` | Selects Kafka broker, topic, TDM endpoint URL, and country filter set |
| `args(1)` | `env` | `staging` or `prod` | Selects TDM base URL (staging vs. production VIP) and Janus metadata API URL |
| `args(2)` | `appName` | Any string | Sets the Spark application name displayed in YARN UI |

## Hardcoded Constants (`RealTimeJob.scala`)

| Constant | Value | Purpose |
|----------|-------|---------|
| `BATCH_INTERVAL` | `20` seconds | Spark Streaming micro-batch window duration |
| `MAX_DELAY` | `19` seconds | Max wait for all HTTP futures before abandoning a batch |
| `API_TIMEOUT` | `2000` ms | Per-request HTTP timeout for TDM API calls |
| `THREAD_POOL_SIZE` | `10` | Threads per Spark partition for concurrent TDM HTTP posting |
| `NA_COUNTRY` | `{"US"}` | Country whitelist for NA colo |
| `EMEA_COUNTRY` | `{"UK","IT","FR","DE","ES","NL","PL","AE","BE","IE","NZ","AU","JP"}` | Country whitelist for EMEA colo |
| `TDM_URL_NA_STAGING` | `http://targeted-deal-message-app1-staging.snc1:8080/v1/updateUserData` | TDM endpoint for NA staging |
| `TDM_URL_EMEA_STAGING` | `http://targeted-deal-message-app2-emea-staging.snc1:8080/v1/updateUserData` | TDM endpoint for EMEA staging |
| `TDM_URL_NA_PROD` | `http://targeted-deal-message-app-vip.snc1/v1/updateUserData` | TDM endpoint for NA production |
| `TDM_URL_EMEA_PROD` | `http://targeted-deal-message-app-vip.dub1/v1/updateUserData` | TDM endpoint for EMEA production |

## Secrets

> No evidence found in codebase. No secrets or credentials are used by the runtime job. The Slack deploy notification webhook URL is configured in `Capfile` via an environment variable. The webhook URL should be stored in a secrets manager, not hardcoded.

## Per-Environment Overrides

Configuration differs by colo/env CLI argument:

- **NA staging**: Kafka broker `kafka.snc1:9092`, topic `janus-tier2`, TDM `targeted-deal-message-app1-staging.snc1:8080`, Janus `JanusBaseURL.PROD`
- **NA prod**: Kafka broker `kafka.snc1:9092`, topic `janus-tier2`, TDM `targeted-deal-message-app-vip.snc1`, Janus `JanusBaseURL.PROD`
- **EMEA staging**: Kafka broker `kafka.dub1:9092`, topic `janus-tier2_snc1`, TDM `targeted-deal-message-app2-emea-staging.snc1:8080`, Janus `JanusBaseURL.PROD`
- **EMEA prod**: Kafka broker `kafka.dub1:9092`, topic `janus-tier2_snc1`, TDM `targeted-deal-message-app-vip.dub1`, Janus `http://janus-metadata-management-app.dub1`
