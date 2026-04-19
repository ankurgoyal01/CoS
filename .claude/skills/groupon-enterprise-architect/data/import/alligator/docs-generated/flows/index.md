---
service: "alligator"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Alligator.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deck Card Retrieval](deck-card-retrieval.md) | synchronous | GET /cardatron/cards | Assembles and returns decorated card set for a deck UUID or card permalink |
| [Deck Config (V5)](deck-config-v5.md) | synchronous | GET /v5/cardatron/cards/deckconfig | Returns possible card configurations for a deck; includes Finch experiment bucketing |
| [Card Decoration](card-decoration.md) | synchronous | GET /v2/cardatron/cards/decorate or GET /v5/cardatron/cards/decorate | Real-time decoration of a single card against its template |
| [Cache Reload](cache-reload.md) | scheduled | Spring scheduler (cacheReloadWorker) | Periodic background refresh of all deck/card/template/client/polygon/permalink data into Redis |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Deck Config (V5)** flow spans `continuumAlligatorService`, `externalCardatronCampaignService` (via cache), `externalFinchService`, `continuumRelevanceApi`, `apiProxy`, and `continuumAudienceManagementService`. See [Deck Config (V5)](deck-config-v5.md).
- The **Cache Reload** flow spans `continuumAlligatorService` and `externalCardatronCampaignService` pulling all catalog data. See [Cache Reload](cache-reload.md).
- Architecture dynamic views for this service: no dynamic views are modeled in the current architecture DSL (`views/dynamics.dsl` contains no views).
