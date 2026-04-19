---
service: "ingestion-jtier"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

ingestion-jtier uses the Groupon Message Bus (mbus) exclusively for outbound async communication. It publishes three event types covering the ingestion lifecycle: feed extraction completion, individual offer ingestion, and operational status. No consumed events are visible in the service inventory — the service is event-publisher only; its work is driven by scheduled Quartz jobs and inbound REST API calls rather than incoming events.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| mbus | `FeedExtractionCompleteEvent` | Feed extraction job completes | partnerId, feedType, extractedAt, recordCount, status |
| mbus | `OfferIngestionEvent` | Single offer processed through ingestion pipeline | offerId, partnerId, dealId, action, processedAt |
| mbus | `IngestionOperationalEvent` | Operational milestone or error condition during ingestion run | eventType, partnerId, severity, message, timestamp |

### FeedExtractionCompleteEvent Detail

- **Topic**: `mbus` (topic name resolved at runtime via jtier-messagebus-client configuration)
- **Trigger**: Completion of a partner feed extraction run, whether initiated by Quartz schedule or `POST /ingest/v1/start`
- **Payload**: partnerId, feedType, extractedAt timestamp, recordCount, status (success/partial/failed)
- **Consumers**: Downstream pipeline consumers tracking ingestion health; no specific consumers confirmed from this inventory
- **Guarantees**: at-least-once (Message Bus delivery semantics)

### OfferIngestionEvent Detail

- **Topic**: `mbus` (topic name resolved at runtime via jtier-messagebus-client configuration)
- **Trigger**: Successful processing of a single offer through the ingestion pipeline (create, update, or delete action)
- **Payload**: offerId, partnerId, associated dealId (if created/updated), action type, processedAt timestamp
- **Consumers**: Deal catalog consumers and downstream systems tracking deal-offer mappings; no specific consumers confirmed from this inventory
- **Guarantees**: at-least-once

### IngestionOperationalEvent Detail

- **Topic**: `mbus` (topic name resolved at runtime via jtier-messagebus-client configuration)
- **Trigger**: Operational milestones (job start, job end) or error conditions (extraction failure, transformation error, deal creation failure) during any ingestion run
- **Payload**: eventType (START, END, ERROR), partnerId, severity, descriptive message, timestamp
- **Consumers**: Monitoring and alerting consumers; no specific consumers confirmed from this inventory
- **Guarantees**: at-least-once

## Consumed Events

> No evidence found of consumed event subscriptions. ingestion-jtier does not consume from any Message Bus topics; all inbound work is driven by Quartz schedules and REST API calls.

## Dead Letter Queues

> No evidence found of DLQ configuration in the service inventory. Dead letter handling deferred to Message Bus platform defaults.
