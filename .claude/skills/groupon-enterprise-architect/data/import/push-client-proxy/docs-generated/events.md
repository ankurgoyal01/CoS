---
service: "push-client-proxy"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

push-client-proxy uses Apache Kafka as its primary async messaging system. It consumes two topics and publishes one topic. All Kafka connections use SSL/TLS with client-certificate authentication. The consumer group ID defaults to `push-client-proxy-group`. The service uses Spring Kafka's manual acknowledgment mode (`MANUAL_IMMEDIATE`) to ensure messages are only committed after successful processing.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `email-send-topic` | Email send retry | Failed SMTP send with retry budget remaining | `requestId`, `userId`, `emailMessage` (full JSON), retry count |

### Email Send Retry Detail

- **Topic**: `email-send-topic` (configurable via `kafka.topic.email-send`, default `email-send-topic`)
- **Trigger**: SMTP send fails inside `EmailSendMessageListener` and the `EmailSendRequest.canRetry()` check returns true
- **Payload**: Serialized `EmailSendRequest` JSON including `requestId` (used as Kafka message key), `userId`, `mailSenderKey`, retry count, and the original `EmailMessage`
- **Consumers**: `pcpKafkaEmailSendListener` (this same service consumes retries back)
- **Guarantees**: at-least-once (Kafka producer acks=1, 3 retries configured)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `msys_delivery` | Email delivery status (CSV) | `KafkaMessageListener.listenToMsysDelivery` | Looks up cached email metadata in Redis, builds delivery callback events, POSTs to downstream HTTP endpoint via `EmailApiTemplate` |
| `email-send-topic` | Email send request (JSON) | `EmailSendMessageListener.listenToEmailSendMessages` | Validates subscriptions, sends email via SMTP, persists `EmailSend` records to PostgreSQL, republishes retries |

### msys_delivery Detail

- **Topic**: `msys_delivery`
- **Consumer group**: `email-search-processor-group` (overrides default group)
- **Container factory**: `batchKafkaListenerContainerFactory` (batch listener, 1 record per poll)
- **Handler**: Parses CSV messages using `CsvFieldExtractor` to extract `sendId` and `userId`. Loads email metadata (`from`, `to`, `customData`, `requestId`) from Redis via `RedisUtil`. Builds delivery event and calls `EmailApiTemplate.sendEmail()` to POST callback.
- **Idempotency**: Non-idempotent — if Redis lookup fails or required fields are missing the message is acknowledged to avoid infinite retry; if processing throws an exception the message is not acknowledged and Kafka retries.
- **Error handling**: On CSV parse failure or missing Redis data, the message index is tracked as processed and acknowledged. On unhandled exceptions, acknowledgment is withheld so Kafka retries the batch.
- **Processing order**: Unordered (batch processing across up to 15 partitions)

### email-send-topic (consumed as inbound send requests) Detail

- **Topic**: `email-send-topic` (configurable via `kafka.topic.email-send`)
- **Consumer group**: `email-send-processor-group` (overrides default group)
- **Container factory**: `emailBatchKafkaListenerContainerFactory` (batch listener, 250 records per poll, 1 GB max fetch)
- **Handler**: Deserializes each message as `EmailMessage` JSON. Checks subscription state (skips non-US users without active subscriptions). Sends MIME email via the resolved `DefaultMailSender`. Persists batch `EmailSend` records to PostgreSQL. Republishes failed messages if retry budget allows.
- **Idempotency**: Non-idempotent — duplicate sends are possible on retry.
- **Error handling**: `JsonProcessingException` on deserialization causes acknowledgment without retry (malformed message). Unexpected errors cause acknowledgment (current implementation acknowledges on unknown exceptions to prevent consumer stall). Batch timeout of 30 seconds: if all futures do not complete within this window a `RuntimeException` is thrown and the batch is retried.
- **Processing order**: Unordered (messages within a batch processed concurrently via a 100-thread `ExecutorService`)

## Dead Letter Queues

> No evidence found in codebase. No DLQ topic configuration was detected. The KAFKA_CONSUMPTION_IMPROVEMENTS.md mentions a DLQ as a future optimization not yet implemented.
