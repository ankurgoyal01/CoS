---
service: "subscription_flow"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Subscription Flow.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Subscription Modal Render](subscription-modal-render.md) | synchronous | HTTP GET request from web client or upstream aggregation layer | Client requests subscription modal; router dispatches to controller; config loaded; renderer pipeline generates HTML |
| [Config and Experiment Loading](config-and-experiment-loading.md) | synchronous | Service bootstrap or scheduled config refresh | Bootstrap initialises; Config Loader fetches GConfig; experiments resolved; client bindings set |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [Subscription Modal Render](subscription-modal-render.md) flow spans `continuumSubscriptionFlowService`, `continuumApiLazloService`, and `grouponV2Api_2d1e`.
- The [Config and Experiment Loading](config-and-experiment-loading.md) flow spans `continuumSubscriptionFlowService` and `gconfigService_4b3a`.
