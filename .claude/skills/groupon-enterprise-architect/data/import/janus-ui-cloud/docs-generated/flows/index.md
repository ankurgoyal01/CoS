---
service: "janus-ui-cloud"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Janus UI Cloud.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [User Request — SPA Load and API Proxy](janus-ui-request-flow.md) | synchronous | User opens browser to Janus UI URL | Browser loads the React SPA from the gateway; subsequent API calls are proxied to the Janus metadata service |
| [Schema Management — Create or Edit Rule](schema-management-flow.md) | synchronous | User submits a create or edit form in the Raw or Canonical Schema module | UI sends a write request through the API proxy to the metadata service to persist a schema definition |
| [Alert Configuration Flow](alert-configuration-flow.md) | synchronous | User registers or updates an alert rule in the Alerts module | UI sends alert create/update payload through the proxy; metadata service stores the alert configuration |
| [Sandbox Query Flow](sandbox-query-flow.md) | synchronous | User submits a test query in the Sandbox or Sample Query module | UI dispatches a query request through the proxy; Janus metadata service evaluates and returns sample output |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The primary cross-service flow is documented in the architecture dynamic view `dynamic-janus-ui-request-flow`. It spans:

- `continuumJanusUiCloudFrontend` — initiates the API call
- `continuumJanusUiCloudGateway` — proxies the request
- `continuumJanusWebCloudService` — fulfils the metadata operation

See [User Request — SPA Load and API Proxy](janus-ui-request-flow.md) for the detailed step-by-step flow.
