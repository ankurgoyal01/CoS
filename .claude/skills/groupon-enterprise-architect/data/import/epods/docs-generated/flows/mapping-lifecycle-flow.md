---
service: "epods"
title: "Mapping Lifecycle Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "mapping-lifecycle-flow"
flow_type: synchronous
trigger: "API call or internal sync trigger requiring entity mapping creation or refresh"
participants:
  - "continuumEpodsService"
  - "continuumEpodsPostgres"
  - "continuumDealCatalogService"
  - "continuumPartnerService"
  - "continuumMerchantApi"
  - "mindbodyApi"
  - "bookerApi"
  - "continuumIngestionService"
architecture_ref: "dynamic-epods-mapping"
---

# Mapping Lifecycle Flow

## Summary

The Mapping Lifecycle Flow covers how EPODS creates and maintains the bi-directional identity mappings between Groupon entities (deals, products, units, segments, merchants) and their counterparts in third-party partner systems. Mappings are created when a new deal is onboarded to a partner, updated when partner configuration changes, and read on every booking and availability request to perform translation. EPODS queries Deal Catalog, Partner Service, and Merchant API to enrich mappings, then persists them in PostgreSQL and pushes to the Ingestion pipeline.

## Trigger

- **Type**: api-call or internal sync
- **Source**: Onboarding process, Deal Catalog update, or internal mapping refresh job
- **Frequency**: On-demand during deal onboarding; periodic refresh via sync job

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| EPODS Service | Orchestrates mapping creation and refresh; resolves cross-system identifiers | `continuumEpodsService` |
| EPODS Postgres | Persistent store for all entity mappings | `continuumEpodsPostgres` |
| Deal Catalog Service | Source of truth for Groupon deal and product identifiers | `continuumDealCatalogService` |
| Partner Service | Provides partner-specific configuration and partner entity metadata | `continuumPartnerService` |
| Merchant API | Provides Groupon merchant profile data for merchant mappings | `continuumMerchantApi` |
| MindBody API | Partner system queried to resolve or validate partner-side entity IDs | `mindbodyApi` |
| Booker API | Partner system queried to resolve or validate partner-side entity IDs | `bookerApi` |
| Ingestion Service | Receives mapping data for downstream pipeline ingestion | `continuumIngestionService` |

## Steps

### Create Mapping

1. **Initiate mapping creation**: A mapping creation request arrives at EPODS (via internal API call or onboarding trigger) with a Groupon deal ID, merchant ID, and target partner identifier.
   - From: Onboarding caller or internal trigger
   - To: `continuumEpodsService`
   - Protocol: REST or direct

2. **Fetch deal data from Deal Catalog**: EPODS calls Deal Catalog Service to retrieve the canonical Groupon deal, product, unit, and segment identifiers for the given deal ID.
   - From: `continuumEpodsService`
   - To: `continuumDealCatalogService`
   - Protocol: REST

3. **Fetch partner configuration**: EPODS calls Partner Service to retrieve partner-specific configuration (partner ID, integration settings) for the target partner.
   - From: `continuumEpodsService`
   - To: `continuumPartnerService`
   - Protocol: REST

4. **Fetch merchant data**: EPODS calls Merchant API to retrieve the Groupon merchant profile and any partner-assigned merchant identifiers.
   - From: `continuumEpodsService`
   - To: `continuumMerchantApi`
   - Protocol: REST

5. **Resolve partner entity IDs**: EPODS calls the target partner API (MindBody or Booker) to look up or validate the partner-side identifiers for the merchant, product, or service being mapped.
   - From: `continuumEpodsService`
   - To: `mindbodyApi` or `bookerApi`
   - Protocol: REST

6. **Build mapping record**: EPODS constructs the complete bi-directional mapping record linking Groupon identifiers (dealId, productId, unitId, segmentId, merchantId) to partner identifiers.
   - From: `continuumEpodsService`
   - To: `continuumEpodsService` (internal)
   - Protocol: direct

7. **Persist mapping**: EPODS writes the mapping record to `continuumEpodsPostgres` using an upsert pattern (insert or update on conflict).
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

8. **Push to Ingestion pipeline**: EPODS notifies Ingestion Service of the new or updated mapping for downstream data pipeline processing.
   - From: `continuumEpodsService`
   - To: `continuumIngestionService`
   - Protocol: REST

### Mapping Read (per request)

1. **Inbound request requires translation**: A booking, availability, or entity lookup request arrives with a Groupon entity ID that must be translated to a partner entity ID (or vice versa).
   - From: caller
   - To: `continuumEpodsService`
   - Protocol: REST

2. **Look up mapping in PostgreSQL**: EPODS queries `continuumEpodsPostgres` for the mapping record indexed by Groupon ID or partner ID.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

3. **Return translated identifier**: EPODS uses the resolved partner ID to construct the partner API request or returns the Groupon ID from the inbound partner request.
   - From: `continuumEpodsService`
   - To: caller or next step in flow
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not found in Deal Catalog | Return error to caller; abort mapping creation | No mapping persisted |
| Partner entity not found in partner system | Return error; log for manual investigation | Mapping creation fails; onboarding blocked until resolved |
| Merchant API unavailable | Retry via `failsafe`; fail mapping creation if retries exhausted | Mapping not created; onboarding retry required |
| Mapping not found on lookup | Return 404 to caller; log for investigation | Dependent flow (booking, availability) cannot proceed |
| Ingestion push failure | Log and retry; mapping is still persisted locally | Downstream pipeline may have stale data until retry succeeds |
| Duplicate mapping (upsert conflict) | Upsert resolves conflict; most recent values win | Mapping updated in place; no duplicate records |

## Sequence Diagram

```
Caller -> EPODS: Initiate mapping creation (dealId, merchantId, partnerId)
EPODS -> DealCatalogService: Fetch deal/product/unit/segment identifiers
EPODS -> PartnerService: Fetch partner configuration
EPODS -> MerchantAPI: Fetch merchant profile data
EPODS -> PartnerAPI (MindBody/Booker): Resolve partner-side entity IDs
EPODS -> EPODS: Build bi-directional mapping record
EPODS -> EpodsPostgres: Upsert mapping record
EPODS -> IngestionService: Push mapping to ingestion pipeline
EPODS --> Caller: Mapping created/updated confirmation
```

### Mapping Read (abbreviated)

```
Caller -> EPODS: Request requiring entity translation (grouponId or partnerEntityId)
EPODS -> EpodsPostgres: Lookup mapping by ID
EpodsPostgres --> EPODS: Mapping record (grouponId <-> partnerEntityId)
EPODS -> EPODS: Apply translation
```

## Related

- Architecture dynamic view: `dynamic-epods-mapping`
- Related flows: [Booking Flow](booking-flow.md), [Availability Sync Flow](availability-sync-flow.md), [Webhook Processing Flow](webhook-processing-flow.md)
