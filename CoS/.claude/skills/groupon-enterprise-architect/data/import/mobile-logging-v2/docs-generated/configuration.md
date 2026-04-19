---
service: "mobile-logging-v2"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secret]
---

# Configuration

## Overview

Mobile Logging V2 is configured through a combination of JTier YAML configuration files (mounted at runtime via `JTIER_RUN_CONFIG`), Helm chart values files (under `.meta/deployment/cloud/`), and a small set of container environment variables. Kafka TLS credentials are sourced from a Kubernetes-mounted volume at `/var/groupon/certs/`. There are no feature flags or external config stores (Consul/Vault) evidenced in the codebase.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML config file | yes | None | helm (`envVars` in environment yml) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent container OOM kills | no | `4` | helm (`common.yml`) |

### Per-environment values

| Variable | Staging value | Production value |
|----------|---------------|-----------------|
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found of feature flags in the codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Helm values: service ID, image, scaling, ports, resource requests, log config |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production overrides: GCP production cluster, VIP, CPU request, Filebeat volume type `high`, VPA enabled |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging overrides: GCP stable cluster, VIP, Filebeat volume type `low`, VPA enabled |
| `src/main/docker/Dockerfile` | Dockerfile | Container build; calls `kafka-tls.sh` at startup before launching JTier service |
| `src/main/docker/kafka-tls.sh` | Shell | Converts TLS cert/key from Kubernetes secret volume into a PKCS12/JKS keystore and builds a trust store from the Groupon Root CA |
| `doc/swagger/swagger.yaml` | YAML (OpenAPI 2.0) | OpenAPI specification for all exposed endpoints |

### JTier application configuration keys (from source code)

The JTier YAML config file (loaded via `JTIER_RUN_CONFIG`) must supply the following configuration blocks:

**`process` block** (`ProcessConfiguration`):

| Key | Type | Purpose | Example |
|-----|------|---------|---------|
| `networkPoolSize` | integer | Number of HTTP network threads | 8 |
| `decodePoolSize` | integer | Number of decode worker threads | 4 |
| `maxInFlightTasks` | integer | Maximum concurrent in-flight decode tasks | 100 |
| `bufferSize` | integer | Request body read buffer size | 65536 |
| `requestReadTimeout` | Duration | Timeout for reading request body | `5S` |
| `requestAcceptanceTimeout` | Duration | Timeout for accepting a new request | `0.05S` |
| `logTimeout` | Duration | Timeout for log processing | `1S` |
| `decodeTimeout` | Duration | Timeout for decode pipeline | `1S` |
| `replaceInfinity` | boolean | Whether to replace infinity float values during MessagePack decode | false |

**`kafkaConnectionConfig` block** (`KafkaConnectionConfig`):

| Key | Type | Purpose |
|-----|------|---------|
| `useTLS` | boolean | Enable TLS for Kafka connection |
| `useTrustStore` | boolean | Enable trust store validation |
| `certPath` | string | Path to the JKS keystore file |
| `trustStore` | string | Path to the trust store file |
| `password` | string | Keystore/truststore password |

**`kafkaProducer` block** (`KafkaProducerConfiguration`):

| Key | Type | Purpose |
|-----|------|---------|
| `broker` | string | Kafka bootstrap broker address |
| `topic` | string | Target topic name (e.g., `mobile_tracking`) |
| `clientId` | string | Kafka producer client identifier |
| `keySerializerClass` | string | Key serialiser class |
| `valueSerializerClass` | string | Value serialiser class (Loggernaut) |

**`kafkaEmeaProducer` block**: Same structure as `kafkaProducer`, used for EMEA region routing.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `tls.crt` / `tls.key` (volume `client-certs`) | Kafka mutual TLS client certificate and private key | Kubernetes secret, mounted at `/var/groupon/certs/` |
| Kafka keystore password | Used by `kafka-tls.sh` and `kafkaConnectionConfig.password` | JTier run config (file-based) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| `minReplicas` | 1 | 3 |
| `maxReplicas` | 2 | 20 |
| `cpus.main.request` | Default (common.yml: 1000m) | 2000m |
| `filebeat.volumeType` | `low` | `high` |
| `enableVPA` | true | true |
| Kubernetes namespace | `mobile-logging-staging` | `mobile-logging-production` |
| VIP | `mobile-logging.us-central1.conveyor.stable.gcp.groupondev.com` | `mobile-logging.us-central1.conveyor.prod.gcp.groupondev.com` |
