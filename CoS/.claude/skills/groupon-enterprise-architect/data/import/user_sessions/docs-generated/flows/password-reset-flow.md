---
service: "user_sessions"
title: "Password Reset Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "password-reset-flow"
flow_type: synchronous
trigger: "User requests a password reset or clicks a password reset link from email"
participants:
  - "shopperUser_2f1a"
  - "continuumUserSessionsWebApp"
  - "gapiSystem_5c8b"
architecture_ref: "dynamic-user-sessions-password-reset"
---

# Password Reset Flow

## Summary

This flow enables a user who has forgotten their password to set a new one. It has two halves: (1) the user requests a reset, which causes GAPI to generate a token and send a reset email; and (2) the user clicks the link in the email, which brings them to user_sessions with a token, submits a new password, and GAPI updates the credential. Three URL patterns are supported for the second half to accommodate legacy paths. No session is created during this flow — the user must log in separately after resetting their password.

## Trigger

- **Type**: user-action
- **Source**: User clicks "Forgot password" on the login page and submits their email address; OR user clicks the password reset link received via email
- **Frequency**: On demand — once per reset request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shopper (browser) | Requests reset; receives email; submits new password | `shopperUser_2f1a` |
| user_sessions Web App | Renders reset request and new-password forms; relays token and new password to GAPI | `continuumUserSessionsWebApp` |
| GAPI | Generates reset token; sends reset email; validates token; updates password | `gapiSystem_5c8b` |

## Steps

### Part 1 — Request Reset

1. **User requests password reset**: User navigates to the forgot-password form (linked from `/login`) and submits their email address.
   - From: `shopperUser_2f1a`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS POST

2. **Relay reset request to GAPI**: `authFlows` calls `userSessions_gapiClient`, which sends a GraphQL mutation to GAPI requesting a password reset token for the given email.
   - From: `continuumUserSessionsWebApp`
   - To: `gapiSystem_5c8b`
   - Protocol: GraphQL / HTTP

3. **GAPI generates token and sends email**: GAPI creates a time-limited reset token, associates it with the user account, and triggers a password reset email to the user containing a link with the token.
   - From: `gapiSystem_5c8b`
   - To: User's email inbox (external mail delivery — not directly through user_sessions)
   - Protocol: Internal to GAPI

4. **Confirmation page rendered**: user_sessions renders a confirmation page informing the user that a reset email has been sent.
   - From: `continuumUserSessionsWebApp`
   - To: `shopperUser_2f1a`
   - Protocol: HTTPS 200 OK (HTML)

### Part 2 — Submit New Password

5. **User clicks reset link**: User opens the reset email and clicks the link, which navigates to one of the three supported reset paths: `/users/password_reset/:token`, `/passwordreset/:token`, or `/users/reset_password/:userId/:token`.
   - From: `shopperUser_2f1a`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS GET

6. **Render new-password form**: `routes` maps the path to `controllers`; `frontendRenderer` renders the new-password form, passing the token (and userId if present) from the URL.
   - From: `continuumUserSessionsWebApp`
   - To: `shopperUser_2f1a`
   - Protocol: HTTPS 200 OK (HTML)

7. **User submits new password**: User enters and confirms their new password and submits the form.
   - From: `shopperUser_2f1a`
   - To: `continuumUserSessionsWebApp`
   - Protocol: HTTPS POST

8. **Update password via GAPI**: `authFlows` calls `userSessions_gapiClient`, which sends a GraphQL mutation to GAPI with the reset token and new password. GAPI validates the token (not expired, not already used) and updates the user's credential.
   - From: `continuumUserSessionsWebApp`
   - To: `gapiSystem_5c8b`
   - Protocol: GraphQL / HTTP

9. **Confirm reset and redirect**: On success, GAPI returns a confirmation; user_sessions renders a success page or redirects the user to `/login` to authenticate with their new password.
   - From: `continuumUserSessionsWebApp`
   - To: `shopperUser_2f1a`
   - Protocol: HTTPS (200 OK or 302 redirect to `/login`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Email address not registered | GAPI returns not-found; service renders informational message (may be intentionally vague for security) | User sees confirmation-style message regardless |
| Reset token expired | GAPI token validation fails; service renders error page with link to request a new reset | User prompted to restart the reset flow |
| Reset token already used | GAPI rejects the token; service renders error page | User prompted to request a new reset |
| New password fails validation | GAPI returns validation error; service re-renders form with inline error | User remains on new-password form with feedback |
| GAPI unreachable | GraphQL call fails; error page rendered | Password reset unavailable |

## Sequence Diagram

```
Browser -> user_sessions: POST /forgot-password (email)
user_sessions -> GAPI: GraphQL mutation requestPasswordReset(email)
GAPI --> user_sessions: { success }
GAPI -> Email service: send reset email with token link
user_sessions --> Browser: 200 OK (check your email confirmation page)

[User clicks link in email]
Browser -> user_sessions: GET /users/password_reset/:token
user_sessions --> Browser: 200 OK (new password form)
Browser -> user_sessions: POST /users/password_reset/:token (newPassword)
user_sessions -> GAPI: GraphQL mutation resetPassword(token, newPassword)
GAPI --> user_sessions: { success } or error
user_sessions --> Browser: 302 redirect to /login (or error page)
```

## Related

- Architecture dynamic view: `dynamic-user-sessions-password-reset`
- Related flows: [User Login — Email & Password](user-login-email-password.md)
