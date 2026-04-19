---
service: "users-service"
title: "Account Deactivation and Erasure Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "account-deactivation-erasure"
flow_type: synchronous
trigger: "DELETE /v1/accounts/:id or POST /erasure"
participants:
  - "consumer"
  - "continuumUsersService"
  - "continuumUsersDb"
  - "continuumUsersRedis"
  - "continuumUsersResqueWorkers"
  - "continuumUsersMessageBusBroker"
architecture_ref: "containers-users-service"
---

# Account Deactivation and Erasure Flow

## Summary

Users Service handles two related account termination flows: voluntary deactivation via `DELETE /v1/accounts/:id` and GDPR-mandated erasure via `POST /erasure`. Both paths transition the account to an inactive/erased state in MySQL, invalidate active tokens, and publish an `account.deactivated` event to the Message Bus. The GDPR erasure path additionally removes or anonymizes personal data fields in compliance with right-to-erasure requirements.

## Trigger

- **Type**: api-call
- **Source**: Authenticated user requesting deactivation, or internal service/compliance tooling triggering GDPR erasure
- **Frequency**: On-demand per user action or compliance request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (client) or internal caller | Initiates deactivation or erasure | `consumer` |
| Users Service API | Orchestrates deactivation/erasure via Account Strategies | `continuumUsersService` |
| Users DB | Updates account status and removes/anonymizes personal data | `continuumUsersDb` |
| Users Redis | Resque job enqueue for async event publishing | `continuumUsersRedis` |
| Users Resque Workers | Publishes account.deactivated event asynchronously | `continuumUsersResqueWorkers` |
| Message Bus Broker | Receives account.deactivated event | `continuumUsersMessageBusBroker` |

## Steps

### Path A: Account Deactivation (`DELETE /v1/accounts/:id`)

1. **Receive deactivation request**: Authenticated client sends `DELETE /v1/accounts/:id`.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Authorize and load account**: Accounts Controller validates the JWT token via Token Service and loads the account via Account Repository.
   - From: `continuumUsersServiceApi_accountsController`
   - To: `continuumUsersServiceApi_tokenService` + `continuumUsersServiceApi_repository`
   - Protocol: Ruby (in-process) + ActiveRecord

3. **Deactivate account**: Account Strategies sets the account status to deactivated and invalidates all active tokens.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Queue deactivation event**: Account & Auth Event Publishers inserts a `MessageBusMessage` outbox record and enqueues a Resque job for `account.deactivated`.
   - From: `continuumUsersServiceApi_eventPublishers`
   - To: `continuumUsersDb` (outbox) + `continuumUsersRedis` (Resque)
   - Protocol: ActiveRecord + Redis

5. **Return success response**: API returns HTTP 200.
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

6. **Publish account.deactivated event (async)**: Resque worker reads outbox and publishes to Message Bus Broker.
   - From: `continuumUsersResqueWorkers`
   - To: `continuumUsersMessageBusBroker`
   - Protocol: GBus/STOMP

### Path B: GDPR Erasure (`POST /erasure`)

1. **Receive erasure request**: Internal compliance service or tooling sends `POST /erasure` with account identifier.
   - From: internal caller
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Load and validate account**: Accounts Controller authenticates the request and loads the account.
   - From: `continuumUsersServiceApi_accountsController`
   - To: `continuumUsersServiceApi_repository`
   - Protocol: ActiveRecord

3. **Anonymize / remove personal data**: Account Strategies removes or anonymizes PII fields (email, name, profile attributes) per GDPR requirements, and sets the account to erased status.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Invalidate all tokens and credentials**: All active tokens, passwords, and third-party links are deleted or invalidated.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

5. **Queue deactivation event**: Publishes `account.deactivated` event with reason `gdpr_erasure` via the outbox pattern.
   - From: `continuumUsersServiceApi_eventPublishers`
   - To: `continuumUsersDb` (outbox) + `continuumUsersRedis` (Resque)
   - Protocol: ActiveRecord + Redis

6. **Return erasure confirmation**: API returns HTTP 200.
   - From: `continuumUsersService`
   - To: internal caller
   - Protocol: HTTPS / REST

7. **Publish account.deactivated event (async)**: Resque worker publishes event.
   - From: `continuumUsersResqueWorkers`
   - To: `continuumUsersMessageBusBroker`
   - Protocol: GBus/STOMP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Account not found | Repository returns nil | 404 Not Found |
| Unauthorized deactivation | Token validation fails or account mismatch | 403 Forbidden |
| Database update failure | ActiveRecord raises exception | 500; account not deactivated |
| Resque job failure (event) | Resque retries with backoff | Event delayed; deactivation already applied |
| GDPR erasure on already-erased account | Idempotent — no-op | 200 OK |

## Sequence Diagram

```
[Path A - Deactivation]
Consumer          -> UsersServiceAPI         : DELETE /v1/accounts/:id
UsersServiceAPI   -> TokenService            : validate_token
UsersServiceAPI   -> AccountRepository       : SELECT account WHERE id = ?
AccountStrategies -> AccountRepository       : UPDATE accounts SET status = deactivated
AccountStrategies -> AccountRepository       : UPDATE tokens SET invalid = true
EventPublishers   -> AsyncMBPublisher        : queue account.deactivated
AsyncMBPublisher  -> UsersDb                 : INSERT message_bus_messages
AsyncMBPublisher  -> UsersRedis              : RPUSH resque:queue
UsersServiceAPI   --> Consumer               : 200 OK
[async]
ResqueWorker      -> MessageBusBroker        : PUBLISH account.deactivated

[Path B - GDPR Erasure]
InternalCaller    -> UsersServiceAPI         : POST /erasure (account_id)
UsersServiceAPI   -> AccountRepository       : SELECT account WHERE id = ?
AccountStrategies -> AccountRepository       : anonymize PII fields
AccountStrategies -> AccountRepository       : DELETE tokens, passwords, third_party_links
AccountStrategies -> AccountRepository       : UPDATE accounts SET status = erased
EventPublishers   -> AsyncMBPublisher        : queue account.deactivated (reason: gdpr_erasure)
AsyncMBPublisher  -> UsersDb                 : INSERT message_bus_messages
AsyncMBPublisher  -> UsersRedis              : RPUSH resque:queue
UsersServiceAPI   --> InternalCaller         : 200 OK
[async]
ResqueWorker      -> MessageBusBroker        : PUBLISH account.deactivated
```

## Related

- Related flows: [Account Creation](account-creation.md), [Authentication](authentication.md)
