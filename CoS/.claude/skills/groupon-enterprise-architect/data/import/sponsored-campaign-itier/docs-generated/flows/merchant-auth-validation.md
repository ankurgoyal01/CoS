---
service: "sponsored-campaign-itier"
title: "Merchant Auth Validation"
generated: "2026-03-02"
type: flow
flow_name: "merchant-auth-validation"
flow_type: synchronous
trigger: "Every inbound HTTP request to the service"
participants:
  - "Merchant (browser)"
  - "continuumSponsoredCampaignItier"
  - "continuumSponsoredCampaignItier_authMiddleware"
  - "continuumSponsoredCampaignItier_featureFlagsClient"
  - "continuumMerchantApi"
  - "continuumBirdcageService"
architecture_ref: "components-continuum-sponsored-campaign-itier"
---

# Merchant Auth Validation

## Summary

Every request to `sponsored-campaign-itier` passes through a shared authentication and authorization middleware chain before any route handler executes. The `itier-user-auth` middleware validates the `authToken` session cookie against the Merchant API. The `@grpn/mx-merchant` and layout service middleware then check feature flags via Birdcage to determine which sponsored campaign capabilities the merchant is authorized to access (e.g., gating internal-only merchants or pre-launch features). Requests that fail auth or flag checks are rejected before any proxy or rendering work is performed.

## Trigger

- **Type**: api-call
- **Source**: Every inbound HTTP request — both UI page routes and API proxy routes
- **Frequency**: per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Sends request with cookies | — |
| Sponsored Campaign iTier | BFF — runs middleware chain on every request | `continuumSponsoredCampaignItier` |
| Merchant Auth Middleware | Validates authToken session cookie via itier-user-auth | `continuumSponsoredCampaignItier_authMiddleware` |
| Feature Flags Client | Evaluates feature flags to gate route access | `continuumSponsoredCampaignItier_featureFlagsClient` |
| Merchant API | Validates session and returns merchant identity | `continuumMerchantApi` |
| Birdcage Service | Evaluates feature flags for this merchant | `continuumBirdcageService` |

## Steps

1. **Receive inbound request**: Any request arrives at `continuumSponsoredCampaignItier` with cookies attached.
   - From: `Merchant (browser)`
   - To: `continuumSponsoredCampaignItier`
   - Protocol: REST/HTTP

2. **Extract session cookies**: itier-server middleware extracts `authToken` and `mc_mid` cookies from the request.
   - From: `continuumSponsoredCampaignItier`
   - To: `continuumSponsoredCampaignItier_authMiddleware` (in-process)
   - Protocol: In-process middleware

3. **Validate authToken with Merchant API**: `itier-user-auth` middleware calls the Merchant API to validate the session token and retrieve merchant identity.
   - From: `continuumSponsoredCampaignItier_authMiddleware`
   - To: `continuumMerchantApi`
   - Protocol: REST/HTTP

4. **Reject unauthenticated requests**: If the authToken is invalid or expired, the middleware returns 401 or redirects to login. No further processing occurs.
   - From: `continuumSponsoredCampaignItier_authMiddleware`
   - To: `Merchant (browser)`
   - Protocol: HTTP 401 / redirect

5. **Evaluate feature flags**: For authenticated requests, Feature Flags Client evaluates relevant flags for the merchant.
   - From: `continuumSponsoredCampaignItier_featureFlagsClient`
   - To: `continuumBirdcageService`
   - Protocol: REST/HTTP

6. **Apply feature-flag access guards**: Middleware applies flag results — e.g., `restrictInternalUsersFeature.enabled` blocks internal-only merchants from certain routes; `preLaunchFeature.enabled` controls pre-launch access.
   - From: `continuumSponsoredCampaignItier_featureFlagsClient` (in-process)
   - To: Route handler (in-process)
   - Protocol: In-process guard

7. **Pass request to route handler**: If all guards pass, the request proceeds to the appropriate UI route or API proxy handler.
   - From: `continuumSponsoredCampaignItier`
   - To: Route handler (UI render or API proxy)
   - Protocol: In-process Express routing

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing authToken cookie | `itier-user-auth` rejects immediately | HTTP 401 or redirect to Merchant Center login |
| Expired session token | `itier-user-auth` validates and rejects | HTTP 401 or redirect to login |
| Merchant API unavailable | Auth middleware cannot validate session | All requests blocked until Merchant API recovers |
| Birdcage unavailable | Feature flags default to disabled | Merchants may lose access to flag-gated features; core flows continue if flags default gracefully |
| Internal-only merchant on restricted route | `restrictInternalUsersFeature.enabled` guard rejects | Access denied response |

## Sequence Diagram

```
Merchant         -> BFF:               Any HTTP request (with authToken, mc_mid cookies)
BFF              -> AuthMiddleware:     Extract and validate cookies (in-process)
AuthMiddleware   -> MerchantAPI:        Validate authToken session
MerchantAPI      --> AuthMiddleware:    Merchant identity or 401
AuthMiddleware   --> BFF:              Auth result
BFF              -> FeatureFlagsClient: Evaluate flags for merchant (in-process)
FeatureFlagsClient -> Birdcage:        GET feature flag states
Birdcage         --> FeatureFlagsClient: Flag values
FeatureFlagsClient -> BFF:             Apply access guards
BFF              -> RouteHandler:       Pass request if all guards pass
BFF              --> Merchant:          401 / redirect if auth or flag check fails
```

## Related

- Related flows: [Create Sponsored Campaign](create-sponsored-campaign.md), [View Campaign Performance](view-campaign-performance.md), [Wallet Top-Up](wallet-topup.md), [Campaign Status Toggle](campaign-status-toggle.md), [Delete Campaign](delete-campaign.md)
- Architecture component view: `components-continuum-sponsored-campaign-itier`
