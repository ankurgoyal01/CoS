---
service: "gcp-prometheus"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

`gcp-prometheus` does not publish or consume application-level async events on a message bus. All metric data flows through synchronous Prometheus remote-write (HTTP) and Thanos Store API (gRPC) protocols. However, each Thanos and Grafana pod runs a Filebeat sidecar that ships container log lines to a Kafka cluster for centralized log aggregation. This is a one-directional infrastructure log-shipping flow, not application event publishing.

## Published Events

> No evidence found in codebase. This service does not publish application-level async events.

## Consumed Events

> No evidence found in codebase. This service does not consume application-level async events.

## Log Shipping via Filebeat (Infrastructure Only)

The following describes the Filebeat sidecar log-shipping behaviour present on all pods in the stack. This is not application event messaging but is documented for operational completeness.

| Destination Kafka Endpoint | Prefix | Environment |
|---------------------------|--------|-------------|
| `kafka-logging-kafka-bootstrap.kafka-production.svc.cluster.local:9093` | `logging_production_` | Production (Grafana) |
| MSK Kafka (staging) | — | Staging (Thanos components, `filebeatMsk: true`) |

- Filebeat collects logs from `/var/log` and `/var/lib/docker/containers` host paths.
- TLS certificates for Kafka are mounted from `telegraf--gateway--default-kafka-secret`.
- Filebeat identity certificates are mounted from `telegraf-production-tls-identity`.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present in this repository.
