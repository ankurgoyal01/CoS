---
service: "global_subscription_service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, kafka]
---

# Events

## Overview

The Global Subscription Service uses two async messaging systems: MBus (Groupon's internal message bus, via `jtier-messagebus-client`) and Kafka (TLS-secured cluster). The service both publishes subscription and GDPR state-change events and consumes several inbound MBus event streams that trigger automatic subscription management. In batch mode (env var `BATCH=true`), connections to MBus and Kafka are skipped — the batch component is used exclusively for email subscription calculations.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBus (subscription channel) | Subscription change event | SMS consent created, updated, or removed | consumer_id, phone_number, consent_type, country_code, locale, operation |
| MBus (subscription channel) | GDPR unsubscribe event | Bulk or per-type consent removal for consumer or phone | consumer_id / phone_number, country_code, scope |
| Kafka (push token topic) | Push token create event | New push device token registered | device_token, consumer_id, app_type, country_code, status |
| Kafka (push token topic) | Push token update event | Push device token updated (status or metadata change) | device_token, consumer_id, app_type, country_code, status |

### Subscription Change Event Detail

- **Topic**: MBus subscription channel (configured via `mbus` in service config)
- **Trigger**: SMS consent created, updated, or removed via Consent API
- **Payload**: consumer_id, phone_number, consent_type UUID, country_code, locale, operation type (CREATE / UPDATE / DELETE)
- **Consumers**: Downstream notification routing, Rocketman SMS, regulatory audit
- **Guarantees**: at-least-once (MBus delivery semantics)

### GDPR Unsubscribe Event Detail

- **Topic**: MBus subscription channel
- **Trigger**: `DELETE /scs/v1.0/consent/consumer/{id}/consent_type/all` or phone-level bulk delete
- **Payload**: consumer_id or phone_number, country_code, unsubscribe scope
- **Consumers**: Regulatory consent log (regulatory-consent-log service), downstream systems that cache consent state
- **Guarantees**: at-least-once

### Push Token Create / Update Event Detail

- **Topic**: Kafka push token topic (endpoint configured via `KAFKA_ENDPOINT` env var; TLS via `kafka-tls-v2.sh`)
- **Trigger**: `POST /push-token/device-token` (create) or `PUT /push-token/device-token/{token}` (update)
- **Payload**: device_token, consumer_id, app_type (consumer / enterprise / asia_consumer), country_code, status (active / activating / inactive / failed)
- **Consumers**: Push notification routing services
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus travellers topic | Travellers subscription event | `mbusTravellersConfiguration` consumer | Auto-subscribes travellers to relevant SMS lists |
| MBus auto-sub topic | Auto-subscription event | `mbusAutosubConfiguration` consumer | Automatically subscribes consumers to configured lists |
| MBus location-sub topic | Location subscription event | `mbusLocationSubConfiguration` consumer | Subscribes consumers based on location signals |
| MBus RTF topic | RTF subscription event | `mbusRtfConfiguration` consumer | Manages RTF-triggered subscription changes |
| MBus data migration topic | Data migration event | `mbusDataMigrationConfiguration` consumer | Drives push token Cassandra-to-Postgres data migration |
| Kafka PTS topic | Push token system event | `ptsKafkaConfiguration` consumer | Processes push token system events for push subscription management |

### Travellers Subscription Event Detail

- **Topic**: MBus travellers topic (configured via `mbusTravellersConfiguration`)
- **Handler**: Subscription manager processes the event to enroll consumer in traveller-specific SMS lists
- **Idempotency**: Checked via existing consent lookup before insert
- **Error handling**: MBus client retry with error logging
- **Processing order**: Unordered

### Data Migration Event Detail

- **Topic**: MBus data migration topic (configured via `mbusDataMigrationConfiguration`)
- **Handler**: Reads push token record from Cassandra and writes to Postgres
- **Idempotency**: Upsert pattern on push token key
- **Error handling**: Logged and tracked; manual replay available via `/push-subscription/migration/{token}`
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase. Dead letter queue configuration is managed by the MBus platform; service-level DLQ names are not defined in this repository.
