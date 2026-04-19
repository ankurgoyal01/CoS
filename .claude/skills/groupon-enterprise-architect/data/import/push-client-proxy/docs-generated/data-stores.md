---
service: "push-client-proxy"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPushClientProxyPostgresMainDb"
    type: "postgresql"
    purpose: "Primary persistence for audience entities and email-send records"
  - id: "continuumPushClientProxyPostgresExclusionsDb"
    type: "postgresql"
    purpose: "Read-only denylist of excluded email addresses and wildcard patterns"
  - id: "continuumPushClientProxyMySqlUsersDb"
    type: "mysql"
    purpose: "Read-only user account existence lookup"
  - id: "continuumPushClientProxyRedisPrimary"
    type: "redis"
    purpose: "Email metadata cache, rate-limit token buckets, audience keys"
  - id: "continuumPushClientProxyRedisIncentive"
    type: "redis"
    purpose: "Incentive audience treatment keys"
---

# Data Stores

## Overview

push-client-proxy uses five data stores. The primary PostgreSQL database stores audience membership and email-send records. A secondary read-only PostgreSQL database holds the exclusion denylist. A MySQL database provides read-only user account lookup. Two Redis clusters serve as high-speed caches for email metadata and audience keys, and also back the Bucket4j distributed rate limiter.

## Stores

### push-client-proxy main database (`continuumPushClientProxyPostgresMainDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPushClientProxyPostgresMainDb` |
| Purpose | Primary persistence for audience entities and email-send records |
| Ownership | owned |
| Migrations path | Not discovered in codebase |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `Audience` | Stores audience membership records | `audienceId`, UUID membership list, counts |
| `EmailSend` | Persists outbound email send outcomes for auditing | `requestId`, `userId`, send result, timestamp |

#### Access Patterns

- **Read**: `AudienceRepository` queries audience by ID for count retrieval; `EmailSendRepository` queries for history.
- **Write**: `AudienceService` writes audience patch results; `EmailSendMessageListener` batch-inserts `EmailSend` records after processing each Kafka batch.
- **Indexes**: Not discoverable from source — JPA entities are present but schema DDL is not in the repository.

---

### rocketman exclusions database (`continuumPushClientProxyPostgresExclusionsDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPushClientProxyPostgresExclusionsDb` |
| Purpose | Read-only denylist of excluded email addresses and wildcard patterns |
| Ownership | shared (read-only access) |
| Migrations path | Not applicable — this is an external read-only data source |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `Exclusion` | Stores email addresses and wildcard patterns that must not receive email | email address or pattern |

#### Access Patterns

- **Read**: `EmailExclusionService` queries `ExclusionRepository` before each email send to check if the recipient address matches any exclusion rule (including wildcard patterns).
- **Write**: None — this database is read-only from this service's perspective.
- **Indexes**: Not discoverable from source.

---

### users lookup database (`continuumPushClientProxyMySqlUsersDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumPushClientProxyMySqlUsersDb` |
| Purpose | Read-only user account existence lookup |
| Ownership | shared (read-only access) |
| Migrations path | Not applicable — external data source owned by Users service |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `RocketmanEmailLookup` | Maps user IDs to account existence status | `userId` |

#### Access Patterns

- **Read**: `UserAccountService` queries `RocketmanEmailLookupRepository` to verify a user account exists before permitting an email send.
- **Write**: None — this service only reads.
- **Indexes**: Not discoverable from source.

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumPushClientProxyRedisPrimary` | Redis (cluster) | Stores email metadata keyed by `userId`+`sendId` for delivery callback lookup; also backs Bucket4j rate-limit token buckets for email send and audience patch | Not discoverable from source (Bucket4j expiration set to 5 seconds post-refill) |
| `continuumPushClientProxyRedisIncentive` | Redis (cluster) | Stores incentive audience treatment keys read and written by `AudienceRedisUtil` | Not discoverable from source |

Both Redis clusters use Lettuce connection pooling. The primary Redis cluster is also used by the `RateLimiterConfig` to back the Bucket4j `LettuceBasedProxyManager`.

## Data Flows

- Bloomreach POSTs an email send request → `EmailController` validates against MySQL (user existence) and PostgreSQL exclusions DB → if approved, calls `EmailInjectorService` which stores email metadata in primary Redis (keyed for later callback lookup) and sends via SMTP.
- Kafka `msys_delivery` consumer reads delivery events → looks up stored metadata from primary Redis → POSTs callback to downstream HTTP endpoint.
- Kafka `email-send-topic` consumer processes batch email sends → after all sends complete, batch-inserts `EmailSend` records into the primary PostgreSQL database.
- `AudienceService` receives patch requests → writes audience membership to primary Redis and PostgreSQL atomically.
