---
service: "push-client-proxy"
title: "Audience Patch"
generated: "2026-03-03"
type: flow
flow_name: "audience-patch"
flow_type: synchronous
trigger: "PATCH /audiences/{audienceId} from Audience Management Service"
participants:
  - "continuumAudienceManagementService"
  - "continuumPushClientProxyService"
  - "continuumPushClientProxyRedisPrimary"
  - "continuumPushClientProxyRedisIncentive"
  - "continuumPushClientProxyPostgresMainDb"
  - "influxDb"
architecture_ref: "dynamic-audience-patch-flow"
---

# Audience Patch

## Summary

The internal Audience Management Service sends a `PATCH /audiences/{audienceId}` request containing a list of UUIDs and an operation (add or remove) to update campaign audience membership. push-client-proxy applies rate limiting, validates the request, and then writes the membership changes to both Redis clusters and the primary PostgreSQL database, returning updated audience counts.

## Trigger

- **Type**: api-call
- **Source**: `continuumAudienceManagementService`
- **Frequency**: Per-request (on-demand for each audience membership change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Audience Management Service | Caller — sends audience patch payload | `continuumAudienceManagementService` |
| push-client-proxy service | Orchestrator — validates, applies changes, returns counts | `continuumPushClientProxyService` |
| Primary Redis cache | State store — holds audience keys and counters | `continuumPushClientProxyRedisPrimary` |
| Incentive Redis cache | State store — holds incentive audience keys | `continuumPushClientProxyRedisIncentive` |
| Main PostgreSQL database | Persistence — stores audience entities | `continuumPushClientProxyPostgresMainDb` |
| InfluxDB | Observability — receives audience endpoint metrics | `influxDb` |

## Steps

1. **Receives audience patch request**: `AudienceController` receives `PATCH /audiences/{audienceId}` with an `AudiencePatchRequest` body containing a list of UUIDs (max 500) and the patch operation type.
   - From: `continuumAudienceManagementService`
   - To: `continuumPushClientProxyService` (`pcpAudienceApiController`)
   - Protocol: HTTPS

2. **Checks rate limit**: Calls `RateLimiterService.checkAudiencePatchRateLimit()` using the Redis-backed Bucket4j token bucket. If limit exceeded, returns `HTTP 429` with `X-Rate-Limit-Retry-After-Seconds` header.
   - From: `pcpAudienceApiController`
   - To: `continuumPushClientProxyRedisPrimary` (via `pcpRateLimiterService`)
   - Protocol: Redis

3. **Validates request**: Confirms `audienceId` is present in the path and that the UUID batch size does not exceed 500. Returns `HTTP 400` if validation fails.
   - From: `pcpAudienceApiController`
   - To: (internal validation)
   - Protocol: direct

4. **Applies audience patch**: Delegates to `AudienceService.patchAudience(request)` which calls `AudienceRedisUtil` to read and write audience membership keys and counters across both Redis clusters.
   - From: `pcpAudienceService`
   - To: `continuumPushClientProxyRedisPrimary` (via `pcpAudienceRedisUtil`)
   - Protocol: Redis

5. **Updates incentive audience keys**: `AudienceRedisUtil` also writes incentive treatment keys to the secondary Redis cluster.
   - From: `pcpAudienceService` (via `pcpAudienceRedisUtil`)
   - To: `continuumPushClientProxyRedisIncentive`
   - Protocol: Redis

6. **Persists audience state**: `AudienceService` saves the updated `Audience` entity via `AudienceRepository` to the main PostgreSQL database.
   - From: `pcpAudienceService` (via `pcpAudienceRepositoryComponent`)
   - To: `continuumPushClientProxyPostgresMainDb`
   - Protocol: JPA/JDBC

7. **Emits audience metrics**: `MetricsProvider` records `audience.patch.request.duration` (timer) and `audience.patch.request` (counter) with `status_code=2xx` and `endpoint=patch-audience` tags.
   - From: `pcpMetricsProvider`
   - To: `influxDb`
   - Protocol: HTTP

8. **Returns updated counts**: Returns `HTTP 200` with `AudienceCountResponse` JSON body and `X-Rate-Limit-Remaining` header.
   - From: `continuumPushClientProxyService`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rate limit exceeded | Return `HTTP 429` with retry-after header; emit `4xx` metric | Caller retries after delay |
| Missing audienceId in path | Return `HTTP 400`; emit `4xx` metric | Caller corrects request |
| Batch size exceeds 500 UUIDs | Return `HTTP 400` via `request.isValid()` check; emit `4xx` metric | Caller splits the batch |
| `IllegalArgumentException` from AudienceService | Return `HTTP 400`; emit `4xx` metric | Caller corrects request |
| Unexpected exception | Return `HTTP 500`; emit `5xx` metric | Caller retries |

## Sequence Diagram

```
AudienceManagementService -> AudienceController: PATCH /audiences/{audienceId} {AudiencePatchRequest}
AudienceController -> RateLimiterService: checkAudiencePatchRateLimit()
RateLimiterService -> PrimaryRedis: token bucket consume
PrimaryRedis --> RateLimiterService: allowed
RateLimiterService --> AudienceController: RateLimitResult
AudienceController -> AudienceService: patchAudience(request)
AudienceService -> AudienceRedisUtil: read/write audience keys
AudienceRedisUtil -> PrimaryRedis: HSET/INCR audience keys
AudienceRedisUtil -> IncentiveRedis: HSET/INCR incentive keys
AudienceService -> AudienceRepository: save(audience)
AudienceRepository -> PostgresMainDb: INSERT/UPDATE audience
PostgresMainDb --> AudienceRepository: saved entity
AudienceRepository --> AudienceService: AudienceCountResponse
AudienceService --> AudienceController: AudienceCountResponse
AudienceController -> MetricsProvider: timer + counter (2xx)
MetricsProvider -> InfluxDB: write metrics
AudienceController --> AudienceManagementService: 200 OK {AudienceCountResponse}
```

## Related

- Architecture dynamic view: `dynamic-audience-patch-flow`
- Related flows: [Async Email Send](async-email-send.md)
