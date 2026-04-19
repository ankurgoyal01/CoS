---
service: "deal-management-api"
title: "Deal Create (Sync)"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-create-sync"
flow_type: synchronous
trigger: "HTTP POST to /v1/deals or /v3/deals"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
  - "continuumTaxonomyService"
  - "continuumPricingService"
  - "salesForce"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-dealCreateSync"
---

# Deal Create (Sync)

## Summary

The synchronous deal creation flow handles inbound POST requests to `/v1/deals` or `/v3/deals`. The API validates the request payload, resolves taxonomy and pricing metadata from downstream services, persists the new deal record to MySQL, and synchronously notifies Salesforce and the Deal Catalog Service before returning the created deal to the caller.

## Trigger

- **Type**: api-call
- **Source**: Internal tooling, merchant portals, or service-to-service caller
- **Frequency**: On demand (per create request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Receives request, orchestrates validation and persistence | `continuumDealManagementApi` |
| Deal Management MySQL | Stores the new deal record | `continuumDealManagementMysql` |
| Taxonomy Service | Supplies taxonomy classification for the deal | `continuumTaxonomyService` |
| Pricing Service | Provides pricing data for deal configuration | `continuumPricingService` |
| Salesforce | Receives CRM record for the new deal | `salesForce` |
| Deal Catalog Service | Receives catalog entry for the new deal | `continuumDealCatalogService` |

## Steps

1. **Receive create request**: API Controllers accept POST `/v1/deals` or `/v3/deals` with JSON deal payload.
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Validate request payload**: Validators check required fields, data types, and domain constraints against service-discovery-validations rules.
   - From: `apiControllers`
   - To: `validationLayer` (internal)
   - Protocol: in-process

3. **Fetch taxonomy data**: Remote Clients call Taxonomy Service to resolve category classification for the deal.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `continuumTaxonomyService`
   - Protocol: REST/HTTPS

4. **Fetch pricing data**: Remote Clients call Pricing Service to retrieve applicable pricing rules for the deal type.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `continuumPricingService`
   - Protocol: REST/HTTPS

5. **Persist deal record**: Repositories write the new deal and associated attributes to MySQL.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

6. **Sync to Salesforce**: Remote Clients push the new deal record to Salesforce CRM.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `salesForce`
   - Protocol: REST/HTTPS

7. **Publish to Deal Catalog**: Remote Clients send the deal data to the Deal Catalog Service.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `continuumDealCatalogService`
   - Protocol: REST/HTTPS

8. **Return created deal**: API Controllers return HTTP 201 with the created deal payload.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Return HTTP 422 with error details | Deal not created; caller must fix and retry |
| Taxonomy Service unavailable | Return HTTP 503 or 500 | Deal not created; downstream call failure surfaced to caller |
| Pricing Service unavailable | Return HTTP 503 or 500 | Deal not created; downstream call failure surfaced to caller |
| MySQL write failure | Return HTTP 500 | Deal not created; transaction rolled back |
| Salesforce sync failure | Return HTTP 500 (sync path) | Deal may be persisted but Salesforce out of sync; retry required |
| Deal Catalog failure | Return HTTP 500 (sync path) | Deal may be persisted but catalog out of sync; retry required |

## Sequence Diagram

```
Client -> continuumDealManagementApi: POST /v1/deals {deal payload}
continuumDealManagementApi -> validationLayer: validate(payload)
validationLayer --> continuumDealManagementApi: valid / errors
continuumDealManagementApi -> continuumTaxonomyService: GET taxonomy classification
continuumTaxonomyService --> continuumDealManagementApi: taxonomy data
continuumDealManagementApi -> continuumPricingService: GET pricing rules
continuumPricingService --> continuumDealManagementApi: pricing data
continuumDealManagementApi -> continuumDealManagementMysql: INSERT deal record
continuumDealManagementMysql --> continuumDealManagementApi: deal_id
continuumDealManagementApi -> salesForce: POST deal CRM record
salesForce --> continuumDealManagementApi: 200 OK
continuumDealManagementApi -> continuumDealCatalogService: POST catalog entry
continuumDealCatalogService --> continuumDealManagementApi: 200 OK
continuumDealManagementApi --> Client: 201 Created {deal}
```

## Related

- Architecture dynamic view: `dynamic-dealCreateSync`
- Related flows: [Deal Create (Async)](deal-create-async.md), [Deal Publish Workflow](deal-publish-workflow.md)
