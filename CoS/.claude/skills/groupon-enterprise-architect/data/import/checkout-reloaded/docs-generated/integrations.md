---
service: "checkout-reloaded"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 7
---

# Integrations

## Overview

checkout-reloaded integrates with one external third-party system (Adyen for payment processing) and seven internal Groupon/Continuum services. All integrations are synchronous REST/HTTP calls made per-request, consistent with the stateless BFF pattern. The `itier-groupon-v2-client` library acts as an API proxy intermediary for most internal service calls, routing them through a centralized proxy layer.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Adyen Payment Gateway | HTTPS / SDK | Payment authorization during checkout submit | yes | — |

### Adyen Payment Gateway Detail

- **Protocol**: HTTPS via `@adyen/adyen-web` SDK 5.x (client-side drop-in component) with server-side API calls using `ADYEN_API_KEY`
- **Base URL / SDK**: `@adyen/adyen-web` 5.x; server-side calls to Adyen API endpoints using `ADYEN_API_KEY` and `ADYEN_MERCHANT_ACCOUNT`
- **Auth**: API key (`ADYEN_API_KEY`) and merchant account identifier (`ADYEN_MERCHANT_ACCOUNT`)
- **Purpose**: Authorizes consumer payment transactions during the POST /checkout/submit flow; the Adyen drop-in component is toggled via the `checkout.adyenDropIn` feature flag
- **Failure mode**: Payment authorization failure causes the BFF to return an error state to the checkout page; order finalization is not called if Adyen authorization fails
- **Circuit breaker**: > No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Cart Service | REST / HTTP (via API Proxy) | Loads current cart contents and applies item updates | — |
| Pricing Service | REST / HTTP (via API Proxy) | Validates and applies pricing rules during checkout page render and submit | — |
| Order Service | REST / HTTP (via API Proxy) | Finalizes orders after successful payment authorization | — |
| Deal Catalog Service | REST / HTTP (via API Proxy) | Fetches deal and product details for cart display | — |
| Auth/Identity Service (UMAPI) | REST / HTTP (via API Proxy) | Validates merchant and user identity | — |
| Layout Service | REST / HTTP | Provides shared site header and footer HTML for SSR page assembly | — |
| Keldor | HTTP / SDK (`keldor-client`) | Supplies runtime feature flag configuration | — |

### API Proxy (itier-groupon-v2-client) Detail

- **Protocol**: HTTP (internal)
- **Base URL / SDK**: Configured via `API_PROXY_BASE_URL` environment variable; client library is `itier-groupon-v2-client`
- **Auth**: Internal service authentication managed by the proxy layer
- **Purpose**: Routes internal API calls from the BFF to Cart, Pricing, Order, Deal Catalog, and UMAPI services through a centralized proxy
- **Failure mode**: Proxy unavailability causes upstream service calls to fail, resulting in checkout page error states or 5xx responses
- **Circuit breaker**: > No evidence found in codebase.

### Keldor Detail

- **Protocol**: HTTP SDK (`keldor-client`)
- **Base URL / SDK**: Endpoint configured via `KELDOR_CONFIG_SOURCE` environment variable
- **Auth**: Internal
- **Purpose**: Provides runtime feature flag values (`checkout.newPaymentFlow`, `checkout.adyenDropIn`, `checkout.postPurchaseUpsell`) that control checkout behavior without redeployment
- **Failure mode**: Keldor unavailability causes flags to fall back to default values; service continues operating with baseline behavior
- **Circuit breaker**: > No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model. checkout-reloaded is consumed directly by Groupon consumer browsers and mobile web views navigating the checkout funnel.

## Dependency Health

The `/health` endpoint confirms the BFF process is alive for Kubernetes readiness and liveness probes. Individual downstream dependency health is not separately probed at this layer — failures surface as degraded page renders or redirects to error pages. No explicit circuit breaker or retry library configuration is documented in the service inventory.
