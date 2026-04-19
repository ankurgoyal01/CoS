---
service: "users-service"
title: "Forced Password Reset Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "forced-password-reset"
flow_type: event-driven
trigger: "bemod.suspiciousBehavior event consumed from Message Bus"
participants:
  - "continuumUsersMessageBusConsumer"
  - "continuumUsersMessageBusBroker"
  - "continuumUsersDb"
  - "continuumUsersMailService"
  - "continuumUsersResqueWorkers"
architecture_ref: "components-continuumUsersMessageBusConsumer"
---

# Forced Password Reset Flow

## Summary

The forced password reset flow is triggered by security signals indicating compromised or suspicious account activity. It operates through two complementary paths: an event-driven path via the Message Bus Consumer (processing `bemod.suspiciousBehavior` events) and a batch path via the Resque Forced Password Reset Job (processing compromised-credential batches from Flare). Both paths invalidate credentials, update account records, and send notification emails to affected users.

## Trigger

- **Type**: event (primary path) and batch (secondary path)
- **Source**: `bemod.suspiciousBehavior` topic on `continuumUsersMessageBusBroker`; Flare compromised-password batch input (Resque job)
- **Frequency**: Event-driven as security signals arrive; batch on schedule or manual trigger

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus Consumer | Consumes suspicious behavior events and triggers credential invalidation | `continuumUsersMessageBusConsumer` |
| Message Bus Broker | Delivers `bemod.suspiciousBehavior` events | `continuumUsersMessageBusBroker` |
| Users DB | Stores account credentials and audit records; updated during reset | `continuumUsersDb` |
| Mail Delivery Service | Delivers forced reset notification emails to users | `continuumUsersMailService` |
| Users Resque Workers | Executes Forced Password Reset Job for batch remediation | `continuumUsersResqueWorkers` |

## Steps

### Path A: Event-Driven via Message Bus Consumer

1. **Receive suspicious behavior event**: Message Bus Consumer Runner receives a `bemod.suspiciousBehavior` event from `continuumUsersMessageBusBroker`.
   - From: `continuumUsersMessageBusBroker`
   - To: `continuumUsersMessageBusConsumer_consumerRunner`
   - Protocol: GBus/STOMP

2. **Normalize and route event**: Message Handler Base normalizes the incoming payload and routes it to the Forced Password Reset Handler.
   - From: `continuumUsersMessageBusConsumer_consumerRunner`
   - To: `continuumUsersMessageBusConsumer_forcedPasswordResetHandler`
   - Protocol: Ruby (in-process)

3. **Load affected account**: Forced Password Reset Handler queries Account Repository (Consumer) to load the account and its password history.
   - From: `continuumUsersMessageBusConsumer_forcedPasswordResetHandler`
   - To: `continuumUsersDb` (via `continuumUsersMessageBusConsumer_accountRepository`)
   - Protocol: MySQL / ActiveRecord

4. **Invalidate credentials**: Handler marks existing tokens as invalid and resets the password to a temporary value in `continuumUsersDb`.
   - From: `continuumUsersMessageBusConsumer_forcedPasswordResetHandler`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

5. **Send forced reset notification**: Message Bus Mailer delivers a forced password reset notification email to the user.
   - From: `continuumUsersMessageBusConsumer_mailer`
   - To: `continuumUsersMailService`
   - Protocol: SMTP/Mailman

### Path B: Batch via Resque Worker

1. **Enqueue batch job**: Forced Password Reset Job is enqueued with a batch of compromised account identifiers (from Flare or manual trigger).
   - From: External trigger / `continuumUsersRedis` queue
   - To: `continuumUsersResqueWorkers_resetPasswordJob`
   - Protocol: Resque

2. **Read account credentials**: Job reads account and credential records from `continuumUsersDb` via Worker Repository.
   - From: `continuumUsersResqueWorkers_resetPasswordJob`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

3. **Update account records**: Job resets passwords and invalidates tokens for each account in the batch.
   - From: `continuumUsersResqueWorkers_resetPasswordJob`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Send notification emails**: Worker Mailer sends forced reset emails to all impacted users.
   - From: `continuumUsersResqueWorkers_mailer`
   - To: `continuumUsersMailService`
   - Protocol: SMTP/Mailman

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message parsing failure | Message Handler Base catches and logs; message may be re-delivered | Event reprocessed or dropped per broker policy |
| Account not found for event | Handler logs missing account; processing continues | No credential change for unknown account |
| Database write failure | Exception raised in handler; GBus consumer may retry delivery | Credential not reset; event retried |
| Email delivery failure (event path) | Mailman error; no retry in synchronous call | Reset still applied; user not notified |
| Resque batch job failure | Resque retries with backoff | Batch processing delayed; eventually retried |

## Sequence Diagram

```
[Path A - Event-Driven]
MessageBusBroker     -> ConsumerRunner          : DELIVER bemod.suspiciousBehavior
ConsumerRunner       -> MessageHandlerBase       : normalize(event)
MessageHandlerBase   -> ForcedResetHandler       : handle(event)
ForcedResetHandler   -> AccountRepository        : SELECT account + passwords
AccountRepository    --> ForcedResetHandler       : account record
ForcedResetHandler   -> UsersDb                  : UPDATE tokens SET invalid = true
ForcedResetHandler   -> UsersDb                  : UPDATE passwords SET reset = true
ForcedResetHandler   -> MessageBusMailer          : send_forced_reset_email(account)
MessageBusMailer     -> MailService               : SMTP deliver notification

[Path B - Batch Resque]
ResquePool           -> ForcedResetJob            : execute(batch)
ForcedResetJob       -> WorkerRepository          : SELECT accounts WHERE id IN (batch)
ForcedResetJob       -> UsersDb                   : UPDATE credentials for batch
ForcedResetJob       -> WorkerMailer              : send_reset_emails(accounts)
WorkerMailer         -> MailService               : SMTP deliver notifications
```

## Related

- Related flows: [Password Reset](password-reset.md), [Authentication](authentication.md)
