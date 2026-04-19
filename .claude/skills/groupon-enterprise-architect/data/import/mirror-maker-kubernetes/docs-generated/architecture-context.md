---
service: "mirror-maker-kubernetes"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMirrorMakerService"]
---

# Architecture Context

## System Context

MirrorMaker Kubernetes lives within the `continuumSystem` (Continuum Platform), acting as an internal data-plane bridge between Kafka clusters. It does not serve external traffic or human users. Its sole consumers are other internal Groupon services that subscribe to mirrored topics on the destination cluster. The service connects to the `continuumKafkaBroker` (representing both source and destination Kafka clusters depending on replication direction) and emits operational telemetry to the shared `metricsStack` and `loggingStack`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MirrorMaker Service | `continuumMirrorMakerService` | Worker | Bash, Apache Kafka MirrorMaker, Java | Kafka-bundled | Containerized Kafka MirrorMaker runtime that consumes whitelisted topics from a source cluster and republishes to a destination cluster with optional topic transforms |

## Components by Container

### MirrorMaker Service (`continuumMirrorMakerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Environment Validator (`mirrorMaker_envValidator`) | Validates required and optional environment variables and applies defaults before startup | Bash |
| Config Writer (`mirrorMaker_configWriter`) | Builds producer, consumer, and MirrorMaker2 property files from resolved runtime settings | Bash |
| Security Bootstrap (`mirrorMaker_securityBootstrap`) | Creates keystores/truststores and appends SSL/TLS settings for source and destination brokers | OpenSSL, keytool |
| MirrorMaker Runtime Launcher (`mirrorMaker_runtimeLauncher`) | Executes kafka-mirror-maker with optional message handlers for topic rename/prefix/header handling | Apache Kafka MirrorMaker |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMirrorMakerService` | `continuumKafkaBroker` (source) | Consumes whitelisted topics from source cluster | Kafka (port 9093 mTLS or 9094 plaintext) |
| `continuumMirrorMakerService` | `continuumKafkaBroker` (destination) | Publishes replicated topics to destination cluster | Kafka (port 9093 mTLS or 9094 plaintext) |
| `continuumMirrorMakerService` | `metricsStack` | Emits JVM and replication metrics via Jolokia/Telegraf | HTTP (Jolokia port 8778) → InfluxDB |
| `continuumMirrorMakerService` | `loggingStack` | Emits runtime logs for aggregation | Filebeat sidecar |
| `mirrorMaker_envValidator` | `mirrorMaker_configWriter` | Passes validated runtime variables for properties generation | In-process (Bash) |
| `mirrorMaker_configWriter` | `mirrorMaker_securityBootstrap` | Provides producer/consumer/MM2 configs for secure startup | In-process (Bash) |
| `mirrorMaker_securityBootstrap` | `mirrorMaker_runtimeLauncher` | Provides security material and launches replication process | In-process (Bash) |

## Architecture Diagram References

- Component: `components-continuum-mirror-maker-service`
- Dynamic replication flow: `dynamic-mirror-maker-replication-flow`
