---
service: "leadminer"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Leadminer (M3 Editor).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Search Places](search-places.md) | synchronous | Operator submits place search query | Operator searches for Place records by name, address, or other criteria |
| [Edit Place](edit-place.md) | synchronous | Operator submits place edit form | Operator views and saves edits to a Place record via M3 Write Service |
| [Merge Places](merge-places.md) | synchronous | Operator initiates a place merge action | Operator merges two duplicate Place records into one canonical record |
| [Defrank Place](defrank-place.md) | synchronous | Operator triggers defrank action on a place | Operator defrankens a Place record flagged as a duplicate/stub |
| [Search Merchants](search-merchants.md) | synchronous | Operator submits merchant search query | Operator searches for Merchant records by name or identifier |
| [Edit Merchant](edit-merchant.md) | synchronous | Operator submits merchant edit form | Operator views and saves edits to a Merchant record via M3 Merchant Service |
| [View Input History](view-input-history.md) | synchronous | Operator navigates to input history | Operator reviews the audit trail of changes made to a place or merchant |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 7 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [Edit Place](edit-place.md) flow spans `continuumM3LeadminerService`, `continuumPlaceReadService`, and `continuumPlaceWriteService`. It is documented in the central architecture dynamic view: `dynamic-place-edit-flow`.
- The [Merge Places](merge-places.md) and [Defrank Place](defrank-place.md) flows also cross into `continuumPlaceWriteService`.
- All flows depend on `continuumControlRoom` for session authentication.
