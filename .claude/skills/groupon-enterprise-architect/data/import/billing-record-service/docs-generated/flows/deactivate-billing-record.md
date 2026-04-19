---
service: "billing-record-service"
title: "Deactivate Billing Record"
generated: "2026-03-03"
type: flow
flow_name: "deactivate-billing-record"
flow_type: synchronous
trigger: "PUT request from checkout service or user account action to remove a payment method"
participants:
  - "continuumCheckoutReloadedService"
  - "brs_apiLayer"
  - "brs_coreService"
  - "brs_integrationAdapters"
  - "brs_persistence"
  - "brs_cacheAdapter"
  - "continuumBillingRecordPostgres"
  - "continuumBillingRecordRedis"
  - "paymentGateways"
architecture_ref: "dynamic-billing-record-create"
---

# Deactivate Billing Record

## Summary

When a purchaser removes a saved payment method or the checkout system marks a payment instrument as no longer valid, BRS deactivates the billing record by transitioning its status to USER_DEACTIVATED. After deactivation, BRS checks whether the associated payment token is still referenced by any other active billing record for any purchaser. If the token is no longer needed, BRS calls PCI-API to delete the token from the PCI vault. The cache entry for the purchaser is evicted.

## Trigger

- **Type**: api-call
- **Source**: `continuumCheckoutReloadedService` or user account management service — PUT to `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/deactivate`
- **Frequency**: On-demand (per user action or system-initiated deactivation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Checkout Reloaded Service | Initiates the deactivate request | `continuumCheckoutReloadedService` |
| API Layer | Receives the PUT request and routes to service layer | `brs_apiLayer` |
| Billing Record Service Layer | Applies USER_DEACTIVATED status; checks token usage; orchestrates PCI token deletion | `brs_coreService` |
| External Integration Adapters | Calls PCI-API to delete token if no longer needed | `brs_integrationAdapters` |
| Persistence Layer | Updates billing record status in PostgreSQL; queries token usage | `brs_persistence` |
| Cache Adapter | Evicts stale cache entries for the purchaser | `brs_cacheAdapter` |
| PostgreSQL | Stores the deactivated billing record | `continuumBillingRecordPostgres` |
| Redis | Cache entries evicted | `continuumBillingRecordRedis` |
| PCI-API | Deletes the payment token if no longer required | `paymentGateways` |

## Steps

1. **Receive deactivate request**: Caller sends PUT to `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/deactivate`.
   - From: `continuumCheckoutReloadedService`
   - To: `brs_apiLayer`
   - Protocol: HTTP/JSON

2. **Validate and delegate**: API Layer validates path parameters and delegates to the Service Layer.
   - From: `brs_apiLayer`
   - To: `brs_coreService`
   - Protocol: in-process

3. **Apply deactivation**: Service Layer reads the billing record, sets status to USER_DEACTIVATED, and persists the change.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process (JDBC to `continuumBillingRecordPostgres`)

4. **Check token usage**: Service Layer queries the persistence layer to determine whether the token associated with the deactivated billing record is still referenced by other active billing records.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process

5. **Delete token if unused**: If the token is not referenced by any other active billing record, the Service Layer instructs the External Integration Adapters to call PCI-API and delete the token.
   - From: `brs_coreService`
   - To: `brs_integrationAdapters`
   - Protocol: in-process (adapter calls PCI-API via HTTPS)

6. **Evict cache**: Cache Adapter removes stale cached entries for the purchaser.
   - From: `brs_coreService`
   - To: `brs_cacheAdapter`
   - Protocol: in-process (Redis protocol to `continuumBillingRecordRedis`)

7. **Return response**: API Layer serializes the updated `BillingRecordResource` and returns 200.
   - From: `brs_apiLayer`
   - To: `continuumCheckoutReloadedService`
   - Protocol: HTTP/JSON (HAL+JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Billing record not found | Persistence returns empty result | 404 returned to caller |
| PCI-API token deletion failure | Hystrix circuit breaker; error logged; billing record deactivation still committed | Token deletion deferred; no rollback of status change |
| PostgreSQL write failure | Transaction rolled back | 500 returned; cache not evicted |

## Sequence Diagram

```
CheckoutReloaded -> brs_apiLayer: PUT /v2/{countryCode}/users/{purchaserId}/billingrecords/{id}/deactivate
brs_apiLayer -> brs_coreService: validate and delegate deactivate
brs_coreService -> brs_persistence: update status to USER_DEACTIVATED
brs_persistence --> brs_coreService: updated BillingRecord
brs_coreService -> brs_persistence: isTokenRequired(tokenId)?
brs_persistence --> brs_coreService: false (no other active records use this token)
brs_coreService -> brs_integrationAdapters: call PCI-API to delete token
brs_integrationAdapters --> brs_coreService: token deleted
brs_coreService -> brs_cacheAdapter: evict stale cache entries
brs_cacheAdapter --> brs_coreService: cache evicted
brs_coreService --> brs_apiLayer: updated BillingRecord
brs_apiLayer --> CheckoutReloaded: 200 BillingRecordResource (HAL+JSON)
```

## Related

- Architecture dynamic view: `dynamic-billing-record-create`
- Related flows: [Create Billing Record](create-billing-record.md), [GDPR IRR Erasure](gdpr-irr-erasure.md)
