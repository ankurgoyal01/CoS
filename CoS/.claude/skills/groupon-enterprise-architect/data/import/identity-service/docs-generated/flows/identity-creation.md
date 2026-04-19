---
service: "identity-service"
title: "Identity Creation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "identity-creation"
flow_type: synchronous
trigger: "API consumer sends POST /v1/identities with identity attributes"
participants:
  - "API consumer (web/mobile/partner service)"
  - "continuumIdentityServiceApp"
  - "continuumIdentityServicePrimaryPostgres"
  - "continuumIdentityServiceRedis"
  - "Message Bus"
architecture_ref: "dynamic-api-create-identity"
---

# Identity Creation

## Summary

This flow describes how a new user identity record is created within the Groupon ecosystem. An authenticated API consumer sends a POST request with identity attributes; the service validates the JWT, persists the record to PostgreSQL, optionally primes the Redis cache, and publishes identity lifecycle events (`created`) to both the `identity.v1.event` and `identity.v1.c2.event` topics on the Message Bus. The entire HTTP leg is synchronous; event publishing may be asynchronous via the outbox pattern.

## Trigger

- **Type**: api-call
- **Source**: Groupon web application, mobile application, or partner service with a valid Bearer JWT
- **Frequency**: On-demand, per new user account creation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API consumer | Initiates identity creation with POST body and Bearer JWT | External |
| `continuumIdentityServiceApp` | Validates JWT, creates record, writes outbox entry, returns response | `continuumIdentityServiceApp` |
| `continuumIdentityServicePrimaryPostgres` | Persists identity record and message bus outbox entry atomically | `continuumIdentityServicePrimaryPostgres` |
| `continuumIdentityServiceRedis` | Cache prime — stores new identity for fast subsequent reads | `continuumIdentityServiceRedis` |
| Message Bus | Receives and delivers `identity.v1.event` and `identity.v1.c2.event` created events | Internal Message Bus infrastructure |

## Steps

1. **Receive creation request**: API consumer sends `POST /v1/identities` with identity attribute payload and `Authorization: Bearer <jwt>` header.
   - From: API consumer
   - To: `continuumIdentityServiceApp`
   - Protocol: REST / HTTPS

2. **Validate Bearer JWT**: rack middleware extracts and verifies the JWT using `JWT_SECRET`; rejects with 401 if invalid or expired.
   - From: `continuumIdentityServiceApp` (JWT middleware)
   - To: `continuumIdentityServiceApp` (request handler)
   - Protocol: direct (in-process)

3. **Validate request payload**: Application validates required identity fields; returns 422 if validation fails.
   - From: `continuumIdentityServiceApp`
   - To: `continuumIdentityServiceApp`
   - Protocol: direct (in-process)

4. **Persist identity record**: Writes the new identity record and a `message_bus_messages` outbox entry within a single database transaction.
   - From: `continuumIdentityServiceApp`
   - To: `continuumIdentityServicePrimaryPostgres`
   - Protocol: ActiveRecord / SQL

5. **Prime Redis cache**: Writes the new identity record to Redis for fast subsequent lookups.
   - From: `continuumIdentityServiceApp`
   - To: `continuumIdentityServiceRedis`
   - Protocol: Redis

6. **Return HTTP 201 response**: Returns the created identity record (with UUID) to the API consumer.
   - From: `continuumIdentityServiceApp`
   - To: API consumer
   - Protocol: REST / HTTPS

7. **Publish lifecycle events**: Outbox relay (or in-process publisher) reads unpublished rows from `message_bus_messages` and publishes `identity.v1.event` (type: `created`) and `identity.v1.c2.event` (type: `created`) to the Message Bus.
   - From: `continuumIdentityServiceApp` / outbox relay
   - To: Message Bus
   - Protocol: Thrift / g-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired JWT | JWT middleware returns HTTP 401 | Consumer receives 401; no record written |
| Missing required fields | Validation layer returns HTTP 422 | Consumer receives 422 with field errors; no record written |
| PostgreSQL write failure | ActiveRecord raises exception; transaction rolls back | Consumer receives HTTP 500; no partial record or outbox entry persisted |
| Redis write failure | Cache write is non-critical; failure is logged and ignored | Identity created successfully; subsequent reads fall back to PostgreSQL |
| Message Bus publish failure | Outbox row remains unpublished; relay retries on next cycle | Event eventually delivered; at-least-once guarantee via outbox |

## Sequence Diagram

```
APIConsumer -> continuumIdentityServiceApp: POST /v1/identities [Bearer JWT]
continuumIdentityServiceApp -> continuumIdentityServiceApp: Validate JWT
continuumIdentityServiceApp -> continuumIdentityServiceApp: Validate payload
continuumIdentityServiceApp -> continuumIdentityServicePrimaryPostgres: INSERT identity + outbox row [transaction]
continuumIdentityServicePrimaryPostgres --> continuumIdentityServiceApp: Commit OK
continuumIdentityServiceApp -> continuumIdentityServiceRedis: SET identity:<uuid>
continuumIdentityServiceApp --> APIConsumer: 201 Created (identity record with UUID)
continuumIdentityServiceApp -> MessageBus: Publish identity.v1.event (created)
continuumIdentityServiceApp -> MessageBus: Publish identity.v1.c2.event (created)
```

## Related

- Architecture dynamic view: `dynamic-api-create-identity`
- Related flows: [Identity Erasure (GDPR)](identity-erasure-gdpr.md), [Erasure Request Handling (Async)](erasure-request-handling.md)
