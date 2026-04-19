---
service: "vespa-indexer"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Vespa Indexer.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Real-Time Deal Update Indexing](real-time-deal-update.md) | event-driven | MessageBus deal change event on `jms.topic.mars.mds.genericchange` | Consumes STOMP messages from MessageBus, transforms deal option data, and upserts documents in Vespa |
| [Scheduled Deal Refresh from Feed](scheduled-deal-refresh.md) | scheduled | Kubernetes CronJob daily at 10:00 UTC | Streams deal UUIDs from GCS MDS feed, fetches full deal data from MDS REST API, enriches with BigQuery features, and indexes all options to Vespa |
| [Scheduled ML Feature Refresh](scheduled-feature-refresh.md) | scheduled | Kubernetes CronJob at 04:00, 16:00, 22:00 UTC | Queries BigQuery feature tables and performs partial updates on existing Vespa documents with latest ML ranking signals |
| [On-Demand Deal Indexing by UUID](on-demand-indexing.md) | synchronous | `POST /indexing/index-deals` API call | Accepts up to 50 deal UUIDs, fetches data from MDS REST API, and indexes options to Vespa in the background |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

These flows span multiple services and are documented in the central architecture dynamic views:

- **Real-time deal update**: `dynamic-vespa-indexer-deal-updates` — spans `messageBus`, `continuumVespaIndexerService`, `bigQuery`, `vespaCluster`
- **Scheduled deal refresh**: `dynamic-vespa-indexer-refresh-from-feed` — spans `continuumVespaIndexerCronJobs`, `continuumVespaIndexerService`, `cloudPlatform`, `continuumMarketingDealService`, `vespaCluster`
