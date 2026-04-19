---
service: "users-service"
title: "Password Reset Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "password-reset"
flow_type: synchronous
trigger: "POST /v1/password_resets"
participants:
  - "consumer"
  - "continuumUsersService"
  - "continuumUsersDb"
  - "continuumUsersMailService"
architecture_ref: "containers-users-service"
---

# Password Reset Flow

## Summary

The self-service password reset flow allows users to regain account access by requesting a reset token via email and completing the reset using that token. The Password Resets Controller delegates both initiation and completion to Authentication Strategies and Account Strategies, which handle token generation, email dispatch (via Mailman), and credential update. The flow is two-phased: initiate (sends email) and complete (validates token and updates password).

## Trigger

- **Type**: api-call
- **Source**: User requesting password reset from web or mobile client
- **Frequency**: On-demand per user request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (client) | Initiates reset and submits new password with token | `consumer` |
| Users Service API | Orchestrates both phases of the reset flow | `continuumUsersService` |
| Users DB | Persists and validates reset tokens; updates password record | `continuumUsersDb` |
| Mail Delivery Service | Delivers password reset email with token link | `continuumUsersMailService` |

## Steps

### Phase 1: Initiate Password Reset

1. **Receive initiation request**: Client sends `POST /v1/password_resets` with the user's email address.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Locate account**: Password Resets Controller invokes Authentication Strategies to look up the account by email via Account Repository.
   - From: `continuumUsersServiceApi_passwordResetsController`
   - To: `continuumUsersServiceApi_authenticationStrategies` -> `continuumUsersServiceApi_repository`
   - Protocol: Ruby (in-process) + ActiveRecord

3. **Generate reset token**: A time-limited reset token is created and persisted to `continuumUsersDb` (password_resets table).
   - From: `continuumUsersServiceApi_authenticationStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Send reset email**: App Mailer delivers the reset email with token link and locale-aware template via Mailman.
   - From: `continuumUsersServiceApi_mailer`
   - To: `continuumUsersMailService`
   - Protocol: SMTP/Mailman

5. **Return accepted response**: API returns HTTP 200/202 (no account enumeration; response is identical whether account exists or not).
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

### Phase 2: Complete Password Reset

6. **Receive completion request**: Client sends `PUT /v1/password_resets/:token` with the token from the email and the new password.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

7. **Validate reset token**: Password Resets Controller looks up the token in `continuumUsersDb` and checks expiry.
   - From: `continuumUsersServiceApi_passwordResetsController`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

8. **Update password**: Account Strategies updates the password hash (bcrypt) on the account record and marks the reset token as consumed.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

9. **Send confirmation email**: App Mailer delivers a password-changed confirmation email.
   - From: `continuumUsersServiceApi_mailer`
   - To: `continuumUsersMailService`
   - Protocol: SMTP/Mailman

10. **Return success response**: API returns HTTP 200 with a new session token or success confirmation.
    - From: `continuumUsersService`
    - To: `consumer`
    - Protocol: HTTPS / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Email not found | No-op; response is identical to success | 200 (no enumeration) |
| Reset token expired | Token validation fails | 422 Unprocessable Entity |
| Reset token already used | Token marked consumed; validation fails | 422 Unprocessable Entity |
| Password does not meet policy | Validation error in Account Strategies | 422 with error details |
| Email delivery failure | Mailman error; no retry in synchronous path | 500 or silent failure |

## Sequence Diagram

```
[Phase 1 - Initiate]
Consumer          -> UsersServiceAPI         : POST /v1/password_resets (email)
UsersServiceAPI   -> AuthStrategies          : find_account(email)
AuthStrategies    -> AccountRepository       : SELECT account WHERE email = ?
AccountRepository --> AuthStrategies         : account (or nil)
AuthStrategies    -> AccountRepository       : INSERT password_resets (token, expires_at)
UsersServiceAPI   -> AppMailer               : send_reset_email(account, token, locale)
AppMailer         -> MailService             : SMTP deliver reset email
UsersServiceAPI   --> Consumer               : 200 OK

[Phase 2 - Complete]
Consumer          -> UsersServiceAPI         : PUT /v1/password_resets/:token (new_password)
UsersServiceAPI   -> AccountRepository       : SELECT password_resets WHERE token = ?
AccountRepository --> UsersServiceAPI        : token record (valid / expired)
UsersServiceAPI   -> AccountStrategies       : update_password(account, new_password)
AccountStrategies -> AccountRepository       : UPDATE passwords SET digest = bcrypt(new)
AccountStrategies -> AccountRepository       : UPDATE password_resets SET consumed = true
UsersServiceAPI   -> AppMailer               : send_confirmation_email(account)
AppMailer         -> MailService             : SMTP deliver confirmation
UsersServiceAPI   --> Consumer               : 200 OK
```

## Related

- Related flows: [Forced Password Reset](forced-password-reset.md), [Authentication](authentication.md)
