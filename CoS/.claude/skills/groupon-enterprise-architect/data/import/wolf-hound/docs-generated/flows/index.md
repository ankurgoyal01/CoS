---
service: "wolf-hound"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Wolfhound Editor UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Editorial Publish](editorial-publish.md) | synchronous | Editor clicks Publish in the workboard UI | An editor-initiated publish action flows through the BFF routing and service adapter layers to `continuumWolfhoundApi` |
| [Page Create and Save](page-create-save.md) | synchronous | Editor creates or saves an editorial page | Editor submits a new or updated page; the BFF validates the request and writes to `continuumWolfhoundApi` |
| [Template Management](template-management.md) | synchronous | Editor creates, updates, or deletes a template | Template CRUD operations routed through BFF to `continuumWolfhoundApi` |
| [Schedule Management](schedule-management.md) | synchronous | Editor creates or modifies a publish schedule | Schedule entry CRUD routed through BFF to `continuumWolfhoundApi`; scheduling engine triggers publish at the configured time |
| [Editor Page Load (Data Aggregation)](editor-page-load.md) | synchronous | Editor opens the workboard or an editorial page | BFF aggregates data from multiple services (Wolfhound API, MECS, Deals, Clusters, Relevance, Bhuvan) to compose the editor view |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The **Editorial Publish** flow is documented as a Structurizr dynamic view: `dynamic-editorial-publish-flow`. It spans `continuumWolfHound` and `continuumWolfhoundApi`.
- The **Editor Page Load** flow spans `continuumWolfHound` and all eight downstream Continuum service containers.
