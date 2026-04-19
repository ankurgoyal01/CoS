---
service: "authoring2"
title: "Partial Snapshot Creation"
generated: "2026-03-03"
type: flow
flow_name: "partial-snapshot-creation"
flow_type: synchronous
trigger: "User selects specific taxonomy GUIDs and requests a partial snapshot via POST /partialsnapshots/create"
participants:
  - "authoring2RestApi"
  - "authoring2TaxonomyService"
  - "continuumAuthoring2Postgres"
architecture_ref: "components-continuum-authoring2-authoring2TaxonomyService"
---

# Partial Snapshot Creation

## Summary

A partial snapshot packages only a selected subset of taxonomy GUIDs rather than the full taxonomy content. This allows targeted, faster deployments when only specific taxonomies have changed. The `PartialSnapshotRESTFacade` accepts a list of taxonomy GUIDs and an optional comment, delegates to `PartialSnapshotCreationService` for validation and content assembly, and returns a success or failure response synchronously. Partial snapshots follow the same deploy lifecycle as full snapshots (test → certify → live) but use the `pt_deploy.live.activation_ep` endpoint for live activation.

## Trigger

- **Type**: api-call (user-action via browser)
- **Source**: Ember.js authoring UI — content authors select specific taxonomies for partial deployment
- **Frequency**: On demand; used for targeted incremental updates between full deployment cycles

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ember.js UI | Initiates partial snapshot with taxonomy GUID list | — |
| REST Facades (`PartialSnapshotRESTFacade`) | Routes and delegates creation request | `authoring2RestApi` |
| Taxonomy Domain Services (`PartialSnapshotCreationService`, `TaxonomySnapshotMapService`) | Validates and builds the partial snapshot | `authoring2TaxonomyService` |
| Authoring2 PostgreSQL | Stores `TaxonomySnapshotMap` mappings and snapshot records | `continuumAuthoring2Postgres` |

## Steps

1. **Fetches taxonomy-to-snapshot mappings**: Ember.js UI may first call `POST /partialsnapshots/mappings` to retrieve current `TaxonomySnapshotInfo` records for all taxonomies, showing which snapshot each taxonomy was last deployed from.
   - From: Ember.js UI
   - To: `PartialSnapshotRESTFacade` → `TaxonomySnapshotMapService`
   - Protocol: REST / HTTP POST

2. **Requests partial snapshot creation**: Ember.js UI sends `POST /partialsnapshots/create` with JSON body containing `taxGuids` (list of taxonomy GUIDs) and `comment`.
   - From: Ember.js UI
   - To: `PartialSnapshotRESTFacade`
   - Protocol: REST / HTTP POST

3. **Validates input and assembles snapshot**: `PartialSnapshotCreationService.createNewSnapshot` validates the provided taxonomy GUIDs, reads category and relationship data for those taxonomies from PostgreSQL, and builds the partial XML snapshot content.
   - From: `PartialSnapshotCreationService`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

4. **Persists partial snapshot record**: Creates a `Snapshots` row (with `is_full_snapshot = 0`) and updates `TaxonomySnapshotMap` entries to link each selected taxonomy GUID to the new snapshot.
   - From: `PartialSnapshotCreationService`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

5. **Returns result**: If creation succeeds, returns HTTP 200 with `SnapshotValidatorResponse` (success = true). If validation fails, returns HTTP 400 with the validator response.
   - From: `PartialSnapshotRESTFacade`
   - To: Ember.js UI
   - Protocol: REST / HTTP 200 or 400

6. **User proceeds to deploy lifecycle**: The partial snapshot follows the same `deploy_test` → `test_certify` → `deploy_live` steps as full snapshots, but the live activation call goes to `pt_deploy.live.activation_ep` = `http://taxonomyv2.production.service/partialsnapshots/liveactivate`.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No taxonomy GUIDs provided | `SnapshotValidatorResponse.success = false` | HTTP 400 with error details |
| Invalid taxonomy GUID | Validation in `PartialSnapshotCreationService` fails | HTTP 400 with validator response |
| No mappings found | `POST /partialsnapshots/mappings` returns HTTP 204 | Empty response; user selects GUIDs manually |
| DB write failure | Exception propagated | HTTP 500 or exception error |

## Sequence Diagram

```
Ember.js UI -> PartialSnapshotRESTFacade: POST /partialsnapshots/mappings
PartialSnapshotRESTFacade -> TaxonomySnapshotMapService: fetchTaxonomySnapshotMappingForAllTaxonomies
TaxonomySnapshotMapService -> PostgreSQL: SELECT taxonomy_snapshot_map JOIN snapshots
PostgreSQL --> TaxonomySnapshotMapService: mapping list
PartialSnapshotRESTFacade --> Ember.js UI: HTTP 200 (TaxonomySnapshotInfo list)

Ember.js UI -> PartialSnapshotRESTFacade: POST /partialsnapshots/create {taxGuids, comment}
PartialSnapshotRESTFacade -> PartialSnapshotCreationService: createNewSnapshot(taxGuids, comment)
PartialSnapshotCreationService -> PostgreSQL: SELECT categories, relationships for taxGuids
PostgreSQL --> PartialSnapshotCreationService: taxonomy data
PartialSnapshotCreationService -> PostgreSQL: INSERT INTO snapshots (is_full_snapshot=0, ...)
PartialSnapshotCreationService -> PostgreSQL: UPDATE taxonomy_snapshot_map ...
PartialSnapshotCreationService --> PartialSnapshotRESTFacade: SnapshotValidatorResponse(success=true)
PartialSnapshotRESTFacade --> Ember.js UI: HTTP 200
```

## Related

- Architecture dynamic view: `components-continuum-authoring2-authoring2TaxonomyService`
- Related flows: [Snapshot Creation](snapshot-creation.md), [Snapshot Deploy to Live](snapshot-deploy-live.md)
