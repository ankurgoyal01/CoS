---
service: "mygroupons"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 9
---

# Integrations

## Overview

My Groupons integrates exclusively with internal Continuum services. All outbound HTTP calls are routed through `apiProxy`. The service has nine downstream dependencies, all accessed via REST/HTTP using the Gofer HTTP client and purpose-built itier client libraries. There are no external third-party API integrations owned directly by this service.

## External Dependencies

> No evidence found. No direct external third-party integrations are owned by this service.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy | REST/HTTP | Central outbound routing layer for all downstream calls | `apiProxy` |
| Orders Service | REST/HTTP | Fetches customer orders, vouchers, and order state | `continuumOrdersService` |
| Deal Catalog Service | REST/HTTP | Retrieves deal metadata, redemption instructions, and merchant details | `continuumDealCatalogService` |
| Users Service | REST/HTTP | Resolves user identity, validates session, fetches account details | `continuumUsersService` |
| Voucher Inventory Service | REST/HTTP | Reads voucher state; determines return/exchange eligibility | `continuumVoucherInventoryService` |
| Relevance API | REST/HTTP | Provides personalized deal recommendations on the My Groupons page | `continuumRelevanceApi` |
| GIMS | REST/HTTP | Geographic and merchant information for deal display | `gims` |
| Third-Party Inventory Service | REST/HTTP | Checks third-party inventory availability for exchange flows and order tracking | `continuumThirdPartyInventoryService` |
| Barcode Service | REST/HTTP | Generates barcode data embedded in voucher detail and PDF pages | — |
| Layout Service | REST/HTTP | Supplies the global page layout (header, footer, navigation chrome) | — |

### API Proxy (`apiProxy`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Configured via environment variable; all outbound calls pass through this proxy
- **Auth**: Internal service-to-service credentials
- **Purpose**: Centralises routing, auth token injection, and retry policies for downstream calls
- **Failure mode**: If API Proxy is unavailable, all downstream calls fail and the service returns an error page
- **Circuit breaker**: Managed by API Proxy layer

### Orders Service (`continuumOrdersService`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: `itier-groupon-v2-orders` 2.0.1 client library
- **Auth**: Session-propagated via API Proxy
- **Purpose**: Primary data source — provides the list of customer orders and voucher states for all My Groupons pages
- **Failure mode**: Critical; unavailability results in an error page for the main and voucher detail routes
- **Circuit breaker**: No evidence found

### Voucher Inventory Service (`continuumVoucherInventoryService`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: `itier-groupon-v2-mygroupons` 3.2.4 client library
- **Auth**: Session-propagated via API Proxy
- **Purpose**: Reads and mutates voucher state; used for return and exchange eligibility checks and submission
- **Failure mode**: Return and exchange routes degrade to an error state; main page may still render
- **Circuit breaker**: No evidence found

### Relevance API (`continuumRelevanceApi`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Gofer 4.1.0
- **Auth**: Internal service credentials
- **Purpose**: Fetches personalised deal recommendations displayed on the My Groupons page
- **Failure mode**: Non-critical; recommendations section is omitted if unavailable
- **Circuit breaker**: No evidence found

### GIMS Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Gofer 4.1.0
- **Auth**: Internal service credentials
- **Purpose**: Provides geographic and merchant-level data used in deal display
- **Failure mode**: Non-critical; affected sections degrade gracefully
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Dependency health is managed at the `myGroupons_requestOrchestration` layer using the `async` library (0.9.2) for parallel fan-out. Non-critical dependencies (Relevance API, GIMS) are treated as optional — failures suppress the corresponding UI section without failing the full page render. Critical dependencies (Orders Service, Users Service) propagate failures to an error page. Retry and circuit breaker logic is delegated to API Proxy where applicable.
