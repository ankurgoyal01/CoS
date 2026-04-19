---
service: "itier-3pip-merchant-onboarding"
title: "Square Onboarding Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "square-onboarding"
flow_type: synchronous
trigger: "Merchant clicks 'Connect Square' in the onboarding UI"
participants:
  - "continuumMerchantOnboardingItier"
  - "merchantRoutes"
  - "merchantOauthHandlers"
  - "merchantApiClient"
  - "continuumUniversalMerchantApi"
  - "continuumPartnerService"
architecture_ref: "dynamic-square-oauth-callback"
---

# Square Onboarding Flow

## Summary

This flow guides a Groupon merchant through connecting their Square POS account to Groupon via OAuth2. The merchant is redirected to Square's authorization page, returns to the service via the OAuth callback, and the service exchanges the authorization code and persists the resulting merchant-partner mapping to the Universal Merchant API and Partner Service.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks 'Connect Square' or navigates to the Square onboarding page in the 3PIP Merchant Onboarding UI
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Initiates onboarding; receives redirects | — |
| Route Handlers | Receives install request; builds OAuth redirect URL | `merchantRoutes` |
| OAuth Callback Handlers | Receives OAuth callback; orchestrates token exchange | `merchantOauthHandlers` |
| Integration API Client | Calls internal APIs to persist onboarding state | `merchantApiClient` |
| Universal Merchant API | Stores merchant-partner mapping and auth state | `continuumUniversalMerchantApi` |
| Partner Service | Triggers partner self-service onboarding | `continuumPartnerService` |
| Square OAuth Platform | Issues authorization code; validates token exchange | stub-only |

## Steps

1. **Receives install request**: Merchant browser sends `GET /install` to the service.
   - From: `Merchant browser`
   - To: `merchantRoutes`
   - Protocol: HTTPS

2. **Builds OAuth redirect URL**: Route handler constructs the Square OAuth authorization URL with app ID, scopes, and state parameter.
   - From: `merchantRoutes`
   - To: `merchantOauthHandlers`
   - Protocol: direct

3. **Redirects merchant to Square**: Service responds with an HTTP redirect to the Square OAuth authorization page.
   - From: `merchantOauthHandlers`
   - To: `Square OAuth Platform`
   - Protocol: HTTPS Redirect

4. **Merchant authorizes on Square**: Merchant logs in to Square and approves the Groupon integration.
   - From: `Merchant browser`
   - To: `Square OAuth Platform`
   - Protocol: HTTPS

5. **Receives OAuth callback**: Square redirects the merchant browser back to `GET /oauth-redirect` with an authorization code and state parameter.
   - From: `Square OAuth Platform`
   - To: `merchantRoutes`
   - Protocol: HTTPS Redirect

6. **Dispatches callback to handler**: Route handler forwards the callback to the OAuth callback handler.
   - From: `merchantRoutes`
   - To: `merchantOauthHandlers`
   - Protocol: direct

7. **Validates authorization code**: OAuth handler validates the callback state parameter and exchanges the authorization code with the Square platform.
   - From: `merchantOauthHandlers`
   - To: `Square OAuth Platform`
   - Protocol: HTTPS/JSON

8. **Requests onboarding state update**: OAuth handler instructs the API client to persist the merchant-partner mapping.
   - From: `merchantOauthHandlers`
   - To: `merchantApiClient`
   - Protocol: direct

9. **Persists merchant partner mapping**: API client writes the partner auth token and mapping to the Universal Merchant API.
   - From: `merchantApiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

10. **Triggers partner self-service onboarding**: API client calls Partner Service to activate the merchant's Square integration when eligible.
    - From: `merchantApiClient`
    - To: `continuumPartnerService`
    - Protocol: HTTPS/JSON

11. **Redirects merchant to Merchant Center**: On successful onboarding, the service redirects the merchant to their Merchant Center deal/reservation page.
    - From: `merchantRoutes`
    - To: `merchantCenter`
    - Protocol: HTTPS Redirect

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| State parameter mismatch on callback | OAuth handler rejects callback | Merchant shown error page; no state persisted |
| Square token exchange failure | OAuth handler catches error | Merchant shown error page; no mapping persisted |
| `continuumUniversalMerchantApi` unavailable | `merchantApiClient` returns error | Merchant shown error page; onboarding incomplete |
| `continuumPartnerService` unavailable | `merchantApiClient` returns error | Merchant shown partial error; mapping may be persisted but activation incomplete |

## Sequence Diagram

```
Merchant browser -> merchantRoutes: GET /install
merchantRoutes -> merchantOauthHandlers: Build OAuth redirect URL
merchantOauthHandlers --> Merchant browser: HTTP 302 Redirect to Square OAuth
Merchant browser -> Square OAuth Platform: Authorizes integration
Square OAuth Platform --> Merchant browser: HTTP 302 Redirect to /oauth-redirect?code=...&state=...
Merchant browser -> merchantRoutes: GET /oauth-redirect?code=...&state=...
merchantRoutes -> merchantOauthHandlers: Dispatch OAuth callback
merchantOauthHandlers -> Square OAuth Platform: Exchange authorization code for token
Square OAuth Platform --> merchantOauthHandlers: Access token response
merchantOauthHandlers -> merchantApiClient: Persist partner mapping
merchantApiClient -> continuumUniversalMerchantApi: PUT merchant partner mapping + auth state
continuumUniversalMerchantApi --> merchantApiClient: 200 OK
merchantApiClient -> continuumPartnerService: POST trigger self-service onboarding
continuumPartnerService --> merchantApiClient: 200 OK
merchantRoutes --> Merchant browser: HTTP 302 Redirect to Merchant Center
```

## Related

- Architecture dynamic view: `dynamic-square-oauth-callback` (stub-only in local workspace)
- Related flows: [Mindbody Onboarding](mindbody-onboarding.md), [Shopify Onboarding](shopify-onboarding.md), [Connection Management](connection-management.md)
