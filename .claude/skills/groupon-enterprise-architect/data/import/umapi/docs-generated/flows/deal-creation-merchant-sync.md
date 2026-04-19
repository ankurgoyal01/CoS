---
service: "umapi"
title: "Deal Creation Merchant Sync"
generated: "2026-03-03"
type: flow
flow_name: "deal-creation-merchant-sync"
flow_type: synchronous
trigger: "API request from Marketing Deal Service during deal creation"
participants:
  - "continuumMarketingDealService"
  - "continuumUniversalMerchantApi"
architecture_ref: "dynamic-continuum-runtime"
---

# Deal Creation Merchant Sync

## Summary

During the deal creation workflow, the Marketing Deal Service needs up-to-date merchant profile and contact data to associate with the new deal. It calls UMAPI to synchronize this information. This flow is referenced in the central Continuum runtime dynamic view (`dynamic-continuum-runtime`), confirming it is a key cross-service interaction in the deal lifecycle.

## Trigger

- **Type**: api-call
- **Source**: Marketing Deal Service, as part of the deal creation pipeline
- **Frequency**: On demand (per deal creation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Marketing Deal Service | Requests merchant profile data during deal creation | `continuumMarketingDealService` |
| Universal Merchant API (UMAPI) | Returns merchant profile and contact data | `continuumUniversalMerchantApi` |

## Steps

1. **Merchant sync request**: During deal creation, Marketing Deal Service calls UMAPI to fetch the merchant's current profile and contact data.
   - From: `continuumMarketingDealService`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTP

2. **Data retrieval**: UMAPI queries its data store for the merchant profile associated with the deal.
   - From: `continuumUniversalMerchantApi`
   - To: Internal data store (not modeled)
   - Protocol: Direct (database query)

3. **Response**: UMAPI returns the merchant profile and contact data to the Marketing Deal Service.
   - From: `continuumUniversalMerchantApi`
   - To: `continuumMarketingDealService`
   - Protocol: HTTP/JSON

4. **Deal association**: Marketing Deal Service associates the merchant data with the deal being created and continues the deal creation pipeline.
   - From: `continuumMarketingDealService`
   - To: Internal processing
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant not found | Deal creation fails or uses cached data (inferred) | Deal may not be created without valid merchant |
| UMAPI timeout | Marketing Deal Service may retry or fail the deal creation (inferred) | Deal creation delayed or blocked |
| Stale merchant data | UMAPI returns latest persisted state | Deal created with most recent available data |

## Sequence Diagram

```
continuumMarketingDealService -> continuumUniversalMerchantApi: Sync merchant profile (HTTP)
continuumUniversalMerchantApi -> DataStore: Query merchant profile and contacts
DataStore --> continuumUniversalMerchantApi: Return merchant data
continuumUniversalMerchantApi --> continuumMarketingDealService: Merchant profile + contact data (JSON)
continuumMarketingDealService -> continuumMarketingDealService: Associate merchant with deal
```

## Related

- Architecture dynamic view: `dynamic-continuum-runtime`
- Related flows: [Merchant Profile Lookup](merchant-profile-lookup.md), [Merchant Onboarding](merchant-onboarding.md)
