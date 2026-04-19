---
service: "regla"
title: "Rule Evaluation Query"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "rule-evaluation-query"
flow_type: synchronous
trigger: "Downstream service issues a synchronous rule evaluation query to check a user's purchase history"
participants:
  - "reglaService"
  - "reglaRedisCache"
  - "reglaPostgresDb"
architecture_ref: "dynamic-containers-regla"
---

# Rule Evaluation Query

## Summary

This flow covers the synchronous rule evaluation query path, where a downstream service (e.g., inbox management orchestration) asks regla whether a specific user satisfies a purchase-based rule condition. The two evaluation endpoints are `GET /userHasDealPurchaseSince` (has the user purchased a specific deal since a given timestamp?) and `GET /userHasAnyPurchaseEver` (has the user ever made any purchase?). regla answers these queries by checking `reglaRedisCache` first for low-latency responses, falling back to `reglaPostgresDb` on a cache miss. This path is latency-sensitive and is the primary synchronous query surface of the service.

## Trigger

- **Type**: api-call
- **Source**: Downstream service (inbox management orchestration, campaign decision layer) calls a rule evaluation endpoint
- **Frequency**: Per-request; high-frequency during campaign evaluation windows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Downstream Service (Inbox Mgmt / Campaign) | Sends evaluation query; acts on result | — |
| regla Service | Accepts query; checks Redis cache; falls back to PostgreSQL; returns boolean result | `reglaService` |
| regla Redis Cache | Provides low-latency purchase history lookup (TTL 403200s) | `reglaRedisCache` |
| regla PostgreSQL | Authoritative purchase history store; used on cache miss | `reglaPostgresDb` |

## Steps

### `GET /userHasDealPurchaseSince`

1. **Downstream service queries regla**: Caller sends `GET /userHasDealPurchaseSince?userId=<id>&dealId=<id>&since=<timestamp>` with API key.
   - From: Downstream Service
   - To: `reglaService`
   - Protocol: REST/HTTP GET, API key auth

2. **reglaService constructs cache key and queries Redis**: Service builds a cache key from `userId + dealId` and queries `reglaRedisCache` for a cached purchase record.
   - From: `reglaService`
   - To: `reglaRedisCache`
   - Protocol: Redis GET (jedis 2.8.0)

3a. **Cache hit path**: Redis returns a cached purchase record; service evaluates the `purchased_at` timestamp against the `since` parameter.
   - From: `reglaRedisCache`
   - To: `reglaService`
   - Protocol: Redis response

3b. **Cache miss path**: Redis returns nil; service queries `reglaPostgresDb` for the purchase record.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC SELECT from `purchases` WHERE `user_id = ? AND deal_id = ?`

4. **reglaService evaluates condition and returns result**: Service compares `purchased_at` against `since` and returns `{result: true|false}`.
   - From: `reglaService`
   - To: Downstream Service
   - Protocol: REST/HTTP JSON

### `GET /userHasAnyPurchaseEver`

5. **Downstream service queries any-purchase check**: Caller sends `GET /userHasAnyPurchaseEver?userId=<id>` with API key.
   - From: Downstream Service
   - To: `reglaService`
   - Protocol: REST/HTTP GET, API key auth

6. **reglaService queries Redis for user purchase presence**: Checks cache for any purchase record keyed by `userId`.
   - From: `reglaService`
   - To: `reglaRedisCache`
   - Protocol: Redis GET

7. **Falls back to PostgreSQL on cache miss**: If not in Redis, queries `purchases` table: `SELECT 1 FROM purchases WHERE user_id = ? LIMIT 1`.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC SELECT

8. **Returns boolean result**: Service returns `{result: true|false}` to caller.
   - From: `reglaService`
   - To: Downstream Service
   - Protocol: REST/HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | `reglaService` falls back to PostgreSQL; latency increases | Evaluation succeeds but slower; Redis cache miss logged |
| PostgreSQL unavailable (on cache miss) | `reglaService` returns 500 | Downstream caller receives error; must handle with fallback or retry |
| Missing query parameters | `reglaService` returns 400 | Caller receives parameter validation error |
| User not found in purchase history | PostgreSQL returns empty result set | `{result: false}` returned |
| Redis TTL expired (403200s since last write) | Cache miss; PostgreSQL fallback | Correct result returned; slightly higher latency |

## Sequence Diagram

```
DownstreamService -> reglaService: GET /userHasDealPurchaseSince?userId=X&dealId=Y&since=T
reglaService -> reglaRedisCache: GET purchase:X:Y
alt Cache hit
  reglaRedisCache --> reglaService: purchase record
else Cache miss
  reglaRedisCache --> reglaService: nil
  reglaService -> reglaPostgresDb: SELECT purchased_at FROM purchases WHERE user_id=X AND deal_id=Y
  reglaPostgresDb --> reglaService: purchase record or empty
end
reglaService --> DownstreamService: {result: true|false}
```

## Related

- Related flows: [Stream Processing](stream-processing.md), [Category Taxonomy Resolution](category-taxonomy-resolution.md)
