---
service: "itier-3pip-merchant-onboarding"
title: "SSO Token Verification Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "sso-token-verification"
flow_type: synchronous
trigger: "Merchant arrives at the service via an SSO deep link"
participants:
  - "continuumMerchantOnboardingItier"
  - "merchantRoutes"
  - "merchantOauthHandlers"
architecture_ref: "dynamic-sso-token-verification"
---

# SSO Token Verification Flow

## Summary

When a merchant arrives at the 3PIP Merchant Onboarding service via an SSO deep link (e.g., from Merchant Center or an email), the service must decode and validate the Okta-signed JWT carried in the request. This flow establishes the merchant's verified identity before any onboarding or connection management action proceeds.

## Trigger

- **Type**: api-call
- **Source**: Merchant browser or upstream service posts an Okta-signed SSO token to `POST /decode-sso-token`
- **Frequency**: on-demand (every SSO-initiated entry into the service)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser / upstream service | Submits the SSO token for verification | — |
| Route Handlers | Receives `POST /decode-sso-token`; invokes verification | `merchantRoutes` |
| OAuth Callback Handlers | Delegates JWT decode to `itier-user-auth` / `@okta/jwt-verifier` | `merchantOauthHandlers` |

## Steps

1. **Receives SSO token**: Merchant browser or upstream service posts `POST /decode-sso-token` with the Okta JWT in the request body.
   - From: `Merchant browser / upstream service`
   - To: `merchantRoutes`
   - Protocol: HTTPS/JSON

2. **Routes to verification handler**: Route handler delegates the token to the OAuth/identity handler.
   - From: `merchantRoutes`
   - To: `merchantOauthHandlers`
   - Protocol: direct

3. **Validates JWT signature and claims**: `@okta/jwt-verifier` validates the token against the configured Okta issuer, client ID, and claims.
   - From: `merchantOauthHandlers`
   - To: `@okta/jwt-verifier` (in-process)
   - Protocol: direct

4. **Returns verified identity claims**: On success, the handler returns the decoded merchant identity claims (user ID, email, roles) to the route handler.
   - From: `merchantOauthHandlers`
   - To: `merchantRoutes`
   - Protocol: direct

5. **Responds to caller**: Route handler returns the verified merchant identity payload.
   - From: `merchantRoutes`
   - To: `Merchant browser / upstream service`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JWT expired | `@okta/jwt-verifier` rejects token | 401 Unauthorized response |
| JWT signature invalid | `@okta/jwt-verifier` rejects token | 401 Unauthorized response |
| Incorrect issuer or client ID | `@okta/jwt-verifier` rejects token | 401 Unauthorized response |
| Malformed token (not parseable) | `@okta/jwt-verifier` throws parse error | 400 Bad Request response |

## Sequence Diagram

```
Merchant browser -> merchantRoutes: POST /decode-sso-token {token: "<okta-jwt>"}
merchantRoutes -> merchantOauthHandlers: Decode and verify SSO token
merchantOauthHandlers -> @okta/jwt-verifier: Validate JWT signature, issuer, claims
@okta/jwt-verifier --> merchantOauthHandlers: Verified claims payload
merchantOauthHandlers --> merchantRoutes: Merchant identity claims
merchantRoutes --> Merchant browser: 200 OK {merchantId, email, roles, ...}
```

## Related

- Architecture dynamic view: `dynamic-sso-token-verification` (no evidence of a defined dynamic view in DSL)
- Related flows: [MSS Onboarding](mss-onboarding.md), [Connection Management](connection-management.md)
