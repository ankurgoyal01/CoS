---
service: "travel-inventory"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 5
---

# Integrations

## Overview

Getaways Inventory Service has one external dependency (AWS SFTP Transfer for daily report export) and five active internal Continuum service dependencies. All outbound HTTP calls use the External HTTP Clients component (Jersey Client abstractions). The service also integrates with the Groupon message bus (MBus over JMS/STOMP) for async event publishing and consumption. The Forex Service integration is managed via a dedicated Forex Client component.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS SFTP Transfer | SFTP | Daily inventory report CSV file export for downstream consumption | no | `continuumAwsSftpTransfer` |

### AWS SFTP Transfer Detail

- **Protocol**: SFTP over SSH
- **Base URL / SDK**: AWS-managed SFTP endpoint; hostname and credentials managed by environment configuration
- **Auth**: SSH key-based authentication (managed via secrets)
- **Purpose**: The Worker Domain generates daily inventory report CSV files and the AWS SFTP Client transfers them to this managed endpoint. Downstream finance and reporting consumers pull files from this location.
- **Failure mode**: If SFTP is unavailable, the daily report transfer fails; report generation state is tracked in the database and can be retried. Shopping and Extranet operations are unaffected.
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Getaways Content Service | HTTP, JSON | Retrieves hotel contact details and localized content for inventory responses | `continuumContentService` |
| Backpack Reservation Service | HTTP, JSON, MBus | Sends reservation and cancel events; interacts with asynchronous reservation workflows | `continuumBackpackReservationService` |
| Voucher Inventory Service | HTTP, JSON | Requests voucher-based inventory product information during availability and booking flows | `continuumVoucherInventoryService` |
| Forex Service | HTTP | Fetches foreign exchange rates for multi-currency pricing | Resolved via `forex-ng` alias in central workspace |
| Message Bus | MBus over JMS/STOMP | Publishes reservation/cancel events; consumes order status and worker task messages | `messageBus` |

### Getaways Content Service Detail

- **Protocol**: HTTP, JSON
- **Base URL / SDK**: Configured via Configuration & Environment component; base URL managed per environment
- **Auth**: Internal service-to-service authentication
- **Purpose**: Provides hotel contact details and localized content (descriptions, amenities, images metadata) that are embedded in inventory API responses
- **Failure mode**: If Content Service is unavailable, inventory responses may lack content enrichment; core inventory data remains accessible
- **Circuit breaker**: No evidence found; consult service owner

### Backpack Reservation Service Detail

- **Protocol**: HTTP, JSON, MBus
- **Base URL / SDK**: Configured via Configuration & Environment component; base URL and MBus destinations managed per environment
- **Auth**: Internal service-to-service authentication
- **Purpose**: Receives reservation creation and cancellation events from Getaways Inventory; exposes reservation APIs for itinerary and booking state management. The Shopping Domain calls Backpack synchronously for availability queries and asynchronously for reservation lifecycle events.
- **Failure mode**: If Backpack is unavailable, reservation creation and cancellation may fail or be delayed; availability queries fall back to cached results in the Backpack Availability Cache
- **Circuit breaker**: No evidence found; availability cache provides partial resilience

### Voucher Inventory Service Detail

- **Protocol**: HTTP, JSON
- **Base URL / SDK**: Configured via External HTTP Clients component
- **Auth**: Internal service-to-service authentication
- **Purpose**: Provides voucher-based inventory product information used during availability checks and booking flows where Getaways products have a voucher component
- **Failure mode**: If Voucher Inventory Service is unavailable, voucher-dependent availability checks may fail; non-voucher flows are unaffected
- **Circuit breaker**: No evidence found

### Forex Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Configured via dedicated Forex Client component; host and path managed per environment
- **Auth**: Internal service-to-service authentication
- **Purpose**: Provides foreign exchange rates used by the Shopping Domain for multi-currency pricing calculations
- **Failure mode**: If Forex Service is unavailable, multi-currency pricing may fail or fall back to cached rates
- **Circuit breaker**: No evidence found

### Message Bus Detail

- **Protocol**: MBus over JMS/STOMP
- **Base URL / SDK**: Broker endpoints and destinations configured via Configuration & Environment component
- **Auth**: Managed via broker credentials in environment configuration
- **Purpose**: Central async messaging infrastructure. The service publishes reservation and cancel events consumed by Backpack and other downstream services, and consumes order status and worker task messages.
- **Failure mode**: If the message bus is unavailable, async event delivery is disrupted; reservation and cancel events may be delayed; order status updates are not received until bus recovers
- **Circuit breaker**: No evidence found; MBus provides built-in retry mechanisms

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include Getaways Extranet UI, consumer shopping services, channel managers (via Connect API), and OTA partners (via OTA Update API).

## Dependency Health

- All synchronous HTTP dependencies are called via the External HTTP Clients component and Forex Client, which provide configurable timeouts and base URLs per environment.
- The Backpack Availability Cache (Memcached) provides a resilience layer for Backpack availability queries -- cached results can be served when the live Backpack service is slow or unavailable.
- MBus provides built-in retry mechanisms for async message delivery; the Message Bus Integration component logs failures via Metrics & Logging.
- No explicit circuit breaker pattern is evidenced in the federated model; consult service owner for runtime configuration of resilience patterns.
