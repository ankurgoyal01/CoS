---
service: "mobile-logging-v2"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

Mobile Logging V2 has three external platform dependencies: Kafka (primary data sink), the ELK logging stack (operational observability), and the Grafana/tsdaggr metrics stack. One internal dependency, `api-proxy`, acts as the upstream gateway routing mobile client requests to this service. The service is a downstream leaf from the mobile clients' perspective and an upstream producer from the Kafka consumers' perspective.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka (`messageBus`) | Kafka/TLS | Receives all normalised GRP telemetry events on topic `mobile_tracking` | yes | `messageBus` |
| ELK Logging Stack (`loggingStack`) | Log shipping (Filebeat) | Operational log aggregation; queryable via Kibana | no | `loggingStack` |
| Grafana / tsdaggr Metrics Stack (`metricsStack`) | tsdaggr (UDP/TCP) | Service health and per-event-type processing metrics | no | `metricsStack` |

### Kafka Detail

- **Protocol**: Kafka producer protocol over TLS (mutual TLS with JKS keystore)
- **Base URL / SDK**: `org.apache.kafka:kafka-clients:2.8.1`; broker address from `kafkaProducer.broker` config key
- **Auth**: TLS client certificate — cert/key mounted at `/var/groupon/certs/tls.crt` and `/var/groupon/certs/tls.key`, converted to JKS at container startup by `kafka-tls.sh`; truststore built from the Groupon Root CA
- **Purpose**: Primary event sink — every successfully decoded GRP event is serialised via `kafka-message-serde` (Loggernaut) and sent to the configured topic (default: `mobile_tracking`)
- **Failure mode**: Failed sends are logged as `KAFKA_SEND` log events and counted as `error` metrics outcomes. With `retries=1` and `acks=1`, a single retry is attempted before the event is dropped. If the broker is unavailable, events are lost (no local buffer or DLQ)
- **Circuit breaker**: No evidence found

### ELK Logging Stack Detail

- **Protocol**: Log file shipping via Filebeat sidecar (configured via `logConfig.sourceType: mobile_logging_server`)
- **Base URL / SDK**: `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/oEaTM`
- **Auth**: Internal cluster authentication
- **Purpose**: Operational log aggregation for debugging and alerting; log events include decode errors, encode errors, Kafka send events, and request-level debug info
- **Failure mode**: Logging is best-effort; loss of log shipping does not affect event processing
- **Circuit breaker**: Not applicable

### Grafana / Metrics Stack Detail

- **Protocol**: tsdaggr (JTier-standard metrics daemon)
- **Base URL / SDK**: `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/mobile-logging-v2/mobile-logging-v2`
- **Auth**: Internal cluster authentication
- **Purpose**: Tracks per-event-type counters (success, error, exception, processed, fail) and system health metrics (thread pool, JVM, HTTP request rates)
- **Failure mode**: Metrics loss does not affect event processing
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `api-proxy` | HTTP (upstream gateway) | Routes mobile client HTTP requests to this service; handles SSL termination and client IP forwarding via `true-client-ip` header | `api-proxy` (`.service.yml` dependency) |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| iOS Groupon app (legacy and MBNXT) | HTTP REST (`POST /v2/mobile/logs`) | Uploads batched GRP telemetry log files |
| Android Groupon app (legacy and MBNXT) | HTTP REST (`POST /v2/mobile/logs`) | Uploads batched GRP telemetry log files |
| Janus (data analytics pipeline) | Kafka consumer (`mobile_tracking`) | Reads and processes decoded GRP events for analytics |

> Upstream consumers are also tracked in the central architecture model at `continuumSystem`.

## Dependency Health

- **Kafka**: Checked via the Grafana dashboard — a "mobile-logging No events produced" Nagios alert fires if no events reach Kafka in a one-hour window (severity 4, routed to `sem-da-alerts`)
- **api-proxy**: If no HTTP requests arrive, the Grafana dashboard shows a drop in request rate; contact MBNXT team to verify no traffic shift has occurred
- Health check endpoint `GET /v2/mobile/health` returns service readiness; thread pool health is monitored via `ThreadPoolExecutorHealthCheck`
