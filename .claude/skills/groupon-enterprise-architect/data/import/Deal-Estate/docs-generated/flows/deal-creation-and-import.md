---
service: "Deal-Estate"
title: "Deal Creation and Import"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-creation-and-import"
flow_type: synchronous
trigger: "API call — POST /deals or POST /deals/:id/import"
participants:
  - "continuumDealEstateWeb"
  - "continuumDealEstateMysql"
  - "continuumDealEstateRedis"
  - "continuumDealCatalogService"
  - "continuumDealManagementApi"
  - "continuumVoucherInventoryService"
  - "continuumCustomFieldsService"
architecture_ref: "dynamic-deal-creation-and-import"
---

# Deal Creation and Import

## Summary

This flow handles the creation of new deal records and the import of deal data from external sources (e.g., Salesforce or Deal Management API). On creation, Deal-Estate persists the deal to MySQL, optionally initialises voucher inventory, syncs custom fields, and publishes a `dealEstate.option.create` event to notify downstream consumers. The import path additionally fetches data from Deal Catalog or Deal Management API to enrich the deal record before persisting.

## Trigger

- **Type**: api-call
- **Source**: Internal tooling or other Continuum services calling `POST /deals` (create) or `POST /deals/:id/import` (import)
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Estate Web | Receives API request, validates input, orchestrates creation/import | `continuumDealEstateWeb` |
| Deal Estate MySQL | Persists new deal and option records | `continuumDealEstateMysql` |
| Deal Estate Redis | Caches deal data; enqueues async follow-up jobs if required | `continuumDealEstateRedis` |
| Deal Catalog Service | Source of deal/product data during import | `continuumDealCatalogService` |
| Deal Management API | Source of deal management data during import | `continuumDealManagementApi` |
| Voucher Inventory Service | Initialises voucher inventory for the new deal | `continuumVoucherInventoryService` |
| Custom Fields Service | Writes initial custom field values for the deal | `continuumCustomFieldsService` |

## Steps

1. **Receive creation or import request**: Client calls `POST /deals` (create) or `POST /deals/:id/import` (import).
   - From: `caller`
   - To: `continuumDealEstateWeb`
   - Protocol: REST

2. **Validate request payload**: Rails controller validates required fields and deal state preconditions via `state_machine`.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateWeb` (internal)
   - Protocol: direct

3. **Fetch external data (import path only)**: Fetches deal data from Deal Catalog and/or Deal Management API to enrich the new deal record.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealCatalogService`, `continuumDealManagementApi`
   - Protocol: REST (service-client)

4. **Persist deal and option records**: Writes the new deal and its options to MySQL via ActiveRecord.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

5. **Initialise voucher inventory**: Calls Voucher Inventory Service to set up inventory for the new deal options.
   - From: `continuumDealEstateWeb`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST (service-client)

6. **Write initial custom fields**: Calls Custom Fields Service to persist any custom field values for the new deal.
   - From: `continuumDealEstateWeb`
   - To: `continuumCustomFieldsService`
   - Protocol: REST (service-client)

7. **Publish option create event**: Emits `dealEstate.option.create` on the message bus for each new option created.
   - From: `continuumDealEstateWeb`
   - To: message bus
   - Protocol: mbus (messagebus gem)

8. **Cache deal data and enqueue async jobs if needed**: Writes deal data to Redis cache; enqueues any follow-up background jobs.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateRedis`
   - Protocol: Redis protocol

9. **Return response to caller**: Returns created deal record (or import status) to the caller.
   - From: `continuumDealEstateWeb`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid payload | Rails validation error returned immediately | HTTP 422; no record persisted |
| MySQL write failure | ActiveRecord exception; transaction rolled back | HTTP 500; deal not created |
| Deal Catalog unavailable (import) | service-client timeout/error | HTTP 502 or 500; import aborted |
| Voucher Inventory Service unavailable | service-client timeout/error | HTTP 502 or 500; deal may be partially created |
| Custom Fields Service unavailable | service-client timeout/error | Custom fields not written; deal record still persisted |
| Message bus unavailable | messagebus publish failure | Event not delivered; downstream consumers may miss the event |

## Sequence Diagram

```
caller -> continuumDealEstateWeb: POST /deals or POST /deals/:id/import
continuumDealEstateWeb -> continuumDealEstateWeb: validate payload + state machine
continuumDealEstateWeb -> continuumDealCatalogService: fetch deal data (import path)
continuumDealEstateWeb -> continuumDealManagementApi: fetch deal mgmt data (import path)
continuumDealEstateWeb -> continuumDealEstateMysql: INSERT deal + options
continuumDealEstateWeb -> continuumVoucherInventoryService: initialise voucher inventory
continuumDealEstateWeb -> continuumCustomFieldsService: write custom fields
continuumDealEstateWeb -> messageBus: publish dealEstate.option.create
continuumDealEstateWeb -> continuumDealEstateRedis: cache + enqueue follow-up jobs
continuumDealEstateWeb --> caller: 201 Created / import status
```

## Related

- Architecture dynamic view: `dynamic-deal-creation-and-import`
- Related flows: [Deal Scheduling and Publication](deal-scheduling-and-publication.md), [Custom Field Sync](custom-field-sync.md)
