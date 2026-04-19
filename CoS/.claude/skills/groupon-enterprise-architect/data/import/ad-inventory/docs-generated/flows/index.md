---
service: "ad-inventory"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Ad Inventory.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Ad Placement Serving](ad-placement-serving.md) | synchronous | Inbound HTTP GET from Groupon frontend | Resolves eligible audiences for a placement request and returns ad content |
| [Sponsored Listing Click Tracking](sponsored-listing-click-tracking.md) | synchronous | Inbound HTTP GET from Groupon frontend | Records a sponsored listing click and forwards it to CitrusAd |
| [Audience Lifecycle Management](audience-lifecycle-management.md) | synchronous | Inbound HTTP API call | Creates, validates, and deletes audience definitions backed by AMS and GCS bloom filters |
| [DFP Report Ingestion Pipeline](dfp-report-ingestion-pipeline.md) | batch | Quartz scheduler (cron) | Downloads ad performance reports from Google Ad Manager, validates, and loads into Hive |
| [Audience Cache Warm-Up](audience-cache-warm-up.md) | scheduled | Quartz scheduler (cron) | Loads audience bloom filters from GCS and MySQL into Redis and in-memory caches |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The **DFP Report Ingestion Pipeline** spans multiple systems:
- `continuumAdInventoryService` → `googleAdManager` (DFP) → `continuumAdInventoryGcs` → `continuumAdInventoryHive`
- Architecture dynamic view: `dynamic-ad-inventory-reporting-ingestion-flow`

The **Audience Lifecycle Management** flow spans:
- `continuumAdInventoryService` → `continuumAudienceManagementService` (AMS) → `continuumAdInventoryGcs` → `continuumAdInventoryMySQL`
