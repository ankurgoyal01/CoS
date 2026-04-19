---
service: "proximity-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Proximity UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Application Startup and Auth Gate](app-startup-auth-gate.md) | synchronous | Application load in browser | Fetches current user and user allowlist; routes to Permission or Home screen |
| [Create Hotzone (Event-based)](create-hotzone.md) | synchronous | Administrator submits create hotzone form | Validates form, builds hotzone payload, POSTs to proxy API, relays to Hotzone API |
| [Browse and Search Hotzones](browse-hotzones.md) | synchronous | Administrator opens Summary view | Fetches paginated hotzone list via server-side DataTables browse endpoint |
| [Create Campaign (Deal-based)](create-campaign.md) | synchronous | Administrator submits create campaign form | Validates form, builds campaign payload, POSTs to proxy API, relays to Hotzone API |
| [Delete Hotzone](delete-hotzone.md) | synchronous | Administrator submits delete hotzone form | Sends DELETE request via proxy API to remove a hotzone by ID |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The "Create Hotzone" flow is documented as a Structurizr dynamic view: `dynamic-proximity-create-hotzone-flow`. This view spans `administrator`, `continuumProximityUi`, and `continuumProximityHotzoneApi` within the `continuumSystem`. All flows in this service follow the same pattern of: administrator browser action -> Vue SPA AJAX call -> Express proxy -> `continuumProximityHotzoneApi`.
