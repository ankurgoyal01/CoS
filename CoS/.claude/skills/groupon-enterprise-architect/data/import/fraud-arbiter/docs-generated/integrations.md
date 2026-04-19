---
service: "fraud-arbiter"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 7
internal_count: 9
---

# Integrations

## Overview

Fraud Arbiter integrates with 7 external systems and 9 internal Continuum services. Externally, it maintains bidirectional relationships with Signifyd and Riskified as the primary fraud intelligence providers, and communicates with Appointment Engine, Bhuvan, Kill Bill Payments, Taxonomy V2, and TPIS for order context enrichment and payment coordination. Internally, it queries a broad range of Continuum services to build the fraud evaluation payload and report outcomes back.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Signifyd | REST / webhook | Primary fraud evaluation provider; receives order data, returns fraud decisions | yes | `signifyd` |
| Riskified | REST / webhook | Secondary fraud evaluation provider; receives order data, returns fraud decisions | yes | `riskified` |
| Appointment Engine | REST | Fetches appointment/booking context for orders involving time-based services | no | `appointmentEngine` |
| Bhuvan | REST | Fetches additional order or merchant context data | no | `bhuvan` |
| Kill Bill Payments | REST | Coordinates payment authorization and void decisions based on fraud outcomes | yes | `killbillPayments` |
| Taxonomy V2 | REST | Fetches product taxonomy context to enrich fraud evaluation payload | no | `taxonomyV2` |
| TPIS | REST | Fetches third-party inventory or service context | no | `tpis` |

### Signifyd Detail

- **Protocol**: REST (outbound submissions) + HTTPS webhook (inbound decisions)
- **Base URL / SDK**: Signifyd REST API (base URL configured via environment variable)
- **Auth**: API key (configured via secret)
- **Purpose**: Submits order data for fraud scoring; receives approve/reject/review decisions and fulfillment/return update notifications via webhook
- **Failure mode**: Order fraud review remains in pending state; Sidekiq retries submission; escalates to manual review queue
- **Circuit breaker**: No evidence found in codebase

### Riskified Detail

- **Protocol**: REST (outbound submissions) + HTTPS webhook (inbound decisions)
- **Base URL / SDK**: Riskified REST API (base URL configured via environment variable)
- **Auth**: HMAC-SHA256 signed requests
- **Purpose**: Alternative fraud evaluation provider; submits orders and receives approve/reject decisions plus fulfillment, refund, and cancellation update notifications
- **Failure mode**: Falls back to alternate provider or pending state; Sidekiq retries
- **Circuit breaker**: No evidence found in codebase

### Kill Bill Payments Detail

- **Protocol**: REST
- **Base URL / SDK**: Internal Continuum service endpoint
- **Auth**: Internal service credentials
- **Purpose**: Receives fraud outcome signals to authorize or void payment charges aligned with fraud decisions
- **Failure mode**: Payment action queued for retry; fraud decision persisted regardless
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Orders Service | REST | Fetches order details and reports fraud outcomes | `continuumOrdersService` |
| Deal Catalog Service | REST | Fetches deal/product details for fraud evaluation context | `continuumDealCatalogService` |
| Goods Inventory Service | REST | Fetches goods inventory context for physical goods orders | `continuumGoodsInventoryService` |
| Incentive Service | REST | Fetches coupon/incentive context to detect promo abuse patterns | `continuumIncentiveService` |
| M3 Places Service | REST | Fetches merchant place/location context | `continuumM3PlacesService` |
| M3 Merchant Service | REST | Fetches merchant account and risk profile context | `continuumM3MerchantService` |
| Users Service | REST | Fetches customer profile, history, and identity data | `continuumUsersService` |
| Voucher Inventory Service | REST | Fetches voucher context for local deals orders | `continuumVoucherInventoryService` |
| Message Bus (mbus) | message-bus | Consumes order/shipment events; publishes fraud decision events | `mbus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit circuit breaker or health-check configuration. Sidekiq retry with exponential backoff is the primary resilience mechanism for failed outbound HTTP calls made via Faraday. Service owners should define health-check and circuit-breaker policies.
