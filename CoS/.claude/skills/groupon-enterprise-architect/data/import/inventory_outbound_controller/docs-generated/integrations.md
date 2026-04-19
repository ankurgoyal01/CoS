---
service: "inventory_outbound_controller"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 7
---

# Integrations

## Overview

inventory_outbound_controller has a broad integration footprint: three external dependencies (Landmark Global 3PL, Rocketman Email, Google Sheets) and seven internal Continuum service dependencies. All internal integrations use HTTP/REST. External integrations use HTTP. Async message bus integrations (consuming and publishing) are documented in [Events](events.md). The service also integrates with MySQL for persistence and the JMS message bus as a first-class runtime dependency.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Landmark Global 3PL | HTTP | Sends fulfillment instructions to the third-party logistics provider; receives shipment acknowledgements via message bus | yes | No Structurizr stub ID evidenced |
| Rocketman Email | HTTP | Sends transactional email notifications (e.g., shipment confirmation, cancellation) | yes | No Structurizr stub ID evidenced |
| Google Sheets | HTTP / Sheets API | Reads or writes fulfillment configuration or reporting data | no | No Structurizr stub ID evidenced |

### Landmark Global 3PL Detail

- **Protocol**: HTTP (outbound fulfillment instructions); inbound acknowledgements arrive via `jms.topic.goods.logistics.gateway.generic` message bus topic
- **Base URL / SDK**: No evidence found — managed via `outboundExternalServiceClients` using Play WS
- **Auth**: No evidence found
- **Purpose**: Physical fulfillment execution — receives pick/pack/ship instructions; notifies back when orders are shipped via the logistics gateway message bus topic
- **Failure mode**: Fulfillment instructions cannot be sent; shipments are delayed; retry jobs (`outboundSchedulingJobs`) are expected to handle transient failures
- **Circuit breaker**: No evidence found

### Rocketman Email Detail

- **Protocol**: HTTP
- **Base URL / SDK**: No evidence found — managed via `outboundExternalServiceClients`
- **Auth**: No evidence found
- **Purpose**: Delivers transactional email notifications to customers (e.g., order shipped, order cancelled)
- **Failure mode**: Email notifications not delivered; fulfillment operations continue unaffected; notifications may be retried
- **Circuit breaker**: No evidence found

### Google Sheets Detail

- **Protocol**: HTTP / Google Sheets API
- **Base URL / SDK**: No evidence found
- **Auth**: No evidence found (Google API credentials expected)
- **Purpose**: Fulfillment configuration or operational reporting data exchange; exact use case not fully confirmed from inventory
- **Failure mode**: Configuration reads/writes fail; expected non-critical path
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Inventory Service | HTTP / REST | Queries and updates inventory quantities and eligibility for fulfillment routing | `continuumInventoryService` |
| Goods Inventory Service | HTTP / REST | Reads goods-level inventory data for fulfillment decisions | `continuumGoodsInventoryService` |
| Orders Service | HTTP / REST | Reads order details for fulfillment processing; notified on cancellation | `continuumOrdersService` |
| Deal Catalog Service | HTTP / REST | Reads deal configuration and fulfillment deal config (routing rules, eligibility) | `continuumDealCatalogService` |
| Users Service | HTTP / REST | Reads user PII data for GDPR account erasure anonymization | `continuumUsersService` |
| Pricing Service | HTTP / REST | Reads pricing data for rate estimation queries | `continuumPricingService` |
| Message Bus (JMS) | JMS / mbus-client | Consumes inventory update, logistics gateway, shipment tracker, and GDPR events; publishes sales order, marketplace shipped, and GDPR complete events | `messageBus` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Orders Service | HTTP / REST | Triggers order cancellation via API endpoints |
| Internal admin tooling | HTTP / REST | Manages fulfillment state, schedules jobs, starts/stops consumers |
| Message Bus event producers | JMS | Publishes inventory update, logistics gateway, shipment tracker, and GDPR erasure events consumed by this service |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit circuit breakers, bulkheads, or retry policies on HTTP dependencies. Quartz-scheduled retry jobs (`outboundSchedulingJobs`) provide a scheduled retry mechanism for failed fulfillments, which partially compensates for transient downstream failures. JMS consumer start/stop admin endpoints allow manual intervention when message bus connectivity issues occur.
