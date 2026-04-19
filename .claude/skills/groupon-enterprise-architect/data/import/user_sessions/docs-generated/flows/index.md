---
service: "user_sessions"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for user_sessions.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [User Login — Email & Password](user-login-email-password.md) | synchronous | User submits the `/login` form with email and password | Validates credentials via GAPI, creates Memcached session, sets cookie, and redirects the authenticated user |
| [Social Login — Google](social-login-google.md) | synchronous | User clicks "Sign in with Google" on the login page | Executes Google OAuth 2.0 authorization code flow; resolves Groupon user via GAPI; creates session |
| [Password Reset Flow](password-reset-flow.md) | synchronous | User requests a reset or clicks a reset link from email | GAPI generates and validates reset tokens; user submits new password; three URL path aliases supported |
| [User Registration](user-registration.md) | synchronous | User submits the `/signup` form with new account details | Creates Groupon user account via GAPI, immediately creates session, and logs the user in |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Login redirect from Deal Page**: When an unauthenticated user attempts to access a deal page, `dealPageService_3b4d` redirects to `/login`. After successful authentication via any of the flows above, user_sessions redirects back to the deal page. This cross-service flow spans `continuumUserSessionsWebApp` and `dealPageService_3b4d`.
- **Google Social Login** spans `continuumUserSessionsWebApp`, `googleOAuth_1d2e`, and `gapiSystem_5c8b`. The architecture dynamic view `login_with_google` is defined in the Structurizr model but currently commented out due to stub-only container references.
