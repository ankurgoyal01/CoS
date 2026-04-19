---
service: "killbill-adyen-plugin"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [soap, rest, osgi-service]
auth_mechanisms: [http-basic, api-key, hmac-signature]
---

# API Surface

## Overview

The plugin exposes two surfaces: an OSGi `PaymentPluginApi` service consumed internally by Kill Bill (payment operations), and HTTP servlet endpoints registered under the Kill Bill servlet framework. External callers interact with this plugin via Kill Bill's own REST API (e.g., `POST /1.0/kb/accounts/{accountId}/payments`), which Kill Bill internally routes to the plugin. Adyen pushes notifications to the plugin's notification endpoint over SOAP/HTTP.

## Endpoints

### Kill Bill Payment Operations (via Kill Bill REST API)

These endpoints are part of Kill Bill's public REST API. The plugin handles them by implementing the `PaymentPluginApi` OSGi service contract.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/1.0/kb/accounts/{accountId}/paymentMethods` | Add a payment method (credit card, SEPA, or empty for CSE) | HTTP Basic + KB API key/secret |
| POST | `/1.0/kb/accounts/{accountId}/payments` | Trigger a payment (AUTHORIZE, PURCHASE) | HTTP Basic + KB API key/secret |
| DELETE | `/1.0/kb/payments/{paymentId}` | Void an authorised payment | HTTP Basic + KB API key/secret |
| POST | `/1.0/kb/payments/{paymentId}/captures` | Capture an authorised payment | HTTP Basic + KB API key/secret |
| POST | `/1.0/kb/payments/{paymentId}/refunds` | Refund a captured payment | HTTP Basic + KB API key/secret |
| POST | `/1.0/kb/accounts/{accountId}/paymentMethods/refresh` | Sync payment methods from Adyen recurring | HTTP Basic + KB API key/secret |

### Hosted Payment Page (HPP)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/1.0/kb/paymentGateways/hosted/form/{accountId}` | Generate an HPP redirect URL/form | HTTP Basic + KB API key/secret |

### Adyen Notification Webhook

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/1.0/kb/paymentGateways/notification/killbill-adyen` | Receive SOAP notification from Adyen | HTTP Basic (configured on Adyen side) |

### Plugin Healthcheck

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/plugins/killbill-adyen/healthcheck` | Check Adyen endpoint reachability | None |

### Tenant Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/1.0/kb/tenants/uploadPluginConfig/killbill-adyen` | Upload per-tenant plugin configuration | HTTP Basic + KB API key/secret |

## Request/Response Patterns

### Common headers

| Header | Description |
|--------|-------------|
| `X-Killbill-ApiKey` | Kill Bill tenant API key |
| `X-Killbill-ApiSecret` | Kill Bill tenant API secret |
| `X-Killbill-CreatedBy` | Audit trail creator identity |
| `Content-Type: application/json` | Required for JSON body requests |

### Plugin Properties

Payment and payment method calls accept `pluginProperty` query parameters or JSON `properties` arrays. Key plugin properties include:

| Property Key | Description |
|-------------|-------------|
| `country` | Country code to select merchant account |
| `recurringType` | `ONECLICK` or `RECURRING` for recurring payments |
| `contAuth` | `true`/`false` — continuous authentication (no CVV required) |
| `recurringDetailId` | Adyen recurring detail ID for stored credentials |
| `encryptedJson` | Client-Side Encrypted card JSON |
| `ccNumber` | Credit card number (plain) |
| `ccExpirationMonth` / `ccExpirationYear` | Card expiry |
| `ccVerificationValue` | CVV/CVC |
| `ddHolderName` / `ddNumber` / `ddBic` | SEPA direct debit fields |
| `PaRes` / `MD` | 3D Secure v1 response values |
| `threeDS2Token` / `threeDSServerTransID` | 3D Secure v2 challenge fields |
| `paymentProcessorAccountId` | Override merchant account selection |
| `skip_gw=true` | Skip gateway call (used for CSE payment method creation) |

### Error format

Kill Bill wraps plugin errors as `PaymentPluginApiException`. The plugin's HTTP healthcheck returns a plain JSON body with `{"healthy": true/false, "message": "..."}`.

### Pagination

The `getPaymentInfo` and `searchPayments` operations in the `PaymentPluginApi` use Kill Bill's `Pagination<PaymentTransactionInfoPlugin>` pattern.

## Rate Limits

No rate limiting configured at the plugin level. Adyen SOAP and REST endpoints have their own rate limits managed by Adyen.

## Versioning

No URL versioning at the plugin level. Plugin version (`0.5.y`) tracks Kill Bill `0.18.z` compatibility. The Adyen Checkout REST API version is controlled by the `adyen-java-api-library` version (`12.0.1`). Adyen SOAP WSDL versions (Payment v12, Recurring v12) are embedded in `src/main/resources/cxf/`.

## OpenAPI / Schema References

No OpenAPI specification file is present. SOAP contracts are defined by WSDLs at:
- `src/main/resources/cxf/Payment.wsdl`
- `src/main/resources/cxf/Recurring.wsdl`
- `src/main/resources/cxf/Notification.wsdl`
- `src/main/resources/cxf/OpenInvoiceDetail.wsdl`
