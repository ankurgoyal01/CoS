---
service: "mds-feed-api"
title: "Feed Configuration Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "feed-configuration-lifecycle"
flow_type: synchronous
trigger: "API call — POST, PUT, PATCH, or DELETE on /feed endpoints"
participants:
  - "continuumMdsFeedApi"
  - "continuumMdsFeedApiPostgres"
architecture_ref: "dynamic-continuumMdsFeedApi"
---

# Feed Configuration Lifecycle

## Summary

This flow covers how feed configurations are created, updated, patched, promoted, and deleted via the REST API. A feed configuration defines all aspects of a deal feed: datasources (MDS deal data from GCS), transformers, filters, output fields, file format, upload destinations, and status. Only configurations with status `ACTIVE` are eligible for feed generation.

## Trigger

- **Type**: api-call
- **Source**: Operations teams or affiliate managers via REST client or UI
- **Frequency**: On-demand (whenever feed configurations need to be created or modified)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST Client (operator) | Initiates configuration CRUD operations | External |
| Feed API Resource Layer | Receives HTTP requests, validates, and delegates to service layer | `continuumMdsFeedApi` |
| Feed Orchestration Service | Executes business rules for configuration lifecycle | `continuumMdsFeedApi` |
| Persistence Gateway (JDBI DAOs) | Reads and writes feed records to PostgreSQL | `continuumMdsFeedApi` |
| MDS Feed API Postgres | Stores feed configuration records | `continuumMdsFeedApiPostgres` |

## Steps

### Create Feed Configuration

1. **Receives create request**: REST client POSTs a feed configuration JSON to `POST /feed`.
   - From: REST client
   - To: `Feed API Resource Layer` (`FeedResource`)
   - Protocol: REST/HTTP

2. **Validates and persists configuration**: `FeedOrchestrationService` validates the configuration structure and writes a new feed record with a generated `feedUuid`.
   - From: `Feed API Resource Layer`
   - To: `Persistence Gateway` → `continuumMdsFeedApiPostgres`
   - Protocol: JDBI/PostgreSQL

3. **Returns created configuration**: The new feed configuration (including `feedUuid`, `createdAt`, `updatedAt`) is returned to the caller.
   - From: `Feed API Resource Layer`
   - To: REST client
   - Protocol: REST/HTTP, `application/json`

### Update Feed Configuration (Full and Partial)

4. **Receives update request**: REST client sends `PUT /feed/{uuid}` (full update) or `PATCH /feed/{uuid}` (JSON Patch per RFC 6902).
   - From: REST client
   - To: `Feed API Resource Layer`
   - Protocol: REST/HTTP

5. **Applies changes**: Full update replaces the configuration; JSON Patch applies incremental operations (add, replace, remove) from the `json-patch` library.
   - From: `Feed API Resource Layer`
   - To: `Persistence Gateway` → `continuumMdsFeedApiPostgres`
   - Protocol: JDBI/PostgreSQL

6. **Returns updated configuration**: Updated feed record is returned.
   - From: `Feed API Resource Layer`
   - To: REST client
   - Protocol: REST/HTTP, `application/json`

### Promote Feed Configuration

7. **Receives promote request**: REST client sends `POST /feed/promote/{uuid}` to copy a configuration to a new or target feed.
   - From: REST client
   - To: `Feed API Resource Layer` → `FeedPromoterService`
   - Protocol: REST/HTTP

8. **Copies configuration**: `FeedPromoterService` reads source feed and writes a new feed record per `PromoteConfig` rules.
   - From: `FeedPromoterService`
   - To: `Persistence Gateway` → `continuumMdsFeedApiPostgres`
   - Protocol: JDBI/PostgreSQL

### Delete Feed Configuration

9. **Receives delete request**: REST client sends `DELETE /feed/{uuid}`.
   - From: REST client
   - To: `Feed API Resource Layer`
   - Protocol: REST/HTTP

10. **Marks feed as deleted**: Feed status is set to `DELETED` (soft delete).
    - From: `Feed API Resource Layer`
    - To: `Persistence Gateway` → `continuumMdsFeedApiPostgres`
    - Protocol: JDBI/PostgreSQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Feed UUID not found | `ResourceNotFoundException` mapped by `ResourceNotFoundExceptionMapper` | HTTP 404 with error message |
| Unauthorized request (missing client ID) | `ClientIdBundle` authentication check | HTTP 401 |
| Invalid JSON Patch document | `json-patch` library validation | HTTP 400 |
| Database write failure | Exception propagated by JDBI | HTTP 500 |

## Sequence Diagram

```
Client -> FeedResource: POST /feed (feed config JSON)
FeedResource -> FeedOrchestrationService: create(feedDto)
FeedOrchestrationService -> FeedsDao: insert(feedRecord)
FeedsDao -> PostgreSQL: INSERT INTO feeds
PostgreSQL --> FeedsDao: feedUuid
FeedsDao --> FeedOrchestrationService: feedDto (with UUID)
FeedOrchestrationService --> FeedResource: feedDto
FeedResource --> Client: 200 OK, feedDto JSON
```

## Related

- Architecture dynamic view: `dynamic-continuumMdsFeedApi`
- Related flows: [Scheduled Feed Generation](scheduled-feed-generation.md), [Manual Feed Generation](manual-feed-generation.md)
