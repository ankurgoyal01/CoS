---
service: "forex-ng"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Forex NG.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Rate Query (API Lookup)](rate-query.md) | synchronous | Incoming HTTP GET request | Consumer calls `GET /v1/rates/{currency}.json`; service reads rate JSON from S3 and returns it |
| [Scheduled Rate Refresh](scheduled-rate-refresh.md) | scheduled | Kubernetes cron job (`*/11 * * * *`) or Quartz cron (`0 */5 * * * ?`) | Periodic refresh of all 46 currency rates from NetSuite, validated and published to S3 |
| [Rate Refresh with Sanity Check](rate-refresh-sanity.md) | batch | Invoked within rate refresh flow | Multi-step staging, sanity validation, and promotion of new rate files in S3 |
| [Manual Rate Refresh (Admin)](manual-rate-refresh.md) | synchronous | `GET /v1/rates/data` admin endpoint or `refresh-rates` CLI command | On-demand rate refresh triggered by an operator or admin caller |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The rate refresh flow spans `continuumForexService` and the external `continuumForexNetsuiteApi` and `continuumForexS3Bucket` containers. This flow is captured in the architecture dynamic view `dynamic-forex-refresh-rates` in the Structurizr workspace at `structurizr/import/forex-ng/architecture/views/dynamics/refresh-rates.dsl`.

See [Architecture Context](../architecture-context.md) for the full relationship map.
