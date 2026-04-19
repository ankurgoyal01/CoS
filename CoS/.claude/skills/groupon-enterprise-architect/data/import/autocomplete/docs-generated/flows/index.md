---
service: "autocomplete"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Autocomplete.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Autocomplete Search Request](autocomplete-search-request.md) | synchronous | HTTP GET from Consumer App | Receives a query, normalizes request, orchestrates suggestion and recommendation generators, returns combined cards response |
| [Health Check Flow](health-check-flow.md) | synchronous | HTTP GET from monitoring or load balancer | Validates DataBreakers client connectivity and reports health status |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The autocomplete search request flow spans multiple external systems. Its representative dynamic view is `autocompleteRequestRuntimeFlow` defined in `architecture/views/dynamics/autocomplete-request-flow.dsl`. The full cross-service path (Consumer Apps -> autocomplete -> DataBreakers / SuggestApp / Finch) is partially commented out in the dynamic view due to stub-only resolution in the federated model; see the central architecture model in `continuumSystem` for the complete picture.
