---
service: "authoring2"
title: "Bulk Taxonomy Import"
generated: "2026-03-03"
type: flow
flow_name: "bulk-taxonomy-import"
flow_type: asynchronous
trigger: "User submits a bulk CSV/JSON payload to a /bulk/* endpoint"
participants:
  - "authoring2RestApi"
  - "authoring2BulkIngress"
  - "continuumAuthoring2Queue"
  - "authoring2QueueConsumer"
  - "authoring2TaxonomyService"
  - "continuumAuthoring2Postgres"
architecture_ref: "components-continuum-authoring2-authoring2TaxonomyService"
---

# Bulk Taxonomy Import

## Summary

A content author submits a large batch of taxonomy changes (attribute updates, category creations, category/header updates, translation changes, or relationship updates) as a structured payload to one of the `/bulk/*` endpoints. The REST facade creates a tracking record in PostgreSQL, publishes a JMS message to the `Authoring2` ActiveMQ queue, and immediately returns a GUID to the caller. The `BulkQueueListener` picks up the message asynchronously and applies the changes row-by-row, updating the `Bulk` progress record in PostgreSQL. The caller polls `GET /bulk/{guid}` to monitor progress.

## Trigger

- **Type**: api-call (user-action via browser)
- **Source**: Ember.js authoring UI; bulk data originated from CSV/XLS file uploaded by the content author
- **Frequency**: On demand; typically during bulk taxonomy restructuring events

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ember.js UI | Initiates bulk operation with parsed CSV data | — |
| REST Facades (`BulkRESTFacade`) | Validates, records, and enqueues the bulk job | `authoring2RestApi` |
| Bulk Job Producer | Publishes JMS message to ActiveMQ | `authoring2BulkIngress` |
| Authoring2 Bulk Queue | Transports the job message to the consumer | `continuumAuthoring2Queue` |
| Bulk Queue Listener | Consumes message and executes mutations | `authoring2QueueConsumer` |
| Taxonomy Domain Services | Applies individual CRUD operations during processing | `authoring2TaxonomyService` |
| Authoring2 PostgreSQL | Stores `Bulk` tracking record and receives mutations | `continuumAuthoring2Postgres` |

## Steps

1. **Receives bulk payload**: Ember.js UI sends `POST /bulk/<operation>` with JSON payload (2D array of CSV rows or translation map).
   - From: Ember.js UI
   - To: `BulkRESTFacade`
   - Protocol: REST / HTTP POST JSON

2. **Checks for in-progress jobs**: Queries PostgreSQL for any existing `Bulk` record with `percent != 100`. Rejects if found (only one bulk job at a time).
   - From: `BulkRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

3. **Checks for duplicate submission**: Computes hashcode of the payload and checks for an existing record with the same hashcode and operation type. Rejects duplicates.
   - From: `BulkRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

4. **Creates Bulk tracking record**: Inserts a `Bulk` row with `percent = 0`, `linesOk = 0`, `linesError = 0`, and the full JSON payload.
   - From: `BulkRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

5. **Publishes JMS message**: Creates a JMS `TextMessage` with `OPERATION_TYPE` property set to the operation type (e.g., `UPDATE_ATTRIBUTE_BULK`) and the serialized `BulkCSV` GUID as the message body. Sends to queue `Authoring2` on `tcp://localhost:61616`.
   - From: `authoring2BulkIngress`
   - To: `continuumAuthoring2Queue`
   - Protocol: JMS (ActiveMQ)

6. **Returns job GUID**: REST facade responds immediately with `{"guid": "<uuid>"}`.
   - From: `BulkRESTFacade`
   - To: Ember.js UI
   - Protocol: REST / HTTP 200 JSON

7. **Consumer picks up message**: `BulkQueueListener` receives the JMS message from the `Authoring2` queue and dispatches to the appropriate handler based on `OPERATION_TYPE`.
   - From: `continuumAuthoring2Queue`
   - To: `authoring2QueueConsumer`
   - Protocol: JMS consumer

8. **Applies mutations row-by-row**: Processes each CSV row, calling the appropriate JPA controller (`CategoriesJpaController`, `AttributesJpaController`, etc.) to apply the mutation. Updates `linesOk` / `linesError` as each row is processed.
   - From: `authoring2QueueConsumer`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

9. **Updates progress**: When all rows are processed, sets `percent = 100` and writes the result JSON (list of errors) to the `Bulk` record.
   - From: `authoring2QueueConsumer`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

10. **Caller polls status**: Client calls `GET /bulk/{guid}` to check progress. Returns `percent`, `linesTotal`, `linesOk`, `linesError`, and any row-level errors.
    - From: Ember.js UI
    - To: `BulkRESTFacade` → `continuumAuthoring2Postgres`
    - Protocol: REST / HTTP GET

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Another bulk job in progress | Request rejected immediately | HTTP 400 "There is a batch in progress, please wait!" |
| Duplicate payload hashcode | Request rejected | HTTP 400 with duplicate error message |
| JMS connection failure | JMSException propagated | HTTP 400 with error message; `Bulk` record persisted but never processed |
| Individual row error during processing | Error recorded in `Bulk.result`; processing continues for remaining rows | `linesError` incremented; errors returned in `GET /bulk/{guid}` response |
| Pod crash mid-processing | `Bulk` record stuck at intermediate `percent`; message may be redelivered by JMS | Risk of partial application; no explicit compensation logic |

## Sequence Diagram

```
Ember.js UI -> BulkRESTFacade: POST /bulk/edit-attributes (CSV data)
BulkRESTFacade -> PostgreSQL: SELECT bulk WHERE percent != 100
PostgreSQL --> BulkRESTFacade: (empty — no in-progress job)
BulkRESTFacade -> PostgreSQL: INSERT INTO bulk (guid, json, percent=0, ...)
BulkRESTFacade -> ActiveMQ: send TextMessage (OPERATION_TYPE=UPDATE_ATTRIBUTE_BULK, guid)
BulkRESTFacade --> Ember.js UI: HTTP 200 {"guid": "<uuid>"}
ActiveMQ -> BulkQueueListener: deliver TextMessage
BulkQueueListener -> PostgreSQL: (iterative) UPDATE categories, attributes, ...
BulkQueueListener -> PostgreSQL: UPDATE bulk SET percent=100, result=...
Ember.js UI -> BulkRESTFacade: GET /bulk/<uuid> (polling)
BulkRESTFacade -> PostgreSQL: SELECT bulk WHERE guid = ?
PostgreSQL --> BulkRESTFacade: bulk record with results
BulkRESTFacade --> Ember.js UI: HTTP 200 (BulkBO with progress and errors)
```

## Related

- Architecture dynamic view: `components-continuum-authoring2-authoring2TaxonomyService`
- Related flows: [Category Edit](category-edit.md), [Snapshot Creation](snapshot-creation.md)
