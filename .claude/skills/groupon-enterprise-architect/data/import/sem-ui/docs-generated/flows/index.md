---
service: "sem-ui"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for SEM Admin UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Keyword Management](keyword-management.md) | synchronous | SEM operator action on `/keyword-manager` | Operator reads and modifies keyword assignments for a deal permalink via the SEM Keywords Service proxy |
| [Denylist Management](denylist-management.md) | synchronous | SEM operator action on `/denylisting` | Operator adds or removes keyword denylist entries via the SEM Blacklist Service proxy |
| [Attribution Analysis](attribution-analysis.md) | synchronous | SEM operator action on `/attribution-lens` | Operator retrieves and reviews order attribution data via the GPN Data API proxy |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Keyword Management** traverses `continuumSemUiWebApp` -> `semKeywordsService` (stub — not in federated model)
- **Denylist Management** traverses `continuumSemUiWebApp` -> `continuumSemBlacklistService` (modeled in central architecture)
- **Attribution Analysis** traverses `continuumSemUiWebApp` -> `gpnDataApi` (stub — not in federated model)
