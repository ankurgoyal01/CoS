---
service: "hybrid-boundary-ui"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 1
---

# Flows

Process and flow documentation for Hybrid Boundary UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Service Configuration Change](service-config-change.md) | synchronous | Operator submits a configuration change in the UI | End-to-end flow from user login through Okta authentication to service config read/write via Hybrid Boundary API, optionally including PAR request submission |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Service Configuration Change flow spans `continuumHybridBoundaryUi` (browser SPA), Groupon Okta (OIDC identity provider), the Hybrid Boundary API (`/release/v1`), and optionally the PAR Automation API (`/release/par`). The corresponding Structurizr dynamic view (`hybridBoundaryUiChangeFlow`) is currently commented out in the architecture model because all external targets are stub-only.
