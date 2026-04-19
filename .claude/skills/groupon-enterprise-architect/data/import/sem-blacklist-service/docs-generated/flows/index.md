---
service: "sem-blacklist-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for SEM Blacklist Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Denylist Entry Read](denylist-read.md) | synchronous | API call (`GET /denylist` or `GET /blacklist`) | Consumer fetches denylist entries filtered by client, country, and optional search engine / program / channel |
| [Denylist Entry Write](denylist-write.md) | synchronous | API call (`POST /denylist` or `DELETE /denylist`) | Operator adds or soft-deletes a denylist entry via REST API |
| [Asana Task Processing](asana-task-processing.md) | scheduled | Quartz job (`DenylistAsanaTaskProcessingJob`) or `POST /denylist/process-asana-tasks` | Polls Asana section for open tasks, validates and applies add/delete operations to the denylist |
| [Google Sheets Blacklist Refresh](gdoc-blacklist-refresh.md) | scheduled | Quartz job (`GDocRefreshBlacklistJob`) | Reads PLA blacklist data from Google Sheets and performs a full transactional refresh of the database |
| [Batch Denylist Read](denylist-batch-read.md) | synchronous | API call (`GET /denylist/batch` or `GET /denylist/{country}/{client}`) | Consumer fetches denylist entries for multiple countries or within a specific date range |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The [Asana Task Processing](asana-task-processing.md) flow spans `continuumSemBlacklistService` and the external Asana API. The architecture dynamic view is referenced as `dynamic-asana-task-processing` (defined in `architecture/views/dynamics/asana-task-processing.dsl`).
- The [Google Sheets Blacklist Refresh](gdoc-blacklist-refresh.md) flow spans `continuumSemBlacklistService` and the external Google Sheets API stub `googleSheetsApi`.
