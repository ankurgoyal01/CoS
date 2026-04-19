---
service: "merchant-prep-service"
title: "Onboarding Checklist Progression"
generated: "2026-03-03"
type: flow
flow_name: "onboarding-checklist-progression"
flow_type: synchronous
trigger: "Merchant opens or interacts with the onboarding checklist in Merchant Center"
participants:
  - "continuumMerchantPrepService"
  - "continuumMerchantPrepPrimaryDb"
  - "salesForce"
architecture_ref: "components-merchant-prep-service"
---

# Onboarding Checklist Progression

## Summary

The onboarding checklist flow tracks new merchant progress through a structured set of getting-started tasks in Merchant Center. When a merchant or an internal system requests the checklist state, the service retrieves each checklist item's status from the primary database. When a merchant completes or skips a checklist item, the service updates the item status, and when all items are complete it updates the overall onboarding status. Campaign onboarding pop-ups have a parallel dismissal flow. The `onboardingEligibilityDate` configuration value controls whether a merchant is subject to the new or legacy onboarding experience.

## Trigger

- **Type**: user-action (and api-call for status queries)
- **Source**: Merchant Center front-end requests checklist status or submits a step completion; may also be triggered by internal services checking onboarding completion status
- **Frequency**: On-demand, per merchant session interaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center / UMAPI | Sends checklist status requests and step completion events | — |
| Merchant Prep API | Routes requests to domain service | `continuumMerchantPrepService` / `mps_merchantPrepApi` |
| Onboarding Domain Services | Evaluates checklist logic, determines item state, applies eligibility rules | `continuumMerchantPrepService` / `mps_onboardingDomain` |
| Persistence Layer (Primary DB) | Reads and writes `OnboardingStatusDao` and `OnboardingCampaignDao` records | `continuumMerchantPrepPrimaryDb` / `mps_persistenceLayer` |
| Salesforce | Read for opportunity/account context when needed | `salesForce` |

## Steps

### Get Checklist Status

1. **Receives status request**: Merchant Center sends `POST /merchant-self-prep/v1/accounts/{salesforceId}/merchantChecklistOnboarding` (with optional `isOldMerchant` flag).
   - From: `Merchant Center / UMAPI`
   - To: `continuumMerchantPrepService` (`mps_merchantPrepApi`)
   - Protocol: REST (HTTP/JSON)

2. **Determines onboarding variant**: Domain service compares the merchant's account creation date against `onboardingEligibilityDate` to select new vs. legacy checklist template.
   - From: `mps_onboardingDomain`
   - To: in-process config check
   - Protocol: direct

3. **Reads checklist item states**: `OnboardingStatusDao` queries the primary DB for all checklist item statuses for the account.
   - From: `mps_onboardingDomain` via `mps_persistenceLayer`
   - To: `continuumMerchantPrepPrimaryDb`
   - Protocol: JDBC

4. **Returns checklist with statuses**: Assembled checklist (items + completion states) returned.
   - From: `continuumMerchantPrepService`
   - To: `Merchant Center / UMAPI`
   - Protocol: REST (HTTP/JSON)

### Update a Checklist Item

1. **Receives item update**: Merchant Center sends `POST /merchant-self-prep/v1/accounts/{salesforceId}/merchantChecklistOnboarding/{checklistId}` with optional `skip=true` query parameter.
   - From: `Merchant Center / UMAPI`
   - To: `continuumMerchantPrepService` (`mps_merchantPrepApi`)
   - Protocol: REST (HTTP/JSON)

2. **Updates item state in DB**: `OnboardingStatusDao` upserts the checklist item record (complete or skipped).
   - From: `mps_onboardingDomain` via `mps_persistenceLayer`
   - To: `continuumMerchantPrepPrimaryDb`
   - Protocol: JDBC

3. **Returns updated status**: HTTP 200 with updated checklist item state.
   - From: `continuumMerchantPrepService`
   - To: `Merchant Center / UMAPI`
   - Protocol: REST (HTTP/JSON)

### Get Overall Completion Status

1. **Receives completion check**: `GET /merchant-self-prep/v1/accounts/{salesforceId}/merchantChecklistOnboardingStatus`
   - From: `Merchant Center / UMAPI`
   - To: `continuumMerchantPrepService`
   - Protocol: REST (HTTP/JSON)

2. **Aggregates item states**: Domain service reads all item statuses and computes overall completion.
   - From: `mps_onboardingDomain` via `mps_persistenceLayer`
   - To: `continuumMerchantPrepPrimaryDb`
   - Protocol: JDBC

3. **Returns boolean or status**: Overall onboarding completion status returned.
   - From: `continuumMerchantPrepService`
   - To: `Merchant Center / UMAPI`
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Checklist item not found | DAO returns empty result | HTTP 404 or empty list returned |
| Database unavailable | JDBI exception propagates | HTTP 5xx returned |
| Invalid checklist UUID | Deserialization failure | HTTP 400 returned |

## Sequence Diagram

```
MerchantCenter -> MerchantPrepAPI: POST /merchant-self-prep/v1/accounts/{sfId}/merchantChecklistOnboarding
MerchantPrepAPI -> OnboardingDomain: getChecklistStatus(sfId, isOldMerchant)
OnboardingDomain -> PrimaryDB: SELECT * FROM onboarding_status WHERE account_id = sfId
PrimaryDB --> OnboardingDomain: checklist item rows
OnboardingDomain --> MerchantPrepAPI: assembled checklist with statuses
MerchantPrepAPI --> MerchantCenter: 200 OK (checklist payload)
```

## Related

- Architecture dynamic view: `components-merchant-prep-service`
- Related flows: [Merchant Self-Prep Step Completion](merchant-self-prep-step-completion.md), [Flows Index](index.md)
