---
service: "users-service"
title: "Email Verification Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "email-verification"
flow_type: synchronous
trigger: "POST /v1/email_verifications"
participants:
  - "consumer"
  - "continuumUsersService"
  - "continuumUsersDb"
  - "continuumUsersMailService"
  - "continuumUsersResqueWorkers"
  - "continuumUsersMessageBusBroker"
architecture_ref: "containers-users-service"
---

# Email Verification Flow

## Summary

The email verification flow confirms that a registered user owns the email address on their account. The Email Verifications Controller generates a nonce, persists it to MySQL, and dispatches a verification email through Mailman. When the user clicks the link, a `PUT /v1/email_verifications/:nonce` request completes the verification, marks the account as email-verified, and publishes an `email_verification.completed` event to the Message Bus.

## Trigger

- **Type**: api-call
- **Source**: Authenticated user requesting email verification (typically post-registration or email change)
- **Frequency**: On-demand per verification request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (client) | Requests initiation and submits nonce from email link | `consumer` |
| Users Service API | Generates nonce, sends email, and confirms verification | `continuumUsersService` |
| Users DB | Persists nonce and email verification state | `continuumUsersDb` |
| Mail Delivery Service | Delivers verification email with nonce link | `continuumUsersMailService` |
| Users Resque Workers | Publishes email_verification.completed event asynchronously | `continuumUsersResqueWorkers` |
| Message Bus Broker | Receives email verification event | `continuumUsersMessageBusBroker` |

## Steps

### Phase 1: Initiate Verification

1. **Receive initiation request**: Authenticated client sends `POST /v1/email_verifications`.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Generate and persist nonce**: Email Verifications Controller calls Account Strategies to create a time-limited nonce and insert an `email_verifications` record in `continuumUsersDb`.
   - From: `continuumUsersServiceApi_emailVerificationsController`
   - To: `continuumUsersServiceApi_accountStrategies` -> `continuumUsersServiceApi_repository`
   - Protocol: Ruby (in-process) + ActiveRecord

3. **Send verification email**: App Mailer dispatches the verification email with the nonce link.
   - From: `continuumUsersServiceApi_mailer`
   - To: `continuumUsersMailService`
   - Protocol: SMTP/Mailman

4. **Return accepted response**: API responds HTTP 200/202 confirming the email has been sent.
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

### Phase 2: Complete Verification

5. **Receive nonce submission**: User clicks email link; client sends `PUT /v1/email_verifications/:nonce`.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

6. **Validate nonce**: Email Verifications Controller looks up the nonce in `continuumUsersDb` and checks expiry.
   - From: `continuumUsersServiceApi_emailVerificationsController`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

7. **Mark account email-verified**: Account Strategies updates the account's email verification status and marks the nonce record as completed.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

8. **Queue verification event**: Account & Auth Event Publishers queues an `email_verification.completed` event via the outbox pattern.
   - From: `continuumUsersServiceApi_eventPublishers`
   - To: `continuumUsersDb` (outbox) + `continuumUsersRedis` (Resque)
   - Protocol: ActiveRecord + Redis

9. **Return success**: API returns HTTP 200 confirming verification is complete.
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

10. **Publish email_verification.completed event (async)**: Resque worker reads outbox and publishes to Message Bus Broker.
    - From: `continuumUsersResqueWorkers`
    - To: `continuumUsersMessageBusBroker`
    - Protocol: GBus/STOMP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Nonce expired | Token validation fails | 422 Unprocessable Entity |
| Nonce already used | Record marked completed; validation fails | 422 Unprocessable Entity |
| Nonce not found | Repository returns nil | 404 Not Found |
| Email delivery failure | Mailman error | 500; user must retry initiation |
| Resque job failure (event) | Resque retries with backoff | Event delayed; verification still applied |

## Sequence Diagram

```
[Phase 1 - Initiate]
Consumer          -> UsersServiceAPI         : POST /v1/email_verifications
UsersServiceAPI   -> AccountStrategies       : create_email_verification(account)
AccountStrategies -> AccountRepository       : INSERT email_verifications (nonce, expires_at)
UsersServiceAPI   -> AppMailer               : send_verification_email(account, nonce)
AppMailer         -> MailService             : SMTP deliver verification email
UsersServiceAPI   --> Consumer               : 200 OK

[Phase 2 - Complete]
Consumer          -> UsersServiceAPI         : PUT /v1/email_verifications/:nonce
UsersServiceAPI   -> AccountRepository       : SELECT email_verifications WHERE nonce = ?
AccountRepository --> UsersServiceAPI        : verification record (valid / expired)
UsersServiceAPI   -> AccountStrategies       : complete_email_verification(account)
AccountStrategies -> AccountRepository       : UPDATE accounts SET email_verified = true
AccountStrategies -> AccountRepository       : UPDATE email_verifications SET completed_at = now()
EventPublishers   -> AsyncMBPublisher        : queue email_verification.completed
AsyncMBPublisher  -> UsersDb                 : INSERT message_bus_messages
AsyncMBPublisher  -> UsersRedis              : RPUSH resque:queue
UsersServiceAPI   --> Consumer               : 200 OK
[async]
ResqueWorker      -> MessageBusBroker        : PUBLISH email_verification.completed
```

## Related

- Related flows: [Account Creation](account-creation.md), [Authentication](authentication.md)
