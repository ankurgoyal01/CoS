---
service: "deal-management-api"
title: "Merchant and Place Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-place-sync"
flow_type: synchronous
trigger: "HTTP GET /v1/merchants or GET /v1/places"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
architecture_ref: "dynamic-merchantPlaceSync"
---

# Merchant and Place Sync

## Summary

The merchant and place sync flow handles retrieval of merchant and physical location (place) data to support deal authoring. When a deal creator needs to associate a merchant or specific location with a deal, the API fetches the relevant records from the `continuumDealManagementMysql` store (where merchant/place data is cached or mirrored from the upstream `m3` merchant data service) and returns them to the caller.

> Note: The upstream `m3` (merchant/places) service is referenced in the architecture stubs as a dependency for merchant and place data, but is marked `stub_only` — the service is not yet fully integrated into the federated architecture model. Merchant and place data available through DMAPI's `/v1/merchants` and `/v1/places` endpoints reflects data that has been synchronized or mirrored from m3.

## Trigger

- **Type**: api-call
- **Source**: Deal setup tooling or operator looking up merchant/place data during deal configuration
- **Frequency**: On demand (per lookup request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Receives lookup request, queries data store | `continuumDealManagementApi` |
| Deal Management MySQL | Provides merchant and place records | `continuumDealManagementMysql` |

## Steps

1. **Receive merchant or place lookup request**: API Controllers accept GET `/v1/merchants` (with optional filter parameters) or GET `/v1/merchants/:id`.
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Validate query parameters**: Validators check filter parameters and access authorization.
   - From: `apiControllers`
   - To: `validationLayer` (internal)
   - Protocol: in-process

3. **Query merchant or place records**: Repositories query MySQL for matching merchant or place records using provided filters.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

4. **Return results**: API Controllers serialize and return the matching records.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant or place not found | Return HTTP 404 | Caller receives not-found response |
| Invalid query parameters | Return HTTP 400 with error details | Query not executed |
| MySQL read failure | Return HTTP 500 | Caller receives server error |

## Sequence Diagram

```
Client -> continuumDealManagementApi: GET /v1/merchants?filters
continuumDealManagementApi -> validationLayer: validate query params
validationLayer --> continuumDealManagementApi: valid
continuumDealManagementApi -> continuumDealManagementMysql: SELECT merchants WHERE filters
continuumDealManagementMysql --> continuumDealManagementApi: merchant records
continuumDealManagementApi --> Client: 200 OK {merchants[]}

Client -> continuumDealManagementApi: GET /v1/places?filters
continuumDealManagementApi -> continuumDealManagementMysql: SELECT places WHERE filters
continuumDealManagementMysql --> continuumDealManagementApi: place records
continuumDealManagementApi --> Client: 200 OK {places[]}
```

## Related

- Architecture dynamic view: `dynamic-merchantPlaceSync`
- Related flows: [Deal Create (Sync)](deal-create-sync.md), [Deal Create (Async)](deal-create-async.md)
