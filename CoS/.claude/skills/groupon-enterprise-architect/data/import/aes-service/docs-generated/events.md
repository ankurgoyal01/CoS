---
service: "aes-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

AES uses Groupon's internal MBus (message bus) exclusively as a consumer. It does not publish events. Two topic categories are consumed: account erasure events (GDPR) and consent events. Both feed the `aesMessagingConsumers` component, which persists effects to Postgres and coordinates removal from ad-network partner audiences.

## Published Events

> No evidence found in codebase of AES publishing any events to a message bus topic.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Erasure topic (MBus) | Account erasure / GDPR deletion | `aesMessagingConsumers` | Deletes customer from AES Postgres tables; removes customer from all partner ad-audiences; records erasure in denylist |
| Consent topic (MBus) | Consent update | `aesMessagingConsumers` | Persists consent state changes to Postgres; may trigger removal from active audiences based on consent withdrawal |

### Account Erasure Event Detail

- **Topic**: Erasure topic (MBus — exact topic name configured via `BaseMBusConfig` / YAML config, not hardcoded in source)
- **Handler**: `aesMessagingConsumers` component — persists deletion via `aesDataAccessLayer`, coordinates partner audience removal via `aesIntegrationClients`
- **Idempotency**: Not explicitly documented; erasure is destructive and expected to be idempotent by design (deleting a non-existent record is a no-op)
- **Error handling**: Operational procedures documented in `doc/TROUBLESHOOTING.md`; ELK log queries available for GDPR monitoring
- **Processing order**: Unordered

### Consent Event Detail

- **Topic**: Consent topic (MBus — exact topic name configured via `ConsentMBusConfig` / YAML config)
- **Handler**: `aesMessagingConsumers` component
- **Idempotency**: Not explicitly documented
- **Error handling**: Monitored via MBus Elk dashboard; `runConsentService` feature flag controls whether this consumer is active
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase of explicit DLQ configuration. Retry and error handling relies on MBus platform defaults and Grafana/ELK alerting.
