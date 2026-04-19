---
service: "data_pipelines_glossary"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Data Pipelines Glossary.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Repository Discovery](repository-discovery.md) | synchronous | User navigates to the glossary site | Engineer locates the correct data pipeline workflow repository by browsing or searching the glossary index |
| [Content Update](content-update.md) | synchronous | Pull request merged to main branch | A content contributor updates glossary entries or navigation links and the static site is republished |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

> No evidence found in codebase. The Data Pipelines Glossary has no declared runtime relationships with other services in the architecture DSL. Cross-service navigation flows are editorial (hyperlinks) rather than runtime integrations. Dynamic views are not defined (`// No dynamic views defined.`).
