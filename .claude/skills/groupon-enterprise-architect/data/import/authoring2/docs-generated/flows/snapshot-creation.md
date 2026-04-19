---
service: "authoring2"
title: "Snapshot Creation"
generated: "2026-03-03"
type: flow
flow_name: "snapshot-creation"
flow_type: asynchronous
trigger: "User triggers snapshot creation via POST /snapshots/create"
participants:
  - "authoring2RestApi"
  - "continuumAuthoring2Queue"
  - "authoring2QueueConsumer"
  - "authoring2TaxonomyService"
  - "continuumAuthoring2Postgres"
architecture_ref: "components-continuum-authoring2-authoring2TaxonomyService"
---

# Snapshot Creation

## Summary

A taxonomy content author initiates a full taxonomy snapshot — a point-in-time XML serialization of the entire taxonomy content. The `SnapshotRESTFacade` verifies no other snapshot is in progress, creates a new `Snapshots` row in PostgreSQL with status `PENDING`, publishes a JMS `SNAPSHOT` operation message to the `Authoring2` queue, and returns immediately. The `BulkQueueListener` picks up the message asynchronously, generates the full XML snapshot content by querying all taxonomy data, and stores it in the `Snapshots.content` column. The snapshot can then be deployed to the TaxonomyV2 live tier.

## Trigger

- **Type**: api-call (user-action via browser)
- **Source**: Ember.js authoring UI — content authors initiate snapshots approximately every three weeks for production taxonomy deployments
- **Frequency**: On demand; typically pre-production deployment cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ember.js UI | Initiates snapshot creation with an optional comment | — |
| REST Facades (`SnapshotRESTFacade`) | Guards against concurrent snapshots; creates DB record; enqueues job | `authoring2RestApi` |
| Authoring2 Bulk Queue | Transports the snapshot generation message | `continuumAuthoring2Queue` |
| Bulk Queue Listener | Generates snapshot XML and updates DB record | `authoring2QueueConsumer` |
| Taxonomy Domain Services | Reads full taxonomy data for snapshot generation | `authoring2TaxonomyService` |
| Authoring2 PostgreSQL | Stores `Snapshots` record with XML content | `continuumAuthoring2Postgres` |

## Steps

1. **Receives snapshot request**: Ember.js UI sends `POST /snapshots/create` with optional JSON body containing `comment`.
   - From: Ember.js UI
   - To: `SnapshotRESTFacade`
   - Protocol: REST / HTTP POST

2. **Checks for existing PENDING snapshot**: Queries all snapshots; if any has `status = PENDING`, rejects the request.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

3. **Creates Snapshots record**: Inserts a new `Snapshots` row with the comment, status `PENDING`, and a generated UUID.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

4. **Publishes SNAPSHOT JMS message**: Serializes `SnapshotQueue` (containing `id`) and sends as a JMS `TextMessage` with `OPERATION_TYPE = SNAPSHOT` to queue `Authoring2`.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Queue`
   - Protocol: JMS (ActiveMQ TCP `localhost:61616`)

5. **Returns snapshot record**: Responds with the created `Snapshots` entity (including `id` and `status = PENDING`).
   - From: `SnapshotRESTFacade`
   - To: Ember.js UI
   - Protocol: REST / HTTP 200 JSON

6. **Consumer picks up SNAPSHOT message**: `BulkQueueListener` receives the JMS message and dispatches to the snapshot generation handler.
   - From: `continuumAuthoring2Queue`
   - To: `authoring2QueueConsumer`
   - Protocol: JMS consumer

7. **Generates XML snapshot content**: Queries all taxonomy, category, relationship, and attribute data from PostgreSQL; serializes the full content into XML format.
   - From: `authoring2QueueConsumer`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC (multiple queries)

8. **Persists snapshot content**: Updates the `Snapshots` row with the generated XML `content` and sets `status` to the next state (no longer `PENDING`).
   - From: `authoring2QueueConsumer`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

9. **Caller polls status**: Client calls `GET /snapshots/all` or `GET /snapshots/{id}` to check when the snapshot is no longer `PENDING`.
   - From: Ember.js UI
   - To: `SnapshotRESTFacade` → `continuumAuthoring2Postgres`
   - Protocol: REST / HTTP GET

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Snapshot already PENDING | Request rejected before enqueueing | HTTP 400 "There is a snapshot being generated, please wait!" |
| JMS connection failure | Exception propagated | HTTP error; snapshot record created but never processed |
| Snapshot generation failure (queue consumer) | Consumer error; status remains PENDING or set to error state | Snapshot stuck; manual DB update required to unblock |
| Content validation failure | Call `GET /snapshots/validate/{uuid}` to check rule violations | Returns list of `ErrorList` items; user must fix content before deploying |

## Sequence Diagram

```
Ember.js UI -> SnapshotRESTFacade: POST /snapshots/create {comment}
SnapshotRESTFacade -> PostgreSQL: SELECT snapshots WHERE status = 'PENDING'
PostgreSQL --> SnapshotRESTFacade: (empty — no pending snapshot)
SnapshotRESTFacade -> PostgreSQL: INSERT INTO snapshots (guid, comment, status='PENDING')
PostgreSQL --> SnapshotRESTFacade: snapshot.id
SnapshotRESTFacade -> ActiveMQ: send TextMessage (OPERATION_TYPE=SNAPSHOT, id=<snapshot.id>)
SnapshotRESTFacade --> Ember.js UI: HTTP 200 (snapshot entity, status=PENDING)
ActiveMQ -> BulkQueueListener: deliver TextMessage
BulkQueueListener -> PostgreSQL: SELECT all taxonomies, categories, relationships, attributes
PostgreSQL --> BulkQueueListener: full taxonomy dataset
BulkQueueListener -> PostgreSQL: UPDATE snapshots SET content=<xml>, status=<done>
Ember.js UI -> SnapshotRESTFacade: GET /snapshots/{id}
SnapshotRESTFacade -> PostgreSQL: SELECT snapshots WHERE id = ?
PostgreSQL --> SnapshotRESTFacade: snapshot (status no longer PENDING)
SnapshotRESTFacade --> Ember.js UI: HTTP 200 (snapshot status)
```

## Related

- Architecture dynamic view: `components-continuum-authoring2-authoring2TaxonomyService`
- Related flows: [Snapshot Deploy to Live](snapshot-deploy-live.md), [Partial Snapshot Creation](partial-snapshot-creation.md)
