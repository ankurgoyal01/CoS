---
service: "epods"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumEpodsService, continuumEpodsPostgres, continuumEpodsRedis]
---

# Architecture Context

## System Context

EPODS sits within the **Continuum** platform as a dedicated integration gateway for third-party booking partners. It is called by internal Groupon services needing to interact with external booking systems (e.g., the Booking Tool, Orders service) and in turn calls partner APIs (MindBody, Booker, Square, Shopify, HBW, BT, VIS, PAMS). It also receives inbound partner webhooks and forwards translated events onto the Groupon internal message bus. EPODS owns its own PostgreSQL store for mapping and booking data, and uses Redis for caching and distributed locks.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| EPODS Service | `continuumEpodsService` | Service | Java, Dropwizard | JTier 5.13.2 | Translation layer between Groupon and third-party partners for bookings, transactions, and webhooks |
| EPODS Postgres | `continuumEpodsPostgres` | Database | PostgreSQL | — | Stores mappings, bookings, products, merchants, and units |
| EPODS Redis | `continuumEpodsRedis` | Cache | Redis | — | Caching and distributed locks |

## Components by Container

### EPODS Service (`continuumEpodsService`)

> No component definitions found in the architecture model. Component-level decomposition has not yet been recorded.

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Booking Resource | Handles v1/booking create, cancel, and get requests; delegates to partner clients | Dropwizard / REST |
| Availability Resource | Handles v1/availability queries; reads cached partner availability | Dropwizard / REST |
| Merchant / Product / Unit / Segment Resources | Serve entity-mapped data for merchants, products, units, and segments | Dropwizard / REST |
| Webhook Resource | Receives inbound partner webhooks at /webhook/* and routes to handlers | Dropwizard / REST |
| Partner Clients | Outbound HTTP clients to MindBody, Booker, Square, Shopify, HBW, BT, VIS, PAMS | jtier-retrofit / HTTP |
| Message Bus Publisher | Publishes AvailabilityUpdate, VoucherRedemption, BookingStatusChange events | jtier-messagebus-client / JMS/STOMP |
| Message Bus Consumer | Handles AvailabilityMessageHandler and VoucherMessageHandler events | jtier-messagebus-client / JMS/STOMP |
| Availability Sync Job | Scheduled Quartz job that polls partners for availability changes | jtier-quartz-bundle |
| Mapping Store | Reads and writes entity mappings between Groupon and partner IDs | jdbi3-core / JDBC |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumEpodsService` | `continuumEpodsPostgres` | Reads/Writes mappings, bookings, products, merchants, units | JDBC |
| `continuumEpodsService` | `continuumEpodsRedis` | Caches availability data; acquires distributed locks | Redis |
| `continuumEpodsService` | `messageBus` | Publishes and consumes booking, availability, and voucher events | JMS/STOMP |
| `continuumEpodsService` | `mindbodyApi` | Partner booking API calls (outbound) | HTTP |
| `continuumEpodsService` | `bookerApi` | Partner booking API calls (outbound) | HTTP |
| `continuumEpodsService` | `continuumDealCatalogService` | Deal lookup | HTTP |
| `continuumEpodsService` | `continuumCalendarService` | Booking sync | HTTP |
| `continuumEpodsService` | `continuumCfsService` | Custom fields lookup | HTTP |
| `continuumEpodsService` | `continuumPartnerService` | Partner configuration retrieval | HTTP |
| `continuumEpodsService` | `continuumMerchantApi` | Merchant data retrieval | HTTP |
| `continuumEpodsService` | `continuumOrdersService` | Orders read | HTTP |
| `continuumEpodsService` | `continuumIngestionService` | Ingestion pipeline push | HTTP |
| `mindbodyApi` | `continuumEpodsService` | Inbound partner webhooks | HTTP |

## Architecture Diagram References

- System context: `contexts-epods`
- Container: `containers-epods`
- Component: `components-epods`
