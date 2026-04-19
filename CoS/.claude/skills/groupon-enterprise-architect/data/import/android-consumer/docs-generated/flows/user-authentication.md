---
service: "android-consumer"
title: "User Authentication"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "user-authentication"
flow_type: synchronous
trigger: "User initiates sign-in or the app detects an expired OAuth token"
participants:
  - "androidConsumer_appEntryPoints"
  - "androidConsumer_featureModules"
  - "androidConsumer_networkIntegration"
  - "androidConsumer_localPersistence"
  - "continuumAndroidLocalStorage"
  - "oktaIdentity"
  - "apiProxy"
architecture_ref: "dynamic-android-consumer-auth"
---

# User Authentication

## Summary

Authentication is handled via Okta OAuth 2.0 / OpenID Connect using the PKCE flow on the device. When a user taps "Sign In" or when the app detects an expired access token, the Okta Android SDK launches an in-app browser tab for the authorization code exchange. On success, the access and refresh tokens are stored in SharedPreferences. The app then fetches the user profile from `apiProxy` to populate the session context. Token refresh happens silently in the background before token expiry.

## Trigger

- **Type**: user-action (sign-in) or system-event (token expiry detected)
- **Source**: User taps "Sign In" button; or Network Integration Layer receives HTTP 401 from `apiProxy`
- **Frequency**: On demand — once per session or on token expiry

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| App Entry Points | Hosts the login screen activity; receives OAuth redirect intent | `androidConsumer_appEntryPoints` |
| Feature Modules (Account) | Initiates and monitors auth state; triggers profile fetch | `androidConsumer_featureModules` |
| Network Integration Layer | Attaches bearer tokens to requests; triggers token refresh on 401 | `androidConsumer_networkIntegration` |
| Local Persistence Layer | Stores and reads OAuth tokens from SharedPreferences | `androidConsumer_localPersistence` |
| Android Local Storage | SharedPreferences store for tokens and session state | `continuumAndroidLocalStorage` |
| Okta Identity | Issues authorization code, access token, refresh token, and ID token | `oktaIdentity` |
| Groupon Backend APIs | Returns user profile on `GET /account/*` and `GET /identity/*` | `apiProxy` |

## Steps

1. **User taps "Sign In"** (or 401 is detected on an API call):
   - From: `androidConsumer_appEntryPoints` or `androidConsumer_networkIntegration`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct

2. **App launches Okta PKCE authorization flow**: The Okta Android SDK opens a Custom Chrome Tab directed at the Okta authorization endpoint; PKCE code challenge is generated and sent.
   - From: `androidConsumer_featureModules`
   - To: `oktaIdentity`
   - Protocol: HTTPS/OIDC (in-app browser)

3. **User enters credentials in Okta browser UI**: User authenticates within the Okta-hosted login page (username/password, MFA if required).
   - From: User
   - To: `oktaIdentity`
   - Protocol: HTTPS (browser)

4. **Okta redirects back with authorization code**: Okta issues an authorization code and redirects to the app's registered redirect URI (Android App Link or custom scheme).
   - From: `oktaIdentity`
   - To: `androidConsumer_appEntryPoints` (intent filter catches redirect)
   - Protocol: HTTPS redirect / Android intent

5. **App exchanges authorization code for tokens**: Okta SDK sends `POST /identity/*` (token endpoint) with the authorization code and PKCE verifier; receives access token, refresh token, and ID token.
   - From: `androidConsumer_featureModules` → `androidConsumer_networkIntegration`
   - To: `oktaIdentity`
   - Protocol: HTTPS/POST

6. **Tokens stored in SharedPreferences**: Access token, refresh token, and expiry are written to SharedPreferences via `androidConsumer_localPersistence`.
   - From: `androidConsumer_localPersistence`
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct (SharedPreferences)

7. **Profile fetch from `apiProxy`**: Feature module calls `GET /account/*` via Network Integration Layer using the new access token to load user profile and preferences.
   - From: `androidConsumer_featureModules` → `androidConsumer_networkIntegration`
   - To: `apiProxy`
   - Protocol: HTTPS/REST

8. **Session established — app navigates to home**: User profile data is returned; app stores session state in Room and navigates the user to the home/browse screen.
   - From: `apiProxy`
   - To: `androidConsumer_featureModules` → `androidConsumer_appEntryPoints`
   - Protocol: Direct

9. **Silent token refresh (background)**: Before the access token expires, the Okta SDK uses the stored refresh token to obtain a new access token silently; updated tokens are written to SharedPreferences.
   - From: `androidConsumer_networkIntegration` (OkHttp authenticator interceptor)
   - To: `oktaIdentity` → `androidConsumer_localPersistence`
   - Protocol: HTTPS/POST → Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User cancels Okta login | Okta SDK returns cancellation; app returns to sign-in screen | No tokens stored; user remains unauthenticated |
| Okta authorization endpoint unreachable | SDK returns network error | User sees error; retry option shown |
| Token exchange fails (invalid code) | SDK returns error; tokens not stored | User must retry sign-in |
| Token refresh fails (refresh token expired or revoked) | App clears stored tokens and forces re-login | User redirected to sign-in screen |
| Profile fetch returns 4xx | Auth session is still established; profile shown as partial | User may see default/empty profile state |

## Sequence Diagram

```
User -> appEntryPoints: Tap "Sign In"
appEntryPoints -> featureModules: StartAuth
featureModules -> oktaIdentity: Launch PKCE auth (Custom Chrome Tab)
User -> oktaIdentity: Enter credentials
oktaIdentity --> appEntryPoints: Redirect with auth code
featureModules -> networkIntegration: Exchange code for tokens
networkIntegration -> oktaIdentity: POST /identity/* (token endpoint)
oktaIdentity --> networkIntegration: access_token, refresh_token, id_token
networkIntegration -> localPersistence: Store tokens in SharedPreferences
localPersistence -> continuumAndroidLocalStorage: Write tokens
featureModules -> networkIntegration: GET /account/* (profile fetch)
networkIntegration -> apiProxy: GET /account/* [Bearer access_token]
apiProxy --> networkIntegration: User profile JSON
featureModules -> UI: Navigate to home screen
```

## Related

- Architecture dynamic view: `dynamic-android-consumer-auth` (not yet modeled in DSL)
- Related flows: [Shopping Cart and Checkout](shopping-cart-checkout.md), [Deal Discovery and Browse](deal-discovery-browse.md)
