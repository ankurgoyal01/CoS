---
service: "janus-web-cloud"
title: "Metadata Management Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "metadata-management"
flow_type: synchronous
trigger: "REST API calls to /events/*, /attributes/*, /contexts/*, /annotations/*, /destinations/*, /avro/*, /promote/*, and /janus/api/v1/alert/*"
participants:
  - "jwc_apiResources"
  - "jwc_domainServices"
  - "jwc_mysqlDaos"
  - "janusOperationalSchema"
  - "janusSchemaRegistry"
architecture_ref: "components-janus-web-cloud-component-view"
---

# Metadata Management Flow

## Summary

The Metadata Management flow covers all CRUD operations for the core Janus metadata entities — sources, events, attributes, contexts, annotations, destinations, alert definitions, and Avro schema registry entries. Each operation follows a consistent request/response pattern: API Resources receives the HTTP request, delegates to Domain Services for validation and business logic, and routes persistence operations through the MySQL DAO layer to `continuumJanusMetadataMySql`. The flow also handles schema promotion operations (`/promote/*`) that propagate validated metadata configurations to a target environment.

## Trigger

- **Type**: api-call
- **Source**: Operator tooling, internal dashboards, or Continuum platform services calling any metadata or schema registry endpoint
- **Frequency**: Per request (on demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives HTTP request; validates HTTP contract; routes to Domain Services | `jwc_apiResources` |
| Domain Services | Applies Janus domain validation, mapping logic, and business rules | `jwc_domainServices` |
| MySQL DAOs | Executes JDBI read/write operations against the appropriate schema tables | `jwc_mysqlDaos` |
| Janus Operational Schema | Stores sources, events, attributes, contexts, annotations, destinations, users, permissions, and alert metadata | `janusOperationalSchema` |
| Janus Schema Registry | Stores Avro schema definitions and version records | `janusSchemaRegistry` |

## Steps

### Read (GET) path

1. **Receive list or get request**: API Resources receives `GET /{resource}/` or `GET /{resource}/{id}` and authenticates the caller.
   - From: External caller
   - To: `jwc_apiResources`
   - Protocol: REST / HTTP

2. **Invoke domain read logic**: API Resources delegates to Domain Services, which applies any filtering, enrichment, or timeline logic.
   - From: `jwc_apiResources`
   - To: `jwc_domainServices`
   - Protocol: Direct (in-process)

3. **Query MySQL**: MySQL DAOs execute a SELECT against `janusOperationalSchema` (or `janusSchemaRegistry` for `/avro/*` requests) and return the entity or list.
   - From: `jwc_domainServices`
   - To: `jwc_mysqlDaos` -> `janusOperationalSchema` / `janusSchemaRegistry`
   - Protocol: Direct / JDBC

4. **Return response**: API Resources serialises the entity to JSON and returns `200 OK`.
   - From: `jwc_apiResources`
   - To: External caller
   - Protocol: REST / HTTP

### Create (POST) path

1. **Receive create request**: API Resources receives `POST /{resource}/` with a JSON body.
   - From: External caller
   - To: `jwc_apiResources`
   - Protocol: REST / HTTP

2. **Validate and apply domain logic**: Domain Services validates the payload (required fields, referential integrity with related entities), applies any default values, and prepares the entity for persistence.
   - From: `jwc_apiResources`
   - To: `jwc_domainServices`
   - Protocol: Direct (in-process)

3. **Persist entity**: MySQL DAOs execute an INSERT into the appropriate table in `janusOperationalSchema` or `janusSchemaRegistry`.
   - From: `jwc_domainServices`
   - To: `jwc_mysqlDaos` -> `janusOperationalSchema` / `janusSchemaRegistry`
   - Protocol: Direct / JDBC

4. **Return created entity**: API Resources returns `201 Created` with the persisted entity including its generated ID.
   - From: `jwc_apiResources`
   - To: External caller
   - Protocol: REST / HTTP

### Update (PUT) path

1. **Receive update request**: API Resources receives `PUT /{resource}/{id}` with updated JSON body.
2. **Validate and apply domain logic**: Domain Services validates the update, checks entity existence, and applies business rules.
3. **Update entity in MySQL**: MySQL DAOs execute an UPDATE against `janusOperationalSchema` or `janusSchemaRegistry`.
4. **Return updated entity**: API Resources returns `200 OK` with the updated entity.

### Delete (DELETE) path

1. **Receive delete request**: API Resources receives `DELETE /{resource}/{id}`.
2. **Validate deletion eligibility**: Domain Services checks whether the entity can be deleted (e.g., not referenced by active events or replay jobs).
3. **Delete from MySQL**: MySQL DAOs execute a DELETE or soft-delete against `janusOperationalSchema`.
4. **Return confirmation**: API Resources returns `200 OK` or `204 No Content`.

### Promote path

1. **Receive promote request**: API Resources receives `POST /promote/` with a promotion specification (source environment, target, entity set).
2. **Validate and prepare promotion**: Domain Services validates source metadata completeness and target compatibility.
3. **Read source entities**: MySQL DAOs read the full entity set from `janusOperationalSchema`.
4. **Write to target**: Domain Services writes entities to the target environment's schema (may involve a separate target MySQL schema or API call).
5. **Return promotion result**: API Resources returns `200 OK` with promotion outcome.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (missing required field) | Domain Services raises validation exception | `400 Bad Request` returned with field-level error details |
| Entity not found | MySQL DAOs return empty result | `404 Not Found` returned |
| Referential integrity violation | Domain Services or MySQL raises constraint exception | `409 Conflict` or `400 Bad Request` returned |
| MySQL write failure | JDBI exception propagated | `500 Internal Server Error` returned; operation rolled back |
| Avro schema incompatibility | Domain Services validates schema on registration | `400 Bad Request` returned with schema compatibility error |

## Sequence Diagram

```
Caller -> jwc_apiResources: POST /events/ (new event definition JSON)
jwc_apiResources -> jwc_domainServices: Validate and apply domain logic
jwc_domainServices -> jwc_mysqlDaos: Persist new event entity
jwc_mysqlDaos -> janusOperationalSchema: INSERT INTO events
janusOperationalSchema --> jwc_mysqlDaos: Generated event_id
jwc_mysqlDaos --> jwc_domainServices: Persisted entity
jwc_domainServices --> jwc_apiResources: Domain entity
jwc_apiResources --> Caller: 201 Created (event JSON)
```

## Related

- Architecture dynamic view: `components-janus-web-cloud-component-view`
- Related flows: [Alert Notification](alert-notification.md) (uses alert definitions managed here), [Replay Orchestration](replay-orchestration.md) (uses source and event definitions managed here)
- See [API Surface](../api-surface.md) for full endpoint listing
- See [Data Stores](../data-stores.md) for `janusOperationalSchema` and `janusSchemaRegistry` table details
