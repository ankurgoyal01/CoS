---
service: "billing-record-service"
title: "Create Billing Record"
generated: "2026-03-03"
type: flow
flow_name: "create-billing-record"
flow_type: synchronous
trigger: "POST request from checkout service with payment instrument data"
participants:
  - "continuumCheckoutReloadedService"
  - "brs_apiLayer"
  - "brs_coreService"
  - "brs_integrationAdapters"
  - "brs_persistence"
  - "brs_cacheAdapter"
  - "continuumBillingRecordPostgres"
  - "continuumBillingRecordRedis"
architecture_ref: "dynamic-billing-record-create"
---

# Create Billing Record

## Summary

When a purchaser adds a payment method during checkout, the Checkout Reloaded Service sends a POST request to Billing Record Service with the payment instrument data and billing address. BRS validates the request, stores the new billing record in PostgreSQL with INITIATED status, optionally registers token references with the relevant payment gateway, and updates the Redis cache. The new billing record resource is returned to the caller.

## Trigger

- **Type**: api-call
- **Source**: `continuumCheckoutReloadedService` — POST to `/v2/{countryCode}/users/{purchaserId}/billingrecords` or `/v3/users/{purchaserId}/billing_records`
- **Frequency**: On-demand (per checkout / payment method addition)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Checkout Reloaded Service | Initiates the create request with payment instrument data | `continuumCheckoutReloadedService` |
| API Layer | Receives and validates the incoming HTTP request | `brs_apiLayer` |
| Billing Record Service Layer | Orchestrates business logic: creates domain object, sets status to INITIATED, calls integrations | `brs_coreService` |
| External Integration Adapters | Registers token references with PCI-API or payment gateways if required | `brs_integrationAdapters` |
| Persistence Layer | Writes the new billing record and purchaser entities to PostgreSQL | `brs_persistence` |
| Cache Adapter | Evicts stale cache entries for the purchaser and writes the new entry | `brs_cacheAdapter` |
| PostgreSQL | Stores the new billing record durably | `continuumBillingRecordPostgres` |
| Redis | Updated with new cache entry | `continuumBillingRecordRedis` |

## Steps

1. **Receive create request**: Checkout service sends POST with `BillingRecordCreateModel` (required fields: `type`, `variant`) and optional `billingAddress` and `paymentData`.
   - From: `continuumCheckoutReloadedService`
   - To: `brs_apiLayer`
   - Protocol: HTTP/JSON (`application/hal+json` or `application/json`)

2. **Validate and delegate**: API Layer validates request contract (UUID patterns, required fields) and delegates to the Billing Record Service Layer.
   - From: `brs_apiLayer`
   - To: `brs_coreService`
   - Protocol: in-process

3. **Handle token lifecycle**: If the billing record carries payment token data (PCI, Adyen, Braintree), the Service Layer invokes the External Integration Adapters to register or validate the token reference.
   - From: `brs_coreService`
   - To: `brs_integrationAdapters`
   - Protocol: in-process (adapters call HTTPS APIs externally)

4. **Persist billing record**: The Service Layer instructs the Persistence Layer to save the new BillingRecord entity (status: INITIATED) and Purchaser entity to PostgreSQL.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process (JDBC to `continuumBillingRecordPostgres`)

5. **Update cache**: The Service Layer instructs the Cache Adapter to evict any stale entries and write the new billing record into Redis.
   - From: `brs_coreService`
   - To: `brs_cacheAdapter`
   - Protocol: in-process (Redis protocol to `continuumBillingRecordRedis`)

6. **Return response**: API Layer serializes the new `BillingRecordResource` as HAL+JSON (v2) or JSON (v3) and returns 200 to the caller.
   - From: `brs_apiLayer`
   - To: `continuumCheckoutReloadedService`
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request body (missing `type` or `variant`) | Spring MVC bean validation rejects request | 400 Bad Request returned to caller |
| PostgreSQL write failure | Transaction rolled back; no partial state committed | 500 returned to caller; cache not updated |
| Token registration failure (PCI-API / Adyen) | Hystrix circuit breaker may open; error propagated up | 500 returned to caller; DB write not committed |
| Redis cache write failure | Cache miss on next read falls back to DB; non-fatal | Billing record still stored in DB; response still returned |

## Sequence Diagram

```
CheckoutReloaded -> brs_apiLayer: POST /v2/{countryCode}/users/{purchaserId}/billingrecords
brs_apiLayer -> brs_coreService: validate and orchestrate create/update workflow
brs_coreService -> brs_integrationAdapters: handle token lifecycle and external payment references
brs_integrationAdapters --> brs_coreService: token registration result
brs_coreService -> brs_persistence: persist billing record and purchaser updates
brs_persistence --> brs_coreService: saved BillingRecord entity
brs_coreService -> brs_cacheAdapter: update cache entry and evict stale variants
brs_cacheAdapter --> brs_coreService: cache updated
brs_coreService --> brs_apiLayer: BillingRecord domain object
brs_apiLayer --> CheckoutReloaded: 200 BillingRecordResource (HAL+JSON)
```

## Related

- Architecture dynamic view: `dynamic-billing-record-create`
- Related flows: [Authorize Billing Record](authorize-billing-record.md), [Deactivate Billing Record](deactivate-billing-record.md)
