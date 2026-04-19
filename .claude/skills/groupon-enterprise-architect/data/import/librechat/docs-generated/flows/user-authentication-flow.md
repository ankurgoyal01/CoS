---
service: "librechat"
title: "User Authentication Flow"
generated: "2026-03-03"
type: flow
flow_name: "user-authentication-flow"
flow_type: synchronous
trigger: "User navigates to LibreChat and initiates SSO login via Okta"
participants:
  - "consumer"
  - "continuumLibrechatApp"
  - "continuumLibrechatMongodb"
architecture_ref: "components-continuum-librechat-app"
---

# User Authentication Flow

## Summary

When a Groupon employee accesses LibreChat, they authenticate via Okta using OpenID Connect (OIDC). The application redirects the user to Okta's authorization endpoint, receives an authorization code callback, exchanges it for identity tokens, and creates or retrieves a user record in MongoDB. The authenticated session is established for subsequent API requests.

## Trigger

- **Type**: user-action
- **Source**: Groupon employee (`consumer`) navigates to the LibreChat web application
- **Frequency**: On demand, once per session (tokens are reused via `OPENID_REUSE_TOKENS: "true"`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (Groupon employee) | Initiates login and provides Okta credentials | `consumer` |
| LibreChat App (Web UI) | Displays login page and handles browser redirects | `continuumLibrechatApp` / `appWebUi` |
| LibreChat App (API Server) | Handles OIDC callback, token exchange, session creation | `continuumLibrechatApp` / `appApiServer` |
| Okta (OpenID Connect) | Identity provider — authenticates the user | External (`OPENID_ISSUER: https://groupon.okta.com/oauth2/default`) |
| MongoDB (User Store) | Stores/retrieves user profile and role | `continuumLibrechatMongodb` / `mongoUserStore` |

## Steps

1. **User accesses LibreChat**: Consumer navigates to the LibreChat URL in their browser.
   - From: `consumer`
   - To: `continuumLibrechatApp` (`appWebUi`)
   - Protocol: HTTPS

2. **App detects unauthenticated session**: The Web UI determines no valid session exists and displays the login page with the Okta SSO button (labeled `okta`).
   - From: `continuumLibrechatApp` (`appWebUi`)
   - To: `consumer`
   - Protocol: HTTPS (HTML response)

3. **User initiates SSO login**: Consumer clicks the Okta login button. The App Server initiates the OIDC authorization flow.
   - From: `consumer`
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: HTTPS

4. **App Server redirects to Okta**: The API Server redirects the browser to the Okta authorization endpoint with scope `openid email profile` and the configured client ID.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: Okta (`https://groupon.okta.com/oauth2/default`)
   - Protocol: HTTPS (browser redirect)

5. **User authenticates with Okta**: Consumer enters credentials (or uses existing Okta session) at the Okta login portal.
   - From: `consumer`
   - To: Okta
   - Protocol: HTTPS

6. **Okta issues authorization code**: Okta redirects the browser back to the LibreChat callback URL (`/oauth/openid/callback`) with an authorization code.
   - From: Okta
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: HTTPS (browser redirect)

7. **API Server exchanges code for tokens**: The API Server exchanges the authorization code for ID and access tokens at Okta's token endpoint.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: Okta
   - Protocol: HTTPS/JSON (back-channel)

8. **API Server resolves or creates user record**: The API Server looks up the user in MongoDB User Store by their Okta identity. If not found, a new user record is created with the `DEFAULT_USER_ROLE`.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: `continuumLibrechatMongodb` (`mongoUserStore`)
   - Protocol: MongoDB protocol

9. **Session established**: The API Server creates a server-side session and returns a session cookie to the browser.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: `continuumLibrechatApp` (`appWebUi`)
   - Protocol: HTTPS

10. **User accesses the chat interface**: With the session established, the Web UI renders the full chat interface.
    - From: `continuumLibrechatApp` (`appWebUi`)
    - To: `consumer`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Okta unreachable | OIDC redirect fails; browser receives network error | User cannot authenticate; login page displayed with error |
| Invalid or expired authorization code | Token exchange returns error from Okta | User is redirected back to login page |
| User not authorized in Okta | Okta denies authentication | Callback includes error; user is shown login failure |
| MongoDB User Store unavailable | User record cannot be fetched or created | Session cannot be established; login fails |

## Sequence Diagram

```
Consumer -> appWebUi: Navigates to LibreChat (HTTPS)
appWebUi --> Consumer: Displays login page with Okta button
Consumer -> appApiServer: Clicks Okta login button (HTTPS)
appApiServer --> Consumer: Redirects browser to Okta authorization endpoint
Consumer -> Okta: Authenticates with Okta credentials (HTTPS)
Okta --> Consumer: Redirects browser to /oauth/openid/callback with code
Consumer -> appApiServer: Delivers authorization code via callback (HTTPS)
appApiServer -> Okta: Exchanges code for ID + access tokens (HTTPS back-channel)
Okta --> appApiServer: Returns ID token and access token
appApiServer -> mongoUserStore: Looks up or creates user record (MongoDB protocol)
mongoUserStore --> appApiServer: Returns user document
appApiServer --> appWebUi: Establishes session, sets session cookie
appWebUi --> Consumer: Renders authenticated chat interface
```

## Related

- Architecture dynamic view: `components-continuum-librechat-app`
- Related flows: [Chat Request Flow](chat-request-flow.md)
