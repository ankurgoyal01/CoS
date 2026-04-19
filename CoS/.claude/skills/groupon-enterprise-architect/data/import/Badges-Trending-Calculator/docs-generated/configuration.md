---
service: "badges-trending-calculator"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, spark-submit-args, gcp-secrets]
---

# Configuration

## Overview

Configuration is managed through HOCON `.conf` files under `src/main/resources/`, selected by the `env` environment variable passed to the Spark executor at submit time (e.g., `spark.executorEnv.env=prod`). Sensitive key material (TLS keystores and truststores) is injected at runtime by a GCP Secret Manager initialization script. Spark job parameters (batch interval, shuffle partitions, consumer group, offset reset) are passed as command-line `--args` in the Dataproc job definition.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Selects the application config profile (`local`, `staging`, `prod`, `emea-prod`, `emea-staging`) | yes | `local` | `spark.executorEnv.env` / `spark.yarn.appMasterEnv.env` |
| `ARTIFACT_VERSION` | Overrides the sbt `version` during build | no | `0.1` | CI environment |

> IMPORTANT: Actual secret values are never documented. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase of runtime feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/application_prod.conf` | HOCON | NA production settings (Kafka, Redis, Watson, Geo Service, PDS exclusions) |
| `src/main/resources/application_staging.conf` | HOCON | NA staging settings |
| `src/main/resources/application_emea-prod.conf` | HOCON | EMEA production settings |
| `src/main/resources/application_emea-staging.conf` | HOCON | EMEA staging settings |
| `src/main/resources/application_local.conf` | HOCON | Local development settings |
| `orchestrator/config/prod/badges_trending_calculator.json` | JSON | Dataproc cluster and Spark job configuration for production Airflow DAG |
| `orchestrator/config/stable/badges_trending_calculator.json` | JSON | Dataproc cluster and Spark job configuration for staging Airflow DAG |
| `orchestrator/config/dev/badges_trending_calculator.json` | JSON | Dataproc cluster and Spark job configuration for dev Airflow DAG |

### Key config values by section (production)

| Config Key | Production Value | Purpose |
|------------|-----------------|---------|
| `app.prefix` | `bds3` | Redis key prefix for all badge keys |
| `app.country_whitelist` | `US,CA` | Countries for which badges are computed |
| `app.region` | `NA_PROD` | Deployment region label |
| `kafka.kafka_broker_input` | `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094` | Kafka broker address |
| `kafka.topics_input` | `janus-tier1` | Kafka input topic |
| `kafka.security_protocol` | `SSL` | Kafka transport security |
| `kafka.key_store_type` | `PKCS12` | TLS keystore format |
| `geoServiceConfig.path` | `/geoplaces/v1.3/divisions` | Bhuvan API endpoint path |
| `geoServiceConfig.responseLimit` | `1000` | Max divisions returned |
| `geoServiceConfig.timeoutInMilliseconds` | `2000` | Bhuvan HTTP timeout |
| `watsonItemIntrinsicClientConfig.itemIntrinsicPathFormat` | `/v1/dds/buckets/relevance-item-intrinsic/data/deals/` | Watson item-intrinsic path prefix |
| `watsonItemIntrinsicClientConfig.maxConnections` | `200` | Watson HTTP connection pool size |
| `redisConfig.mode` | `cluster` | Redis client mode (`cluster` / `standalone`) |
| `redisConfig.clusterConfig.host` | `badges-cluster-new-memorystore.us-central1.caches.prod.gcp.groupondev.com` | Redis cluster endpoint |
| `redisConfig.clusterConfig.port` | `6379` | Redis port |
| `redisConfig.clusterConfig.minIdle` | `40` | Connection pool minimum idle |
| `redisConfig.clusterConfig.maxTotal` | `300` | Connection pool maximum total |
| `redisConfig.clusterConfig.commandTimeoutMs` | `5000` | Redis command timeout |
| `spark.shufflePartitions` | `200` | Spark shuffle partition count |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `tls--deal-platform-badges-trending-calculator` | TLS keystore (`badges-keystore.jks`) for mTLS to Kafka, Watson, and Bhuvan | GCP Secret Manager |
| `badges-keystore.jks` | PKCS12 keystore for mTLS (injected to `/var/groupon/badges-keystore.jks`) | GCP Secret Manager (via init script) |
| `truststore.jks` | JKS truststore for mTLS (injected to `/var/groupon/truststore.jks`) | GCP Secret Manager (via init script) |

> Secret values are never documented here. The init script `load-certificates-with-truststore.sh` on the Dataproc cluster handles injection.

## Per-Environment Overrides

- **local**: Uses `spark.master=local[8]`, points to local/staging Kafka brokers, no SSL on Kafka, Redis on `127.0.0.1:6379`.
- **staging (NA)**: Points to `kafka-grpn.us-central1.kafka.stable.gcp.groupondev.com:9094`, topic `janus-cloud-tier1`, Redis standalone mode on Memorystore staging instance; country whitelist is expanded to all supported markets.
- **prod (NA)**: Kafka on `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`, topic `janus-tier1`, Redis cluster mode, `prefix=bds3`, country whitelist `US,CA`.
- **emea-prod**: Kafka on `kafka-grpn-consumer.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094`, Watson points to EU edge proxy, expanded country whitelist for EMEA markets.
- **emea-staging**: Watson and Geo Service use EU staging edge proxies.
