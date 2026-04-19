---
service: "product-bundling-service"
title: "Create Bundle"
generated: "2026-03-03"
type: flow
flow_name: "create-bundle"
flow_type: synchronous
trigger: "HTTP POST /v1/bundles/{dealUuid}/{bundleType}"
participants:
  - "pbsApiResource"
  - "pbsBundlingDomainService"
  - "pbsPersistenceAdapter"
  - "pbsDealCatalogSyncService"
  - "continuumProductBundlingPostgres"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-pbs-create-bundle"
---

# Create Bundle

## Summary

The Create Bundle flow is triggered when a caller POSTs bundle value data to PBS for a specific deal UUID and bundle type. PBS validates the request, reads existing configuration from PostgreSQL, fetches deal and bundled-product metadata from Deal Catalog Service, persists the new bundle records (replacing any existing records for the same deal + type), and finally registers an updated bundle node in Deal Catalog so that the DC response includes the latest bundle data. This flow is non-incremental: all existing bundles for the given deal UUID and bundle type are deleted and replaced with the values provided in the request.

## Trigger

- **Type**: api-call
- **Source**: External caller (deal merchandising tools, operators, or the Warranty Refresh job calling PBS internally)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| PBS API Resource | Receives HTTP request, delegates validation and processing | `pbsApiResource` |
| Bundling Domain Service | Validates bundle type and payload; orchestrates persistence and DCS sync | `pbsBundlingDomainService` |
| Persistence Adapter | Reads bundle config and existing bundles; writes new bundle records | `pbsPersistenceAdapter` |
| Deal Catalog Sync Service | Fetches deal and bundled-product metadata; builds and registers Deal Catalog bundle node | `pbsDealCatalogSyncService` |
| Product Bundling Postgres | Stores bundle config and bundle records | `continuumProductBundlingPostgres` |
| Deal Catalog Service | Source of deal metadata; receives bundle node upsert | `continuumDealCatalogService` |

## Steps

1. **Receive bundle create request**: PBS API Resource receives `POST /v1/bundles/{dealUuid}/{bundleType}` with a JSON body containing bundle values (list of `bundledProductId` + `products` mappings).
   - From: `caller (HTTP)`
   - To: `pbsApiResource`
   - Protocol: REST/HTTP

2. **Validate bundle type and payload**: PBS API Resource passes the request to Bundling Domain Service, which validates that `bundleType` is in the configured `allowedBundleTypes` list, that the `products` list is not empty, and that `bundledProductId` values are valid UUIDs.
   - From: `pbsApiResource`
   - To: `pbsBundlingDomainService`
   - Protocol: Direct

3. **Read bundle config from Postgres**: Bundling Domain Service instructs Persistence Adapter to read the `bundles_config` record for the given `bundleType` and fetch any existing bundle records for the deal UUID.
   - From: `pbsBundlingDomainService`
   - To: `pbsPersistenceAdapter` → `continuumProductBundlingPostgres`
   - Protocol: JDBC/PostgreSQL

4. **Retrieve deal and bundled-product metadata from DCS**: Bundling Domain Service instructs Deal Catalog Sync Service to fetch the deal data and creative contents for each `bundledProductId` from Deal Catalog Service.
   - From: `pbsBundlingDomainService`
   - To: `pbsDealCatalogSyncService` → `continuumDealCatalogService`
   - Protocol: HTTP/JSON

5. **Create or update bundle records in Postgres**: Persistence Adapter deletes all existing bundle records for the deal UUID + bundle type, then inserts the new bundle records derived from the validated request.
   - From: `pbsBundlingDomainService`
   - To: `pbsPersistenceAdapter` → `continuumProductBundlingPostgres`
   - Protocol: JDBC/PostgreSQL

6. **Trigger Deal Catalog bundle node upsert**: PBS API Resource instructs Deal Catalog Sync Service to register (upsert) the bundle node in Deal Catalog, using the bundle data just persisted to Postgres.
   - From: `pbsApiResource`
   - To: `pbsDealCatalogSyncService`
   - Protocol: Direct

7. **Build node payload from current bundles**: Deal Catalog Sync Service calls back to Bundling Domain Service to read the current bundle state for the deal and build the Deal Catalog node payload.
   - From: `pbsDealCatalogSyncService`
   - To: `pbsBundlingDomainService`
   - Protocol: Direct

8. **PUT bundle node to Deal Catalog Service**: Deal Catalog Sync Service calls `PUT /deal_catalog/v3/deals/{dealUuid}/nodes/bundles` on Deal Catalog Service with the bundle node payload.
   - From: `pbsDealCatalogSyncService`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON

9. **Return success response**: PBS API Resource returns HTTP 200 to the caller.
   - From: `pbsApiResource`
   - To: caller
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `bundleType` not in allowedBundleTypes | Return HTTP 400 immediately | Request rejected; no persistence |
| `products` list is empty | Return HTTP 422 | Request rejected; no persistence |
| No config in `bundles_config` for bundle type | Return HTTP 403 | Request rejected; no persistence |
| No creative contents found for `bundledProductId` in DCS | Return HTTP 403 | Request rejected; no persistence |
| Invalid UUID format for `bundledProductId` or products | Return HTTP 400 | Request rejected |
| PostgreSQL write failure | Return HTTP 500 | Persistence failed; DCS node not updated |
| Deal Catalog Service unavailable | Bundle records persisted to Postgres; DCS node update fails silently or returns error | Bundles stored but DC response stale until next sync |

## Sequence Diagram

```
Caller -> pbsApiResource: POST /v1/bundles/{dealUuid}/{bundleType}
pbsApiResource -> pbsBundlingDomainService: Validate bundle type, payload, and current state
pbsBundlingDomainService -> pbsPersistenceAdapter: Read config and existing bundles
pbsPersistenceAdapter -> continuumProductBundlingPostgres: SELECT bundles_config, bundles
pbsBundlingDomainService -> pbsDealCatalogSyncService: Retrieve deal and bundled-product metadata
pbsDealCatalogSyncService -> continuumDealCatalogService: GET deal and creative contents
pbsBundlingDomainService -> pbsPersistenceAdapter: Create/update bundle records
pbsPersistenceAdapter -> continuumProductBundlingPostgres: DELETE + INSERT bundles
pbsApiResource -> pbsDealCatalogSyncService: Trigger Deal Catalog node upsert
pbsDealCatalogSyncService -> pbsBundlingDomainService: Build node payload from current bundles
pbsDealCatalogSyncService -> continuumDealCatalogService: PUT /deal_catalog/v3/deals/{dealUuid}/nodes/bundles
pbsApiResource --> Caller: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-pbs-create-bundle`
- Related flows: [Delete Bundle](delete-bundle.md), [Warranty Refresh](warranty-refresh.md)
