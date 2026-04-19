---
service: "arbitration-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Arbitration Service (ABS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Best-For Selection](best-for-selection.md) | synchronous | `POST /best-for` API call | Filters and ranks eligible campaigns for a user using eligibility rules, send history, frequency caps, and real-time counters |
| [Arbitration Decision](arbitration-decision.md) | synchronous | `POST /arbitrate` API call | Applies quota enforcement and winner selection on best-for output; persists send record; returns single winning campaign |
| [Campaign Revoke](campaign-revoke.md) | synchronous | `POST /revoke` API call | Marks a previously committed send as revoked in Cassandra; adjusts Redis counters |
| [Delivery Rule Management](delivery-rule-management.md) | synchronous | Admin CRUD on `/delivery-rules` | Creates, updates, or deletes delivery rules in PostgreSQL; triggers Jira approval workflow ticket |
| [Experiment Config Refresh](experiment-config-refresh.md) | synchronous | `POST /experiment-config/refresh` API call or startup | Re-fetches Optimizely experiment definitions and updates in-memory cache |
| [Startup Cache Loading](startup-cache-loading.md) | scheduled | Service startup | Preloads delivery rules from PostgreSQL and experiment config from Optimizely into in-memory cache |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Arbitration Decision](arbitration-decision.md) and [Best-For Selection](best-for-selection.md) flows are invoked by `marketingDeliveryClients` as part of the broader campaign delivery pipeline. The central architecture dynamic view `arbitrationDecisionFlow` is defined but currently disabled (empty view, all references commented out).
- The [Delivery Rule Management](delivery-rule-management.md) flow spans `continuumArbitrationService` and `continuumJiraService` for approval workflow creation.
