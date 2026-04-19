---
service: "lpapi"
title: "Taxonomy Sync and Category Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "taxonomy-sync-and-category-management"
flow_type: synchronous
trigger: "Operator action or automated taxonomy import via continuumLpapiApp"
participants:
  - "continuumLpapiApp"
  - "appApiResources"
  - "appDataAccess"
  - "continuumTaxonomyService"
  - "continuumLpapiPrimaryPostgres"
architecture_ref: "lpapiAppComponents"
---

# Taxonomy Sync and Category Management

## Summary

LPAPI imports and synchronizes taxonomy category data from the `continuumTaxonomyService` to keep its local category store current. The `continuumLpapiApp` process, through its `appApiResources` and `appDataAccess` components, calls the Taxonomy Service over HTTP using the JTier Taxonomy Client, retrieves the current category hierarchy, and persists the result to `continuumLpapiPrimaryPostgres`. These categories are then used to classify landing pages throughout the system.

## Trigger

- **Type**: api-call (and optionally scheduled)
- **Source**: Operator action via LPAPI management API, or automated import pipeline
- **Frequency**: On-demand; may also be scheduled periodically to keep categories current

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / Automation | Initiates the taxonomy sync action | External to LPAPI |
| LPAPI App | Receives the sync request and coordinates the import | `continuumLpapiApp` |
| API Resources | Handles the incoming REST trigger | `appApiResources` |
| Data Access Layer | Persists imported taxonomy data | `appDataAccess` |
| Taxonomy Service | Authoritative source of taxonomy category hierarchies | `continuumTaxonomyService` |
| LPAPI Primary Postgres | Target for taxonomy category records | `continuumLpapiPrimaryPostgres` |

## Steps

1. **Receives sync trigger**: An operator or automated pipeline initiates a taxonomy import via `continuumLpapiApp`
   - From: Operator / Automation
   - To: `appApiResources`
   - Protocol: REST / HTTP

2. **Calls Taxonomy Service**: `continuumLpapiApp` uses the JTier Taxonomy Client to call `continuumTaxonomyService` and retrieve the current taxonomy category hierarchy
   - From: `continuumLpapiApp`
   - To: `continuumTaxonomyService`
   - Protocol: HTTP

3. **Receives taxonomy data**: `continuumTaxonomyService` returns the category hierarchy payload
   - From: `continuumTaxonomyService`
   - To: `continuumLpapiApp`
   - Protocol: HTTP

4. **Persists taxonomy categories**: `appDataAccess` writes the imported taxonomy categories (upsert) to `continuumLpapiPrimaryPostgres`
   - From: `appDataAccess`
   - To: `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

5. **Returns sync result**: `appApiResources` returns confirmation to the caller
   - From: `continuumLpapiApp`
   - To: Operator / Automation
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Taxonomy Service unreachable | HTTP call fails; exception propagated | Sync aborted; existing stored categories unchanged; HTTP 503 or 500 returned |
| Taxonomy Service returns partial data | Partial import written to DB | Category store partially updated; may require re-sync |
| DB write failure | Exception in `appDataAccess` | Import fails; previously stored categories remain valid |
| Taxonomy Service returns empty/unchanged data | No-op or conditional upsert | No-op write; categories unchanged |

## Sequence Diagram

```
Operator -> appApiResources: trigger taxonomy sync
appApiResources -> continuumTaxonomyService: GET taxonomy category hierarchy (JTier Taxonomy Client)
continuumTaxonomyService --> appApiResources: category hierarchy payload
appApiResources -> appDataAccess: import and upsert categories
appDataAccess -> continuumLpapiPrimaryPostgres: UPSERT taxonomy categories
continuumLpapiPrimaryPostgres --> appDataAccess: write confirmation
appDataAccess --> appApiResources: import result
appApiResources --> Operator: HTTP 200 sync confirmation
```

## Related

- Architecture component view: `lpapiAppComponents`
- Related flows: [Landing Page CRUD](landing-page-crud.md), [Route Resolution and URL Mapping](route-resolution-and-url-mapping.md)
