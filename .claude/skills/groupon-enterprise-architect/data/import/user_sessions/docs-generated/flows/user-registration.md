---
service: "user_sessions"
title: "User Registration"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "user-registration"
flow_type: synchronous
trigger: "User submits the signup form with new account details"
participants:
  - "shopperUser_2f1a"
  - "continuumUserSessionsWebApp"
  - "gapiSystem_5c8b"
  - "memcachedCluster_6e2f"
architecture_ref: "dynamic-user-sessions-registration"
---

# User Registration

## Summary

This flow creates a new Groupon user account. A new user fills in the signup form at `/signup`, which user_sessions forwards to GAPI for account creation. On success, the service immediately creates an authenticated session in Memcached, sets a session cookie, and redirects the user — so they are logged in directly after registering without a separate login step.

## Trigger

- **Type**: user-action
- **Source**: User submits the POST `/signup` form from a web browser
- **Frequency**: On demand — once per registration attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shopper (browser) | Submits new account details via the signup form | `shopperUser_2f1a` |
| user_sessions Web App | Receives form submission; orchestrates account creation; creates session; sets cookie | `continuumUserSessionsWebApp` |
| GAPI | Creates the new user account and returns the new user identity | `gapiSystem_5c8b` |
| Memcached cluster | Stores the authenticated session object for the newly registered user | `memcachedCluster_6e2f` |

## Steps

1. **Render signup page**: User navigates to `/signup`; `routes` dispatches to `controllers`; `frontendRenderer` returns the signup HTML page.
   - From: `shopperUser_2f1a`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS GET

2. **Submit signup form**: User fills in account details (email, password, and any required profile fields) and submits the form.
   - From: `shopperUser_2f1a`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS POST `/signup` (application/x-www-form-urlencoded)

3. **Create account via GAPI**: `authFlows` invokes `userSessions_gapiClient`, which sends a GraphQL mutation to GAPI to create the new user account with the submitted details.
   - From: `continuumUserSessionsWebApp`
   - To: `gapiSystem_5c8b`
   - Protocol: GraphQL / HTTP

4. **GAPI returns new user identity**: GAPI creates the user record, applies any initial account setup, and returns the new user object (user ID, profile data).
   - From: `gapiSystem_5c8b`
   - To: `continuumUserSessionsWebApp`
   - Protocol: GraphQL / HTTP response

5. **Create session in cache**: `authFlows` calls `cacheAdapter`, which writes the session object for the newly created user to Memcached.
   - From: `continuumUserSessionsWebApp`
   - To: `memcachedCluster_6e2f`
   - Protocol: Memcached binary/text protocol

6. **Set session cookie and redirect**: `controllers` sets the authenticated session cookie on the response and redirects the new user to their post-registration destination.
   - From: `continuumUserSessionsWebApp`
   - To: `shopperUser_2f1a`
   - Protocol: HTTPS 302 redirect with `Set-Cookie` header

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Email address already registered | GAPI returns a conflict error; service re-renders signup form with an inline error suggesting the user log in instead | User remains on `/signup` with error feedback and a link to `/login` |
| Invalid email format or weak password | GAPI returns a validation error; service re-renders signup form with inline field-level errors | User remains on `/signup` with validation feedback |
| GAPI unreachable | GraphQL call fails; error page rendered | Registration unavailable |
| Memcached write failure | Session cannot be persisted even after account is created | User account exists in GAPI but user is not logged in; user must log in via `/login` |

## Sequence Diagram

```
Browser -> user_sessions: GET /signup
user_sessions --> Browser: 200 OK (signup page HTML)
Browser -> user_sessions: POST /signup (email, password, profile fields)
user_sessions -> GAPI: GraphQL mutation createUser(email, password, ...)
GAPI --> user_sessions: { userId, profile } or error
user_sessions -> Memcached: SET session:<token> = { userId, ... }
Memcached --> user_sessions: STORED
user_sessions --> Browser: 302 redirect + Set-Cookie: session=<token>
```

## Related

- Architecture dynamic view: `dynamic-user-sessions-registration`
- Related flows: [User Login — Email & Password](user-login-email-password.md), [Social Login — Google](social-login-google.md)
