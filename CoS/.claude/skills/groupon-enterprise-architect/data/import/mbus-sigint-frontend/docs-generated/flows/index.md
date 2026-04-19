---
service: "mbus-sigint-frontend"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for MBus Sigint Frontend.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [SPA Bootstrap](spa-bootstrap.md) | synchronous | User navigates to the portal URL | Browser loads the Node.js server, receives the SPA shell, then fetches app config, session info, clusters, and service names in parallel |
| [Configuration Change Request](configuration-change-request.md) | synchronous | User submits a new MessageBus configuration change request form | SPA collects form data, posts to the proxy, which forwards to `mbus-sigint-config`; the request enters a pending approval queue |
| [Configuration Browse](configuration-browse.md) | synchronous | User selects a cluster and browses its current configuration | SPA fetches cluster config, destination details, credential details, and divert details via the API proxy |
| [Admin Deploy Schedule Update](admin-deploy-schedule-update.md) | synchronous | Admin user edits a deploy schedule via the Admin module | SPA fetches the existing schedule, renders an edit form, and PUTs the updated schedule via the proxy |
| [Change Request Approval](change-request-approval.md) | synchronous | Admin user approves or rejects a pending configuration change request | SPA fetches the pending request details, admin takes action, SPA PUTs the approval decision via the proxy |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Structurizr dynamic view `dynamic-configuration-change-flow` captures the cross-service sequence where `continuumMbusSigintFrontend` proxies change request APIs to `continuumMbusSigintConfigurationService` and loads service metadata from `servicePortal`.

See [Configuration Change Request](configuration-change-request.md) for the detailed step-by-step flow.
