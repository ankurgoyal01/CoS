---
service: "place-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the M3 Place Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Place Read by ID](place-read-by-id.md) | synchronous | HTTP GET `/v2.0/places/{id}` or `/v3.0/places/{id}` | Retrieves a single place record with cache-first lookup, Postgres fallback, and optional merchant enrichment |
| [Place Search](place-search.md) | synchronous | HTTP GET `/v2.0/places/` or `/v3.0/places` | Searches and filters places via OpenSearch with optional geo-radius, full-text, and multi-criteria filters |
| [Place Write / Create](place-write.md) | synchronous | HTTP POST `/placewriteservice/v3.0/places` | Creates or updates a place record via Voltron workflow pipeline and updates OpenSearch index |
| [Google Place Candidate Lookup](google-place-lookup.md) | synchronous | HTTP GET `/v2.0/places/{id}/googleplace` | Enriches a place with Google Maps candidates using cache-first lookup |
| [Salesforce Place Synchronization](salesforce-sync.md) | event-driven | Salesforce sync event via message bus | Synchronizes Salesforce place records into the M3 place store |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [Place Read by ID](place-read-by-id.md) flow spans `continuumM3PlacesService`, `continuumPlacesServiceRedis`, `continuumPlacesServicePostgres`, and `continuumM3MerchantService` — referenced in architecture dynamic view `dynamic-place-read-flow`.
- The [Place Write / Create](place-write.md) flow spans `continuumM3PlacesService`, `continuumPlacesServicePostgres`, `continuumPlacesServiceOpenSearch`, and Voltron Platform.
- The [Salesforce Place Synchronization](salesforce-sync.md) flow originates externally from Salesforce and terminates in place record creation/update within this service's data stores.
