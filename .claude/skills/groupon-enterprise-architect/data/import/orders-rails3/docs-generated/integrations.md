---
service: "orders-rails3"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 9
---

# Integrations

## Overview

orders-rails3 integrates with 4 external systems (payment gateways and fraud screening) and 9 internal Continuum services. All outbound HTTP calls are made through `continuumOrdersApi_serviceClientsGateway` (ServiceRequestFactory / typhoeus). SOAP calls to legacy payment systems are made via the `savon` gem. Internal Continuum services are called synchronously during request processing; payment gateway calls are also executed asynchronously from Workers.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Payment Gateways (GlobalPayments / Killbill / Adyen) | rest / soap | Payment authorization, capture, and refund | yes | `paymentGateways` |
| Accertify | rest | Device fingerprinting and fraud screening | yes | (via `continuumFraudArbiterService`) |
| Message Bus | mbus | Asynchronous event publishing for order lifecycle events | yes | `messageBus` |

### Payment Gateways (GlobalPayments / Killbill / Adyen) Detail

- **Protocol**: REST (typhoeus) and SOAP (savon)
- **Base URL / SDK**: Configured per-gateway via environment variables; `savon` 2.2.0 for SOAP endpoints
- **Auth**: Per-gateway credentials (API keys / SOAP credentials)
- **Purpose**: Submits payment authorization and capture requests during order collection; processes refunds during cancellation flows
- **Failure mode**: Payment errors surface as failed collection state; orders move to retry queue via `continuumOrdersDaemons_retrySchedulers`
- **Circuit breaker**: No evidence found in architecture model

### Accertify Detail

- **Protocol**: REST
- **Base URL / SDK**: Called via `continuumOrdersApi_serviceClientsGateway`
- **Auth**: API credentials managed via environment secrets
- **Purpose**: Device fingerprint analysis and fraud risk scoring during order placement and fraud review
- **Failure mode**: Fraud arbiter fallback decision applied; order may be held for manual review
- **Circuit breaker**: No evidence found in architecture model

### Message Bus Detail

- **Protocol**: Message Bus (`messagebus` 0.2.2 gem)
- **Base URL / SDK**: Internal Groupon Message Bus; configured via environment variables
- **Auth**: Internal service authentication
- **Purpose**: Publishes OrderSnapshots, Transactions, InventoryUnits.StatusChanged, TransactionalLedgerEvents, and BillingRecordUpdate events
- **Failure mode**: Messages durably persisted in `continuumOrdersMsgDb` before dispatch; replay possible
- **Circuit breaker**: Not applicable; outbox pattern provides durability

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | rest | Fetches account details, email/password changes for order and redaction flows | `continuumUsersService` |
| Deal Catalog Service | rest | Fetches deal data and validates deal availability at order placement | `continuumDealCatalogService` |
| Voucher Inventory Service | rest | Reserves and adjusts voucher inventory for order line items | `continuumVoucherInventoryService` |
| Geo Details Service | rest | Geocoding and address normalization for order addresses | `continuumGeoDetailsService` |
| Geo Service | rest | Address normalization and geocoding (additional geo service) | `continuumGeoService` |
| Fraud Arbiter Service | rest | Requests fraud risk decisions during order authorization and fraud review | `continuumFraudArbiterService` |
| Incentives Service | rest | Applies incentives and credits during checkout | `continuumIncentivesService` |
| Payments Service | rest | Payment authorization, capture, refund, and billing record operations | `continuumPaymentsService` |
| Taxonomy Service | rest | Reads taxonomy data used by order and voucher flows | `continuumTaxonomyService` |
| M3 Merchant Service | rest | Reads merchant account data for fulfillment and reconciliation | `continuumM3MerchantService` |
| M3 Places Service | rest | Reads place/location data for merchant and order context | `continuumM3PlacesService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Orders Service is primarily called by storefront clients (web and mobile) and internal Continuum services that initiate or manage orders.

## Dependency Health

- All downstream HTTP calls are made via `continuumOrdersApi_serviceClientsGateway` using `typhoeus` 0.6.5 and `service-client` 2.0.13, which provides connection timeout and retry configuration at the client level.
- No circuit breaker framework is documented in the architecture model; dependency failures propagate as errors to the caller or trigger queue-based retry flows via `continuumOrdersDaemons_retrySchedulers`.
- Payment gateway failures cause orders to enter a retry queue; collection daemons re-enqueue these orders for subsequent attempts.
- Message Bus publish failures are mitigated by the outbox pattern in `continuumOrdersMsgDb` — messages can be replayed from the database.
