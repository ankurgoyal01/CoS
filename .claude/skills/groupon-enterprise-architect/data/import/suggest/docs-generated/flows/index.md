---
service: "suggest"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Suggest service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Suggestion Request](suggestion-request.md) | synchronous | `GET /suggestions` HTTP request | Receives a partial query and user coordinates; returns ranked query and category suggestions |
| [Query Preprocessing](query-preprocessing.md) | synchronous | `POST /query-preprocessing` HTTP request | Cleans a raw query; applies typo correction, locality detection, radius prediction, adult detection, and category detection |
| [Dictionary Refresh](dictionary-refresh.md) | scheduled | Daily timer (86,400-second interval) | Refreshes in-memory suggestion and ranking dictionaries from BigQuery tables |
| [Service Startup and Initialization](service-startup.md) | scheduled | Pod start / container entrypoint | Loads all in-memory dictionaries from BigQuery and local files; initialises ML models; starts background schedulers |
| [Suggestion Ranking](suggestion-ranking.md) | synchronous | Called internally during suggestion request | Scores candidate suggestions using text-similarity and user-engagement features to produce an ordered ranked list |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The [Suggestion Request](suggestion-request.md) flow terminates at the Suggest service boundary; the MBNXT search client receives the response and applies it to the search UI independently.
- The [Dictionary Refresh](dictionary-refresh.md) flow crosses to Google BigQuery (`bigQuery_9a2f`) for data loading.
- The [Service Startup and Initialization](service-startup.md) flow crosses to the Groupon Division API (`grouponDivisionApi_4f7b`) for GPS coordinate loading.
