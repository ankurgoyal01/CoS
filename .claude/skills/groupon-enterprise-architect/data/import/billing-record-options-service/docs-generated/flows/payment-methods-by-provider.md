---
service: "billing-record-options-service"
title: "Payment Methods by Provider Query"
generated: "2026-03-03"
type: flow
flow_name: "payment-methods-by-provider"
flow_type: synchronous
trigger: "HTTP GET /paymentmethods with paymentProviderId query parameter"
participants:
  - "brosPaymentMethodsResource"
  - "brosPaymentMethodsService"
  - "brosPaymentProviderService"
  - "brosPaymentTypeService"
  - "brosJdbiDataAccessor"
  - "daasPostgresPrimary"
  - "raasRedis"
architecture_ref: "components-continuumBillingRecordOptionsService"
---

# Payment Methods by Provider Query

## Summary

This flow handles requests to look up payment method details for a specific payment provider, identified by its `paymentProviderId`. Rather than filtering by country code, the caller specifies a provider ID directly. BROS loads the matching provider record, enriches it with payment type definitions, and returns the result. This is used when the caller already knows which provider to use and needs its full configuration — for example, to render provider-specific UI elements or validate provider capabilities.

## Trigger

- **Type**: api-call
- **Source**: Payment orchestration service or checkout frontend that has a specific provider ID
- **Frequency**: On demand (per-request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller | Sends GET request with `paymentProviderId` | External consumer |
| Payment Methods Resource | Receives HTTP request and extracts the `paymentProviderId` parameter | `brosPaymentMethodsResource` |
| Payment Methods Service | Orchestrates provider lookup and response composition | `brosPaymentMethodsService` |
| Payment Provider Service | Loads the specific payment provider record from the database | `brosPaymentProviderService` |
| Payment Type Service | Loads payment type definition for the provider's payment type | `brosPaymentTypeService` |
| JDBI Data Accessor | Executes SQL queries against the payment_providers and payment_types tables | `brosJdbiDataAccessor` |
| DaaS PostgreSQL | Stores payment provider and payment type configuration | `daasPostgresPrimary` |
| RAAS Redis | Serves cached response if available | `raasRedis` |

## Steps

1. **Receive HTTP Request**: Caller sends `GET /paymentmethods?paymentProviderId=<id>` with optional `amount` and `userAgent` parameters.
   - From: Caller
   - To: `brosPaymentMethodsResource`
   - Protocol: REST HTTP

2. **Check Cache**: Service checks RAAS Redis for a cached response for this provider ID.
   - From: `brosPaymentMethodsService`
   - To: `raasRedis`
   - Protocol: Redis

3. **Load Payment Provider**: Payment Provider Service queries the `payment_providers` table by provider ID.
   - From: `brosPaymentProviderService`
   - To: `brosJdbiDataAccessor` then `daasPostgresPrimary`
   - Protocol: JDBI / PostgreSQL

4. **Load Payment Type Definition**: Payment Type Service loads the `payment_types` record matching the provider's `payment_type` field to obtain `billingRecordType`, `billingRecordVariant`, and `flowType`.
   - From: `brosPaymentTypeService`
   - To: `brosJdbiDataAccessor` then `daasPostgresPrimary`
   - Protocol: JDBI / PostgreSQL

5. **Compose and Return Response**: Payment Methods Service assembles a `PaymentMethodsRepresentation` with the single provider's details. Populates cache for subsequent requests.
   - From: `brosPaymentMethodsService`
   - To: `brosPaymentMethodsResource` then caller
   - Protocol: Direct / REST HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Provider ID not found | Provider DAO returns empty result | Returns `404 Not Found` |
| Missing `paymentProviderId` parameter | No country code or provider ID supplied | Returns `400 Bad Request` |
| Database unavailable | JDBI throws connection exception | Returns `500 Internal Server Error` |

## Sequence Diagram

```
Caller -> brosPaymentMethodsResource: GET /paymentmethods?paymentProviderId=42
brosPaymentMethodsResource -> brosPaymentMethodsService: resolve(params)
brosPaymentMethodsService -> raasRedis: get(cacheKey)
raasRedis --> brosPaymentMethodsService: cache miss
brosPaymentMethodsService -> brosPaymentProviderService: getProvider(providerId=42)
brosPaymentProviderService -> brosJdbiDataAccessor: findById(42)
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT * FROM payment_providers WHERE id = 42
daasPostgresPrimary --> brosJdbiDataAccessor: provider row
brosPaymentProviderService --> brosPaymentMethodsService: provider
brosPaymentMethodsService -> brosPaymentTypeService: getPaymentType(provider.paymentType)
brosPaymentTypeService -> brosJdbiDataAccessor: findByType(paymentType)
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT * FROM payment_types WHERE payment_type = ?
daasPostgresPrimary --> brosJdbiDataAccessor: payment type row
brosPaymentTypeService --> brosPaymentMethodsService: paymentTypeDefinition
brosPaymentMethodsService -> raasRedis: set(cacheKey, response)
brosPaymentMethodsService --> brosPaymentMethodsResource: PaymentMethodsRepresentation
brosPaymentMethodsResource --> Caller: 200 OK {paymentMethods: [provider]}
```

## Related

- Architecture dynamic view: `components-continuumBillingRecordOptionsService`
- Related flows: [Payment Methods by Country Query](payment-methods-by-country.md)
