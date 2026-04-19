---
service: "metro-ui"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Metro UI — Merchant Self-Service Deal Creation UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Creation and Draft](deal-creation-and-draft.md) | synchronous | Merchant navigates to `/merchant/center/draft` | Merchant creates or resumes a deal draft; Metro UI orchestrates deal data reads/writes via Deal Management API |
| [AI Content Generation](ai-content-generation.md) | synchronous | Merchant clicks AI content generation action in the deal creation UI | Metro UI proxies an AI content generation request to the GenAI service and returns generated copy to the browser |
| [Deal Publication](deal-publication.md) | synchronous | Merchant submits a completed deal for publication | Metro UI coordinates deal eligibility checks and publication state transitions via Deal Management API and Marketing Deal Service |
| [Location and Service Area Management](location-service-area-management.md) | synchronous | Merchant adds or modifies location/service area data in the deal creation UI | Metro UI fetches geo autocomplete suggestions and merchant place records, then persists location changes to the deal via Deal Management API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Deal Creation and Draft flow is documented as a cross-service dynamic view in the central architecture model:

- Architecture dynamic view: `dynamic-metro-ui-draft-edit-flow` — covers `continuumMetroUiService` interactions with `apiProxy`, `continuumDealManagementApi`, `continuumGeoDetailsService`, `continuumM3PlacesService`, and `googleTagManager`
