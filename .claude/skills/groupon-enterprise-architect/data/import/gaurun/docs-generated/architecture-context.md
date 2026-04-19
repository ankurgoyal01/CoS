---
service: "gaurun"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGaurunPushNotificationService"]
---

# Architecture Context

## System Context

Gaurun sits within the Continuum platform as a specialised push notification gateway. Internal notification producer services (e.g., email/push campaign engines) POST payloads to Gaurun's HTTP API. Gaurun then routes these through Kafka topics, dispatches them to Apple APNs and Google FCM, and emits delivery telemetry to Telegraf/InfluxDB. Logstash sidecars forward send and failure logs to the central Kafka cluster for downstream analytics. Gaurun does not own any persistent data store; it is a stateless routing and delivery layer backed by Kafka for durability.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Gaurun Push Notification Service | `continuumGaurunPushNotificationService` | API service | Go | 1.23 | Go-based push notification server that accepts HTTP requests, queues work via Kafka, and dispatches notifications to APNs and FCM |

## Components by Container

### Gaurun Push Notification Service (`continuumGaurunPushNotificationService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `gaurunHttpApi` | Handles push, retry, healthcheck, and configuration endpoints | net/http |
| `gaurunNotificationIngestor` | Validates and normalizes push requests into internal notification objects | Go |
| `gaurunQueueManager` | Creates per-context queues and manages notification buffering | Go channels |
| `gaurunPushWorkerManager` | Dispatches notifications to platform-specific push workers | Go goroutines |
| `gaurunApnsClient` | Sends iOS notifications to Apple APNs | HTTP/2 |
| `gaurunFcmClient` | Sends Android notifications to Google FCM | HTTP |
| `gaurunKafkaProducer` | Publishes queued notifications to Kafka topics | confluent-kafka-go v2 |
| `gaurunKafkaConsumer` | Consumes queued notifications from Kafka topics | confluent-kafka-go v2 |
| `gaurunRetryProcessor` | Schedules failed notifications for retry via `mta.gaurun.retry` topic | Go |
| `gaurunMetricsReporter` | Emits counter metrics to Telegraf/InfluxDB | InfluxDB client |
| `gaurunAccessLogger` | Writes access and error logs for notification processing | zap (go.uber.org/zap) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| Notification producer services | `continuumGaurunPushNotificationService` | Sends push requests via HTTP POST | HTTP/JSON |
| `gaurunHttpApi` | `gaurunNotificationIngestor` | Validates and normalizes requests | In-process |
| `gaurunHttpApi` | `gaurunAccessLogger` | Writes access logs | In-process |
| `gaurunNotificationIngestor` | `gaurunQueueManager` | Enqueues notifications to per-context channels | In-process |
| `gaurunQueueManager` | `gaurunKafkaProducer` | Publishes queued notifications to Kafka topics | confluent-kafka-go |
| `gaurunKafkaConsumer` | `gaurunQueueManager` | Consumes queued notifications from Kafka topics | confluent-kafka-go |
| `gaurunQueueManager` | `gaurunPushWorkerManager` | Dispatches queued work | Go channels |
| `gaurunPushWorkerManager` | `gaurunApnsClient` | Sends iOS notifications | HTTP/2 |
| `gaurunPushWorkerManager` | `gaurunFcmClient` | Sends Android notifications | HTTP |
| `gaurunPushWorkerManager` | `gaurunRetryProcessor` | Schedules retries for failed pushes | In-process |
| `gaurunPushWorkerManager` | `gaurunMetricsReporter` | Emits processing metrics | InfluxDB line protocol |
| `continuumGaurunPushNotificationService` | Apple APNs (`appleApns_7f1d6a`) | Sends iOS push notifications | HTTP/2 |
| `continuumGaurunPushNotificationService` | Google FCM (`googleFcm_9c4e1b`) | Sends Android push notifications | HTTP |
| `continuumGaurunPushNotificationService` | Kafka cluster (`kafkaCluster_2f6b9d`) | Publishes and consumes queued notifications; retry topic | Kafka (SSL) |
| `continuumGaurunPushNotificationService` | Telegraf/InfluxDB (`telegrafInfluxdb_3a8c2e`) | Writes delivery metrics | InfluxDB line protocol |

## Architecture Diagram References

- Container: `GaurunContainers`
- Component: `GaurunComponents`

> External dependency stubs (`appleApns_7f1d6a`, `googleFcm_9c4e1b`, `kafkaCluster_2f6b9d`, `telegrafInfluxdb_3a8c2e`, `notificationProducerService_4b2a5c`) are defined in `architecture/stubs.dsl` for local workspace validation. Cross-service relationships are commented out in `architecture/models/relations.dsl` pending federation into the central model.
