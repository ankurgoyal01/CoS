---
service: "product-bundling-service"
title: "Delete Bundle"
generated: "2026-03-03"
type: flow
flow_name: "delete-bundle"
flow_type: synchronous
trigger: "HTTP DELETE /v1/bundles/{dealUuid}/{bundleType}"
participants:
  - "pbsApiResource"
  - "pbsBundlingDomainService"
  - "pbsPersistenceAdapter"
  - "pbsDealCatalogSyncService"
  - "continuumProductBundlingPostgres"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-pbs-create-bundle"
---

# Delete Bundle

## Summary

The Delete Bundle flow removes all bundle records for a given deal UUID and bundle type from the PBS PostgreSQL database, then instructs Deal Catalog Service to delete the corresponding bundle node. This ensures that the DC response no longer includes stale bundle data for the deleted deal-type combination. The operation is synchronous and non-reversible.

## Trigger

- **Type**: api-call
- **Source**: External caller (deal merchandising tools, operators, or automated deal lifecycle management)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| PBS API Resource | Receives HTTP DELETE request, validates path parameters | `pbsApiResource` |
| Bundling Domain Service | Validates bundle type, reads existing records, coordinates deletion | `pbsBundlingDomainService` |
| Persistence Adapter | Deletes bundle records from PostgreSQL | `pbsPersistenceAdapter` |
| Deal Catalog Sync Service | Issues DELETE request to Deal Catalog Service for the bundle node | `pbsDealCatalogSyncService` |
| Product Bundling Postgres | Stores bundle records to be deleted | `continuumProductBundlingPostgres` |
| Deal Catalog Service | Receives bundle node deletion request | `continuumDealCatalogService` |

## Steps

1. **Receive bundle delete request**: PBS API Resource receives `DELETE /v1/bundles/{dealUuid}/{bundleType}`.
   - From: `caller (HTTP)`
   - To: `pbsApiResource`
   - Protocol: REST/HTTP

2. **Validate bundle type**: Bundling Domain Service verifies that `bundleType` is in the configured `allowedBundleTypes` list and that `bundles_config` contains an entry for the given type.
   - From: `pbsApiResource`
   - To: `pbsBundlingDomainService`
   - Protocol: Direct

3. **Check for existing bundles**: Persistence Adapter queries Postgres for existing bundle records for the deal UUID and bundle type.
   - From: `pbsBundlingDomainService`
   - To: `pbsPersistenceAdapter` → `continuumProductBundlingPostgres`
   - Protocol: JDBC/PostgreSQL

4. **Delete bundle records from Postgres**: Persistence Adapter deletes all bundle records for the deal UUID and bundle type.
   - From: `pbsBundlingDomainService`
   - To: `pbsPersistenceAdapter` → `continuumProductBundlingPostgres`
   - Protocol: JDBC/PostgreSQL

5. **Delete bundle node from Deal Catalog Service**: Deal Catalog Sync Service calls `DELETE /deal_catalog/v3/deals/{dealUuid}/nodes/bundles` on Deal Catalog Service.
   - From: `pbsApiResource`
   - To: `pbsDealCatalogSyncService` → `continuumDealCatalogService`
   - Protocol: HTTP/JSON

6. **Return success response**: PBS API Resource returns HTTP 200 to the caller.
   - From: `pbsApiResource`
   - To: caller
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `bundleType` not in allowedBundleTypes | Return HTTP 400 | Request rejected; no deletion |
| `bundleType` not found in `bundles_config` | Return HTTP 403 | Request rejected; no deletion |
| No bundles found for deal UUID + bundle type | Return HTTP 404 | Request rejected; nothing to delete |
| PostgreSQL delete failure | Return HTTP 500 | Records not deleted; DCS node not removed |
| Deal Catalog Service unavailable | Bundles deleted from Postgres; DCS node removal fails | Postgres and DCS out of sync until next bundle operation |

## Sequence Diagram

```
Caller -> pbsApiResource: DELETE /v1/bundles/{dealUuid}/{bundleType}
pbsApiResource -> pbsBundlingDomainService: Validate bundle type and check existing records
pbsBundlingDomainService -> pbsPersistenceAdapter: Check for existing bundles
pbsPersistenceAdapter -> continuumProductBundlingPostgres: SELECT bundles
pbsBundlingDomainService -> pbsPersistenceAdapter: Delete bundle records
pbsPersistenceAdapter -> continuumProductBundlingPostgres: DELETE bundles
pbsApiResource -> pbsDealCatalogSyncService: Delete Deal Catalog bundle node
pbsDealCatalogSyncService -> continuumDealCatalogService: DELETE /deal_catalog/v3/deals/{dealUuid}/nodes/bundles
pbsApiResource --> Caller: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-pbs-create-bundle`
- Related flows: [Create Bundle](create-bundle.md), [Warranty Refresh](warranty-refresh.md)
