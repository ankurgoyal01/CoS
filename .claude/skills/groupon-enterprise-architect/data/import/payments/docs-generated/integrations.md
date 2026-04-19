---
service: "payments"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

The Payments Service integrates with 1 external system (Payment Gateways) and is consumed by 3 internal Continuum services/applications. It has no outbound internal service dependencies beyond its own database; all of its downstream communication is directed at external payment gateways. Observability data flows to the shared Logging, Metrics, and Tracing stacks.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Payment Gateways | rest / api | Payment authorization and capture processing (credit card, debit, alternative methods) | yes | `paymentGateways` |

### Payment Gateways Detail

- **Protocol**: API (HTTP/REST to external PSPs)
- **Base URL / SDK**: Configured per-provider; routed by the Provider Router component
- **Auth**: Per-gateway credentials (API keys / tokens); PCI-scoped
- **Purpose**: Submits payment authorization requests and capture requests to external payment service providers. The Provider Client component handles the actual HTTP calls to the gateway endpoints.
- **Failure mode**: Gateway failures would block payment authorization and capture, causing upstream order processing to fail. Orders Service implements retry logic via its daemon schedulers for failed payment operations.
- **Circuit breaker**: > No evidence found in codebase.

## Internal Dependencies

> The Payments Service does not depend on other internal Continuum services. Its only downstream targets are the external Payment Gateways and its own Payments DB.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Orders Service (`continuumOrdersService`) | JSON/HTTPS | Payment authorization, capture, refund, and billing record operations (SyncAPI, CriticalPath) |
| API Gateway / Lazlo (`continuumApiLazloService`) | HTTP/JSON over internal network | Billing/payments operations |
| Merchant Flutter App (`continuumMobileFlutterMerchantApp`) | HTTP | Retrieves payment schedules and payment details |

## Observability Dependencies

| System | Protocol | Purpose | Architecture Ref |
|--------|----------|---------|-----------------|
| Logging Stack | Async | Structured log emission | `loggingStack` |
| Metrics Stack | Stats/OTel | Metrics publishing | `metricsStack` |
| Tracing Stack | OpenTelemetry | Distributed trace emission | `tracingStack` |

## Dependency Health

- The Provider Client component integrates with external gateways via HTTP. Failure handling and retry strategy details are not documented in the architecture model.
- The relationship from `continuumOrdersService` to `continuumPaymentsService` is tagged `SyncAPI,CriticalPath`, indicating that payment processing is on the critical path for order checkout. Any Payments Service unavailability directly impacts order processing.
- The Orders Service (primary caller) implements retry logic via its daemon schedulers (`continuumOrdersDaemons_retrySchedulers`) for failed payment operations, providing eventual consistency for transient failures.
