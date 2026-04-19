---
service: "regulatory-consent-log"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumRegulatoryConsentLogDb"
    type: "postgresql"
    purpose: "Primary consent, cookie, erasure, event, and outbox store"
  - id: "continuumRegulatoryConsentRedis"
    type: "redis"
    purpose: "User erasure work queue and pub/sub channel"
---

# Data Stores

## Overview

The Regulatory Consent Log owns two data stores: a PostgreSQL instance (provisioned via Groupon DaaS) that serves as the primary relational store for all consent, cookie, erasure, and event records as well as the Cronus message outbox; and a Redis instance (provisioned via Groupon RaaS) used as an intermediate work queue and pub/sub channel for the asynchronous user erasure pipeline.

## Stores

### Regulatory Consent Log Postgres (`continuumRegulatoryConsentLogDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumRegulatoryConsentLogDb` |
| Purpose | Primary relational store for consents, erased cookies, erasure records, Cronus message outbox, and user event audit |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. Managed via DaaS provisioning. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `regulatory_consent_logs` | Stores each user consent log entry | `id` (PK), `identifierType`, `identifierValue`, `workflowType`, `eventType`, `logType`, `termsType`, `termsTypeVersion`, `countryCode`, `locale`, `xClientRole`, `xRemoteAgent`, `createdAt`, `metadata` |
| `mbus_messages` | Cronus transactional outbox for MBus publish | `id` (PK), `uuid_id`, `payload`, `processing_status`, `destination`, `attempted_at`, `attempts`, `created_at`, `updated_at` |
| erased cookie mapping table | Maps erased user UUIDs to their b-cookie values | `b_cookie`, `userId`, `eventId`, `createdAt`, `metadata` |
| erasure status / user erasure table | Tracks user erasure lifecycle state | `userId`, `status` (`initiated`, `deactivated`, `notified`, `in_progress`, `erased`), `createdAt`, `endDate`, `brand`, `locale`, `numberOfDaysLeft`, `erasureReason` |
| user event / audit table | Persists Transcend webhook event status and audit details | user event fields managed by `Register User Event DBI` |

#### Access Patterns

- **Read**: Consent lookups by `identifierValue` with optional `workflowType` filter; b-cookie lookups by UUID; erasure status by `user_id`; Cronus outbox reads by `processing_status` for periodic publishing.
- **Write**: Atomic transactional writes of consent rows + Cronus outbox rows (`POST /v1/consents`); cookie mappings written by the worker after Janus resolution; erasure status updates by worker jobs and the API.
- **Indexes**: Indexed on `identifierValue` for consent lookups and on `b_cookie` for cookie validation lookups (evidence from high-throughput SLA targets of 15,000 RPM on `GET /v1/cookie`).

### Regulatory Consent Redis (RaaS) (`continuumRegulatoryConsentRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumRegulatoryConsentRedis` |
| Purpose | Intermediate work queue and pub/sub channel for the user erasure async pipeline |
| Ownership | owned (RaaS-provisioned) |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Erasure work queue | Holds user UUIDs to be processed by the erasure pipeline | User UUID entries |
| Error queue | Records failed erasure processing attempts for retry or inspection | User UUID, error details, retry count |

#### Access Patterns

- **Read**: `User Erased Redis Pub/Sub Worker` dequeues user UUIDs for processing.
- **Write**: `User Erasure MBus Listener` enqueues user UUIDs on receipt of MBus erasure event; failures are written to the error queue.

## Caches

> The Redis store (`continuumRegulatoryConsentRedis`) is used as a work queue rather than a cache. No read-through or write-through caching pattern is used.

## Data Flows

1. `POST /v1/consents` writes a consent row and a Cronus outbox row to Postgres atomically.
2. The Cronus Publisher Quartz job (in the Worker) reads pending outbox rows from Postgres and publishes them to the MBus consent log topic, updating `processing_status` and `attempted_at`.
3. MBus user erasure events arrive at the Worker, which writes user UUIDs to the Redis work queue.
4. The Redis Pub/Sub Worker dequeues UUIDs, calls Janus Aggregator to resolve b-cookies, writes the cookie-to-user mappings to Postgres, then publishes an erasure-complete event to MBus.
5. The Erasure Complete Message Reader updates the erasure status record in Postgres.
