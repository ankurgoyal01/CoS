---
service: "mirror-maker-kubernetes"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, config-files]
---

# Configuration

## Overview

Each deployed MirrorMaker pod is fully configured through environment variables injected by the Helm chart at deployment time. A two-layer configuration model is used: a `common.yml` provides shared defaults (image, log paths, resource baselines, health probes), and a per-component YAML file (e.g., `production-k8s-msk-janus-mirrors.yml`) overrides env vars, scaling, and resource requests for that specific mirror pair. Secrets (TLS certificates) are mounted from an external volume at `/var/groupon/certs`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SOURCE` | Kafka bootstrap server address for the source cluster | yes | none | helm per-component yaml |
| `DESTINATION` | Kafka bootstrap server address for the destination cluster | yes | none | helm per-component yaml |
| `WHITELIST` | Pipe-delimited list of source topic names to consume | yes | none | helm per-component yaml |
| `GROUPID` | Kafka consumer group ID for this mirror instance | yes | none | helm per-component yaml |
| `NUM_STREAMS` | Number of parallel MirrorMaker consumer threads | yes | none | helm per-component yaml (all set to `10`) |
| `COMPRESSION` | Producer compression codec | no | none | helm per-component yaml (all set to `snappy`) |
| `SOURCE_USE_MTLS` | Enable mTLS for source broker connection | no | `false` | helm per-component yaml |
| `DESTINATION_USE_MTLS` | Enable mTLS for destination broker connection | no | `false` | helm per-component yaml |
| `USE_DESTINATION_TOPIC_PREFIX` | Prepend `DESTINATION_TOPIC_PREFIX` to output topic names | no | `false` | helm per-component yaml |
| `DESTINATION_TOPIC_PREFIX` | Prefix string applied to destination topic names (e.g., `k8s`, `msk`, `gcp`) | no | none | helm per-component yaml |
| `DESTINATION_TOPIC_NAME` | Fixed destination topic name (Janus forwarder rename mode) | no | none | helm per-component yaml |
| `IS_JANUS_FORWARDER` | Activates Janus-specific message handler for topic rename/header manipulation | no | `false` | helm per-component yaml |
| `AUTO_OFFSET_RESET` | Consumer offset reset policy when no committed offset exists | no | `latest` | helm per-component yaml |
| `LINGER_MS` | Producer linger time in milliseconds before flushing batch | no | none | helm per-component yaml (set to `1000` for high-throughput mirrors) |
| `BATCH_SIZE` | Producer batch size in bytes | no | none | helm per-component yaml (e.g., `200000` or `10000`) |
| `MAX_REQUEST_SIZE` | Maximum producer request size in bytes | no | none | helm per-component yaml (e.g., `2097152`, `4194304`) |
| `KAFKA_HEAP_OPTS` | JVM heap settings for the MirrorMaker process | no | none | helm per-component yaml (e.g., `-Xmx2024M`) |
| `ACKS` | Producer acknowledgement mode | no | none | helm per-component yaml (e.g., `1`) |
| `CONFIG_FILE` | Path to the resolved per-component YAML config on the container filesystem | yes | none | helm per-component yaml |
| `TELEGRAF_URL` | InfluxDB endpoint for Telegraf metric output | yes | none | Helm chart injection |
| `JOLOKIA_PORT` | Port for the secondary Jolokia agent scrape (gauge metrics) | no | `8778` | helm config |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `IS_JANUS_FORWARDER` | Enables Janus-specific topic rename and header manipulation in the MirrorMaker message handler | `false` | per-deployment |
| `USE_DESTINATION_TOPIC_PREFIX` | Enables destination topic prefixing with `DESTINATION_TOPIC_PREFIX` value | `false` | per-deployment |
| `SOURCE_USE_MTLS` | Enables mTLS client certificate authentication for source broker | `false` | per-deployment |
| `DESTINATION_USE_MTLS` | Enables mTLS client certificate authentication for destination broker | `false` | per-deployment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/mirror-maker/common.yml` | YAML | Shared image, scaling, probe, log, and resource defaults for all mirror deployments |
| `.meta/deployment/cloud/components/mirror-maker/<region>/<env>/<component>.yml` | YAML | Per-component env var overrides, scaling, and resource limits |
| `/var/groupon/config/cloud/<component>.yml` | YAML | Runtime-resolved config file path referenced by `CONFIG_FILE` env var (mounted by Helm chart) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `/var/groupon/certs` (volume mount) | TLS client certificates and keys for mTLS connections to source and/or destination Kafka brokers | Kubernetes secret / volume (`client-certs` additional volume) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging** (`europe-west1`): One known deployment (`staging-logging-test-mirrors`) targets `kafka-staging` namespace brokers with `KAFKA_HEAP_OPTS=-Xmx2024M` and a logging-specific topic whitelist. Both source and destination use mTLS.
- **Production** (`eu-west-1`): Largest deployment footprint. Janus mirror components scale to min 10 / max 40 replicas. Resource limits range from 500Mi (low-volume) to 3Gi (Janus streams). LINGER_MS and BATCH_SIZE tuned to 1000ms / 200000 bytes for throughput-sensitive mirrors.
- **Production** (`europe-west1` GCP): GCP-sourced or GCP-destined mirrors. `cloudProvider: gcp` set in component YAML. Scale min 3 / max 5.
- **Production** (`us-central1` GCP): GCP NA region. Scale min 5 / max 10 for janus, min 1 for specialized topic forwarders (cdp-ingress, batch-dispatch).
- **Common**: All components use Snappy compression, Telegraf Jolokia scrape at 60s intervals, and Filebeat for log shipping.
