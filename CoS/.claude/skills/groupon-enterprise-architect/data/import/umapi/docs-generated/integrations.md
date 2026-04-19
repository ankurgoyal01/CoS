---
service: "umapi"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

UMAPI is one of the most heavily consumed services in the Continuum ecosystem. It has **1 known outbound dependency** (Message Bus) and is consumed by **15+ upstream services** spanning merchant UIs, backend integration tiers, reporting pipelines, and the Encore next-gen platform. No external (third-party) dependencies are defined in the architecture model.

## External Dependencies

> No evidence found in codebase. No external system dependencies are defined in the UMAPI architecture module or in the central relationship model.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Message Bus (ActiveMQ Artemis) | Async | Publishes and consumes merchant-related events | `messageBus` |

### Message Bus Detail

- **Protocol**: Async (ActiveMQ Artemis)
- **Base URL / SDK**: Internal messaging infrastructure
- **Auth**: Internal service credentials (inferred)
- **Purpose**: Asynchronous event publishing and consumption for merchant lifecycle events
- **Failure mode**: Event delivery delayed or lost; merchant state changes may not propagate to downstream consumers
- **Circuit breaker**: Not documented

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| API Proxy (edge gateway) | JSON/HTTPS | Routes external merchant operations to UMAPI |
| Merchant Center Web | HTTPS/JSON | Calls merchant auth, account, deals, vouchers, reporting, and inbox APIs |
| Mobile Flutter Merchant App | HTTPS (inferred) | Calls merchant APIs for dashboard, deals, vouchers, and account workflows |
| Marketing Deal Service | HTTP | Syncs merchant profile and contact data |
| AI Reporting Service | HTTPS/JSON | Authenticates or looks up users |
| Bookability Dashboard | HTTPS (inferred) | Uses internal OAuth redirect and token endpoints for login |
| Mailman | HTTP/JSON | Fetches merchant and location data |
| Minos | HTTPS (inferred) | Reads merchant details for deduplication |
| Merchant Page Service | HTTPS/JSON | Reads merchant and place data (e.g., place by slug) |
| Merchant Booking Tool | HTTPS/JSON | Reads and writes booking-service data via merchant API clients and proxy endpoints |
| Sponsored Campaign iTier | HTTP | Proxies campaign, billing, and performance operations |
| LS Voucher Archive iTier | HTTPS/JSON | Uses merchant API request module |
| 3PIP Merchant Onboarding iTier | HTTPS/JSON | Reads and updates 3PIP merchant mapping, auth, and onboarding state |
| Merchant Service (M3) | HTTPS (inferred) | Synchronizes merchant/place data via M3SyncClient |
| Encore UMAPI Wrapper | HTTPS (inferred) | Wraps UMAPI for the Encore next-gen platform |

## Dependency Health

> No evidence found in codebase. Health check, retry, and circuit breaker patterns for dependencies are not documented in the architecture model.
