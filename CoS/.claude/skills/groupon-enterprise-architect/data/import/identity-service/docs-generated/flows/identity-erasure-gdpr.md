---
service: "identity-service"
title: "Identity Erasure (GDPR)"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "identity-erasure-gdpr"
flow_type: synchronous
trigger: "API consumer sends POST /v1/identities/erasure with a target identity UUID"
participants:
  - "API consumer (GDPR Platform or authorized service)"
  - "continuumIdentityServiceApp"
  - "continuumIdentityServicePrimaryPostgres"
  - "Message Bus"
architecture_ref: "dynamic-account-erasure-flow"
---

# Identity Erasure (GDPR)

## Summary

This flow covers the HTTP-initiated leg of GDPR erasure. An authorized caller (typically the GDPR Platform or a privacy engineering service) sends a `POST /v1/identities/erasure` request for a specific identity UUID. The HTTP API validates the request, records the erasure intent, and enqueues the erasure for async processing. The heavy lifting — data removal and completion event publishing — occurs in the [Erasure Request Handling (Async)](erasure-request-handling.md) flow. This synchronous leg is intentionally lightweight to return quickly to the caller.

## Trigger

- **Type**: api-call
- **Source**: GDPR Platform or authorized compliance service with a valid Bearer JWT
- **Frequency**: On-demand, per GDPR right-to-erasure request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GDPR Platform / authorized caller | Initiates erasure request with target UUID and Bearer JWT | External (internal Groupon) |
| `continuumIdentityServiceApp` | Validates JWT, validates erasure request, enqueues async erasure job, returns acknowledgement | `continuumIdentityServiceApp` |
| `continuumIdentityServicePrimaryPostgres` | Records erasure intent (marks identity as pending erasure) | `continuumIdentityServicePrimaryPostgres` |
| Message Bus | Optionally receives an erasure-initiated event for audit trail | Internal Message Bus infrastructure |

## Steps

1. **Receive erasure request**: Caller sends `POST /v1/identities/erasure` with the target identity UUID and `Authorization: Bearer <jwt>`.
   - From: GDPR Platform / authorized caller
   - To: `continuumIdentityServiceApp`
   - Protocol: REST / HTTPS

2. **Validate Bearer JWT**: JWT middleware verifies token validity; rejects with 401 if invalid.
   - From: `continuumIdentityServiceApp` (JWT middleware)
   - To: `continuumIdentityServiceApp` (request handler)
   - Protocol: direct (in-process)

3. **Validate erasure request**: Confirms the identity UUID exists and is eligible for erasure.
   - From: `continuumIdentityServiceApp`
   - To: `continuumIdentityServicePrimaryPostgres`
   - Protocol: ActiveRecord / SQL

4. **Record erasure intent**: Marks the identity record as pending erasure in PostgreSQL (soft-flag to prevent concurrent modification).
   - From: `continuumIdentityServiceApp`
   - To: `continuumIdentityServicePrimaryPostgres`
   - Protocol: ActiveRecord / SQL

5. **Enqueue async erasure job**: Places the erasure job on the Resque queue (backed by Redis) for the Mbus consumer worker to process.
   - From: `continuumIdentityServiceApp`
   - To: Resque / `continuumIdentityServiceRedis`
   - Protocol: Redis

6. **Return HTTP 202 Accepted**: Returns an acknowledgement to the caller confirming the erasure has been accepted for processing.
   - From: `continuumIdentityServiceApp`
   - To: GDPR Platform / authorized caller
   - Protocol: REST / HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired JWT | JWT middleware returns HTTP 401 | Erasure request rejected; no data modified |
| Identity UUID not found | Application returns HTTP 404 | Caller notified; no action taken |
| PostgreSQL unavailable | ActiveRecord exception; HTTP 500 returned | Caller must retry; no erasure enqueued |
| Redis unavailable (Resque enqueue fails) | Application exception; HTTP 500 returned | Caller must retry; intent flag may need cleanup |

## Sequence Diagram

```
GDPRPlatform -> continuumIdentityServiceApp: POST /v1/identities/erasure {uuid} [Bearer JWT]
continuumIdentityServiceApp -> continuumIdentityServiceApp: Validate JWT
continuumIdentityServiceApp -> continuumIdentityServicePrimaryPostgres: SELECT identity by uuid
continuumIdentityServicePrimaryPostgres --> continuumIdentityServiceApp: Identity record
continuumIdentityServiceApp -> continuumIdentityServicePrimaryPostgres: UPDATE identity SET pending_erasure=true
continuumIdentityServiceApp -> continuumIdentityServiceRedis: Resque.enqueue(ErasureJob, uuid)
continuumIdentityServiceApp --> GDPRPlatform: 202 Accepted
```

## Related

- Architecture dynamic view: `dynamic-account-erasure-flow`
- Related flows: [Erasure Request Handling (Async)](erasure-request-handling.md), [Identity Creation](identity-creation.md)
