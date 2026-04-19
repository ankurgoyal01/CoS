---
service: "janus-schema-inferrer"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

Janus Schema Inferrer has three outbound integrations: Kafka (message sampling), MBus (message sampling), and the Janus Metadata REST API (schema and sample persistence). All integrations are outbound — no external system calls into this service. The service has no inbound consumers beyond Kubernetes health probes.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka | Kafka protocol (TLS) | Samples raw messages from configured topics for schema inference | yes | `messageBus` |
| MBus | STOMP (port 61613) | Samples raw messages from configured MBus topics for schema inference | yes | `messageBus` |
| Janus Metadata Service | HTTP REST | Fetches mapping rules, source metadata, and MBus topic list; persists inferred schemas and raw sample messages | yes | `continuumJanusWebCloudService` |

### Kafka Detail

- **Protocol**: Kafka consumer protocol, TLS-secured (port 9093 GCP, port 9094 AWS)
- **Base URL / SDK**: `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093` (US prod), `kafka-grpn-consumer.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094` (EU prod)
- **Auth**: mTLS — `keyStoreFile: /var/groupon/jtier/kafka.client.keystore.jks`, `trustStoreFile: /var/groupon/jtier/truststore.jks`; env var `KAFKA_TLS_ENABLED=true` in production
- **Purpose**: Draw a sample of up to `sampleSize` (250 in production) raw messages from each configured topic per hourly run
- **Failure mode**: If Kafka is unreachable for a topic, that topic's sampling fails; `SMAMetrics.gaugeSchemaInferrerFailure(1)` is emitted; other topics continue processing
- **Circuit breaker**: No evidence found in codebase

### MBus Detail

- **Protocol**: STOMP over TCP (port 61613) via `mbus-client 1.5.2` + ZooKeeper-based dynamic server list (`curator-api 0.0.21`)
- **Base URL / SDK**: `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com:61613` (US prod)
- **Auth**: No explicit credential configuration visible in config files; dynamic server list via ZooKeeper
- **Purpose**: Draw a sample of up to `consumerSampleSize` (250 in production) messages from each configured MBus topic; MBus topic list can optionally be fetched dynamically from Janus via `GET /janus/api/v1/sources`
- **Failure mode**: If MBus is unreachable, the run fails; `SMAMetrics.gaugeSchemaInferrerFailure(1)` is emitted; CronJob restarts on failure (backoffLimit: 3–5)
- **Circuit breaker**: No evidence found in codebase

### Janus Metadata Service Detail

- **Protocol**: HTTP REST via `okhttp` (singleton `OkHttpClient`)
- **Base URL / SDK**: `http://janus-web-cloud.production.service` (US prod), `janus-web-cloud.production.service.us-central1.gcp.groupondev.com` (EU prod); configured via `janus.metadata.serverUrl`
- **Auth**: No authentication configured — internal service-to-service via Kubernetes service DNS
- **Purpose**:
  - `GET /janus/api/v1/sources` — retrieves MBus topic list (OLTP source names)
  - `GET` (via `RuleProviderUtil`) — fetches Janus mapping rules for event type extraction
  - `POST /janus/api/v1/persist/{rawEventName}` — persists inferred schema
  - `POST /janus/api/v1/source/{source}/raw_event/{event}/record/raw` — persists raw sample message
- **Failure mode**: If Janus is unreachable, `JanusSchemaInferrerRuntimeException` is thrown and the run aborts; CronJob retries per `cronjobRestartPolicy: OnFailure`
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumJanusWebCloudService` | HTTP REST | Schema metadata, mapping rules, and persistence target | `continuumJanusWebCloudService` |
| `messageBus` (Kafka + MBus) | Kafka / STOMP | Source of messages for schema sampling | `messageBus` |

## Consumed By

> No evidence found in codebase. Upstream consumers of this service are not tracked in this repository. This service is a CronJob — it is not called by any other service. Upstream consumers of the schemas it produces interact with `continuumJanusWebCloudService` (Janus Metadata service), not with this service directly.

## Dependency Health

- **Kafka**: No explicit health check; the CronJob's success/failure provides the signal via `SMAMetrics.gaugeSchemaInferrerFailure`
- **MBus**: Same pattern — CronJob failure metric acts as the health signal
- **Janus Metadata Service**: `JanusMetadataClient.initInstance()` eagerly fetches the writer schema at startup; failure at that point aborts the run before any sampling begins
- **Kubernetes probes**: Readiness uses `pgrep java`; liveness reads `/var/groupon/jtier/schema_inferrer_health.txt` (created by `HealthFlag` at startup, indicates the JVM is alive)
