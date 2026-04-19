---
service: "appointment_engine"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 10
---

# Integrations

## Overview

The appointment engine integrates with 11 services: 1 external (EMEA BTOS) and 10 internal Continuum services. Integrations are a mix of synchronous REST calls (via `api_clients 2.0.1`) and asynchronous Message Bus events (via `messagebus 0.5.2`). The service is deeply integrated with the broader Groupon booking ecosystem — Availability Engine, Deal Catalog, Orders Service, Voucher Inventory, and notification services are all critical dependencies.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| EMEA BTOS (Booking Tool for Online Services) | REST | EMEA-specific merchant booking management integration | no | > No evidence found in codebase. |

### EMEA BTOS Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Internal EMEA BTOS service endpoint
- **Auth**: > No evidence found in codebase.
- **Purpose**: Integrates appointment management with EMEA merchant booking tooling for markets using BTOS
- **Failure mode**: EMEA booking tool interactions fail; EMEA merchants cannot manage appointments via BTOS
- **Circuit breaker**: > No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Availability Engine | REST + Message Bus | Queries availability slots; consumes availability events | > No evidence found in codebase. |
| Deal Catalog | REST | Fetches deal and option metadata for reservation validation | > No evidence found in codebase. |
| Orders Service | REST + Message Bus | Reads order/voucher state; consumes order status change events | > No evidence found in codebase. |
| Voucher Inventory Service | Message Bus | Consumes inventory unit updated events to sync appointment state | > No evidence found in codebase. |
| M3 Merchant / Places | REST | Resolves merchant and location data for appointments | > No evidence found in codebase. |
| Users Service | REST | Resolves consumer identity for reservation creation | > No evidence found in codebase. |
| Calendar Service | REST | Coordinates appointment scheduling with merchant calendar | > No evidence found in codebase. |
| Online Booking Notifications | REST | Triggers consumer and merchant appointment notifications | > No evidence found in codebase. |
| API Lazlo | REST | Internal API gateway / routing layer | > No evidence found in codebase. |
| Message Bus | JMS/mbus | Publishes appointment lifecycle events; consumes external events | > No evidence found in codebase. |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known upstream consumers include:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon Deal Page (dealWebApp) | REST | Consumer books appointments via deal page booking UI |
| Merchant Booking Management Tool | REST | Merchants confirm/decline/reschedule appointments |
| EMEA BTOS | REST | EMEA-specific merchant booking management |

## Dependency Health

- `api_clients 2.0.1` is used for all internal REST calls; retry and timeout behavior is governed by this library.
- Message Bus consumers (Resque workers) retry failed event processing jobs.
- If the Availability Engine is unavailable, reservation requests cannot be validated against availability — reservation creation may fail.
- If the Online Booking Notifications service is unavailable, appointment notifications are not sent; Resque will retry the notification job.
- If the Orders Service / Voucher Inventory Service is unavailable, appointment state synchronization may be delayed (events will be reprocessed when the dependency recovers).
