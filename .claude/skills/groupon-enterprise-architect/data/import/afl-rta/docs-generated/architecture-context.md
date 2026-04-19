---
service: "afl-rta"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumAflRtaService, continuumAflRtaMySql]
---

# Architecture Context

## System Context

AFL RTA sits within the Continuum platform as a Kafka-consumer-driven attribution engine for the Affiliates domain. It is not externally reachable via HTTP from end users or other services; all inbound data arrives through the Kafka `janus-tier2` topic, which is produced and managed by the data-engineering Janus pipeline. Outbound flows go to the `continuumOrdersService` and `continuumMarketingDealService` (MDS) for enrichment, and attributed results are delivered to `messageBus` (MBus/JMS) for downstream partner channel processing, primarily Commission Junction via `afl-3pgw`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| AFL RTA Service | `continuumAflRtaService` | Service | Java, Dropwizard, Kafka Consumer | 1.0.x | Consumes Janus events, performs click and order attribution, stores audit data, and publishes attributed orders |
| AFL RTA MySQL | `continuumAflRtaMySql` | Database | MySQL | — | Persists click history, attribution tiers, and deduplicated attributed orders |

## Components by Container

### AFL RTA Service (`continuumAflRtaService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `RtaPollingConsumer` | Polls Janus events from Kafka and commits offsets | Kafka Consumer Loop |
| `EventProcessor` | Deserializes messages and dispatches to attribution strategies | Event Router |
| `ClickAttributionStrategy` | Performs click-level attribution for `externalReferrer` events | Attribution Strategy |
| `OrderAttributionStrategy` | Performs order-level attribution for `dealPurchase` events | Attribution Strategy |
| `ClicksService` | Handles click registration and click-history lookups | Domain Service |
| `OrderRegistrationFactory` | Builds channel-specific order registration handlers | Factory |
| `MBusOrderRegistration` | Publishes attributed orders to MBus | Outbound Adapter |
| `LoggingOrderRegistration` | Fallback registration path that logs and stores attributed orders | Outbound Adapter |
| `OrderService` | Resolves order details, enriches with MDS data, writes attributed orders | Domain Service |
| `OrdersApiService` | Gets customer status from Orders API | Outbound Service |
| `LegacyOrderIdResolver` | Resolves legacy numeric order IDs from Orders v1 | Order Resolver |
| `OrderUuidResolver` | Resolves UUID-based order IDs from Orders v2 | Order Resolver |
| `MDSHttpAdapter` | Fetches deal taxonomy and deal option details from MDS | Outbound Adapter |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAflRtaService` | `continuumJanusTier2Topic` | Consumes Janus click/order events | Kafka |
| `continuumAflRtaService` | `continuumAflRtaMySql` | Reads and writes clicks, orders, and attribution tiers | JDBC |
| `continuumAflRtaService` | `continuumOrdersService` | Fetches order and user order details | HTTPS/JSON |
| `continuumAflRtaService` | `continuumMarketingDealService` | Fetches deal taxonomy and option details | HTTPS/JSON |
| `continuumAflRtaService` | `messageBus` | Publishes attributed orders for partner channels | MBus/JMS |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-afl-rta-service-components`
- Dynamic — click attribution flow: `dynamic-afl-rta-click-aflRta_clickAttribution`
- Dynamic — order attribution flow: `dynamic-afl-rta-order-aflRta_clickAttribution`
