---
service: "users-service"
title: "Account Creation Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "account-creation"
flow_type: synchronous
trigger: "POST /v1/accounts"
participants:
  - "consumer"
  - "continuumUsersService"
  - "continuumUsersIdentityService"
  - "continuumUsersDb"
  - "continuumUsersRedis"
  - "continuumUsersResqueWorkers"
  - "continuumUsersMessageBusBroker"
  - "continuumUsersMailService"
architecture_ref: "containers-users-service"
---

# Account Creation Flow

## Summary

Account creation handles new user registration via `POST /v1/accounts`. The Accounts Controller delegates to Account Strategies, which validate the submitted data, optionally create the account through the Identity Service, persist the account to MySQL, and enqueue asynchronous side effects including event publishing and welcome email delivery. The flow returns the new account payload synchronously while async jobs proceed in the background.

## Trigger

- **Type**: api-call
- **Source**: Web or mobile client submitting registration form data
- **Frequency**: On-demand per user registration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (client) | Initiates registration request | `consumer` |
| Users Service API | Receives request; orchestrates creation via controller and strategies | `continuumUsersService` |
| Identity Service | Optional: creates authoritative account record when integration enabled | `continuumUsersIdentityService` |
| Users DB | Persists account, password, and outbox message records | `continuumUsersDb` |
| Users Redis | Receives enqueued Resque job for event publishing | `continuumUsersRedis` |
| Users Resque Workers | Publishes account.created / account.registered events and sends welcome email | `continuumUsersResqueWorkers` |
| Message Bus Broker | Receives published account lifecycle events | `continuumUsersMessageBusBroker` |
| Mail Delivery Service | Delivers welcome or verification email | `continuumUsersMailService` |

## Steps

1. **Receive registration request**: Client sends `POST /v1/accounts` with email, password, and profile attributes.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Validate and orchestrate via Accounts Controller**: Accounts Controller parses parameters and invokes Account Strategies.
   - From: `continuumUsersServiceApi_accountsController`
   - To: `continuumUsersServiceApi_accountStrategies`
   - Protocol: Ruby (in-process)

3. **Delegate to Identity Service (if enabled)**: Account Strategies calls Identity Service Client to create the authoritative account record.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersIdentityService` (via `continuumUsersServiceApi_identityServiceClient`)
   - Protocol: HTTP/JSON

4. **Persist account to database**: Account Strategies writes the account, password hash (bcrypt), and token records via Account Repository.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb` (via `continuumUsersServiceApi_repository`)
   - Protocol: MySQL / ActiveRecord

5. **Queue event publishing**: Account & Auth Event Publishers inserts a `MessageBusMessage` outbox record and enqueues a Resque job via Async Message Bus Publisher.
   - From: `continuumUsersServiceApi_eventPublishers`
   - To: `continuumUsersDb` (outbox record) + `continuumUsersRedis` (Resque job)
   - Protocol: ActiveRecord + Redis

6. **Return account response**: API returns the created account payload (HTTP 201) to the caller.
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

7. **Publish account.created event (async)**: Resque worker reads the outbox record and publishes to the Message Bus Broker.
   - From: `continuumUsersResqueWorkers`
   - To: `continuumUsersMessageBusBroker`
   - Protocol: GBus/STOMP

8. **Send welcome / verification email (async)**: Resque worker invokes Worker Mailer to deliver email via Mailman.
   - From: `continuumUsersResqueWorkers`
   - To: `continuumUsersMailService`
   - Protocol: SMTP/Mailman

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Identity Service unavailable | HTTP error from Identity Service Client; Account Strategies may fall back to local creation if fallback is enabled | 503 or local account created |
| Database write failure | ActiveRecord raises exception; request returns 500 | No account created; no event queued |
| Email field validation failure | Account Strategies raises validation error | 422 response; no account persisted |
| Resque job fails (event publishing) | Resque retries with backoff; outbox record remains in `pending` state | Event eventually published on retry success |
| Duplicate email | Unique constraint violation in `continuumUsersDb` | 422 response to caller |

## Sequence Diagram

```
Consumer          -> UsersServiceAPI         : POST /v1/accounts (email, password, profile)
UsersServiceAPI   -> AccountStrategies       : create_account(params)
AccountStrategies -> IdentityServiceClient   : create_identity(params) [if enabled]
IdentityServiceClient -> IdentityService     : POST /accounts
IdentityService   --> IdentityServiceClient  : identity created
AccountStrategies -> AccountRepository       : insert account + password
AccountRepository --> AccountStrategies      : account persisted
AccountStrategies -> EventPublishers         : emit account.created
EventPublishers   -> AsyncMBPublisher        : enqueue MessageBusMessage + Resque job
AsyncMBPublisher  -> UsersDb                 : INSERT message_bus_messages
AsyncMBPublisher  -> UsersRedis              : RPUSH resque:queue
UsersServiceAPI   --> Consumer               : 201 Created (account payload)
[async]
ResqueWorker      -> UsersDb                 : SELECT pending message_bus_messages
ResqueWorker      -> MessageBusBroker        : PUBLISH account.created
ResqueWorker      -> MailService             : send welcome/verification email
```

## Related

- Architecture dynamic view: `dynamic-users-continuumUsersServiceApi_tokenService-authentication-flow`
- Related flows: [Authentication](authentication.md), [Email Verification](email-verification.md), [Third-Party Linking](third-party-linking.md)
