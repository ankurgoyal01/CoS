---
service: "booster"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Booster — the external SaaS relevance engine provided by Data Breakers, integrated into the Continuum platform via `continuumBoosterService`.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Booster Relevance Request](booster-relevance-request.md) | synchronous | Consumer deal discovery request routed through `apiProxy` and `continuumRelevanceApi` | Describes how a consumer search or discovery request is ranked by calling the Booster external API and returning ordered deal results |
| [Integration Health Monitoring](integration-health-monitoring.md) | event-driven | API contract emits health signals whenever Booster API calls are made | Describes how the `boosterSvc_apiContract` component emits metrics to `boosterSvc_integrationHealth`, and how `boosterSvc_supportRunbook` consumes those signals for incident response |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Booster relevance request flow spans multiple Groupon services:

- `apiProxy` routes consumer requests to `continuumRelevanceApi`
- `continuumRelevanceApi` calls `booster` (external SaaS) for ranked results
- `continuumApiLazloService` also routes proxied search requests through `continuumRelevanceApi`

See the architecture dynamic view: `dynamic-booster-relevance-request`
