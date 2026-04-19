---
service: "merchant-prep-service"
title: "Merchant Self-Prep Step Completion"
generated: "2026-03-03"
type: flow
flow_name: "merchant-self-prep-step-completion"
flow_type: synchronous
trigger: "Merchant submits a completed prep step via Merchant Center UI"
participants:
  - "continuumMerchantPrepService"
  - "continuumMerchantPrepPrimaryDb"
  - "salesForce"
architecture_ref: "components-merchant-prep-service"
---

# Merchant Self-Prep Step Completion

## Summary

This flow represents the core of the merchant self-prep workflow. When a merchant completes a prep step — such as submitting their tax information, company type, billing address, or business owner details — the Merchant Preparation Service validates the submitted data, persists the step's completion state to the primary PostgreSQL database, writes the updated field values to Salesforce, and appends an audit entry. The flow is fully synchronous and request-scoped.

## Trigger

- **Type**: user-action
- **Source**: Merchant Center front-end sends a PUT or POST request to the service (via UMAPI proxy)
- **Frequency**: On-demand, once per step completion attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center (front-end / UMAPI) | Initiates the request on behalf of the authenticated merchant | — |
| Merchant Prep API | Receives and routes the HTTP request to the domain service | `continuumMerchantPrepService` / `mps_merchantPrepApi` |
| Onboarding Domain Services | Validates input, orchestrates persistence and Salesforce update | `continuumMerchantPrepService` / `mps_onboardingDomain` |
| Persistence Layer (Primary DB) | Persists step completion state and audit entry | `continuumMerchantPrepPrimaryDb` / `mps_persistenceLayer` |
| Salesforce | System-of-record update for account/opportunity fields | `salesForce` |

## Steps

1. **Receives prep step submission**: Merchant Center sends a `PUT /merchant-self-prep/v1/accounts/{salesforceId}/taxInfo` (or equivalent) with the field payload.
   - From: `Merchant Center / UMAPI`
   - To: `continuumMerchantPrepService` (`mps_merchantPrepApi`)
   - Protocol: REST (HTTP/JSON)

2. **Validates submitted data**: The API layer deserializes the request body into the generated model (e.g., `TaxInfo`) and forwards it to the Onboarding Domain Service.
   - From: `mps_merchantPrepApi`
   - To: `mps_onboardingDomain`
   - Protocol: direct (in-process)

3. **Persists step completion state**: The domain service writes the updated step status and submitted values to the primary database via the JDBI DAO.
   - From: `mps_onboardingDomain` via `mps_persistenceLayer`
   - To: `continuumMerchantPrepPrimaryDb`
   - Protocol: JDBC

4. **Appends audit entry**: The `AuditEntryService` writes an audit record capturing the change, timestamp, and actor.
   - From: `mps_onboardingDomain` via `mps_persistenceLayer` (`AuditEntryDao`)
   - To: `continuumMerchantPrepPrimaryDb`
   - Protocol: JDBC

5. **Updates Salesforce**: The integration client calls the Salesforce REST API to update the corresponding account or opportunity field (e.g., TIN status, billing address, opportunity stage).
   - From: `mps_onboardingDomain` via `mps_integrationClients`
   - To: `salesForce`
   - Protocol: REST (HTTP/JSON with OAuth2 token)

6. **Returns response**: The API layer returns a success response (HTTP 200) with the updated resource representation to the caller.
   - From: `continuumMerchantPrepService`
   - To: `Merchant Center / UMAPI`
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | RxJava 3 error propagation; no retry in sync path | HTTP 5xx returned to caller; state not updated in SF |
| Invalid field data | Request validation in generated stub layer | HTTP 400 returned; no DB write |
| Database write failure | JDBI exception propagates | HTTP 5xx returned; Salesforce not updated (SF update is downstream) |
| OAuth2 token expired | SalesforceClientCustomizer refreshes token | Transparent retry; step completes successfully |

## Sequence Diagram

```
MerchantCenter -> MerchantPrepAPI: PUT /merchant-self-prep/v1/accounts/{sfId}/taxInfo
MerchantPrepAPI -> OnboardingDomain: validateAndProcess(taxInfo)
OnboardingDomain -> PrimaryDB: upsert step state (AccountStepsDao / OpportunityStepsDao)
OnboardingDomain -> PrimaryDB: insert audit entry (AuditEntryDao)
OnboardingDomain -> Salesforce: PATCH account fields (SalesforceClient)
Salesforce --> OnboardingDomain: 200 OK
OnboardingDomain --> MerchantPrepAPI: success
MerchantPrepAPI --> MerchantCenter: 200 OK (updated resource)
```

## Related

- Architecture dynamic view: `components-merchant-prep-service`
- Related flows: [Payment Information Update](payment-info-update.md), [Onboarding Checklist Progression](onboarding-checklist-progression.md)
