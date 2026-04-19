---
service: "orders_mbus_client"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Configuration is managed through layered YAML files loaded at startup via Dropwizard / JTier. The active config file is selected by the `JTIER_RUN_CONFIG` environment variable. Cloud environments also override specific values through env vars (secrets) injected at runtime. On-premises environments use datacenter-specific Docker Compose files. Schema migrations can be disabled via `DISABLE_MIGRATION`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file for the current environment | Yes | `./development.yml` (local) | env |
| `DISABLE_MIGRATION` | Skips Flyway MySQL schema migrations on startup when set to `"true"` | No | `false` | env |
| `USE_TELEGRAF_METRICS` | Enables Telegraf-based metric forwarding | No | `"false"` | env |
| `MYSQL_APP_PASSWORD` | MySQL application user password | Yes (staging/prod) | none | env / secret |
| `MYSQL_DBA_PASSWORD` | MySQL DBA user password | Yes (staging/prod) | none | env / secret |
| `PAYPAL_BILLING_AGREEMENT_TOPIC_PASS` | MBus password for `PaypalBillingAgreementTopic` subscription | Yes (production) | none | env / secret |
| `ACCOUNT_ERASE_TOPIC_PASSWORD` | MBus password for `AccountEraseTopic` subscription | Yes (production) | none | env / secret |
| `VFMPROMOTIONAL_ADJUSTMENTS_TOPIC_PASS` | MBus password for `VFMPromotionalAdjustmentsEnabledTopic` subscription | Yes (production) | none | env / secret |
| `PAYMENT_UPDATE_TOPIC_PASSWORD` | MBus password for `PaymentUpdateTopic` subscription | Yes (production) | none | env / secret |
| `GIFT_PUBLISHER_PASSWORD` | MBus password for `jms.topic.Order.Gift` publisher | Yes (production) | none | env / secret |

> Secret values are NEVER documented here. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `mbusListenersEnabled` | Enables all MBus topic consumers (except test topic) | `false` (dev/UAT), `true` (staging/production) | per-environment YAML |
| `testTopicListenerEnabled` | Enables the `TestingTopic` consumer (`jms.topic.grouponTestTopic1`) | `false` (all except staging) | per-environment YAML |
| `mbusPublishersEnabled` | Enables the Quartz publisher jobs and DB connection initialisation | `true` (UAT, staging, production) | per-environment YAML |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration baseline |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | GCP staging NA (us-central1) overrides |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | GCP production NA (us-central1) overrides |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | GCP production EMEA (eu-west-1) overrides |
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | GCP production NA (us-west-1) overrides |
| `src/main/resources/config/cloud/dev-us-west-1.yml` | YAML | GCP dev (us-west-1) overrides |
| `src/main/resources/config/cloud/dev-us-west-2.yml` | YAML | GCP dev (us-west-2) overrides |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | GCP staging (us-west-1) overrides |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | GCP staging (us-west-2) overrides |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | GCP staging EMEA (europe-west1) overrides |
| `src/main/resources/metrics.yml` | YAML | Codahale metrics flush config (destination URL, flush frequency) |
| `development.yml` | YAML | Docker Compose dev launcher config (repo root copy) |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Kubernetes common deployment spec (replicas, ports, resource requests) |
| `.meta/deployment/cloud/components/worker/<env>.yml` | YAML | Per-environment Kubernetes overrides (namespace, scaling, env vars) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `${MYSQL_APP_PASSWORD}` | MySQL application user password | env (injected at runtime) |
| `${MYSQL_DBA_PASSWORD}` | MySQL DBA user password | env (injected at runtime) |
| `${PAYPAL_BILLING_AGREEMENT_TOPIC_PASS}` | MBus subscriber password for PayPal billing agreement topic | env (injected at runtime) |
| `${ACCOUNT_ERASE_TOPIC_PASSWORD}` | MBus subscriber password for account-erase GDPR topic | env (injected at runtime) |
| `${VFMPROMOTIONAL_ADJUSTMENTS_TOPIC_PASS}` | MBus subscriber password for VFM promotional adjustments topic | env (injected at runtime) |
| `${PAYMENT_UPDATE_TOPIC_PASSWORD}` | MBus subscriber password for payment update topic | env (injected at runtime) |
| `${GIFT_PUBLISHER_PASSWORD}` | MBus producer password for gift order topic | env (injected at runtime) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Development | Staging | Production |
|---------|------------|---------|------------|
| `mbusListenersEnabled` | `false` | `true` | `true` |
| `testTopicListenerEnabled` | `false` | `true` | `false` |
| `mbusPublishersEnabled` | `true` | `true` | `true` |
| Orders base URL | `http://orders-uat-mongrel-vip.snc1` | `http://orders.staging.service` | `http://orders--rw.production.service` |
| MBus host (NA) | `mbus-uat-vip.snc1` | `mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com` | `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com` |
| MySQL host | `messaging_db` (Docker) | `orders-mbus-client-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `orders-mbus-client-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| MySQL database | `messaging` | `orders_msg_stg` | `orders_msg_prod` |
| Publisher `maxRetryCount` | 50 | 3 | 100 |
| Kubernetes min/max replicas | — | 1 / 2 | 2 / 10 |
| Server `maxThreads` | 50 | 500 | 500 |

Publisher tuning parameters (from `publisherConfiguration`):

| Parameter | Staging | Production |
|-----------|---------|------------|
| `poolSize` | 20 | 20 |
| `queueThreshold` | 100 | 100 |
| `batchFetchSize` | 10 | 10 |
| `ttl` (lock TTL ms) | 300000 | 300000 |
| MBus port | 61613 | 61613 |
