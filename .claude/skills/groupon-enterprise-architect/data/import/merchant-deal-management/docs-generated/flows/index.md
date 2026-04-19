---
service: "merchant-deal-management"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Merchant Deal Management.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Synchronous Deal Write](deal-write-synchronous.md) | synchronous | Inbound HTTP request | API receives, validates, and orchestrates a deal write across downstream Continuum services |
| [Async Write Dispatch](async-write-dispatch.md) | asynchronous | API enqueues Resque job | API delegates long-running write work to the worker via Resque |
| [Worker Write Execution](worker-write-execution.md) | asynchronous | Resque job dequeue | Worker executes write request, calls downstream services, and persists result and history |
| [Deal Catalog Synchronization](deal-catalog-sync.md) | synchronous | Deal write request | API or worker synchronizes deal entity with the Deal Catalog Service |
| [Salesforce Deal Sync](salesforce-deal-sync.md) | asynchronous | Deal write or update | API writes synchronously; worker handles async Salesforce record synchronization |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The deal write flows span multiple Continuum services. The `continuumDealManagementApi` coordinates writes across up to 11 internal services and Salesforce for a single deal write operation. The `continuumDealManagementApiWorker` handles the asynchronous tail of those flows involving the deal catalog and Salesforce. Cross-service dynamic views are tracked in the central architecture model under `continuumSystem`.
