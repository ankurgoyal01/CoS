---
service: "itier-3pip-merchant-onboarding"
title: "Mindbody Onboarding Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "mindbody-onboarding"
flow_type: synchronous
trigger: "Merchant clicks 'Connect Mindbody' in the onboarding UI"
participants:
  - "continuumMerchantOnboardingItier"
  - "merchantRoutes"
  - "merchantOauthHandlers"
  - "merchantApiClient"
  - "continuumUniversalMerchantApi"
  - "continuumPartnerService"
architecture_ref: "dynamic-mindbody-onboarding"
---

# Mindbody Onboarding Flow

## Summary

This flow guides a Groupon merchant through activating their Mindbody account connection with Groupon. The service uses `@grpn/mindbody-client` to orchestrate the Mindbody OAuth and API activation steps, then persists the resulting partner mapping through the Universal Merchant API and Partner Service.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to the Mindbody onboarding page in the 3PIP Merchant Onboarding UI
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Initiates onboarding; receives redirects | — |
| Route Handlers | Receives install request; orchestrates Mindbody flow | `merchantRoutes` |
| OAuth Callback Handlers | Handles Mindbody OAuth load and callback | `merchantOauthHandlers` |
| Integration API Client | Calls internal APIs to persist onboarding state | `merchantApiClient` |
| Universal Merchant API | Stores merchant-partner mapping and auth state | `continuumUniversalMerchantApi` |
| Partner Service | Triggers partner self-service onboarding | `continuumPartnerService` |
| Mindbody API Platform | Issues OAuth credentials; handles activation | stub-only |

## Steps

1. **Receives install request**: Merchant browser sends a request to the Mindbody onboarding page.
   - From: `Merchant browser`
   - To: `merchantRoutes`
   - Protocol: HTTPS

2. **Dispatches to OAuth handler**: Route handler forwards the request to the Mindbody-specific OAuth callback handler.
   - From: `merchantRoutes`
   - To: `merchantOauthHandlers`
   - Protocol: direct

3. **Redirects merchant to Mindbody**: Service redirects the merchant to the Mindbody OAuth authorization/activation page.
   - From: `merchantOauthHandlers`
   - To: `Mindbody API Platform`
   - Protocol: HTTPS Redirect

4. **Merchant authorizes on Mindbody**: Merchant logs in to Mindbody and approves the integration.
   - From: `Merchant browser`
   - To: `Mindbody API Platform`
   - Protocol: HTTPS

5. **Receives OAuth callback**: Mindbody redirects the merchant browser back to the service callback endpoint with authorization credentials.
   - From: `Mindbody API Platform`
   - To: `merchantRoutes`
   - Protocol: HTTPS Redirect

6. **Completes Mindbody OAuth authorization**: OAuth handler calls Mindbody API via `@grpn/mindbody-client` to complete the authorization.
   - From: `merchantOauthHandlers`
   - To: `Mindbody API Platform`
   - Protocol: HTTPS/API

7. **Persists merchant partner mapping**: API client writes the partner credentials and mapping to the Universal Merchant API.
   - From: `merchantApiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

8. **Triggers partner self-service onboarding**: API client calls Partner Service to activate the merchant's Mindbody integration.
   - From: `merchantApiClient`
   - To: `continuumPartnerService`
   - Protocol: HTTPS/JSON

9. **Redirects merchant to Merchant Center**: On successful onboarding, the service redirects the merchant to their Merchant Center page.
   - From: `merchantRoutes`
   - To: `merchantCenter`
   - Protocol: HTTPS Redirect

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Mindbody API authorization failure | OAuth handler catches error from `@grpn/mindbody-client` | Merchant shown error page; no mapping persisted |
| `continuumUniversalMerchantApi` unavailable | `merchantApiClient` returns error | Merchant shown error page; onboarding incomplete |
| `continuumPartnerService` unavailable | `merchantApiClient` returns error | Merchant shown partial error; mapping may be persisted but activation incomplete |

## Sequence Diagram

```
Merchant browser -> merchantRoutes: GET /mindbody/install
merchantRoutes -> merchantOauthHandlers: Dispatch Mindbody install
merchantOauthHandlers --> Merchant browser: HTTP 302 Redirect to Mindbody OAuth
Merchant browser -> Mindbody API Platform: Authorizes integration
Mindbody API Platform --> Merchant browser: HTTP 302 Redirect to /oauth-redirect
Merchant browser -> merchantRoutes: GET /oauth-redirect (Mindbody callback)
merchantRoutes -> merchantOauthHandlers: Dispatch Mindbody callback
merchantOauthHandlers -> Mindbody API Platform: Complete OAuth via @grpn/mindbody-client
Mindbody API Platform --> merchantOauthHandlers: Credentials/activation response
merchantOauthHandlers -> merchantApiClient: Persist partner mapping
merchantApiClient -> continuumUniversalMerchantApi: PUT merchant partner mapping
continuumUniversalMerchantApi --> merchantApiClient: 200 OK
merchantApiClient -> continuumPartnerService: POST trigger onboarding
continuumPartnerService --> merchantApiClient: 200 OK
merchantRoutes --> Merchant browser: HTTP 302 Redirect to Merchant Center
```

## Related

- Architecture dynamic view: `dynamic-mindbody-onboarding` (no evidence of a defined dynamic view in DSL)
- Related flows: [Square Onboarding](square-onboarding.md), [Shopify Onboarding](shopify-onboarding.md), [Connection Management](connection-management.md)
