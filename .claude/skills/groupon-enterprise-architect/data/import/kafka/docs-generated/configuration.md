---
service: "kafka"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars, helm-values]
---

# Configuration

## Overview

Kafka components are configured primarily through Java properties files (`server.properties`, `connect-distributed.properties`, etc.) supplied at container startup. In Kubernetes deployments, these files are typically rendered from Helm values or ConfigMaps. Environment variables are used to set JVM options and to pass secrets (SSL/SASL credentials) into the container without embedding them in config files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KAFKA_HEAP_OPTS` | JVM heap size for the broker process (e.g., `-Xmx6g -Xms6g`) | yes | `-Xmx1g -Xms1g` | env / helm |
| `KAFKA_JVM_PERFORMANCE_OPTS` | Additional JVM GC and performance flags | no | G1GC defaults | env / helm |
| `KAFKA_LOG4J_OPTS` | log4j2 configuration file override | no | bundled `log4j2.yaml` | env |
| `KAFKA_OPTS` | Additional JVM `-D` system properties passed to broker | no | — | env / helm |
| `KAFKA_SSL_KEYSTORE_PASSWORD` | Password for the broker's TLS keystore | yes (if TLS enabled) | — | vault / k8s-secret |
| `KAFKA_SSL_TRUSTSTORE_PASSWORD` | Password for the broker's TLS truststore | yes (if TLS enabled) | — | vault / k8s-secret |
| `KAFKA_SSL_KEY_PASSWORD` | Private key password within the keystore | yes (if TLS enabled) | — | vault / k8s-secret |
| `CONNECT_HEAP_OPTS` | JVM heap size for the Kafka Connect worker | no | `-Xmx2g` | env / helm |
| `TROGDOR_AGENT_PORT` | TCP port the Trogdor agent REST API listens on | no | `8888` | env |
| `TROGDOR_COORDINATOR_PORT` | TCP port the Trogdor coordinator REST API listens on | no | `8765` | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `auto.create.topics.enable` | Allows clients to create topics implicitly on first produce/fetch | `true` | global |
| `delete.topic.enable` | Permits topic deletion via the admin API | `true` | global |
| `log.message.format.version` | Controls the record format version advertised to clients | current Kafka version | global |
| `inter.broker.protocol.version` | Protocol version used for inter-broker communication; set during rolling upgrades | current Kafka version | global |
| `transaction.state.log.replication.factor` | Replication factor for the internal `__transaction_state` topic | `3` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/server.properties` | Java properties | Primary broker configuration — listeners, log dirs, replication factors, retention, quotas |
| `config/controller.properties` | Java properties | KRaft controller process configuration — quorum voters, metadata log dir |
| `config/connect-distributed.properties` | Java properties | Kafka Connect worker configuration — bootstrap servers, group ID, offset/config/status topic names |
| `config/trogdor.conf` | JSON | Trogdor coordinator and agent node topology definition |
| `config/log4j2.yaml` | YAML | log4j2 appender and logger configuration for all Kafka processes |
| `config/tools-log4j.properties` | Java properties | Logger configuration for CLI tools and admin scripts |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `kafka-broker-keystore` | TLS keystore for broker mTLS listener | k8s-secret / vault |
| `kafka-broker-truststore` | TLS truststore for broker mTLS listener | k8s-secret / vault |
| `kafka-sasl-jaas-config` | JAAS configuration for SASL authentication (SCRAM or GSSAPI) | k8s-secret / vault |
| `connect-worker-ssl-keystore` | TLS keystore for Connect worker's connection to brokers | k8s-secret / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development / local**: Brokers typically run with a single-node cluster (`replication.factor=1`), `auto.create.topics.enable=true`, no TLS, and reduced retention (`log.retention.hours=24`). The Docker image (`eclipse-temurin:21-jre-alpine`) is used directly with a mounted `server.properties`.
- **Staging**: Multi-broker cluster with replication factor 2–3. TLS enabled. Retention policies mirror production at reduced scale. KRaft controller quorum of 3 nodes.
- **Production**: Full multi-broker cluster with replication factor 3, `min.insync.replicas=2`, TLS + SASL enforced on all listeners, per-client quotas configured, and 7-day default retention. KRaft controller quorum of 3–5 nodes deployed as a Kubernetes StatefulSet.
