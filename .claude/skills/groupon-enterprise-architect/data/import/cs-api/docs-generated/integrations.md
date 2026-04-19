---
service: "cs-api"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 10
---

# Integrations

## Overview

CS API has a large integration footprint: three external third-party platforms and ten active internal Continuum services (with additional stub-only services not yet federated into the central model). All integrations are synchronous HTTP calls made by the `serviceClients` component using `jtier-retrofit`. The service acts as an aggregator — it fans out to multiple downstream systems per request and assembles a unified response for the agent UI.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Zendesk | REST/HTTP | Creates and reads customer support tickets | yes | `zendesk` |
| Salesforce | REST/HTTP | Queries CRM data for customer and merchant context | yes | `salesForce` |
| BoldChat | REST/HTTP | Live chat integration (stub-only; not yet active in federated model) | no | `boldChatApi` |

### Zendesk Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: Configured via `jtier-retrofit` HTTP client
- **Auth**: > Auth method not captured in architecture model; assumed API key or OAuth2 token
- **Purpose**: Agent-initiated ticket creation and retrieval for customer support cases
- **Failure mode**: Ticket operations fail; agent cannot create or view Zendesk tickets
- **Circuit breaker**: > No evidence found in architecture model

### Salesforce Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: Configured via `jtier-retrofit` HTTP client
- **Auth**: > Auth method not captured in architecture model; assumed OAuth2 client credentials
- **Purpose**: CRM data queries to provide agent context on customers and merchants
- **Failure mode**: CRM data unavailable; agent sees degraded customer context
- **Circuit breaker**: > No evidence found in architecture model

### BoldChat Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: `boldChatApi` (stub-only in current federated model)
- **Auth**: > No evidence found
- **Purpose**: Integration for live chat event data
- **Failure mode**: Live chat data unavailable
- **Circuit breaker**: > No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | HTTP | Queries user account and profile data | `continuumUsersService` |
| Orders Service | HTTP | Queries customer order history and order details | `continuumOrdersService` |
| Deal Catalog Service | HTTP | Loads deal metadata for agent inquiry | `continuumDealCatalogService` |
| Lazlo API | HTTP | Requests additional API data (deal/inventory context) | `lazloApi` |
| Goods Inventory Service | HTTP | Reads goods inventory for deal/order support | `continuumGoodsInventoryService` |
| Audience Management Service | HTTP | Fetches customer audience segments and attributes | `continuumAudienceManagementService` |
| Consumer Data Service | HTTP | Fetches consumer profile and preference data | `continuumConsumerDataService` |
| Incentives Service | HTTP | Fetches incentive data; executes convert-to-cash refund actions | `continuumIncentivesService` |
| CS Token Service | HTTP | Issues and validates CS-specific auth tokens | `continuumCsTokenService` |
| Goods Central Service | HTTP | Fetches goods product data for agent context | `continuumGoodsCentralService` |

### Stub-Only Dependencies (not yet in federated model)

The following services appear in the architecture DSL as stub-only references, indicating they are known dependencies but have not yet published their own architecture modules:

- `orderReversalService` — order reversal operations
- `subscriptionService` — subscription program queries
- `visService` — voucher inventory
- `tpisService` — third-party inventory
- `getawaysInventoryProxy` — getaways inventory
- `localbookInventoryService` — booking inventory
- `mrGetawaysService` — Maris getaways inventory
- `legalConsentsService` — legal consents
- `grouponSelectService` — subscription programs
- `incentivesCheckoutService` — checkout incentives
- `glsService` — logistics data
- `readingRainbowService` — Reading Rainbow data
- `bookingToolService` — booking data
- `watsonService` — Watson AI data
- `localizationService` — localization data
- `killbillService` — billing data
- `rocketmanService` — Rocketman data
- `merchantsService` — merchant data
- `giftCardService` — gift card data

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Cyclops CS Agent Application | REST/HTTPS | Agent tooling UI; all agent actions route through CS API |

> Upstream consumers are tracked in the central architecture model. The `customerSupportAgent` container is defined as a stub in the local model, indicating the agent UI is owned and tracked separately.

## Dependency Health

> Circuit breaker and retry configuration details are not captured in the architecture DSL model. Health check and retry policies are assumed to be managed at the JTier platform level via `jtier-retrofit` client configuration. Operational procedures should be confirmed with the service owner (GSO Engineering / nsanjeevi).
