---
service: "doorman"
title: "Okta SSO Callback and Token Delivery"
generated: "2026-03-03"
type: flow
flow_name: "okta-sso-callback-token-delivery"
flow_type: synchronous
trigger: "Okta HTTP POST to /okta/saml/sso after successful user authentication"
participants:
  - "oktaIdentityProvider"
  - "continuumDoormanService"
  - "continuumUsersService"
  - "destinationTool"
architecture_ref: "components-doorman_components"
---

# Okta SSO Callback and Token Delivery

## Summary

After the user successfully authenticates with Okta, Okta posts a SAML assertion back to Doorman's Assertion Consumer Service endpoint (`POST /okta/saml/sso`). Doorman extracts the `SAMLResponse` and `RelayState`, delegates SAML assertion validation and token issuance to the Users Service, then renders an auto-submitting HTML form that the browser uses to POST the signed token to the registered destination tool. This is the core flow that produces a usable authentication token for an internal tool.

## Trigger

- **Type**: api-call (SAML HTTP POST Binding from Okta via browser)
- **Source**: Okta Identity Provider, posting to Doorman's ACS URL via the user's browser
- **Frequency**: On-demand — one callback per completed Okta authentication

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Okta | Posts SAML assertion to Doorman ACS endpoint | `oktaIdentityProvider` |
| Internal user (browser) | Browser carries the SAML POST from Okta to Doorman; submits auto-form to destination | — |
| Doorman | Receives and validates SAML callback; calls Users Service; renders token delivery form | `continuumDoormanService` |
| Users Service | Validates SAML assertion; returns account info and signed token | `continuumUsersService` |
| Destination tool | Receives signed token (or error) via browser form POST | registered destination |

## Steps

1. **Receives Okta SAML callback**: Okta posts the browser to `POST /okta/saml/sso` with `SAMLResponse` (Base64-encoded SAML XML) and `RelayState` (JSON with `destinationId` and optional `destinationPath`).
   - From: `oktaIdentityProvider` (via user browser)
   - To: `continuumDoormanService`
   - Protocol: HTTPS form POST (SAML 2.0 HTTP POST Binding)

2. **Validates required parameters**: Doorman checks that both `SAMLResponse` and `RelayState` are present and non-blank. If either is missing, returns `400 bad request`.
   - From: `authenticationController`
   - To: Rack request params
   - Protocol: direct

3. **Calls Users Service for SAML validation**: Doorman sends `POST /users/v1/accounts/internal_authentication` to the Users Service with `{"saml": "<SAMLResponse>"}`. The request includes `X-Api-Key` and `User-Agent: Doorman` headers. SSL verification is disabled.
   - From: `continuumDoormanService` (`usersServiceInternalAuth`)
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

4. **Receives token or error from Users Service**: Users Service returns either a `200` response with `{"account": {"id": "..."}, "token": "<signed_token>"}` or a non-200 error response.
   - From: `continuumUsersService`
   - To: `continuumDoormanService`
   - Protocol: HTTPS / REST

5. **Determines destination URL**: Doorman parses the `RelayState` JSON to extract `destinationId` and optional `destinationPath`. Looks up the destination in the loaded `config/<env>/destinations.yml` to resolve `destination_host` and `destination_path`.
   - From: `authenticationController`
   - To: in-memory destinations configuration
   - Protocol: direct

6. **Renders SSO postback form**: Doorman renders the `sso_postback.erb` HTML template with:
   - `action` pointing to the resolved `destination_url`
   - Hidden field `token` containing the signed token (or empty on error)
   - Hidden field `error` containing the HTML-escaped error message (or empty on success)
   - A `window.onload` JavaScript handler auto-submits the form immediately.
   - From: `continuumDoormanService`
   - To: Internal user (browser)
   - Protocol: HTTPS (HTML response)

7. **Browser auto-submits token to destination**: The browser's JavaScript auto-submits the form, POSTing the `token` (and/or `error`) to the destination tool's configured path.
   - From: Internal user (browser)
   - To: Destination tool (e.g., `https://command-center.groupondev.com/doorman-auth`)
   - Protocol: HTTPS form POST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `SAMLResponse` or `RelayState` | Returns `400 bad request` (plain text) | Authentication fails immediately |
| Users Service returns non-200 | Sets `error` field in postback form; logs `rendering_postback_form_with_error` | Destination receives `error` param; no token issued |
| Users Service timeout or network error | Rescues exception; sets `error` field with exception details | Destination receives `error` param; no token issued |
| `RelayState` JSON parse failure | Raises exception; caught by `LastChanceForRescue` middleware | 500 error response |
| Destination ID not in registry | Raises `KeyError` when looking up `destination_host`; caught by middleware | 500 error response |

## Sequence Diagram

```
oktaIdentityProvider -> User Browser: SAML POST response (SAMLResponse + RelayState)
User Browser -> continuumDoormanService: POST /okta/saml/sso (SAMLResponse, RelayState)
continuumDoormanService -> continuumDoormanService: Validate SAMLResponse and RelayState present
continuumDoormanService -> continuumUsersService: POST /users/v1/accounts/internal_authentication {saml: <SAMLResponse>}
continuumUsersService --> continuumDoormanService: {account: {id: ...}, token: <signed_token>}
continuumDoormanService -> continuumDoormanService: Resolve destination_url from RelayState + destinations config
continuumDoormanService --> User Browser: HTML (auto-submit form with token, destination_url)
User Browser -> destinationTool: POST <destination_path> {token: <signed_token>}
```

## Related

- Related flows: [SAML Authentication Initiation](saml-authentication-initiation.md), [Token Verification by Destination Tool](token-verification-by-destination.md)
- Architecture component view: `components-doorman_components`
