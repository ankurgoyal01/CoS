---
service: "mobile-flutter-merchant"
title: "Merchant Login Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-login-flow"
flow_type: synchronous
trigger: "User opens app or taps sign-in on the login screen"
participants:
  - "continuumMobileFlutterMerchantApp"
  - "mmaPresentationLayer"
  - "mmaAuthenticationModule"
  - "mmaApiOrchestrator"
  - "googleOAuth"
architecture_ref: "dynamic-merchant-login-flow"
---

# Merchant Login Flow

## Summary

The Merchant Login Flow authenticates a Groupon merchant using Google OAuth / Okta via a webview or system browser. The `mmaAuthenticationModule` orchestrates the OAuth token exchange, persists the session token to platform-secure storage (SharedPreferences / Keychain), and provides the authenticated context to the `mmaApiOrchestrator` for all subsequent API calls. Successful login navigates the merchant to the dashboard screen.

## Trigger

- **Type**: user-action
- **Source**: Merchant opens the app for the first time or after session expiry; taps the sign-in button on the login screen
- **Frequency**: On-demand (per login event)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Presentation Layer | Renders login screen; initiates sign-in action; navigates to dashboard on success | `mmaPresentationLayer` |
| Authentication Module | Orchestrates OAuth webview flow; handles token exchange and session persistence | `mmaAuthenticationModule` |
| API Orchestrator | Receives authenticated context; attaches tokens to downstream API requests | `mmaApiOrchestrator` |
| Google OAuth | Issues OAuth2 tokens for the merchant identity | `googleOAuth` |

## Steps

1. **Display Login Screen**: App launches and `mmaPresentationLayer` renders the login screen, checking secure storage for an existing valid session token.
   - From: `continuumMobileFlutterMerchantApp` (app start)
   - To: `mmaPresentationLayer`
   - Protocol: Direct

2. **Initiate Sign-In**: Merchant taps the sign-in button; `mmaPresentationLayer` delegates to `mmaAuthenticationModule` to start the OAuth flow.
   - From: `mmaPresentationLayer`
   - To: `mmaAuthenticationModule`
   - Protocol: Direct

3. **Open OAuth WebView**: `mmaAuthenticationModule` opens a webview or system browser directed at the Google OAuth / Okta authorisation endpoint.
   - From: `mmaAuthenticationModule`
   - To: `googleOAuth`
   - Protocol: OAuth2 / WebView (HTTPS)

4. **Merchant Authenticates**: Merchant enters credentials in the webview; Google OAuth validates the identity and issues an authorisation code.
   - From: Merchant (user input)
   - To: `googleOAuth`
   - Protocol: HTTPS (browser-based)

5. **Exchange Authorisation Code**: `mmaAuthenticationModule` receives the authorisation code callback and exchanges it for an access token and refresh token.
   - From: `mmaAuthenticationModule`
   - To: `googleOAuth`
   - Protocol: OAuth2 token endpoint (HTTPS)

6. **Persist Session Token**: `mmaAuthenticationModule` writes the access token and refresh token to platform-secure storage (Keychain on iOS, SharedPreferences on Android).
   - From: `mmaAuthenticationModule`
   - To: Platform-secure storage (on-device)
   - Protocol: Direct

7. **Provide Authenticated Context**: `mmaAuthenticationModule` notifies `mmaApiOrchestrator` of the valid session so the token is attached to subsequent API calls.
   - From: `mmaAuthenticationModule`
   - To: `mmaApiOrchestrator`
   - Protocol: Direct

8. **Navigate to Dashboard**: Redux state is updated with the authenticated session; `mmaPresentationLayer` navigates to the merchant dashboard screen.
   - From: `mmaAuthenticationModule`
   - To: `mmaPresentationLayer`
   - Protocol: Direct (Redux state update)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| OAuth authorisation denied by merchant | `mmaAuthenticationModule` receives error callback | Returns to login screen with error message |
| Network timeout during token exchange | HTTP timeout in `mmaApiOrchestrator` | Returns to login screen with connectivity error |
| Invalid or expired token on app resume | `mmaAuthenticationModule` detects expired token on launch | Redirects to login screen; clears stale session |
| Google OAuth service unavailable | WebView fails to load authorisation endpoint | Login screen displays service unavailable error |

## Sequence Diagram

```
Merchant -> mmaPresentationLayer: Opens app / taps sign-in
mmaPresentationLayer -> mmaAuthenticationModule: startSignIn()
mmaAuthenticationModule -> googleOAuth: Open OAuth2 WebView (authorisation request)
googleOAuth --> mmaAuthenticationModule: Return authorisation code
mmaAuthenticationModule -> googleOAuth: Exchange code for tokens (token endpoint)
googleOAuth --> mmaAuthenticationModule: Access token + refresh token
mmaAuthenticationModule -> SecureStorage: Persist tokens
mmaAuthenticationModule -> mmaApiOrchestrator: Set authenticated context
mmaAuthenticationModule --> mmaPresentationLayer: Login success (Redux state)
mmaPresentationLayer -> Merchant: Navigate to Dashboard
```

## Related

- Architecture dynamic view: `dynamic-merchant-login-flow`
- Related flows: [Offline and Sync Workflow](offline-and-sync-workflow.md)
