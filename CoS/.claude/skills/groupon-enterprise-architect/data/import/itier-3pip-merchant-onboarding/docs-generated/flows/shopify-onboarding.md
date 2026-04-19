---
service: "itier-3pip-merchant-onboarding"
title: "Shopify Onboarding Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "shopify-onboarding"
flow_type: synchronous
trigger: "Merchant clicks 'Connect Shopify' in the onboarding UI"
participants:
  - "continuumMerchantOnboardingItier"
  - "merchantRoutes"
  - "merchantOauthHandlers"
  - "merchantApiClient"
  - "continuumUniversalMerchantApi"
  - "continuumPartnerService"
architecture_ref: "dynamic-shopify-onboarding"
---

# Shopify Onboarding Flow

## Summary

This flow guides a Groupon merchant through connecting their Shopify store to Groupon via OAuth2. The service redirects the merchant to Shopify's authorization page, handles the callback, exchanges the authorization code, and persists the resulting merchant-partner mapping to the Universal Merchant API and Partner Service.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to the Shopify onboarding page in the 3PIP Merchant Onboarding UI
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
| Shopify OAuth Platform | Issues authorization code; validates token exchange | stub-only |

## Steps

1. **Receives install request**: Merchant browser sends `GET /install` to the Shopify-specific route.
   - From: `Merchant browser`
   - To: `merchantRoutes`
   - Protocol: HTTPS

2. **Builds OAuth redirect URL**: Route handler constructs the Shopify OAuth authorization URL with API key, scopes, and state parameter.
   - From: `merchantRoutes`
   - To: `merchantOauthHandlers`
   - Protocol: direct

3. **Redirects merchant to Shopify**: Service responds with an HTTP redirect to the Shopify OAuth authorization page.
   - From: `merchantOauthHandlers`
   - To: `Shopify OAuth Platform`
   - Protocol: HTTPS Redirect

4. **Merchant authorizes on Shopify**: Merchant logs in to Shopify and approves the Groupon integration.
   - From: `Merchant browser`
   - To: `Shopify OAuth Platform`
   - Protocol: HTTPS

5. **Receives OAuth callback**: Shopify redirects the merchant browser back to `GET /oauth-redirect` with authorization code and state.
   - From: `Shopify OAuth Platform`
   - To: `merchantRoutes`
   - Protocol: HTTPS Redirect

6. **Dispatches callback to handler**: Route handler forwards the callback to the Shopify-specific OAuth handler.
   - From: `merchantRoutes`
   - To: `merchantOauthHandlers`
   - Protocol: direct

7. **Completes Shopify OAuth authorization**: OAuth handler exchanges the authorization code with the Shopify platform.
   - From: `merchantOauthHandlers`
   - To: `Shopify OAuth Platform`
   - Protocol: HTTPS/JSON

8. **Persists merchant partner mapping**: API client writes the partner access token and mapping to the Universal Merchant API.
   - From: `merchantApiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

9. **Triggers partner self-service onboarding**: API client calls Partner Service to activate the merchant's Shopify integration.
   - From: `merchantApiClient`
   - To: `continuumPartnerService`
   - Protocol: HTTPS/JSON

10. **Redirects merchant to Merchant Center**: On success, the service redirects the merchant to their Merchant Center page.
    - From: `merchantRoutes`
    - To: `merchantCenter`
    - Protocol: HTTPS Redirect

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| State parameter mismatch on callback | OAuth handler rejects callback | Merchant shown error page; no state persisted |
| Shopify token exchange failure | OAuth handler catches error | Merchant shown error page; no mapping persisted |
| `continuumUniversalMerchantApi` unavailable | `merchantApiClient` returns error | Merchant shown error page; onboarding incomplete |
| `continuumPartnerService` unavailable | `merchantApiClient` returns error | Mapping may be persisted but activation incomplete |

## Sequence Diagram

```
Merchant browser -> merchantRoutes: GET /shopify/install
merchantRoutes -> merchantOauthHandlers: Build Shopify OAuth redirect URL
merchantOauthHandlers --> Merchant browser: HTTP 302 Redirect to Shopify OAuth
Merchant browser -> Shopify OAuth Platform: Authorizes integration
Shopify OAuth Platform --> Merchant browser: HTTP 302 Redirect to /oauth-redirect?code=...&state=...
Merchant browser -> merchantRoutes: GET /oauth-redirect (Shopify callback)
merchantRoutes -> merchantOauthHandlers: Dispatch Shopify callback
merchantOauthHandlers -> Shopify OAuth Platform: Exchange authorization code for token
Shopify OAuth Platform --> merchantOauthHandlers: Access token response
merchantOauthHandlers -> merchantApiClient: Persist partner mapping
merchantApiClient -> continuumUniversalMerchantApi: PUT merchant partner mapping + auth state
continuumUniversalMerchantApi --> merchantApiClient: 200 OK
merchantApiClient -> continuumPartnerService: POST trigger self-service onboarding
continuumPartnerService --> merchantApiClient: 200 OK
merchantRoutes --> Merchant browser: HTTP 302 Redirect to Merchant Center
```

## Related

- Architecture dynamic view: `dynamic-shopify-onboarding` (no evidence of a defined dynamic view in DSL)
- Related flows: [Square Onboarding](square-onboarding.md), [Mindbody Onboarding](mindbody-onboarding.md), [Connection Management](connection-management.md)
