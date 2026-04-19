---
service: "janus-engine"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Janus Engine is configured primarily through environment variables and JTier-managed configuration files. The runtime mode (`KAFKA`, `MBUS`, `MBUS_RAW`, `REPLAY`, or `DLQ`) is a key startup parameter that determines which engine adapter `janusOrchestrator` activates. Kafka bootstrap addresses, MBus connection settings, and Janus metadata service endpoints are injected at deploy time. Secret values (credentials) are never documented here.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENGINE_MODE` | Selects the runtime mode: `KAFKA`, `MBUS`, `MBUS_RAW`, `REPLAY`, or `DLQ` | yes | — | env |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka cluster bootstrap address (e.g., `kafka.grpn.kafka.bootstrap.kafka.production.svc.cluster.local:9093`) | yes | — | env |
| `JANUS_METADATA_SERVICE_URL` | Base URL for the Janus metadata service (e.g., `janus.web.cloud.production.service`) | yes | — | env |
| `MBUS_TOPICS` | Comma-separated list of MBus topic/queue names to subscribe to | yes (MBUS/DLQ modes) | — | env |
| `JANUS_SINK_TOPICS` | Configuration for canonical sink topic routing (tier1/tier2/tier3/impression/email/raw) | yes | — | env |
| `LOG_LEVEL` | Application log level | no | INFO | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found

No feature flag system is evidenced in the architecture model. Behavioral variation is controlled by `ENGINE_MODE` at startup.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| JTier application config | YAML/properties | JTier framework configuration, including service identity, metrics, and health settings (managed by JTier 5.14.0 conventions) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| MBus credentials | Authentication for MBus topic subscriptions | > No evidence found — managed externally |
| Kafka credentials | Authentication for Kafka producer/consumer clients | > No evidence found — managed externally |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local Kafka and MBus brokers; Janus metadata service URL points to dev/staging instance; `ENGINE_MODE` set per test scenario.
- **Staging**: Staging Kafka cluster and MBus; reduced topic throughput.
- **Production**: Kafka production cluster (`kafka.grpn.kafka.bootstrap.kafka.production.svc.cluster.local:9093`); full MBus topic subscriptions; Janus metadata service at `janus.web.cloud.production.service`.

> Full per-environment configuration is managed externally (deployment manifests / Helm values). Details are not discoverable from the architecture DSL alone.
