---
service: "ingestion-jtier"
title: "Offer to Deal Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "offer-to-deal-creation"
flow_type: synchronous
trigger: "Completion of feed extraction pipeline stage, or POST /ingest/v1/offer for a single offer"
participants:
  - "continuumIngestionJtierService"
  - "continuumIngestionJtierPostgres"
  - "continuumDealManagementApi"
  - "continuumTaxonomyService"
  - "thirdPartyInventory"
  - "mbusPlatform"
architecture_ref: "dynamic-ingestion-jtier-deal-creation"
---

# Offer to Deal Creation

## Summary

The offer to deal creation flow takes normalized offer records (produced by partner feed extraction) and drives their creation or update as Groupon deals through the Deal Management API. It resolves taxonomy categories for each offer via the Taxonomy Service and retrieves supplemental inventory metadata from TPIS before submitting the deal creation payload. Successfully processed offers result in an `OfferIngestionEvent` published to the Message Bus.

## Trigger

- **Type**: api-call (internal pipeline invocation) / api-call (external)
- **Source**: `ingestionPipeline` after successful feed extraction for a partner batch; or `POST /ingest/v1/offer` for a single offer submission
- **Frequency**: Per ingestion run (batch); on-demand for single-offer API calls

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion JTier Service | Orchestrates offer enrichment and deal creation; persists deal-offer mapping | `continuumIngestionJtierService` |
| Ingestion PostgreSQL | Reads normalized offer records; stores deal-offer association and status | `continuumIngestionJtierPostgres` |
| Deal Management API | Receives deal creation/update requests; returns created deal IDs | `continuumDealManagementApi` |
| Taxonomy Service | Resolves offer categories to Groupon taxonomy hierarchy | `continuumTaxonomyService` |
| Third-Party Inventory Service (TPIS) | Provides supplemental inventory metadata for offer enrichment | `thirdPartyInventory` |
| Message Bus | Receives OfferIngestionEvent after successful deal creation | `mbusPlatform` |

## Steps

1. **Read pending offer records**: `ingestionPersistence` queries PostgreSQL for offers in EXTRACTED status awaiting deal creation.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

2. **Resolve taxonomy category**: `ingestionClientGateway` calls Taxonomy Service to map offer category identifiers to Groupon taxonomy IDs.
   - From: `continuumIngestionJtierService`
   - To: `continuumTaxonomyService`
   - Protocol: HTTP/REST

3. **Fetch supplemental inventory metadata**: `ingestionClientGateway` calls TPIS to retrieve additional inventory attributes (pricing, redemption rules, etc.) for the offer.
   - From: `continuumIngestionJtierService`
   - To: `thirdPartyInventory`
   - Protocol: HTTP/REST

4. **Build deal creation payload**: `ingestionPipeline` assembles the Deal Management API request body by merging the normalized offer data, taxonomy IDs, and TPIS inventory metadata.
   - From: `continuumIngestionJtierService` (internal pipeline step)
   - To: `continuumIngestionJtierService`
   - Protocol: direct (in-process)

5. **Create or update deal**: `ingestionClientGateway` submits the deal payload to Deal Management API. If the offer already has an associated dealId in PostgreSQL, an update is sent; otherwise a new deal creation is requested.
   - From: `continuumIngestionJtierService`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/REST

6. **Persist deal-offer mapping**: `ingestionPersistence` updates the offer record in PostgreSQL with the returned dealId and sets status to DEAL_CREATED or DEAL_UPDATED.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

7. **Publish OfferIngestionEvent**: `ingestionMessaging` publishes an OfferIngestionEvent containing offerId, partnerId, dealId, and action (CREATE/UPDATE) to the Message Bus.
   - From: `continuumIngestionJtierService`
   - To: `mbusPlatform`
   - Protocol: Message Bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Taxonomy Service returns unknown category | Default/fallback taxonomy applied or offer skipped | Offer marked with taxonomy error; IngestionOperationalEvent ERROR published |
| TPIS returns 404 for offer | Proceed without supplemental metadata where possible; log warning | Deal created with reduced metadata |
| Deal Management API returns 422 validation error | Offer marked DEAL_CREATION_FAILED in PostgreSQL; error logged | No deal created; retried on next ingestion run |
| Deal Management API 5xx error | Offer marked DEAL_CREATION_FAILED; run continues for other offers | Failed offers retried on next run |
| Message Bus publish failure | Logged as warning; does not block deal creation | OfferIngestionEvent lost; deal still created |

## Sequence Diagram

```
ingestionPipeline -> continuumIngestionJtierPostgres: read EXTRACTED offers
continuumIngestionJtierPostgres --> ingestionPipeline: offer records
ingestionPipeline -> continuumTaxonomyService: resolve taxonomy for offer category
continuumTaxonomyService --> ingestionPipeline: taxonomy IDs
ingestionPipeline -> thirdPartyInventory: fetch inventory metadata for offerId
thirdPartyInventory --> ingestionPipeline: inventory metadata
ingestionPipeline -> ingestionPipeline: build deal payload
ingestionPipeline -> continuumDealManagementApi: POST/PUT deal
continuumDealManagementApi --> ingestionPipeline: dealId + status
ingestionPipeline -> continuumIngestionJtierPostgres: update offer (dealId, status=DEAL_CREATED)
ingestionPipeline -> mbusPlatform: publish OfferIngestionEvent
```

## Related

- Architecture dynamic view: `dynamic-ingestion-jtier-deal-creation`
- Related flows: [Partner Feed Extraction](partner-feed-extraction.md), [Deal State Management](deal-state-management.md), [Deal Deletion Processing](deal-deletion-processing.md)
