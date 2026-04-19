---
service: "user_sessions"
title: "Social Login — Google"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "social-login-google"
flow_type: synchronous
trigger: "User clicks 'Sign in with Google' on the login page"
participants:
  - "shopperUser_2f1a"
  - "continuumUserSessionsWebApp"
  - "googleOAuth_1d2e"
  - "gapiSystem_5c8b"
  - "memcachedCluster_6e2f"
architecture_ref: "dynamic-login_with_google"
---

# Social Login — Google

## Summary

This flow authenticates a user through Google OAuth 2.0 instead of email/password credentials. The user is redirected to Google's authorization endpoint, approves access, and is returned to user_sessions with an authorization code. The service exchanges the code for a Google identity token, passes it to GAPI to resolve or create the Groupon user account, establishes a session in Memcached, and redirects the user as authenticated. The corresponding architecture dynamic view (`login_with_google`) exists in the Structurizr model but is currently commented out due to stub-only references.

## Trigger

- **Type**: user-action
- **Source**: User clicks the "Sign in with Google" button on the `/login` page
- **Frequency**: On demand — once per Google social login attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shopper (browser) | Initiates Google login; approves OAuth consent | `shopperUser_2f1a` |
| user_sessions Web App | Initiates OAuth redirect; handles callback; creates session | `continuumUserSessionsWebApp` |
| Google OAuth | Authenticates the user with their Google account; issues authorization code | `googleOAuth_1d2e` |
| GAPI | Resolves or creates the Groupon user record from the Google identity token | `gapiSystem_5c8b` |
| Memcached cluster | Stores the authenticated session object | `memcachedCluster_6e2f` |

## Steps

1. **Initiate OAuth redirect**: User clicks "Sign in with Google" on `/login`; `authFlows` constructs the Google OAuth authorization URL with client ID, redirect URI, and scopes; service returns an HTTP redirect to Google's authorization endpoint.
   - From: `continuumUserSessionsWebApp`
   - To: `shopperUser_2f1a`
   - Protocol: HTTPS 302 redirect

2. **User authenticates with Google**: Browser follows the redirect to Google. User logs in (if not already) and approves the OAuth consent screen.
   - From: `shopperUser_2f1a`
   - To: `googleOAuth_1d2e`
   - Protocol: HTTPS (Google-hosted)

3. **Google redirects back with authorization code**: Google redirects the browser to the user_sessions OAuth callback URL, appending the authorization `code` parameter.
   - From: `googleOAuth_1d2e`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS redirect with `code` query parameter

4. **Exchange code for identity token**: `authFlows` calls the Google token endpoint to exchange the authorization code for an ID token and access token.
   - From: `continuumUserSessionsWebApp`
   - To: `googleOAuth_1d2e`
   - Protocol: HTTPS POST (OAuth token endpoint)

5. **Resolve Groupon user via GAPI**: `authFlows` invokes `userSessions_gapiClient`, passing the Google identity token to GAPI. GAPI maps the Google identity to a Groupon user account (creating one if none exists) and returns the user object.
   - From: `continuumUserSessionsWebApp`
   - To: `gapiSystem_5c8b`
   - Protocol: GraphQL / HTTP

6. **Create session in cache**: `authFlows` calls `cacheAdapter`, which writes the session object to Memcached.
   - From: `continuumUserSessionsWebApp`
   - To: `memcachedCluster_6e2f`
   - Protocol: Memcached binary/text protocol

7. **Set session cookie and redirect**: `controllers` sets the authenticated session cookie and redirects the user to the post-login destination.
   - From: `continuumUserSessionsWebApp`
   - To: `shopperUser_2f1a`
   - Protocol: HTTPS 302 redirect with `Set-Cookie` header

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User denies Google OAuth consent | Google returns `error=access_denied` in callback; service renders login page with informational message | User returned to `/login` |
| Invalid or expired authorization code | Token exchange with Google fails; service renders error page | User sees an error; flow aborted |
| GAPI fails to resolve/create user | GraphQL call fails or returns error | Error page rendered; session not created |
| Memcached write failure | Session cannot be persisted | Login fails; user is not authenticated |

## Sequence Diagram

```
Browser -> user_sessions: Click "Sign in with Google"
user_sessions --> Browser: 302 redirect to Google OAuth authorize URL
Browser -> Google OAuth: GET /oauth/authorize (client_id, redirect_uri, scope)
Google OAuth --> Browser: 302 redirect to user_sessions callback?code=<auth_code>
Browser -> user_sessions: GET /auth/google/callback?code=<auth_code>
user_sessions -> Google OAuth: POST /oauth/token (code exchange)
Google OAuth --> user_sessions: { id_token, access_token }
user_sessions -> GAPI: GraphQL mutation socialLogin(provider=google, id_token)
GAPI --> user_sessions: { userId, profile }
user_sessions -> Memcached: SET session:<token> = { userId, ... }
Memcached --> user_sessions: STORED
user_sessions --> Browser: 302 redirect + Set-Cookie: session=<token>
```

## Related

- Architecture dynamic view: `dynamic-login_with_google` (currently commented out in Structurizr model due to stub-only references)
- Related flows: [User Login — Email & Password](user-login-email-password.md), [User Registration](user-registration.md)
