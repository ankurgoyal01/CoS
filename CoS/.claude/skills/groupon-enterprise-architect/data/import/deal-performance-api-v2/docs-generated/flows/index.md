---
service: "deal-performance-api-v2"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Deal Performance API V2.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Performance Metrics Query](deal-performance-metrics-query.md) | synchronous | API call (`POST /getDealPerformanceMetrics`) | Retrieves time-series performance metrics (purchases, views, CLO claims, impressions) for a deal with multi-dimensional grouping |
| [Deal Attribute Metrics Query](deal-attribute-metrics-query.md) | synchronous | API call (`GET /getDealAttributeMetrics`) | Retrieves daily deal attribute data (NOB, NOR, GR, GB, refunds, impressions, etc.) for a deal |
| [Deal Option Performance Metrics Query](deal-option-performance-metrics-query.md) | synchronous | API call (`POST /getDealOptionPerformanceMetrics`) | Retrieves purchases and activations per deal option with configurable grouping |
| [Database Routing and SQL Template Rendering](database-routing-sql-rendering.md) | synchronous | Internal — invoked on every performance metrics request | Selects primary vs. replica DB connection and renders the appropriate StringTemplate4 SQL template |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The architecture dynamic view `dynamic-deal-performance-query-flow` models the core query flow between `continuumDealPerformanceApiV2_dealPerformanceApiV2Resource` and `continuumDealPerformanceApiV2_dealPerformanceDao`. All cross-service data flows are inbound (consumers calling this service's REST API) — this service makes no outbound service calls.
