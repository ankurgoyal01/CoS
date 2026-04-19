---
service: "itier-3pip-merchant-onboarding"
title: "MSS Onboarding Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "mss-onboarding"
flow_type: synchronous
trigger: "Merchant submits the MSS onboarding form"
participants:
  - "continuumMerchantOnboardingItier"
  - "merchantRoutes"
  - "merchantUi"
  - "merchantApiClient"
  - "continuumPartnerService"
  - "continuumUsersService"
  - "salesForce"
architecture_ref: "dynamic-mss-onboarding"
---

# MSS Onboarding Flow

## Summary

The MSS (Merchant Self-Service) onboarding flow handles the form-based activation path where a merchant submits their onboarding data directly rather than completing a full OAuth redirect cycle. The service validates the merchant's identity via Users Service, submits onboarding details to Partner Service, and synchronizes the resulting state to Salesforce CRM.

## Trigger

- **Type**: user-action
- **Source**: Merchant completes and submits the MSS onboarding form via the Onboarding UI
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Submits onboarding form | — |
| Route Handlers | Receives `POST /mss-onboarding`; validates request | `merchantRoutes` |
| Onboarding UI | Renders the MSS form to the merchant | `merchantUi` |
| Integration API Client | Orchestrates downstream API calls | `merchantApiClient` |
| Partner Service | Receives and processes the MSS onboarding submission | `continuumPartnerService` |
| Users Service | Provides merchant user profile for identity validation | `continuumUsersService` |
| Salesforce CRM | Receives CRM state update post-activation | `salesForce` |

## Steps

1. **Renders MSS onboarding form**: The Onboarding UI presents the MSS form to the merchant in the browser.
   - From: `merchantRoutes`
   - To: `merchantUi`
   - Protocol: direct (server-side render)

2. **Receives form submission**: Merchant browser submits `POST /mss-onboarding` with onboarding payload.
   - From: `Merchant browser`
   - To: `merchantRoutes`
   - Protocol: HTTPS/JSON

3. **Fetches merchant profile**: API client retrieves the merchant's user profile to validate identity.
   - From: `merchantApiClient`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Submits MSS onboarding to Partner Service**: API client posts the validated onboarding data to Partner Service for activation.
   - From: `merchantApiClient`
   - To: `continuumPartnerService`
   - Protocol: HTTPS/JSON

5. **Synchronizes CRM state**: API client updates Salesforce CRM with the new onboarding/activation state.
   - From: `merchantApiClient`
   - To: `salesForce`
   - Protocol: HTTPS/JSON

6. **Returns success response**: Route handler returns success and redirects or renders confirmation to the merchant.
   - From: `merchantRoutes`
   - To: `Merchant browser`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or invalid request payload | Route handler validates and rejects | 400 response; merchant shown validation errors |
| `continuumUsersService` unavailable | `merchantApiClient` returns error | 502/503 response; onboarding blocked |
| `continuumPartnerService` returns validation error | `merchantApiClient` propagates error | 4xx response; merchant shown Partner Service error |
| Salesforce CRM unavailable | `merchantApiClient` returns error | Onboarding may succeed but CRM sync is incomplete; log error |

## Sequence Diagram

```
Merchant browser -> merchantRoutes: POST /mss-onboarding {payload}
merchantRoutes -> merchantApiClient: Orchestrate MSS onboarding
merchantApiClient -> continuumUsersService: GET merchant user profile
continuumUsersService --> merchantApiClient: User profile response
merchantApiClient -> continuumPartnerService: POST MSS onboarding data
continuumPartnerService --> merchantApiClient: Activation confirmation
merchantApiClient -> salesForce: POST CRM onboarding state update
salesForce --> merchantApiClient: 200 OK
merchantRoutes --> Merchant browser: 200 OK / onboarding confirmation
```

## Related

- Architecture dynamic view: `dynamic-mss-onboarding` (no evidence of a defined dynamic view in DSL)
- Related flows: [SSO Token Verification](sso-token-verification.md), [Connection Management](connection-management.md)
