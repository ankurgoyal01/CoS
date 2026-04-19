---
service: "place-service"
title: "Place Write / Create"
generated: "2026-03-03"
type: flow
flow_name: "place-write"
flow_type: synchronous
trigger: "HTTP POST or PUT to place write endpoint"
participants:
  - "placeSvc_apiControllers"
  - "placeSvc_writePipeline"
  - "placeSvc_indexGateway"
  - "placeSvc_postgresGateway"
  - "placeSvc_voltronGateway"
  - "continuumPlacesServicePostgres"
  - "continuumPlacesServiceOpenSearch"
architecture_ref: "dynamic-place-read-flow"
---

# Place Write / Create

## Summary

This flow handles creation and update of place records. The write pipeline validates and transforms the incoming `InputPlace` payload (from ICF format to M3 format using `place-transformer` and `place-translator` libraries), then invokes Voltron workflow tasks for write orchestration. On success, the Postgres record is persisted and the OpenSearch index document is updated. Merge and history operations are also served by this pipeline.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon systems with write permission (Merchant Center editor, Salesforce sync worker, Voltron workflows)
- **Frequency**: On-demand (triggered by merchant onboarding, data updates, Salesforce sync)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers (PlaceWriteController) | Receives HTTP POST/PUT, validates `client_id`, delegates to write pipeline | `placeSvc_apiControllers` |
| Place Write Pipeline | Transforms input, executes write/merge/history workflows | `placeSvc_writePipeline` |
| Voltron Gateway | Invokes Voltron workflow for place processing and history | `placeSvc_voltronGateway` |
| OpenSearch Gateway | Updates place index document after write | `placeSvc_indexGateway` |
| Postgres Gateway | Persists ICF place record | `placeSvc_postgresGateway` |
| Place Postgres | Primary place persistence store | `continuumPlacesServicePostgres` |
| Place OpenSearch | Search index store | `continuumPlacesServiceOpenSearch` |

## Steps

1. **Receive write request**: HTTP POST `/placewriteservice/v3.0/places` (create) or PUT `/placewriteservice/v3.0/places/{id}` (update) with `client_id` query parameter and `InputPlace` JSON body.
   - From: calling service (e.g., Merchant Center, Salesforce sync worker)
   - To: `placeSvc_apiControllers` (PlaceWriteController)
   - Protocol: REST/HTTP

2. **Validate client and input**: Controller validates `client_id` authorization and parses the request body. Assigns a UUID if creating a new place.
   - From: `placeSvc_apiControllers`
   - To: `placeSvc_writePipeline`
   - Protocol: direct

3. **Transform input payload**: Write pipeline applies ICF-to-M3 format transformation using `place-transformer` (version 3.13) and `place-translator` (version 2.0.8). Validates schema compliance using `merchantdata-schema-validation`.
   - From: `placeSvc_writePipeline`
   - To: internal transformation (local)
   - Protocol: direct

4. **Invoke Voltron workflow**: Write pipeline calls Voltron via `voltron-tasks` to execute the write workflow (includes business rules, history recording, and event emission within Voltron).
   - From: `placeSvc_writePipeline` → `placeSvc_voltronGateway`
   - To: Voltron Platform
   - Protocol: RPC/HTTP

5. **Persist to Postgres**: Voltron workflow (or direct write path) persists the canonical ICF place record to Postgres.
   - From: `placeSvc_postgresGateway`
   - To: `continuumPlacesServicePostgres`
   - Protocol: TCP/PostgreSQL

6. **Update OpenSearch index**: Write pipeline updates or creates the OpenSearch index document for the place.
   - From: `placeSvc_writePipeline` → `placeSvc_indexGateway`
   - To: `continuumPlacesServiceOpenSearch`
   - Protocol: HTTPS

7. **Return write response**: Controller returns HTTP 200 or 201 with `PlaceWriteServiceResponse` containing the place ID and write status.
   - From: `placeSvc_apiControllers`
   - To: calling service
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `VoltronRejectedInputException` | Thrown by write pipeline; caught at controller | HTTP 422 or 400 with error details |
| `VoltronSynchronousException` | Thrown by Voltron gateway; caught at controller | HTTP 500 with error details |
| `ValidationException` | Input validation failure; thrown by write pipeline | HTTP 400 Bad Request |
| `ElasticsearchPersistenceException` | OpenSearch index write failure | HTTP 500; place may be persisted in Postgres but not indexed |
| `TransformIcfToM3fException` | Model transformation failure | HTTP 500 or 400 depending on cause |
| `AuthorizationException` | Invalid or unauthorized `client_id` | HTTP 403 Forbidden |
| Voltron unavailable | Exception propagated from Voltron gateway | HTTP 500; Postgres write does not proceed |

## Sequence Diagram

```
Caller -> placeSvc_apiControllers: POST /placewriteservice/v3.0/places?client_id=m3_editor (InputPlace JSON)
placeSvc_apiControllers -> placeSvc_writePipeline: write(inputPlace, clientId)
placeSvc_writePipeline -> placeSvc_writePipeline: transform ICF -> M3 (place-transformer)
placeSvc_writePipeline -> VoltronPlatform: invokeWorkflow(inputPlace)
VoltronPlatform --> placeSvc_writePipeline: workflow result
placeSvc_writePipeline -> continuumPlacesServicePostgres: INSERT/UPDATE place record
continuumPlacesServicePostgres --> placeSvc_writePipeline: persisted
placeSvc_writePipeline -> continuumPlacesServiceOpenSearch: index place document
continuumPlacesServiceOpenSearch --> placeSvc_writePipeline: indexed
placeSvc_writePipeline --> placeSvc_apiControllers: PlaceWriteServiceResponse
placeSvc_apiControllers --> Caller: HTTP 200/201 (PlaceWriteServiceResponse JSON)
```

## Related

- Architecture dynamic view: `dynamic-place-read-flow`
- Related flows: [Place Read by ID](place-read-by-id.md), [Salesforce Place Synchronization](salesforce-sync.md)
