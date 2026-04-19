---
service: "deal-catalog-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["mbus"]
---

# Events

## Overview

The Deal Catalog Service publishes deal lifecycle events to Groupon's Message Bus (MBus). These events notify downstream consumers -- such as the Marketing Deal Service and other platform services -- about deal creation, updates, and state changes. The service uses an internal Message Publisher component (`dealCatalog_messagePublisher`) implemented as an MBus Producer. Events are triggered by merchandising operations within the Merchandising Service and by scheduled Node Payload Fetcher jobs.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBus (deal lifecycle) | Deal Created | New deal metadata registered via Catalog API | Deal ID, title, category, availability, merchandising attributes |
| MBus (deal lifecycle) | Deal Updated | Deal metadata modified via Catalog API or merchandising rules | Deal ID, changed fields, updated timestamp |
| MBus (deal lifecycle) | Deal Snapshot | Merchandising Service publishes full deal state | Deal ID, full deal metadata snapshot |
| MBus (node payload) | Node Payload Updated | Node Payload Fetcher completes scheduled refresh | Node ID, payload metadata, refresh timestamp |

### Deal Created / Updated Detail

- **Topic**: MBus deal lifecycle topic (exact topic name managed in service configuration)
- **Trigger**: Salesforce pushes deal metadata to Catalog API, or Deal Management API registers new deal metadata. The Merchandising Service processes the change and delegates to the Message Publisher.
- **Payload**: Deal ID, title, category, availability window, merchandising attributes, timestamps
- **Consumers**: Marketing Deal Service (`continuumMarketingDealService`), and other downstream MBus subscribers
- **Guarantees**: at-least-once (MBus default)

### Node Payload Updated Detail

- **Topic**: MBus node payload topic (exact topic name managed in service configuration)
- **Trigger**: The Node Payload Fetcher (`dealCatalog_nodePayloadFetcher`) runs on a Quartz schedule, fetches remote node payloads, updates node state in the repository, and emits update events via the Message Publisher.
- **Payload**: Node ID, payload metadata, refresh status, timestamp
- **Consumers**: Downstream services subscribed to node payload updates
- **Guarantees**: at-least-once (MBus default)

## Consumed Events

> No evidence found in codebase of the Deal Catalog Service consuming events from external topics. The service primarily acts as an event producer. If event consumption exists, it is not modeled in the current architecture DSL.

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration for MBus topics is typically managed at the MBus infrastructure level.

## Event Flow Summary

```
Salesforce / Deal Management API
        |
        v
  [Catalog API] --> [Merchandising Service] --> [Message Publisher] --> MBus
                                                                          |
                                                                          v
                                                              Marketing Deal Service
                                                              (and other subscribers)

  [Node Payload Fetcher (Quartz)] --> [Repository] --> [Message Publisher] --> MBus
```
