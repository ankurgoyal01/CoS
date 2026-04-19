---
service: "identity-service"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Identity Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Identity Creation](identity-creation.md) | synchronous | `POST /v1/identities` API call | Creates a new identity record in PostgreSQL, publishes lifecycle events to Message Bus |
| [Identity Erasure (GDPR)](identity-erasure-gdpr.md) | synchronous | `POST /v1/identities/erasure` API call | Initiates GDPR erasure for an identity via the HTTP API |
| [Erasure Request Handling (Async)](erasure-request-handling.md) | asynchronous | GDPR erasure event consumed from Message Bus | Mbus consumer worker processes erasure, removes data, publishes completion event |
| [Dog-food Audit](dogfood-audit.md) | event-driven | Audit event consumed from Message Bus | Mbus consumer processes internal audit events and writes audit records |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The following flows cross service boundaries and are referenced in the central architecture Structurizr workspace:

- **Identity Creation** spans `continuumIdentityServiceApp`, `continuumIdentityServicePrimaryPostgres`, and the Message Bus — see dynamic view `dynamic-api-create-identity`.
- **Erasure Request Handling** spans `continuumIdentityServiceMbusConsumer`, `continuumIdentityServicePrimaryPostgres`, the Message Bus, and the GDPR Platform — see dynamic view `dynamic-account-erasure-flow`.
- **Users Sync Cycle** (cross-platform identity synchronization) — see dynamic view `dynamic-users-sync-cycle`.
