---
service: "itier-3pip-merchant-onboarding"
title: "Connection Management Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "connection-management"
flow_type: synchronous
trigger: "Merchant views or modifies an existing 3PIP partner connection"
participants:
  - "continuumMerchantOnboardingItier"
  - "merchantRoutes"
  - "merchantUi"
  - "merchantApiClient"
  - "continuumUniversalMerchantApi"
  - "continuumPartnerService"
architecture_ref: "dynamic-connection-management"
---

# Connection Management Flow

## Summary

The Connection Management flow allows a merchant to view the status of their existing 3PIP partner connections (Square, Mindbody, Shopify) and take actions such as re-authorizing or disconnecting a linked account. The service retrieves the current connection state from the Universal Merchant API and renders it in the Onboarding UI, then processes any modification actions through Partner Service.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to the partner connection management page in the 3PIP Merchant Onboarding UI
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Requests connection status; submits modification actions | — |
| Route Handlers | Handles page requests and action submissions | `merchantRoutes` |
| Onboarding UI | Renders connection state and management controls | `merchantUi` |
| Integration API Client | Retrieves and updates connection state | `merchantApiClient` |
| Universal Merchant API | Source of truth for merchant-partner mappings | `continuumUniversalMerchantApi` |
| Partner Service | Processes disconnection or re-authorization requests | `continuumPartnerService` |

## Steps

1. **Receives connection management page request**: Merchant browser requests the connection management page for a specific partner.
   - From: `Merchant browser`
   - To: `merchantRoutes`
   - Protocol: HTTPS

2. **Fetches current connection state**: API client reads the merchant's 3PIP mapping and auth state from the Universal Merchant API.
   - From: `merchantApiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

3. **Renders connection management UI**: Route handler passes connection state to the Onboarding UI for rendering.
   - From: `merchantRoutes`
   - To: `merchantUi`
   - Protocol: direct (server-side render)

4. **Displays current connection status**: The Onboarding UI presents the connection state and available actions (reconnect/disconnect) to the merchant.
   - From: `merchantUi`
   - To: `Merchant browser`
   - Protocol: HTTPS (rendered HTML)

5. **(Optional) Merchant submits action**: Merchant clicks to disconnect or re-authorize a partner connection.
   - From: `Merchant browser`
   - To: `merchantRoutes`
   - Protocol: HTTPS

6. **(Optional) Executes partner auth operation**: API client calls Partner Service to process the disconnect or re-authorization action.
   - From: `merchantApiClient`
   - To: `continuumPartnerService`
   - Protocol: HTTPS/JSON

7. **(Optional) Updates merchant mapping**: API client writes the updated connection state back to the Universal Merchant API.
   - From: `merchantApiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

8. **Returns updated connection state**: Service re-renders the connection management page with the updated state.
   - From: `merchantRoutes`
   - To: `Merchant browser`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `continuumUniversalMerchantApi` unavailable | `merchantApiClient` returns error | Error page displayed; connection state unavailable |
| `continuumPartnerService` returns error on action | `merchantApiClient` propagates error | Action fails; merchant shown error; existing mapping unchanged |
| Merchant has no existing connection | Route handler renders empty connection state | Merchant shown "not connected" UI |

## Sequence Diagram

```
Merchant browser -> merchantRoutes: GET /square/manage (or /mindbody/manage, /shopify/manage)
merchantRoutes -> merchantApiClient: Fetch connection state
merchantApiClient -> continuumUniversalMerchantApi: GET merchant 3PIP mapping
continuumUniversalMerchantApi --> merchantApiClient: Mapping + auth state
merchantRoutes -> merchantUi: Render connection management UI
merchantUi --> Merchant browser: Connection status page
Merchant browser -> merchantRoutes: POST disconnect/reconnect action
merchantRoutes -> merchantApiClient: Execute partner auth operation
merchantApiClient -> continuumPartnerService: POST/DELETE partner connection
continuumPartnerService --> merchantApiClient: Operation result
merchantApiClient -> continuumUniversalMerchantApi: PUT updated mapping state
continuumUniversalMerchantApi --> merchantApiClient: 200 OK
merchantRoutes --> Merchant browser: Updated connection state page
```

## Related

- Architecture dynamic view: `dynamic-connection-management` (no evidence of a defined dynamic view in DSL)
- Related flows: [Square Onboarding](square-onboarding.md), [Mindbody Onboarding](mindbody-onboarding.md), [Shopify Onboarding](shopify-onboarding.md)
