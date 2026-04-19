---
service: "emailsearch-dataloader"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

The Email Search Dataloader consumes events from the Groupon Kafka cluster (`externalKafkaCluster_3c9a`). The Kafka Event Processors component parses delivery, bounce, and unsubscribe events from the email platform. These events drive the core data pipeline: delivery events populate campaign performance state, bounce events update bounce configuration, and unsubscribe events trigger subscription changes via the Subscription Service. The service does not publish Kafka events itself; all outbound async communication is via HTTP webhooks (Slack/GChat notifications).

## Published Events

> No evidence found in codebase of this service publishing Kafka topics or other async messages. Outbound notifications are delivered synchronously via HTTP webhooks to Slack and Google Chat.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Kafka cluster (`externalKafkaCluster_3c9a`) | Email delivery events | `kafkaEventProcessors` → `emailSearchService` | Updates campaign performance state in Email Search Postgres |
| Kafka cluster (`externalKafkaCluster_3c9a`) | Email bounce events | `kafkaEventProcessors` → `bounceConfigService` | Updates bounce configuration data |
| Kafka cluster (`externalKafkaCluster_3c9a`) | Email unsubscribe events | `kafkaEventProcessors` → `unsubscriptionService` | Triggers unsubscription via Subscription Service; updates state in Postgres |

### Email Delivery Event Detail

- **Topic**: Kafka cluster topic (specific topic name configured via `KAFKA_ENDPOINT` and `kafka` config block at runtime; not hardcoded in source)
- **Handler**: `kafkaEventProcessors` component routes to `emailSearchService` for performance state updates
- **Idempotency**: Not documented in codebase
- **Error handling**: Not documented in codebase — standard Kafka consumer error behavior applies
- **Processing order**: Unordered (per-partition ordering preserved by Kafka)

### Email Unsubscribe Event Detail

- **Topic**: Kafka cluster topic (runtime-configured)
- **Handler**: `kafkaEventProcessors` component routes to `unsubscriptionService`, which calls the Subscription Service via Retrofit HTTP client
- **Idempotency**: Not documented in codebase
- **Error handling**: Not documented in codebase
- **Processing order**: Unordered

### Kafka TLS Configuration

The Kafka connection uses mutual TLS. At container startup, the `kafka-tls-v2.sh` script configures the TLS truststore and keystore from mounted certificate secrets (`emailsearch-dataloader-staging-tls-identity` in staging; production equivalent). The Kafka broker endpoint is configured via the `KAFKA_ENDPOINT` environment variable, e.g., `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`.

## Dead Letter Queues

> No evidence found in codebase of dead letter queue configuration.

## Parser Configuration

The service supports multiple configurable Kafka message parsers via the `parser` config list (`List<ParserConfig>` in `EmailSearchDataloaderConfiguration`). Each parser entry defines a separator and index for parsing message fields. Specific topic names, parser types, and field mappings are defined in the runtime YAML config files, not in source code.
