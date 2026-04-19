---
service: "killbill-adyen-plugin"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

The plugin has one external dependency (Adyen payment gateway) accessed via SOAP and REST, and one internal dependency (Kill Bill platform) accessed via the OSGi service registry and JDBC data source provided by the container. Adyen is the only outbound integration with network I/O; everything else is intra-process via the OSGi bundle lifecycle.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Adyen | SOAP / HTTPS REST | Payment authorisation, capture, refund, recurring, HPP, Checkout API | yes | `adyen` |

### Adyen Detail

- **Protocol**: SOAP over HTTPS (Payment, Recurring, Notification, OpenInvoiceDetail WSDLs via Apache CXF); REST/JSON (Adyen Checkout API via `adyen-java-api-library` 12.0.1)
- **Base URL / SDK**:
  - SOAP Payment: `org.killbill.billing.plugin.adyen.paymentUrl` (e.g., `https://pal-live.adyen.com/pal/servlet/Payment/v12`)
  - SOAP Recurring: `org.killbill.billing.plugin.adyen.recurringUrl` (e.g., `https://pal-live.adyen.com/pal/servlet/Recurring/v12`)
  - Checkout REST: configured per-country via `org.killbill.billing.plugin.adyen.checkout.liveUrl.<COUNTRY>`
  - HPP: `org.killbill.billing.plugin.adyen.hpp.target` (e.g., `https://live.adyen.com/hpp/pay.shtml`)
- **Auth**:
  - SOAP: HTTP Basic authentication (`org.killbill.billing.plugin.adyen.username` / `org.killbill.billing.plugin.adyen.password`)
  - Checkout REST: API Key per country (`org.killbill.billing.plugin.adyen.checkout.apiKey.<COUNTRY>`)
  - HPP: HMAC signature (`org.killbill.billing.plugin.adyen.hmac.secret` using `HmacSHA256`)
- **Purpose**: All outbound payment lifecycle operations are routed through Adyen. SOAP is used for legacy payment and recurring flows; REST Checkout API is used for card-on-file and 3DSv2 flows. Adyen pushes asynchronous AUTHORISATION, CAPTURE, REFUND, CANCELLATION, and CHARGEBACK notifications back to the plugin via SOAP webhooks.
- **Failure mode**: On connection timeout or SOAP fault, the plugin returns a `PENDING` or `ERROR` state to Kill Bill. The `paymentConnectionTimeout` defaults to 30,000 ms and `paymentReadTimeout` defaults to 60,000 ms. If Adyen is unreachable, the healthcheck returns unhealthy.
- **Circuit breaker**: No evidence found of a client-side circuit breaker. Timeout configuration (`paymentConnectionTimeout`, `paymentReadTimeout`) is the primary resilience mechanism.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Kill Bill Platform | OSGi service | Invokes `PaymentPluginApi`; provides `OSGIKillbillAPI`, `OSGIConfigPropertiesService`, data source | `continuumKillbillAdyenPlugin` (consumer of Kill Bill OSGi APIs) |
| Plugin Database (`continuumKillbillAdyenPluginDb`) | JDBC | Persists payment methods, responses, HPP requests, notifications | `continuumKillbillAdyenPluginDb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Kill Bill Platform | OSGi service (`PaymentPluginApi`) | Delegating payment operations (authorize, capture, refund, void, recurring) and payment method management |
| Adyen (inbound) | SOAP over HTTPS webhook | Pushing asynchronous payment event notifications |

> Upstream callers of Kill Bill (e.g., Groupon checkout services) interact with this plugin indirectly through Kill Bill's REST API layer. Direct consumers are tracked in the central architecture model.

## Dependency Health

- The plugin exposes a `GET /plugins/killbill-adyen/healthcheck` endpoint that performs an HTTP probe against the configured `paymentUrl`. An HTTP 401 or 403 response from Adyen is considered healthy (indicating network reachability; the auth rejection is expected without credentials in the probe).
- No retry logic for outbound Adyen SOAP calls beyond connection/read timeout configuration.
- Per-region URL overrides allow routing to region-specific Adyen endpoints (configured via `<REGION>.org.killbill.billing.plugin.adyen.paymentUrl`).
