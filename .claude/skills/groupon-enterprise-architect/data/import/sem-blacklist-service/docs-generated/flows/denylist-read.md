---
service: "sem-blacklist-service"
title: "Denylist Entry Read"
generated: "2026-03-03"
type: flow
flow_name: "denylist-read"
flow_type: synchronous
trigger: "HTTP GET request to /denylist or /blacklist"
participants:
  - "continuumSemBlacklistService"
  - "continuumSemBlacklistPostgres"
architecture_ref: "components-sem-blacklist-components"
---

# Denylist Entry Read

## Summary

A consumer (internal SEM tool or bidding system) sends a GET request to the service to retrieve denylist entries matching specified filter criteria. The service queries the `sem_raw_blacklist` PostgreSQL table, applies all requested filters, and returns the results as a JSON object or flat JSON array of terms. This is the primary read path used by downstream SEM systems to determine which entities to suppress from campaigns.

## Trigger

- **Type**: api-call
- **Source**: Internal SEM consumer (bidding system, keyword management tool, or SEM operations tooling)
- **Frequency**: On demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEM Consumer | Initiates the HTTP GET request | (external caller) |
| REST Resources (`apiResources_SemBla`) | Receives request, validates required params, delegates to DAO | `continuumSemBlacklistService` |
| RawBlacklistDAO (`blacklistDao`) | Executes filtered SQL query against the denylist table | `continuumSemBlacklistService` |
| SEM Blacklist Postgres | Stores and returns denylist rows | `continuumSemBlacklistPostgres` |

## Steps

1. **Receives GET request**: Consumer sends `GET /denylist?client=<client>&country=<country>` (plus optional `program`, `channel`, `active`, `list`, `page`, `size`, `search_engine` params) or the equivalent `/blacklist` legacy path.
   - From: SEM Consumer
   - To: `continuumSemBlacklistService` (JAX-RS `SemDenylistServiceResource` or `SemBlacklistServiceResource`)
   - Protocol: REST / HTTP

2. **Validates required parameters**: The JAX-RS resource validates that `client` and `country` are present (`@NotNull`). If absent, the JTier/Dropwizard framework returns a 400-series error.
   - From: `apiResources_SemBla`
   - To: `apiResources_SemBla`
   - Protocol: direct

3. **Selects DAO query variant**: Based on the presence of optional filter parameters (`program/channel`, `page/size`, multiple countries for batch), the resource selects the appropriate overloaded `RawBlacklistDAO.fetch()` method.
   - From: `apiResources_SemBla`
   - To: `blacklistDao`
   - Protocol: direct

4. **Executes SQL query against PostgreSQL**: The DAO issues a `SELECT * FROM sem_raw_blacklist WHERE client = :client AND country_code = :countryCode AND active = :active [AND entity_option_id = :programChannel] [OFFSET :page*:size LIMIT :size] ORDER BY create_at DESC`.
   - From: `blacklistDao`
   - To: `continuumSemBlacklistPostgres`
   - Protocol: JDBC / SQL

5. **Maps results to BlacklistEntity objects**: The `BlacklistMapper` maps each row to a `BlacklistEntity` instance.
   - From: `continuumSemBlacklistPostgres`
   - To: `blacklistDao`
   - Protocol: JDBC / SQL

6. **Returns JSON response**: If `list=true` was requested, returns only the entity ID strings as a flat JSON array; otherwise returns full `BlacklistEntity` objects. The HTTP response is `application/json`.
   - From: `apiResources_SemBla`
   - To: SEM Consumer
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required `client` or `country` param | JTier/JAX-RS validation rejection | HTTP 400 response |
| Database connection failure | JDBI propagates exception; JTier exception mapper handles it | HTTP 500 response |
| Empty result set | Returns empty JSON array or object | HTTP 200 with empty body |

## Sequence Diagram

```
Consumer -> SemDenylistServiceResource: GET /denylist?client=X&country=US&active=true
SemDenylistServiceResource -> RawBlacklistDAO: fetch(client, countryCode, active)
RawBlacklistDAO -> sem_raw_blacklist: SELECT * FROM sem_raw_blacklist WHERE ...
sem_raw_blacklist --> RawBlacklistDAO: Set<BlacklistEntity>
RawBlacklistDAO --> SemDenylistServiceResource: Set<BlacklistEntity>
SemDenylistServiceResource --> Consumer: HTTP 200 application/json
```

## Related

- Architecture dynamic view: `components-sem-blacklist-components`
- Related flows: [Denylist Entry Write](denylist-write.md), [Batch Denylist Read](denylist-batch-read.md)
