---
service: "sem-blacklist-service"
title: "Denylist Entry Write"
generated: "2026-03-03"
type: flow
flow_name: "denylist-write"
flow_type: synchronous
trigger: "HTTP POST or DELETE request to /denylist or /blacklist"
participants:
  - "continuumSemBlacklistService"
  - "continuumSemBlacklistPostgres"
architecture_ref: "components-sem-blacklist-components"
---

# Denylist Entry Write

## Summary

An operator or internal tool adds or removes a denylist entry by calling the REST API. On `POST`, the service inserts a new entry (or reactivates a previously soft-deleted entry) in the `sem_raw_blacklist` table. On `DELETE`, the service soft-deletes the entry by setting `active = FALSE` along with `deleted_by` and `deleted_at` audit fields. Both operations record the caller's identity via the `X-GRPN-Username` header. Batch writes (`POST /denylist/batch`) follow the same path for each entry in the submitted list.

## Trigger

- **Type**: api-call
- **Source**: SEM operations tooling, internal SEM management UI, or automated pipeline
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEM Operator / Tool | Initiates the HTTP write request | (external caller) |
| REST Resources (`apiResources_SemBla`) | Receives and validates request; extracts username header | `continuumSemBlacklistService` |
| RawBlacklistDAO (`blacklistDao`) | Executes insert or soft-delete SQL batches | `continuumSemBlacklistService` |
| SEM Blacklist Postgres | Persists the denylist change | `continuumSemBlacklistPostgres` |

## Steps

### Add Entry (POST)

1. **Receives POST request**: Caller sends `POST /denylist` with a JSON body containing `entityId`, `client`, `searchEngine`, `countryCode` (required) and optional `entityOptionId`, `brandMerchantId`, `brandBlacklistType`. The `X-GRPN-Username` header identifies the caller.
   - From: SEM Operator
   - To: `continuumSemBlacklistService`
   - Protocol: REST / HTTP

2. **Validates and builds BlacklistEntity**: The JAX-RS resource validates the request (`@NotNull @Valid`). `BlacklistApiRequest.buildEntity()` constructs a `BlacklistEntity` with `active = TRUE` and `createdBy` set to the username header value.
   - From: `apiResources_SemBla`
   - To: `apiResources_SemBla`
   - Protocol: direct

3. **Executes conditional insert**: `RawBlacklistDAO.insertAll()` calls `insertNew()` — a `SqlBatch` with a `WHERE NOT EXISTS` guard to prevent duplicate active entries — then `updatePrev()` to reactivate any matching inactive entry.
   - From: `blacklistDao`
   - To: `continuumSemBlacklistPostgres`
   - Protocol: JDBC / SQL

4. **Returns response**: The resource returns an HTTP 200 response confirming the operation.
   - From: `apiResources_SemBla`
   - To: SEM Operator
   - Protocol: REST / HTTP

### Remove Entry (DELETE)

1. **Receives DELETE request**: Caller sends `DELETE /denylist` with a JSON body identifying the entry to remove. The `X-GRPN-Username` header is required for audit.
   - From: SEM Operator
   - To: `continuumSemBlacklistService`
   - Protocol: REST / HTTP

2. **Validates and builds BlacklistEntity**: The resource builds a `BlacklistEntity` with `active = FALSE` and `deletedBy` set to the username header value.
   - From: `apiResources_SemBla`
   - To: `apiResources_SemBla`
   - Protocol: direct

3. **Executes soft-delete**: `RawBlacklistDAO.deletePrevious()` issues a `SqlBatch` `UPDATE sem_raw_blacklist SET active = FALSE, deleted_by = :user, deleted_at = :deleteTime WHERE entity_id = :entityId AND ...` matching on all key fields.
   - From: `blacklistDao`
   - To: `continuumSemBlacklistPostgres`
   - Protocol: JDBC / SQL

4. **Returns response**: HTTP 200 response confirming deletion.
   - From: `apiResources_SemBla`
   - To: SEM Operator
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required fields (`entityId`, `client`, `searchEngine`, `countryCode`) | JAX-RS `@NotNull @Valid` constraint | HTTP 400 validation error |
| Duplicate insert (entry already active) | `WHERE NOT EXISTS` guard silently skips insert; `updatePrev()` is a no-op | HTTP 200; no duplicate created |
| Database error during insert or delete | JDBI propagates exception; JTier exception mapper handles | HTTP 500 response |
| Unknown `brandBlacklistType` value | `convertBrandBlacklistType()` normalizes to `NON` | Entry stored with type `non` |

## Sequence Diagram

```
Operator -> SemDenylistServiceResource: POST /denylist {entityId, client, searchEngine, countryCode, ...}
SemDenylistServiceResource -> BlacklistApiRequest: buildEntity(user, CREATE)
BlacklistApiRequest --> SemDenylistServiceResource: BlacklistEntity (active=true)
SemDenylistServiceResource -> RawBlacklistDAO: insertAll({entity})
RawBlacklistDAO -> sem_raw_blacklist: INSERT ... WHERE NOT EXISTS (...)
RawBlacklistDAO -> sem_raw_blacklist: UPDATE ... SET active=TRUE WHERE ... AND active IS FALSE
sem_raw_blacklist --> RawBlacklistDAO: rows affected
RawBlacklistDAO --> SemDenylistServiceResource: done
SemDenylistServiceResource --> Operator: HTTP 200
```

## Related

- Architecture dynamic view: `components-sem-blacklist-components`
- Related flows: [Denylist Entry Read](denylist-read.md), [Asana Task Processing](asana-task-processing.md)
