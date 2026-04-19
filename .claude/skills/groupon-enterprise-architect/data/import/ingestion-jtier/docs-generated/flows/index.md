---
service: "ingestion-jtier"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for ingestion-jtier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Partner Feed Extraction](partner-feed-extraction.md) | scheduled | Quartz scheduler (periodic) or `POST /ingest/v1/start` | Extracts raw offer data from external partner APIs/SFTP and persists to PostgreSQL |
| [Offer to Deal Creation](offer-to-deal-creation.md) | synchronous | Completion of feed extraction pipeline stage | Transforms extracted partner offers into Groupon deals via Deal Management API |
| [Availability Synchronization](availability-synchronization.md) | scheduled | Quartz scheduler (periodic) or `POST /ingest/v1/availability/start` | Synchronizes offer availability windows and capacity from partner APIs to active deals |
| [Deal State Management](deal-state-management.md) | synchronous | `PUT /deals/v1/pause`, `PUT /deals/v1/unpause`, `PUT /partner/v1/pause` | Pauses, unpauses, or otherwise changes the lifecycle state of deals and partners |
| [API Availability Query](api-availability-query.md) | synchronous | `GET /partner/v1/feed/availability`, `GET /partner/v1/stats/availabilitySegment` | Returns current availability feed status and segment statistics for a partner |
| [Deal Deletion Processing](deal-deletion-processing.md) | batch | Quartz scheduler or `POST /ingest/v1/deal_deletion_processor` | Drains the deal deletion queue and removes deals from the Groupon catalog |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

- **Offer to Deal Creation** spans `continuumIngestionJtierService` -> `continuumDealManagementApi` -> `continuumTaxonomyService`. See the central architecture dynamic view `dynamic-ingestion-jtier-deal-creation`.
- **Partner Feed Extraction** spans `continuumIngestionJtierService` -> external partner APIs (`viatorApi`, `mindbodyApi`, `bookerApi`, `rewardsNetworkApi`) -> `mbusPlatform`. See `dynamic-ingestion-jtier-feed-extraction`.
- **Availability Synchronization** spans `continuumIngestionJtierService` -> external partner APIs -> `continuumDealManagementApi`. See `dynamic-ingestion-jtier-availability-sync`.
