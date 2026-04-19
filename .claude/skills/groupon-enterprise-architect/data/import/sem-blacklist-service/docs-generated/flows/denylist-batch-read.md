---
service: "sem-blacklist-service"
title: "Batch Denylist Read"
generated: "2026-03-03"
type: flow
flow_name: "denylist-batch-read"
flow_type: synchronous
trigger: "HTTP GET request to /denylist/batch, /blacklist/batch, or /denylist/{country}/{client}"
participants:
  - "continuumSemBlacklistService"
  - "continuumSemBlacklistPostgres"
architecture_ref: "components-sem-blacklist-components"
---

# Batch Denylist Read

## Summary

This flow covers two specialized read patterns that extend the basic denylist read. The batch-country read (`GET /denylist/batch`) allows consumers to fetch denylist entries for multiple countries in a single request using an SQL `IN` clause, reducing round-trips when checking multiple markets. The date-range read (`GET /denylist/{country}/{client}`) returns active denylist entries that were created within a specified time window, supporting change tracking and delta synchronization by downstream systems.

## Trigger

- **Type**: api-call
- **Source**: Internal SEM consumer requiring multi-country or date-range denylist data
- **Frequency**: On demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEM Consumer | Initiates the HTTP GET request | (external caller) |
| REST Resources (`apiResources_SemBla`) | Receives and validates the request; selects the appropriate DAO method | `continuumSemBlacklistService` |
| RawBlacklistDAO (`blacklistDao`) | Executes the multi-country IN query or date-range query | `continuumSemBlacklistService` |
| SEM Blacklist Postgres | Returns matching denylist rows | `continuumSemBlacklistPostgres` |

## Steps

### Multi-Country Batch Read

1. **Receives batch GET request**: Consumer sends `GET /denylist/batch?client=<client>&country=<country1>&country=<country2>&...` (plus optional filters). The `country` parameter is collected as a `List<String>`.
   - From: SEM Consumer
   - To: `continuumSemBlacklistService`
   - Protocol: REST / HTTP

2. **Delegates to batch DAO method**: The resource calls `RawBlacklistDAO.fetch(client, List<String> countryCode, active)` (with optional `programChannel`, `page`, `size` overloads).
   - From: `apiResources_SemBla`
   - To: `blacklistDao`
   - Protocol: direct

3. **Executes SQL with IN clause**: DAO issues `SELECT * FROM sem_raw_blacklist WHERE client = :client AND country_code IN (<countryCode>) AND active = :active [AND entity_option_id = :program_channel] [OFFSET :page*:size LIMIT :size] ORDER BY create_at DESC`. JDBI's `@BindIn` renders the country list into the SQL `IN` clause.
   - From: `blacklistDao`
   - To: `continuumSemBlacklistPostgres`
   - Protocol: JDBC / SQL

4. **Returns combined results**: All matching entries across all requested countries are returned as a JSON array in a single response.
   - From: `apiResources_SemBla`
   - To: SEM Consumer
   - Protocol: REST / HTTP

### Date-Range Read

1. **Receives date-range GET request**: Consumer sends `GET /denylist/{country}/{client}?start_at=<epochMs>&end_at=<epochMs>`. If `end_at` is omitted it defaults to now; if `start_at` is omitted it defaults to one day before `end_at`.
   - From: SEM Consumer
   - To: `continuumSemBlacklistService`
   - Protocol: REST / HTTP

2. **Resolves date defaults**: `SemDenylistServiceResource.fetchActiveDenylistWithinDate()` computes `startDate` and `endDate` from the query parameters and their defaults.
   - From: `apiResources_SemBla`
   - To: `apiResources_SemBla`
   - Protocol: direct

3. **Executes date-range SQL**: DAO issues `SELECT * FROM sem_raw_blacklist WHERE client = :client AND country_code = :countryCode AND active = :active AND create_at > :startAt AND create_at <= :endAt ORDER BY create_at DESC`.
   - From: `blacklistDao`
   - To: `continuumSemBlacklistPostgres`
   - Protocol: JDBC / SQL

4. **Returns filtered results**: Entries created within the requested time window are returned as a JSON array.
   - From: `apiResources_SemBla`
   - To: SEM Consumer
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required `client` or `country` param (batch) | JAX-RS `@NotNull` validation | HTTP 400 response |
| Empty `country` list | DAO `IN` clause with empty list — behavior depends on JDBI/DB; returns empty result set | HTTP 200 with empty body |
| Invalid epoch millisecond timestamps | JTier type coercion may reject; defaults are applied if params omitted | HTTP 400 or defaults applied |
| Database connection failure | JDBI propagates exception; JTier exception mapper handles | HTTP 500 response |

## Sequence Diagram

```
Consumer -> SemDenylistServiceResource: GET /denylist/batch?client=X&country=US&country=CA
SemDenylistServiceResource -> RawBlacklistDAO: fetch(client, [US, CA], active)
RawBlacklistDAO -> sem_raw_blacklist: SELECT * FROM sem_raw_blacklist WHERE client=X AND country_code IN (US, CA) AND active=...
sem_raw_blacklist --> RawBlacklistDAO: Set<BlacklistEntity>
RawBlacklistDAO --> SemDenylistServiceResource: Set<BlacklistEntity>
SemDenylistServiceResource --> Consumer: HTTP 200 application/json

Consumer -> SemDenylistServiceResource: GET /denylist/{country}/{client}?start_at=T1&end_at=T2
SemDenylistServiceResource -> SemDenylistServiceResource: resolve startDate/endDate (defaults applied)
SemDenylistServiceResource -> RawBlacklistDAO: fetch(client, country, startDate, endDate, active=true)
RawBlacklistDAO -> sem_raw_blacklist: SELECT * FROM sem_raw_blacklist WHERE ... AND create_at > T1 AND create_at <= T2
sem_raw_blacklist --> RawBlacklistDAO: Set<BlacklistEntity>
RawBlacklistDAO --> SemDenylistServiceResource: Set<BlacklistEntity>
SemDenylistServiceResource --> Consumer: HTTP 200 application/json
```

## Related

- Architecture dynamic view: `components-sem-blacklist-components`
- Related flows: [Denylist Entry Read](denylist-read.md), [Flows Index](index.md)
