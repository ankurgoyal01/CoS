---
service: "billing-record-service"
title: "Orders Migration"
generated: "2026-03-03"
type: flow
flow_name: "orders-migration"
flow_type: synchronous
trigger: "POST request to migration endpoint to backfill billing records from legacy Orders data"
participants:
  - "continuumCheckoutReloadedService"
  - "brs_apiLayer"
  - "brs_coreService"
  - "brs_integrationAdapters"
  - "brs_persistence"
  - "continuumBillingRecordPostgres"
architecture_ref: "dynamic-billing-record-create"
---

# Orders Migration

## Summary

Billing Record Service provides a migration endpoint that reads legacy payment instrument data from the Orders system and backfills it as BRS billing records. This flow supports the platform migration from the legacy Orders-based payment record storage to the dedicated BRS model. It is triggered per purchaser by a POST request and writes new billing records to the BRS PostgreSQL database using the existing persistence layer.

## Trigger

- **Type**: api-call (or batch process invoking the endpoint per purchaser)
- **Source**: Migration batch runner or admin tooling — POST to `/v2/{countryCode}/users/{purchaserId}/migration`
- **Frequency**: Per-purchaser batch run during the Orders-to-BRS migration campaign; not a routine checkout flow

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Migration Trigger (batch / admin) | Initiates the migration request for a specific purchaser | `continuumCheckoutReloadedService` (or admin tooling) |
| API Layer | Receives the migration POST request and routes to service layer | `brs_apiLayer` |
| Billing Record Service Layer | Orchestrates the read from Orders and write to BRS PostgreSQL | `brs_coreService` |
| External Integration Adapters | Reads legacy billing record data from the Orders MySQL database | `brs_integrationAdapters` |
| Persistence Layer | Writes migrated billing records to BRS PostgreSQL | `brs_persistence` |
| PostgreSQL | Destination for migrated billing records | `continuumBillingRecordPostgres` |

## Steps

1. **Receive migration request**: Migration trigger sends POST to `/v2/{countryCode}/users/{purchaserId}/migration` with the purchaser UUID.
   - From: Migration trigger
   - To: `brs_apiLayer`
   - Protocol: HTTP/JSON

2. **Validate and delegate**: API Layer validates the `purchaserId` UUID format and routes to the Service Layer.
   - From: `brs_apiLayer`
   - To: `brs_coreService`
   - Protocol: in-process

3. **Read Orders legacy data**: Service Layer instructs the External Integration Adapters (Orders-specific adapter) to read the purchaser's existing payment records from the Orders MySQL database.
   - From: `brs_coreService`
   - To: `brs_integrationAdapters`
   - Protocol: in-process (adapter uses JDBC to Orders MySQL)

4. **Transform and persist**: For each Orders billing record found, the Service Layer transforms the data into the BRS domain model and persists it via the Persistence Layer to BRS PostgreSQL. Already-migrated records are skipped to maintain idempotency.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process (JDBC to `continuumBillingRecordPostgres`)

5. **Return migration result**: API Layer returns the migration status to the caller (default response on completion).
   - From: `brs_apiLayer`
   - To: migration trigger
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Purchaser not found in Orders | Adapter returns empty result | Migration completes with no records written; 200 returned |
| Orders MySQL connectivity failure | Exception propagated; transaction not committed | 500 returned to caller; migration must be retried |
| BRS PostgreSQL write failure | Transaction rolled back | 500 returned; no partial state; retry is safe |
| Already-migrated record | Detected by `ordersLegacyId` lookup in BRS DB | Duplicate skipped; migration continues |

## Sequence Diagram

```
MigrationTrigger -> brs_apiLayer: POST /v2/{countryCode}/users/{purchaserId}/migration
brs_apiLayer -> brs_coreService: delegate migration for purchaserId
brs_coreService -> brs_integrationAdapters: read Orders legacy records for purchaserId
brs_integrationAdapters --> brs_coreService: List of Orders billing records
brs_coreService -> brs_persistence: check existing by ordersLegacyId (skip duplicates)
brs_persistence --> brs_coreService: existing record IDs
brs_coreService -> brs_persistence: persist new migrated BillingRecord entities
brs_persistence --> brs_coreService: saved
brs_coreService --> brs_apiLayer: migration complete
brs_apiLayer --> MigrationTrigger: 200 (default response)
```

## Related

- Architecture dynamic view: `dynamic-billing-record-create`
- Related flows: [Create Billing Record](create-billing-record.md)
- API endpoint: `GET /v2/{countryCode}/users/{purchaserId}/billingrecords/orderslegacyid/{ordersLegacyId}` (used to verify migrated records)
