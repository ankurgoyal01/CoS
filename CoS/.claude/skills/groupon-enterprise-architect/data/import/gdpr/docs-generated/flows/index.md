---
service: "gdpr"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the GDPR Offboarding Tool.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Web Export Request](web-export-request.md) | synchronous | Agent submits web form (`POST /data`) | Agent-initiated GDPR data export through the browser UI; collects all consumer data categories, packages into ZIP, delivers via HTTP download and email |
| [Token Acquisition](token-acquisition.md) | synchronous | Pre-step before each Lazlo API call | Authenticates with `cs-token-service` to obtain a scoped access token for a specific Lazlo resource |
| [Data Collection Pipeline](data-collection-pipeline.md) | synchronous | Triggered by GDPR Orchestrator after token acquisition | Sequential collection of orders, preferences, subscriptions, UGC reviews, and profile addresses from six internal services |
| [Manual CLI Export](manual-cli-export.md) | synchronous | Operator invokes `./gdpr manual` binary with flags | Command-line-driven GDPR export for operator use; runs the same data collection pipeline as the web flow without HTTP |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The GDPR Manual Export dynamic view (`dynamic-GdprManualExport`) in the central Structurizr workspace documents the relationship between `continuumGdprService` and `continuumConsumerDataService`. The other five downstream dependencies (`cs-token-service`, `api-lazlo`, `global-subscription-service`, `ugc-api-jtier`, `m3-placeread`) are represented as stubs in the federated model because their service repos are not currently federated into the central architecture workspace.
