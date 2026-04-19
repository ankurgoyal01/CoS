---
service: "orders_mbus_client"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumOrdersMbusClient"
  containers: ["continuumOrdersMbusClient", "continuumOrdersMbusClientMessageStore"]
---

# Architecture Context

## System Context

Orders Mbus Client sits within the Continuum platform and acts as an event-routing worker between the Groupon Message Bus (`messageBus`) and the Orders service (`continuumOrdersService`). It does not expose a public-facing API; instead it is driven entirely by MBus topic subscriptions and Quartz-scheduled jobs. Outbound messages flow from the Orders service into this worker's MySQL store and are then forwarded to MBus. Inbound MBus events are translated into HTTP calls back into the Orders service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| orders_mbus_client worker | `continuumOrdersMbusClient` | Service | Java, Dropwizard | 2.1.x | Consumes and publishes MBus messages; coordinates order-side effects via HTTP |
| orders_mbus_client message store | `continuumOrdersMbusClientMessageStore` | Database | MySQL | — | Stores outbound and retryable messages with status and lock metadata |

## Components by Container

### orders_mbus_client (`continuumOrdersMbusClient`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Application Bootstrap | Initialises DB connection, Quartz scheduler, MbusPublisher, and ConsumerManager on startup | Dropwizard Application |
| Consumer Manager | Creates MBus readers and registers topic processor callbacks; starts single-thread consumer loop | JTier MessageConsumerGroup |
| Topic Processors | Transforms inbound message payloads into Orders API HTTP calls, one processor per topic | OkHttp / JTier MBus |
| Orders Client | HTTP client wrapper for all outbound calls to the Orders service endpoints | OkHttp3 |
| MBus Publisher | Fetches pending messages from MySQL, publishes to MBus, handles exponential-backoff retry scheduling | JTier messagebus Producer |
| Producer Pool | Resolves destination configs and manages reusable MBus producer instances | JTier ProducerPool |
| Message DAO | SQL Object interface for reading, locking, and updating `messages` table rows | JDBI / MySQL |
| Persisted Message Mapper | Maps JDBC result sets to `PersistedMessage` value objects | JDBI RowMapper |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOrdersMbusClient` | `continuumOrdersMbusClientMessageStore` | Reads and updates persisted message records | JDBI/MySQL |
| `continuumOrdersMbusClient` | `continuumOrdersService` | Calls order, billing, redaction, and merchant payment endpoints | HTTP/JSON |
| `continuumOrdersMbusClient` | `messageBus` | Publishes gift order events to `jms.topic.Order.Gift` | MBus/STOMP |
| `continuumOrdersMbusClient` | `messageBus` | Consumes payment update events from `jms.topic.payments.PaymentUpdate` | MBus |
| `continuumOrdersMbusClient` | `messageBus` | Consumes account erasure events from `jms.topic.gdpr.account.v1.erased` | MBus |
| `continuumOrdersMbusClient` | `messageBus` | Consumes bucks mirror sync messages from `jms.queue.UserRewardToBucksMirrorQueue` | MBus |
| `continuumOrdersMbusClient` | `messageBus` | Consumes VFM promotional adjustment events from `jms.topic.merchantPayments.inventoryProduct.promotionalAdjustmentsEnabled` | MBus |
| `continuumOrdersMbusClient` | `messageBus` | Consumes PayPal billing agreement deletion events from `jms.topic.BillingRecords.PaypalBillingAgreementEvents` | MBus |
| `continuumOrdersMbusClient` | `messageBus` | Consumes suspicious-behaviour events from `jms.topic.bemod.account.v1.suspiciousBehaviorDetected` | MBus |

## Architecture Diagram References

- System context: `contexts-continuumOrdersMbusClient`
- Container: `containers-continuumOrdersMbusClient`
- Component: `components-continuumOrdersMbusClient`
