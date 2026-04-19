---
service: "glive-inventory-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 4
---

# Integrations

## Overview

GLive Inventory Service has a broad integration landscape with 4 external third-party ticketing providers and 4 internal Continuum platform services. External integrations are the core of the service's value -- bridging Groupon's commerce platform with Ticketmaster, AXS, Telecharge, and ProVenue for ticket inventory sourcing and fulfillment. Internal integrations provide reservation/purchase orchestration (GTX), accounting data (Accounting Service), email delivery (Mailman), and asynchronous event messaging (MessageBus). All external and internal HTTP integrations are managed through the `continuumGliveInventoryService_externalClients` component using Faraday, Clientable, and service_discovery_client.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Ticketmaster API | REST (HTTP/JSON) | Event, reservation, order, and export operations for Ticketmaster-sourced inventory | yes | `continuumTicketmasterApi` |
| AXS API | REST (HTTP/JSON) | Event, reservation, order, token, and timer operations via AXS v1/v2 OAuth APIs | yes | `continuumAxsApi` |
| Telecharge Partner | REST (HTTP/JSON) | Ticket purchases and reporting for Telecharge-sourced inventory | yes | `continuumTelechargePartner` |
| ProVenue Partner | REST (HTTP/JSON) | Ticketing operations for ProVenue-sourced inventory | yes | `continuumProvenuePartner` |

### Ticketmaster API Detail

- **Protocol**: REST (HTTP/JSON)
- **Base URL / SDK**: Configured via ticketmaster configuration (service discovery or static config)
- **Auth**: API key / partner credentials
- **Purpose**: Primary integration for Ticketmaster-sourced live-event tickets. Supports event discovery, seat/section availability queries, reservation creation and management, order placement and confirmation, and data exports for reporting.
- **Failure mode**: Ticketmaster-sourced reservations and purchases fail; cached availability data may become stale. Other provider flows unaffected.
- **Circuit breaker**: Managed via Faraday middleware and/or service_discovery_client retry policies

### AXS API Detail

- **Protocol**: REST (HTTP/JSON) with OAuth 2.0 for v2 endpoints
- **Base URL / SDK**: Configured via AXS configuration (service discovery or static config)
- **Auth**: OAuth 2.0 tokens (v2) / API credentials (v1)
- **Purpose**: Integration with AXS ticketing platform supporting event queries, reservation workflows, order placement, token management, and timer-based reservation expiry via both legacy v1 and modern v2 APIs.
- **Failure mode**: AXS-sourced reservations and purchases fail; cached availability may become stale. Other provider flows unaffected.
- **Circuit breaker**: Managed via Faraday middleware and/or service_discovery_client retry policies

### Telecharge Partner Detail

- **Protocol**: REST (HTTP/JSON)
- **Base URL / SDK**: Configured via telecharge configuration (service discovery or static config)
- **Auth**: Partner credentials
- **Purpose**: Integration for Telecharge-sourced ticket purchases and reporting. Used for completing orders and generating fulfillment reports.
- **Failure mode**: Telecharge-sourced ticket purchases fail; reporting data unavailable until recovery.
- **Circuit breaker**: Managed via Faraday middleware and/or service_discovery_client retry policies

### ProVenue Partner Detail

- **Protocol**: REST (HTTP/JSON)
- **Base URL / SDK**: Configured via provenue configuration (service discovery or static config)
- **Auth**: Partner credentials
- **Purpose**: Integration for ProVenue ticketing operations, enabling inventory sourcing and order fulfillment through the ProVenue platform.
- **Failure mode**: ProVenue-sourced ticketing operations fail; other provider flows unaffected.
- **Circuit breaker**: Managed via Faraday middleware and/or service_discovery_client retry policies

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GTX Service | REST (HTTP/JSON) | Creates reservations and purchases for third-party ticket inventory via GTX client | `continuumGtxService` |
| Accounting Service | REST (HTTP/JSON) | Requests invoice summaries and accounting data for merchant payment reports | `continuumAccountingService` |
| Mailman Service | REST (HTTP/JSON) | Sends transactional and reporting emails (payment reports, notifications) | `continuumMailmanService` |
| MessageBus | STOMP/JMS | Publishes and consumes inventory, GDPR, and configuration events | `messageBus` |

### GTX Service Detail

- **Protocol**: REST (HTTP/JSON)
- **Purpose**: GTX (Groupon Transaction) Service is the orchestration layer for creating reservations and completing purchases in the Continuum platform. GLive Inventory Service calls GTX to create ticket reservations and initiate purchase transactions against third-party inventory.
- **Architecture Ref**: `continuumGtxService`
- **Failure mode**: Reservation and purchase operations fail; inventory cannot be allocated to customer orders.

### Accounting Service Detail

- **Protocol**: REST (HTTP/JSON)
- **Purpose**: Provides invoice summaries and accounting data used by GLive Inventory Service to generate merchant payment reports (MerchantPaymentReportService).
- **Architecture Ref**: `continuumAccountingService`
- **Failure mode**: Merchant payment reports cannot be generated; existing reports and inventory operations unaffected.

### Mailman Service Detail

- **Protocol**: REST (HTTP/JSON)
- **Purpose**: Email delivery service used to send transactional emails (reservation confirmations, purchase receipts) and reporting emails (merchant payment reports) generated by GLive Inventory Service.
- **Architecture Ref**: `continuumMailmanService`
- **Failure mode**: Emails are not delivered; core inventory and reservation operations continue normally.

### MessageBus Detail

- **Protocol**: STOMP/JMS
- **Purpose**: Asynchronous event publishing and consumption. Both the main service and worker tier publish inventory state changes and consume GDPR and configuration events. Topic/queue configuration is defined in `messagebus.yml`.
- **Architecture Ref**: `messageBus`
- **Failure mode**: Event publishing fails; downstream consumers do not receive inventory updates. Inventory state in MySQL remains consistent. Consumed events (GDPR, config) are not processed until MessageBus recovers.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon Website | HTTP/JSON | Consumes inventory and availability APIs for customer-facing deal discovery and purchase flows |
| GLive Inventory Admin | HTTP/JSON | Consumes management APIs for operational workflows (product/event management, reporting) |
| Varnish HTTP Cache | HTTP | Routes and caches HTTP API traffic; receives PURGE requests for invalidation |

## Dependency Health

All HTTP integrations to external third-party providers and internal Continuum services are built using Faraday HTTP client with Clientable abstractions and service_discovery_client for service resolution. Health monitoring is provided through:

- **Steno Logger**: Structured logging of all external call successes, failures, and latencies
- **Sonoma Metrics**: Counter and timing metrics for each integration client
- **Elastic APM**: Distributed tracing across service boundaries for request-level visibility
- **Redis-based locking**: Prevents concurrent conflicting operations against external providers
- **Background job retries**: Resque/ActiveJob retry mechanisms for failed third-party calls in asynchronous workflows
