---
service: "doorman"
title: "SAML Authentication Initiation"
generated: "2026-03-03"
type: flow
flow_name: "saml-authentication-initiation"
flow_type: synchronous
trigger: "Internal user navigates to GET /authentication/initiation/:destination_id"
participants:
  - "internalUser"
  - "continuumDoormanService"
  - "oktaIdentityProvider"
architecture_ref: "components-doorman_components"
---

# SAML Authentication Initiation

## Summary

When an internal Groupon employee needs to access an internal tool, they are directed to Doorman's initiation endpoint with a registered `destination_id`. Doorman validates that the destination is in its allowlist, builds a SAML 2.0 `AuthnRequest` (including a `RelayState` carrying the destination context), and redirects the user's browser to Okta's SSO URL. This flow is purely a redirect — Doorman does not call any backend service during initiation.

## Trigger

- **Type**: user-action (browser navigation or redirect from destination tool)
- **Source**: Internal Groupon employee's browser, directed by a destination tool login page
- **Frequency**: On-demand — one initiation per authentication attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal user (browser) | Originates the request; receives redirect to Okta | — |
| Doorman | Validates destination; builds SAML AuthnRequest; issues HTTP 302 redirect | `continuumDoormanService` |
| Okta | Receives SAML AuthnRequest via browser redirect; presents login UI | `oktaIdentityProvider` |

## Steps

1. **Receives initiation request**: The user's browser sends `GET /authentication/initiation/:destination_id` to Doorman.
   - From: Internal user (browser)
   - To: `continuumDoormanService`
   - Protocol: HTTPS

2. **Validates destination ID**: Doorman checks whether `destination_id` is present as a key in the loaded `config/<env>/destinations.yml`. If not found, returns `404 not found`.
   - From: `authenticationController`
   - To: in-memory destinations configuration
   - Protocol: direct

3. **Builds SAML AuthnRequest**: Doorman calls `SamlAuthenticationRequestBuilder.build()`, which uses the `ruby-saml` library (`OneLogin::RubySaml::Authrequest`) to construct a SAML 2.0 `AuthnRequest`. The request includes:
   - `Issuer`: Doorman's host URL (e.g., `https://doorman-na.groupondev.com`)
   - `AssertionConsumerServiceURL`: `<doorman_host>/okta/saml/sso`
   - `AuthnContextClassRef`: `urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport`
   - `RelayState`: JSON `{"destinationId": "<id>", "destinationPath": "<optional override>"}` (Base64-encoded in the redirect URL)
   - From: `authenticationController`
   - To: `samlAuthRequestBuilder`
   - Protocol: direct

4. **Redirects browser to Okta**: Doorman responds with an HTTP 302 redirect to the Okta SSO URL, with the SAML `AuthnRequest` encoded in the query string (HTTP redirect binding).
   - From: `continuumDoormanService`
   - To: `oktaIdentityProvider`
   - Protocol: HTTPS redirect (SAML 2.0 HTTP Redirect Binding)

5. **Okta authenticates user**: The user's browser follows the redirect to Okta, which presents the Groupon login page. The user enters credentials and completes any MFA requirements.
   - From: Internal user (browser)
   - To: `oktaIdentityProvider`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `destination_id` not in destinations registry | Returns `404 not found` (plain text) | User sees 404; no redirect to Okta |
| Invalid or missing `destination_id` path parameter | Sinatra route not matched; `404 not found` | User sees 404 |

## Sequence Diagram

```
User Browser -> continuumDoormanService: GET /authentication/initiation/:destination_id
continuumDoormanService -> continuumDoormanService: Validate destination_id in destinations registry
continuumDoormanService -> samlAuthRequestBuilder: Build SAML AuthnRequest with RelayState
samlAuthRequestBuilder --> continuumDoormanService: SAML redirect URL
continuumDoormanService --> User Browser: HTTP 302 Redirect to Okta SSO URL
User Browser -> oktaIdentityProvider: SAML AuthnRequest (HTTP Redirect Binding)
oktaIdentityProvider --> User Browser: Okta login page
```

## Related

- Related flows: [Okta SSO Callback and Token Delivery](okta-sso-callback-token-delivery.md)
- Architecture component view: `components-doorman_components`
