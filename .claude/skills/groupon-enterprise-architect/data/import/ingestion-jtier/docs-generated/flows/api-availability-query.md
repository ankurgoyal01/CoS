---
service: "ingestion-jtier"
title: "API Availability Query"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "api-availability-query"
flow_type: synchronous
trigger: "Caller issues GET /partner/v1/feed/availability or GET /partner/v1/stats/availabilitySegment"
participants:
  - "continuumIngestionJtierService"
  - "continuumIngestionJtierPostgres"
  - "continuumIngestionJtierRedis"
architecture_ref: "dynamic-ingestion-jtier-availability-query"
---

# API Availability Query

## Summary

The API availability query flow provides read-only access to current partner feed availability status and availability segment statistics. Callers (internal tooling, monitoring systems, or operations dashboards) query these endpoints to inspect the current state of partner feeds and deal availability segments without triggering any processing. Responses are served from PostgreSQL, potentially with Redis caching for hot queries.

## Trigger

- **Type**: api-call
- **Source**: Internal tooling, monitoring systems, operations dashboards, or other services querying partner availability state
- **Frequency**: On-demand; potentially frequent polling by monitoring tooling

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion JTier Service | Receives query, fetches data from store, returns response | `continuumIngestionJtierService` |
| Ingestion PostgreSQL | Primary source of availability and partner feed state data | `continuumIngestionJtierPostgres` |
| Ingestion Redis | Cache layer for frequently queried availability data | `continuumIngestionJtierRedis` |

## Steps

### Feed Availability Query — `GET /partner/v1/feed/availability`

1. **Receive availability query**: `ingestionApiResources` receives GET request with partner ID query parameter.
   - From: API caller
   - To: `continuumIngestionJtierService`
   - Protocol: HTTP/REST

2. **Check Redis cache**: `ingestionCache` checks for a cached availability response for the partner.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis (GET)

3. **Query PostgreSQL (on cache miss)**: `ingestionPersistence` reads the partner's latest availability records and ingestion run status from PostgreSQL.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

4. **Populate cache**: `ingestionCache` writes the query result to Redis for subsequent requests.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis (SET with TTL)

5. **Return availability response**: `ingestionApiResources` returns the availability status for the partner (feed availability windows, last sync time, status).
   - From: `continuumIngestionJtierService`
   - To: API caller
   - Protocol: HTTP/REST

### Availability Segment Statistics — `GET /partner/v1/stats/availabilitySegment`

1. **Receive stats query**: `ingestionApiResources` receives GET request with partner ID.
   - From: API caller
   - To: `continuumIngestionJtierService`
   - Protocol: HTTP/REST

2. **Query PostgreSQL for segment stats**: `ingestionPersistence` aggregates availability records from the `availability` table, grouping by segment (time window, capacity bucket, etc.).
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

3. **Return segment statistics**: `ingestionApiResources` returns the aggregated segment statistics payload.
   - From: `continuumIngestionJtierService`
   - To: API caller
   - Protocol: HTTP/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner ID not found | Return 404 to caller | No data returned |
| PostgreSQL read error | Return 503 to caller | Query fails; caller may retry |
| Redis unavailable | Fall through to PostgreSQL | Query served from database; no caching |

## Sequence Diagram

```
apiCaller -> ingestionApiResources: GET /partner/v1/feed/availability?partnerId=X
ingestionApiResources -> continuumIngestionJtierRedis: check cache for partnerId=X
continuumIngestionJtierRedis --> ingestionApiResources: cache miss
ingestionApiResources -> continuumIngestionJtierPostgres: query availability for partnerId=X
continuumIngestionJtierPostgres --> ingestionApiResources: availability records
ingestionApiResources -> continuumIngestionJtierRedis: set cache (with TTL)
ingestionApiResources --> apiCaller: 200 OK { availability data }
```

## Related

- Architecture dynamic view: `dynamic-ingestion-jtier-availability-query`
- Related flows: [Availability Synchronization](availability-synchronization.md)
