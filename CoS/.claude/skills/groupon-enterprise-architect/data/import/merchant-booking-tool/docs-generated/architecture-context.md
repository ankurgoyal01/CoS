---
service: "merchant-booking-tool"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMerchantBookingTool]
---

# Architecture Context

## System Context

The Merchant Booking Tool is a container within the `continuumSystem` (Continuum Platform), Groupon's core commerce engine. It sits at the merchant-facing edge of the booking domain: merchants interact with it directly via web and mobile web browsers, and the tool orchestrates downstream calls to the Universal Merchant API booking service. It delegates layout rendering to the `continuumLayoutService` and authenticates Google Calendar sync flows through `googleOAuth`. Embedded support flows are authenticated via Inbenta (noted in the DSL as not currently in the federated model).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Booking Tool | `continuumMerchantBookingTool` | WebApp / Service | Node.js, Preact, I-tier | — | I-tier web application serving merchant booking and reservation management pages, plus proxy/auth helper endpoints |

## Components by Container

### Merchant Booking Tool (`continuumMerchantBookingTool`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Routing and Page Composition (`mbtWebRoutes`) | Defines OpenAPI routes, renders Preact pages, and orchestrates server-side action handlers | Node.js Action Handlers |
| Merchant API Client Adapter (`mbtMerchantApiClient`) | Calls merchant booking-service endpoints and coordinates read/write payload handling for reservations, calendars, accounts, campaigns, workshops, and staff profiles | Merchant API Client |
| Proxy Controller (`mbtProxyController`) | Forwards selected API calls to the upstream booking service base URL with request/response normalization; handles `/reservations/mbt/proxy/*` passthrough requests | Gofer-based Proxy |
| Inbenta Support Client (`mbtInbentaClient`) | Builds auth payloads and requests Inbenta support tokens for embedded support flows | node-fetch Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `merchant` | `continuumMerchantBookingTool` | Uses merchant booking workflows via web and mobile web entry points | HTTPS |
| `continuumMerchantBookingTool` | `continuumUniversalMerchantApi` | Reads and writes booking-service data via merchant API clients and proxy endpoints | HTTPS/JSON |
| `continuumMerchantBookingTool` | `googleOAuth` | Authenticates Google Calendar sync flows | OAuth 2.0 / HTTPS |
| `continuumMerchantBookingTool` | `continuumLayoutService` | Renders merchant shell/layout and app context | HTTPS |
| `mbtWebRoutes` | `mbtMerchantApiClient` | Calls booking-service endpoints for reservations, calendars, accounts, campaigns, workshops, and staff profiles | HTTP/JSON |
| `mbtWebRoutes` | `mbtProxyController` | Handles `/reservations/mbt/proxy/*` passthrough requests | In-process call |
| `mbtWebRoutes` | `mbtInbentaClient` | Handles support authentication bootstrap | In-process call |
| `mbtProxyController` | `mbtMerchantApiClient` | Proxied booking API calls forwarded to upstream booking service | HTTP/JSON |

## Architecture Diagram References

- Component diagram: `components-continuum-merchant-booking-tool-components`
- Dynamic flow: `dynamic-merchant-booking-primary-flow`
