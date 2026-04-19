---
service: "cs-token"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "csTokenRedis"
    type: "redis"
    purpose: "Short-lived token payload cache"
---

# Data Stores

## Overview

CS Token Service is effectively stateless beyond its Redis cache. There is no relational database. All token state is held in a single Redis instance (`csTokenRedis`) under TTL-based keys. When a key expires, the token is invalidated automatically.

## Stores

### Token Redis Cache (`csTokenRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `csTokenRedis` |
| Purpose | Cache token payloads; key is the (optionally encrypted) token string |
| Ownership | external (managed infrastructure) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Token payload key | Stores token metadata indexed by encrypted token | `method`, `accountId`, `email`, `csAgentId`, `csAgentEmail`, `tokenExpiration` |

Redis key format: the raw `SecureRandom.hex(32)` token string, or its AES-256-GCM / Base64url-encoded form when `token_encryption_enabled` is `true`.

Redis value format: JSON string containing:
```json
{
  "method": "<method_name_or_array>",
  "accountId": "<consumer_id>",
  "email": "<customer_email>",
  "csAgentId": "<agent_id>",
  "csAgentEmail": "<agent_email>",
  "tokenExpiration": "<ISO8601 datetime>"
}
```

#### Access Patterns

- **Read**: On every `GET /verify_auth` call — `redis.get(encrypted_token)` to retrieve cached payload, then validate method, consumer ID, and expiration in-process.
- **Write**: On every `POST /token` call — `redis.setex(encrypted_token, ttl_seconds, json_payload)` atomically stores and sets TTL.
- **Indexes**: Redis keys only; no secondary indexes. Lookup is always by the exact token string.

#### Per-environment Redis Hosts

| Environment | Host | SSL |
|-------------|------|-----|
| Development | `localhost:6379` | No |
| Staging (US) | `custsvc-tokenizer.us-central1.caches.stable.gcp.groupondev.com:6379` | No |
| Production (US) | `custsvc-tokenizer-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379` | Yes |
| Production (EU) | `custsvc-tokenizer--redis.prod:6379` | Yes |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `csTokenRedis` | Redis | Primary token payload store | Per-method configurable; default 5 minutes; test tokens: 30 days |

Per-method TTL configuration (production-us-central1):

| Method | TTL |
|--------|-----|
| Default | 5 minutes |
| `voucher_archive` | 10 minutes |
| `get_order` | 5 minutes |
| `issue_refund` | 15 minutes |
| `issue_bucks` | 15 minutes |

## Data Flows

Token data flows only through in-request paths:

1. **Token creation**: `POST /token` request → `TokensHelper#create_auth_token_info` → `redis.setex(key, ttl, json)` — payload written to Redis.
2. **Token verification**: `GET /verify_auth` request → `TokensHelper#get_auth_token_info` → `redis.get(key)` — payload read from Redis, validated in memory, then discarded.
3. **Token expiry**: Redis TTL expires the key automatically — no explicit deletion required.

There is no CDC, ETL, or replication between data stores.
