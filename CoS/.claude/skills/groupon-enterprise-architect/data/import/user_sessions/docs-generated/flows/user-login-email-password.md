---
service: "user_sessions"
title: "User Login — Email & Password"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "user-login-email-password"
flow_type: synchronous
trigger: "User submits the login form with email and password credentials"
participants:
  - "shopperUser_2f1a"
  - "continuumUserSessionsWebApp"
  - "gapiSystem_5c8b"
  - "memcachedCluster_6e2f"
architecture_ref: "dynamic-user-sessions-login"
---

# User Login — Email & Password

## Summary

This flow handles the most common authentication path: a returning user submits their email address and password through the `/login` form. The service validates the credentials against GAPI, creates a session in Memcached, sets an authenticated session cookie, and redirects the user to their intended destination. No tokens are issued directly by this service — GAPI owns credential validation.

## Trigger

- **Type**: user-action
- **Source**: User submits the POST `/login` form from a web browser
- **Frequency**: On demand — once per login attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shopper (browser) | Initiates login by submitting credentials | `shopperUser_2f1a` |
| user_sessions Web App | Receives form, orchestrates auth, sets cookie, redirects | `continuumUserSessionsWebApp` |
| GAPI | Validates email/password credentials; returns user identity on success | `gapiSystem_5c8b` |
| Memcached cluster | Stores the authenticated session object | `memcachedCluster_6e2f` |

## Steps

1. **Render login page**: User navigates to `/login`; `routes` dispatches to `controllers`; `frontendRenderer` returns the login HTML page.
   - From: `shopperUser_2f1a`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS GET

2. **Submit credentials**: User enters email and password and submits the form.
   - From: `shopperUser_2f1a`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS POST `/login` (application/x-www-form-urlencoded)

3. **Validate credentials via GAPI**: `authFlows` invokes `userSessions_gapiClient`, which sends a GraphQL mutation to GAPI with the submitted email and password.
   - From: `continuumUserSessionsWebApp`
   - To: `gapiSystem_5c8b`
   - Protocol: GraphQL / HTTP

4. **GAPI returns user identity**: GAPI validates the credentials against the user store and returns the authenticated user object (user ID, profile data) on success, or an error on failure.
   - From: `gapiSystem_5c8b`
   - To: `continuumUserSessionsWebApp`
   - Protocol: GraphQL / HTTP response

5. **Create session in cache**: `authFlows` calls `cacheAdapter`, which writes the session object (user ID, session metadata) to Memcached using `itier-cached`.
   - From: `continuumUserSessionsWebApp`
   - To: `memcachedCluster_6e2f`
   - Protocol: Memcached binary/text protocol

6. **Set session cookie and redirect**: `controllers` sets the authenticated session cookie on the HTTP response and issues a redirect to the post-login destination (e.g., the Deal Page or the originally requested URL).
   - From: `continuumUserSessionsWebApp`
   - To: `shopperUser_2f1a`
   - Protocol: HTTPS 302 redirect with `Set-Cookie` header

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid credentials (wrong password) | GAPI returns an authentication error; `controllers` re-renders the login page with an inline error message | User remains on `/login` with error feedback |
| Account not found | GAPI returns a not-found error | Login page re-rendered with error message |
| GAPI unreachable | GraphQL call fails; service catches the error and renders a generic error page | User sees an error page; login unavailable |
| Memcached write failure | Cache write fails; session cannot be persisted | Login fails; user is not authenticated; error page rendered |

## Sequence Diagram

```
Browser -> user_sessions: GET /login
user_sessions -> Browser: 200 OK (login page HTML)
Browser -> user_sessions: POST /login (email, password)
user_sessions -> GAPI: GraphQL mutation validateCredentials(email, password)
GAPI --> user_sessions: { userId, profile } or error
user_sessions -> Memcached: SET session:<token> = { userId, ... }
Memcached --> user_sessions: STORED
user_sessions --> Browser: 302 redirect + Set-Cookie: session=<token>
```

## Related

- Architecture dynamic view: `dynamic-user-sessions-login`
- Related flows: [Social Login — Google](social-login-google.md), [User Registration](user-registration.md), [Password Reset Flow](password-reset-flow.md)
