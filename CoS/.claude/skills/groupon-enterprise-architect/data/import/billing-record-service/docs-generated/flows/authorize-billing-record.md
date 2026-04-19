---
service: "billing-record-service"
title: "Authorize Billing Record"
generated: "2026-03-03"
type: flow
flow_name: "authorize-billing-record"
flow_type: synchronous
trigger: "PUT request from checkout service after successful payment verification"
participants:
  - "continuumCheckoutReloadedService"
  - "brs_apiLayer"
  - "brs_coreService"
  - "brs_persistence"
  - "brs_cacheAdapter"
  - "continuumBillingRecordPostgres"
  - "continuumBillingRecordRedis"
architecture_ref: "dynamic-billing-record-create"
---

# Authorize Billing Record

## Summary

After a payment has been successfully verified by the payment gateway, the Checkout Reloaded Service calls BRS to authorize the billing record. This transitions the record from INITIATED to AUTHORIZED status, indicating it is a confirmed, reusable payment method. The updated record is persisted to PostgreSQL and the Redis cache is invalidated.

## Trigger

- **Type**: api-call
- **Source**: `continuumCheckoutReloadedService` — PUT to `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/authorize`
- **Frequency**: On-demand (once per successful payment authorization at checkout)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Checkout Reloaded Service | Initiates the authorize request after payment gateway confirmation | `continuumCheckoutReloadedService` |
| API Layer | Receives the PUT request and routes to service layer | `brs_apiLayer` |
| Billing Record Service Layer | Validates the state transition and applies AUTHORIZED status | `brs_coreService` |
| Persistence Layer | Updates the billing record status in PostgreSQL | `brs_persistence` |
| Cache Adapter | Evicts stale cache entries for the purchaser | `brs_cacheAdapter` |
| PostgreSQL | Stores the updated billing record | `continuumBillingRecordPostgres` |
| Redis | Cache entries evicted to force fresh reads | `continuumBillingRecordRedis` |

## Steps

1. **Receive authorize request**: Checkout service sends PUT to `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/authorize`.
   - From: `continuumCheckoutReloadedService`
   - To: `brs_apiLayer`
   - Protocol: HTTP/JSON

2. **Validate and delegate**: API Layer validates path parameters and delegates to the Service Layer.
   - From: `brs_apiLayer`
   - To: `brs_coreService`
   - Protocol: in-process

3. **Apply state transition**: Service Layer reads the existing billing record, validates the transition from INITIATED to AUTHORIZED, and updates the domain object.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process (JDBC to `continuumBillingRecordPostgres`)

4. **Evict cache**: Cache Adapter removes stale cached entries for the purchaser so that subsequent reads reflect the authorized status.
   - From: `brs_coreService`
   - To: `brs_cacheAdapter`
   - Protocol: in-process (Redis protocol to `continuumBillingRecordRedis`)

5. **Return response**: API Layer serializes the updated `BillingRecordResource` and returns 200 to the caller.
   - From: `brs_apiLayer`
   - To: `continuumCheckoutReloadedService`
   - Protocol: HTTP/JSON (HAL+JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Billing record not found | Persistence layer returns empty result | 404 returned to caller |
| Invalid state transition (already AUTHORIZED or DEACTIVATED) | Service layer rejects transition | Error response returned; no DB update |
| PostgreSQL write failure | Transaction rolled back | 500 returned; cache not evicted |

## Sequence Diagram

```
CheckoutReloaded -> brs_apiLayer: PUT /v2/{countryCode}/users/{purchaserId}/billingrecords/{id}/authorize
brs_apiLayer -> brs_coreService: validate and delegate authorize
brs_coreService -> brs_persistence: read billing record by ID
brs_persistence --> brs_coreService: BillingRecord (status: INITIATED)
brs_coreService -> brs_persistence: update status to AUTHORIZED
brs_persistence --> brs_coreService: updated BillingRecord
brs_coreService -> brs_cacheAdapter: evict stale cache entries
brs_cacheAdapter --> brs_coreService: cache evicted
brs_coreService --> brs_apiLayer: updated BillingRecord
brs_apiLayer --> CheckoutReloaded: 200 BillingRecordResource (HAL+JSON)
```

## Related

- Architecture dynamic view: `dynamic-billing-record-create`
- Related flows: [Create Billing Record](create-billing-record.md), [Deactivate Billing Record](deactivate-billing-record.md)
