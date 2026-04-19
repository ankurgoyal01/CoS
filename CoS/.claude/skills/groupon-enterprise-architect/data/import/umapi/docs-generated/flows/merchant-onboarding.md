---
service: "umapi"
title: "Merchant Onboarding"
generated: "2026-03-03"
type: flow
flow_name: "merchant-onboarding"
flow_type: synchronous
trigger: "API request from Merchant Center or onboarding service"
participants:
  - "continuumMerchantCenterWeb"
  - "continuumUniversalMerchantApi"
  - "messageBus"
  - "continuumMerchantOnboardingItier"
architecture_ref: ""
---

# Merchant Onboarding

## Summary

A new merchant is onboarded through UMAPI, typically initiated by the Merchant Center Web UI or the 3PIP Merchant Onboarding iTier. UMAPI creates the merchant profile, persists the data, and publishes lifecycle events to the Message Bus so downstream consumers can react to the new merchant (e.g., syncing to M3 Merchant Service, updating search indexes).

## Trigger

- **Type**: api-call
- **Source**: Merchant Center Web UI, 3PIP Merchant Onboarding iTier, or other onboarding workflows
- **Frequency**: On demand (per merchant registration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center Web | Initiates merchant registration via UI | `continuumMerchantCenterWeb` |
| 3PIP Merchant Onboarding iTier | Initiates 3PIP merchant mapping and onboarding | `continuumMerchantOnboardingItier` |
| Universal Merchant API (UMAPI) | Processes onboarding request, persists data, publishes events | `continuumUniversalMerchantApi` |
| Message Bus | Carries merchant lifecycle events to downstream consumers | `messageBus` |

## Steps

1. **Onboarding request**: The Merchant Center or onboarding service submits a merchant registration request.
   - From: `continuumMerchantCenterWeb` or `continuumMerchantOnboardingItier`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

2. **Validation and persistence**: UMAPI validates the merchant data and persists the new merchant profile to its data store.
   - From: `continuumUniversalMerchantApi`
   - To: Internal data store (not modeled)
   - Protocol: Direct (database write)

3. **Event publication**: UMAPI publishes a merchant-created event to the Message Bus for downstream consumers.
   - From: `continuumUniversalMerchantApi`
   - To: `messageBus`
   - Protocol: Async (ActiveMQ Artemis)

4. **Confirmation response**: UMAPI returns a success response with the created merchant profile.
   - From: `continuumUniversalMerchantApi`
   - To: Requesting consumer
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate merchant | Return conflict error (inferred) | Consumer handles duplicate detection |
| Validation failure | Return 400 with validation details (inferred) | Consumer corrects input |
| Database write failure | Return 5xx error (inferred) | No event published; consumer can retry |
| Message Bus unavailable | Merchant persisted but event not published (inferred) | Downstream consumers may not be notified; eventual consistency via retry or reconciliation |

## Sequence Diagram

```
MerchantCenter -> continuumUniversalMerchantApi: POST /merchants (onboarding payload)
continuumUniversalMerchantApi -> DataStore: Persist merchant profile
DataStore --> continuumUniversalMerchantApi: Confirm write
continuumUniversalMerchantApi -> messageBus: Publish merchant-created event (Async)
continuumUniversalMerchantApi --> MerchantCenter: 201 Created (merchant profile)
messageBus -> DownstreamConsumers: Deliver merchant-created event
```

## Related

- Related flows: [Merchant Profile Lookup](merchant-profile-lookup.md), [Deal Creation Merchant Sync](deal-creation-merchant-sync.md)
