---
service: "janus-schema-inferrer"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Configuration is provided through a combination of environment variables (for mode selection and config file path), YAML config files (for runtime parameters), and Helm values (for Kubernetes deployment parameters). The JTier framework loads the YAML config file specified by `JTIER_RUN_CONFIG` at startup. Different config files are used for each deployment target (environment, region, and inferrer type).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `INFERRER_TYPE` | Selects the inference mode: `kafka` or `mbus`. Controls which `SchemaInferrerApp` implementation is instantiated | yes | None | Helm deployment env vars |
| `JTIER_RUN_CONFIG` | Absolute path to the YAML runtime config file loaded by JTier at startup | yes | None | Helm deployment env vars |
| `KAFKA_TLS_ENABLED` | Enables TLS for Kafka consumer connections | no | `false` | Helm deployment env vars (Kafka production only) |
| `DEPLOY_SERVICE` | Telegraf global tag: service name | no | Set by platform | JTier/Telegraf |
| `DEPLOY_COMPONENT` | Telegraf global tag: component (kafka or mbus) | no | Set by platform | JTier/Telegraf |
| `DEPLOY_ENV` | Telegraf global tag: deployment environment | no | Set by platform | JTier/Telegraf |
| `DEPLOY_AZ` | Telegraf global tag: availability zone | no | Set by platform | JTier/Telegraf |
| `TELEGRAF_URL` | Telegraf InfluxDB output URL | no | Set by platform | JTier/Telegraf |
| `TELEGRAF_METRICS_ATOM` | Telegraf metrics atom tag | no | Set by platform | JTier/Telegraf |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `dryRun` | When `true`, logs schema changes but does not commit them to Janus (`dryRun: false` in production) | `true` (dev), `false` (production) | per-deployment |
| `enabledRawEventsForInferringSchema` | Controls which raw event types have their schemas published. `["*"]` enables all; `[]` disables all; specific event names enable selectively | `["*"]` (production) | per-deployment, per-topic-config |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development defaults for Janus, MBus, and Kafka; `dryRun: true` |
| `src/main/resources/config/cloud/kafka/staging-us-central1.yml` | YAML | Kafka mode — staging, GCP us-central1 |
| `src/main/resources/config/cloud/kafka/production-us-central1.yml` | YAML | Kafka mode — production, GCP us-central1 |
| `src/main/resources/config/cloud/kafka/production-eu-west-1.yml` | YAML | Kafka mode — production, AWS eu-west-1 |
| `src/main/resources/config/cloud/mbus/staging-us-central1.yml` | YAML | MBus mode — staging, GCP us-central1 |
| `src/main/resources/config/cloud/mbus/production-us-central1.yml` | YAML | MBus mode — production, GCP us-central1 |
| `src/main/resources/config/cloud/mbus/staging-us-west-2.yml` | YAML | MBus mode — staging, AWS us-west-2 |
| `src/main/resources/config/cloud/mbus/production-us-west-1.yml` | YAML | MBus mode — production, AWS us-west-1 |
| `src/main/resources/metrics.yml` | YAML | Metrics destination URL (`http://localhost:8186/`) and flush frequency (10s) |
| `.meta/deployment/cloud/components/kafka/common.yml` | YAML | Helm common values for Kafka CronJob (resource requests, probes, schedule, log config) |
| `.meta/deployment/cloud/components/mbus/common.yml` | YAML | Helm common values for MBus CronJob |
| `.meta/deployment/cloud/components/kafka/production-us-central1.yml` | YAML | Helm production override for Kafka (region, namespace, VIP, env vars) |
| `.meta/deployment/cloud/components/mbus/production-us-central1.yml` | YAML | Helm production override for MBus (region, namespace, VIP, env vars) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Kafka keystore (`/var/groupon/jtier/kafka.client.keystore.jks`) | mTLS client certificate for Kafka TLS authentication | k8s-secret (mounted as volume `client-certs`) |
| Kafka truststore (`/var/groupon/jtier/truststore.jks`) | Trusted CA certificates for Kafka TLS | k8s-secret (mounted as volume) |

> Secret values are NEVER documented. Only names and paths are listed.

## Per-Environment Overrides

| Parameter | Development | Staging | Production (us-central1) | Production (eu-west-1) |
|-----------|-------------|---------|--------------------------|------------------------|
| `janus.metadata.serverUrl` | `http://janus-web-cloud--dev.staging.service` | `http://janus-web-cloud.staging.service` | `http://janus-web-cloud.production.service` | `janus-web-cloud.production.service.us-central1.gcp.groupondev.com` |
| `kafka.brokerUrls` | `kafka-08-broker-staging-vip.snc1:9092` | `kafka-grpn-kafka-bootstrap.kafka-staging.svc.cluster.local:9093` | `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093` | `kafka-grpn-consumer.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094` |
| `kafka.sampleSize` | 20 | 250 | 250 | 250 |
| `kafka.topics` | `[test_12345]` | `[tracky_json_nginx, cdp_ingress]` | 15 topics | `[cdp_ingress]` |
| `mbus.mbusBrokerUrls` | `mbus-lb-stg-na.us-central1.mbus.stable.gcp.groupondev.com:61613` | `mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com:61613` | `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com:61613` | N/A |
| `mbus.subscriptionId` | `stage_schema_inferrer` | `stage_schema_inferrer` | `prod_schema_inferrer` | N/A |
| `mbus.consumerSampleSize` | 2500 | 250 | 250 | N/A |
| `dryRun` | `true` | `false` | `false` | `false` |
| `healthFlagFile` | (not set) | `/var/groupon/jtier/schema_inferrer_health.txt` | `/var/groupon/jtier/schema_inferrer_health.txt` | `/var/groupon/jtier/schema_inferrer_health.txt` |
