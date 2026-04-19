---
service: "gaurun"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Gaurun is configured primarily via a TOML file selected at startup using the `-c` flag. The config file path resolves to `/app/conf/${APPLICATION_ENV}.toml` in the container (e.g., `production-us-central1.toml`). The config loader performs environment variable substitution for `{{VAR_NAME}}` tokens in the TOML file. Command-line flags can override `port`, `workers`, and `queues` at startup. Runtime pusher concurrency can be adjusted via `PUT /config/pushers`.

Metrics tags are sourced from environment variables (`DEPLOY_NAMESPACE`, `DEPLOY_SERVICE`, `DEPLOY_COMPONENT`, `DEPLOY_ENV`, `TELEGRAF_METRICS_ATOM`, `HOSTNAME`). Go runtime memory is limited via `GOMEMLIMIT`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `APPLICATION_ENV` | Selects the TOML config file to load (e.g., `production-us-central1`) | yes | — | Kubernetes env (`deployment/*.yml`) |
| `GOMEMLIMIT` | Go runtime soft memory limit | no | — | Kubernetes env (e.g., `3072MiB` production, `1024MiB` staging) |
| `DEPLOY_NAMESPACE` | Metrics tag: deployment namespace | no | `gaurun-fallback` | env |
| `DEPLOY_SERVICE` | Metrics tag: service name | no | `gaurun-service` | env |
| `DEPLOY_COMPONENT` | Metrics tag: component name | no | `app-fallback` | env |
| `DEPLOY_ENV` | Metrics tag: deployment environment | no | `env-fallback` | env |
| `TELEGRAF_METRICS_ATOM` | Metrics tag: atom identifier | no | `atom-fallback` | env |
| `HOSTNAME` | Metrics tag: hostname | no | `host-fallback` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `core.dry_run` | Simulates push delivery without calling APNs/FCM | `true` (dev config), `false` (production) | global |
| `core.frontend` | Enables the `/grpn/payload` upload form UI | `false` | global |
| `core.allows_empty_message` | Allows notifications with empty message body | `false` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/gaurun.toml` | TOML | Default/development configuration template |
| `conf/development.toml` | TOML | Local development overrides |
| `conf/production-us-central1.toml` | TOML | Production GCP US-Central1 configuration |
| `conf/production-eu-west-1.toml` | TOML | Production AWS EU-West-1 configuration |
| `conf/production-europe-west1.toml` | TOML | Production GCP Europe-West1 configuration |
| `conf/staging-us-central1.toml` | TOML | Staging GCP US-Central1 configuration |
| `conf/staging-europe-west1.toml` | TOML | Staging GCP Europe-West1 configuration |

### Core Section (`[core]`)

| Key | Type | Purpose | Default |
|-----|------|---------|---------|
| `port` | string | Listen port or Unix socket path | `1056` |
| `workers` | int64 | Number of push worker goroutines | `runtime.NumCPU()` |
| `queues` | int64 | Size of internal queue buffer | `8192` |
| `notification_max` | int64 | Maximum notifications per request | `100` |
| `pusher_max` | int64 | Max goroutines for async pushing (0 = synchronous) | `0` |
| `shutdown_timeout` | int64 | Graceful shutdown timeout (seconds) | `10` |
| `pid` | string | Path to PID file | `""` |
| `dry_run` | bool | Simulate delivery without sending | `false` |
| `gaurun_url` | string | Self-URL for retry processor HTTP client | `""` |
| `frontend` | bool | Enable payload upload form UI | `false` |

### iOS Section (`[ios]`)

| Key | Type | Purpose | Default |
|-----|------|---------|---------|
| `enabled` | bool | Enable iOS push delivery | `true` |
| `pem_cert_path` | string | PEM certificate path for APNs | `""` |
| `pem_key_path` | string | PEM key path for APNs | `""` |
| `pem_key_passphrase` | string | PEM key passphrase | `""` |
| `token_auth_key_path` | string | APNs `.p8` auth key path (token-based) | `""` |
| `token_auth_key_id` | string | APNs key ID (token-based) | `""` |
| `token_auth_team_id` | string | APNs team ID (token-based) | `""` |
| `sandbox` | bool | Use APNs sandbox endpoint | `true` |
| `retry_max` | int | Max retry count for APNs failures | `1` |
| `timeout` | int | APNs connection timeout (seconds) | `5` |
| `keepalive_timeout` | int | Keep-alive duration (seconds) | `90` |
| `keepalive_conns` | int | Number of keep-alive connections | `runtime.NumCPU()` |
| `topic` | string | APNs topic (bundle ID) | `""` |

### iOS Context Section (`[ios-context.*]`)

Named iOS contexts (e.g., `[ios-context.iphone-consumer]`) configure per-app APNs credentials and worker counts. Contexts defined in production config:

| Context Key | Topic (Bundle ID) | Certificate Set |
|-------------|------------------|-----------------|
| `iphone-consumer` | `com.groupon.grouponapp` | `conf/grpn-ios-cert/` |
| `ipad-consumer` | `com.groupon.grouponapp` | `conf/grpn-ios-cert/` |
| `catfood-consumer` | `com.groupon.enterprise.iosgroupon` | `conf/grpn-catfood-cert/` |
| `ls-catfood-consumer` | `com.livingsocial.enterprise.deals` | `conf/ls-catfood-cert/` |
| `ivingsocial-iphone-consumer` | `com.livingsocial.deals` | `conf/ls-ios-cert/` |
| `ivingsocial-ipad-consumer` | `com.livingsocial.deals` | `conf/ls-ios-cert/` |
| `mbnxt-iphone-consumer` | (see cert dir) | `conf/mbnxt-iphone-consumer-cert/` |

### Android Section (`[android]`)

| Key | Type | Purpose | Default |
|-----|------|---------|---------|
| `enabled` | bool | Enable Android push delivery | `true` |
| `apikey` | string | FCM legacy API key | `""` |
| `timeout` | int | FCM connection timeout (seconds) | `5` |
| `keepalive_timeout` | int | Keep-alive duration (seconds) | `90` |
| `keepalive_conns` | int | Number of keep-alive connections | `runtime.NumCPU()` |
| `retry_max` | int | Max retry count for FCM failures | `1` |

### Android Context Section (`[android-context.*]`)

| Context Key | Purpose |
|-------------|---------|
| `android-fcm-consumer` | Groupon consumer app (FCM) |
| `android-consumer` | Groupon consumer app (alternative API key) |
| `android-merchant` | Groupon Merchant app |

### Kafka Section (`[kafka]`)

| Key | Purpose |
|-----|---------|
| `read_host` | Kafka bootstrap server for consumers |
| `write_host` | Kafka bootstrap server for producers |
| `topic` | Default retry topic (`mta.gaurun.retry`) |
| `enable_tls` | Enable TLS for Kafka connections |
| `ca_cert_path` | CA certificate path |
| `tls_cert_path` | Client TLS certificate path |
| `tls_key_path` | Client TLS key path |
| `consumer_group_name` | Kafka consumer group name |
| `consumer_clients` | Number of consumer client instances |

### Retry Section (`[retry_later]`)

| Key | Purpose | Default |
|-----|---------|---------|
| `max_retries` | Maximum retry attempts before discarding | `12` |
| `min_message_age` | Minimum age (ms) before retrying a message | `300000` (5 minutes) |

### Log Section (`[log]`)

| Key | Purpose | Default |
|-----|---------|---------|
| `access_log` | Access log destination (`stdout`, file path, `discard`) | `stdout` |
| `error_log` | Error log destination | `stderr` |
| `accept_log` | Accepted notification log destination | `stdout` |
| `level` | Log level (`panic`, `fatal`, `error`, `warn`, `info`, `debug`) | `error` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| APNs PEM certificates (`conf/grpn-ios-cert/`, `conf/ls-ios-cert/`, etc.) | iOS push authentication certificates | Kubernetes volume mount at `/var/groupon/certs` (`client-certs` volume) |
| FCM API keys (`android.apikey`, `android-context.*.api_key`) | Android push authentication | TOML config file (environment-specific, managed via secrets infrastructure) |
| Kafka TLS certificates (`kafka.ca_cert_path`, `kafka.tls_cert_path`, `kafka.tls_key_path`) | Kafka SSL mutual auth | Kubernetes volume or secret mount |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging**: `minReplicas=1`, `maxReplicas=1`, `GOMEMLIMIT=1024MiB`, memory request 1Gi / limit 2Gi. Kafka bootstrap uses `kafka-staging` namespace.
- **Production (GCP us-central1)**: `minReplicas=10`, `maxReplicas=60`, `GOMEMLIMIT=3072MiB`, CPU request 500m, memory request 3Gi / limit 4Gi. HPA target CPU 70%, memory 80%. VPA enabled.
- **Production (AWS eu-west-1)**: Same resource profile as GCP US. Kafka bootstrap port 9094 (AWS) vs 9093 (GCP).
- **Production (GCP europe-west1)**: Same resource profile as GCP US. Kafka bootstrap uses `kafka-production` namespace.
