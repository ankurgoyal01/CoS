---
service: "merchant-booking-tool"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Merchant Booking Tool.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Primary Booking Data Flow](primary-booking-data-flow.md) | synchronous | Merchant page request | Routing layer reads booking data from Merchant API and composes Preact page for the merchant |
| [Proxy Write Flow](proxy-write-flow.md) | synchronous | Merchant write/update action | Routing layer proxies booking write and update operations through to the upstream booking service |
| [Google Calendar Sync Auth Flow](google-calendar-sync-auth-flow.md) | synchronous | Merchant initiates calendar connection | Routes Google OAuth 2.0 authorization to authenticate merchant calendar sync |
| [Inbenta Support Auth Flow](inbenta-support-auth-flow.md) | synchronous | Merchant opens support panel | Inbenta Support Client generates support authentication tokens for embedded knowledge base |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The primary booking data flow and proxy write flow span the Merchant Booking Tool and the `continuumUniversalMerchantApi`. The layout rendering step spans the `continuumLayoutService`. These are captured in the architecture dynamic view `dynamic-merchant-booking-primary-flow`.

- Architecture dynamic view: `dynamic-merchant-booking-primary-flow`
- See [Architecture Context](../architecture-context.md) for full relationship map
