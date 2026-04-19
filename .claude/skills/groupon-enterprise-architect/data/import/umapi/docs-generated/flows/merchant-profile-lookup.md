---
service: "umapi"
title: "Merchant Profile Lookup"
generated: "2026-03-03"
type: flow
flow_name: "merchant-profile-lookup"
flow_type: synchronous
trigger: "API request from upstream consumer"
participants:
  - "apiProxy"
  - "continuumUniversalMerchantApi"
  - "continuumMerchantPageService"
  - "continuumMerchantCenterWeb"
architecture_ref: ""
---

# Merchant Profile Lookup

## Summary

An upstream consumer (e.g., Merchant Center Web, Merchant Page Service, Mailman, Minos, or the mobile merchant app) requests merchant or place data from UMAPI. UMAPI retrieves the requested data from its data store and returns it. This is one of the highest-traffic flows through UMAPI, supporting merchant dashboards, page rendering, email context loading, and deduplication workflows.

## Trigger

- **Type**: api-call
- **Source**: Any upstream consumer needing merchant/place data
- **Frequency**: On demand, per-request (high volume)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Proxy | Routes external requests to UMAPI | `apiProxy` |
| Merchant Center Web | UI requesting merchant profile data | `continuumMerchantCenterWeb` |
| Merchant Page Service | Requests place data by slug for page rendering | `continuumMerchantPageService` |
| Universal Merchant API (UMAPI) | Retrieves and returns merchant/place data | `continuumUniversalMerchantApi` |

## Steps

1. **Request initiation**: An upstream consumer sends an HTTPS request to retrieve merchant or place data.
   - From: `apiProxy` or internal service (e.g., `continuumMerchantPageService`)
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

2. **Data retrieval**: UMAPI queries its internal data store for the requested merchant or place record.
   - From: `continuumUniversalMerchantApi`
   - To: Internal data store (not modeled)
   - Protocol: Direct (database query)

3. **Response**: UMAPI returns the merchant/place data as a JSON response.
   - From: `continuumUniversalMerchantApi`
   - To: Requesting consumer
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant not found | Return 404 response (inferred) | Consumer handles missing merchant gracefully |
| Database timeout | Return 5xx error (inferred) | Consumer retries or displays error |
| Invalid request parameters | Return 400 response (inferred) | Consumer adjusts request |

## Sequence Diagram

```
Consumer -> apiProxy: GET /merchants/{id} or /places/{slug}
apiProxy -> continuumUniversalMerchantApi: Forward request (JSON/HTTPS)
continuumUniversalMerchantApi -> DataStore: Query merchant/place data
DataStore --> continuumUniversalMerchantApi: Return record
continuumUniversalMerchantApi --> apiProxy: 200 OK (JSON)
apiProxy --> Consumer: Merchant/place data
```

## Related

- Related flows: [Merchant Onboarding](merchant-onboarding.md), [Deal Creation Merchant Sync](deal-creation-merchant-sync.md)
