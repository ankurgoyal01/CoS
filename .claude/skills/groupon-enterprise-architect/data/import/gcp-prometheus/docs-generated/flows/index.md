---
service: "gcp-prometheus"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Thanos-Prometheus GCP.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Metric Scraping and Remote Write](metric-scraping-remote-write.md) | synchronous | Prometheus scrape interval | Prometheus scrapes targets, appends to local TSDB, and remote-writes to Thanos Receive |
| [Metric Federation via Conveyor](metric-federation-conveyor.md) | synchronous | Prometheus scrape interval | Prometheus Conveyor federates metrics from upstream Prometheus instances into central server |
| [Long-Term Block Storage to GCS](block-storage-gcs.md) | asynchronous | Thanos Receive TSDB flush | Thanos Receive seals and uploads metric blocks to GCS for long-term retention |
| [Block Compaction and Downsampling](block-compaction-downsampling.md) | scheduled | Continuous background loop | Thanos Compact reads, deduplicates, compacts, and down-samples blocks in GCS |
| [Dashboard Query Flow](dashboard-query-flow.md) | synchronous | User dashboard request in Grafana | Grafana queries Thanos Query Frontend, which fans out to Store Gateway and Receive |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |
| Continuous background | 1 |

## Cross-Service Flows

- The [Dashboard Query Flow](dashboard-query-flow.md) spans `grafana`, `thanosQueryFrontend`, `thanosQuery`, `thanosStoreGateway`, and `thanosReceive`.
- The [Long-Term Block Storage to GCS](block-storage-gcs.md) flow spans `thanosReceive` and `thanosObjectStorage`.
- The [Block Compaction and Downsampling](block-compaction-downsampling.md) flow spans `thanosCompact` and `thanosObjectStorage`.
