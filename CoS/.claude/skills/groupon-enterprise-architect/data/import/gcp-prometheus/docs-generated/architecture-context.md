---
service: "gcp-prometheus"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "prometheusServer"
    - "prometheusConveyor"
    - "prometheusBlackboxExporter"
    - "grafana"
    - "thanosReceive"
    - "thanosQuery"
    - "thanosQueryFrontend"
    - "thanosStoreGateway"
    - "thanosCompact"
    - "thanosObjectStorage"
---

# Architecture Context

## System Context

`gcp-prometheus` is part of the `continuumSystem` (Groupon's Continuum Platform) and provides the observability layer for GCP-hosted Kubernetes workloads. Prometheus scrapes metrics from cluster targets, ships them via remote-write to Thanos Receive, which persists blocks to GCS. Engineers and SRE teams consume metrics through Grafana dashboards backed by Thanos Query Frontend. The system runs in two GCP regions (`us-central1` and `europe-west1`), supporting production and staging environments.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Prometheus Server | `prometheusServer` | Container | Prometheus | — | Scrapes metrics targets and stores time-series data for short-term query and alerting |
| Prometheus Conveyor | `prometheusConveyor` | Container | Prometheus | — | Federates and relays metrics between clusters for centralized scraping |
| Prometheus Blackbox Exporter | `prometheusBlackboxExporter` | Container | Prometheus Exporter | — | Runs blackbox probes and exposes probe metrics |
| Grafana | `grafana` | Container | Grafana | 10.4.1 / 11.4.0 | Visualization and dashboarding for metrics and alerts |
| Thanos Receive | `thanosReceive` | Container | Thanos | v0.30.2 | Ingests remote-write metrics and exposes recent data via Store API (5 replicas, 2000Gi PVC each) |
| Thanos Query | `thanosQuery` | Container | Thanos | v0.31.0 | Aggregates queries across store gateways and receives (10 replicas) |
| Thanos Query Frontend | `thanosQueryFrontend` | Container | Thanos | — | Query caching and splitting for Thanos queries |
| Thanos Store Gateway | `thanosStoreGateway` | Container | Thanos | v0.31.0 / v0.32.2 | Serves historical blocks from GCS object storage (3 shards x 3 replicas) |
| Thanos Compact | `thanosCompact` | Container | Thanos | v0.30.2 | Compacts and down-samples metric blocks in GCS (1 replica) |
| Thanos Object Storage | `thanosObjectStorage` | Datastore | GCS Bucket | — | Long-term storage for Prometheus/Thanos metric blocks |

## Components by Container

### Prometheus Server (`prometheusServer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Scraper (`promScraper`) | Collects metrics from targets and exporters | Prometheus |
| TSDB (`promTsdb`) | Local time-series database for short-term storage | Prometheus |
| HTTP API (`promHttpApi`) | Serves queries and metadata to internal consumers | Prometheus |
| Remote Write (`promRemoteWriter`) | Ships samples to Thanos Receive via HTTP | Prometheus |

### Prometheus Conveyor (`prometheusConveyor`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Federation Scraper (`conveyorFederationScraper`) | Relays and federates metrics to the central Prometheus server | Prometheus |

### Prometheus Blackbox Exporter (`prometheusBlackboxExporter`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Probe Handler (`blackboxProbeHandler`) | Executes blackbox probes and exposes results | Prometheus Blackbox Exporter |

### Grafana (`grafana`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Dashboard UI (`grafanaDashboardUi`) | Web interface for dashboards and exploration | Grafana |
| Datasource Proxy (`grafanaDatasourceProxy`) | Proxies and manages datasource queries to Thanos Query Frontend | Grafana |

### Thanos Receive (`thanosReceive`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Receiver (`thanosReceiveReceiver`) | Accepts remote-write samples from Prometheus | Thanos |
| Store API (`thanosReceiveStoreApi`) | Serves recent blocks to Thanos Query via gRPC | Thanos |

### Thanos Query (`thanosQuery`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Query Engine (`thanosQueryEngine`) | Aggregates results across stores and receives | Thanos |
| Store API Client (`thanosQueryStoreApiClient`) | Executes gRPC calls to store gateways and receives | Thanos |

### Thanos Query Frontend (`thanosQueryFrontend`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Query Frontend (`thanosQueryFrontendService`) | Splits, caches, and forwards queries to Thanos Query | Thanos |

### Thanos Store Gateway (`thanosStoreGateway`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Store API (`thanosStoreGatewayStoreApi`) | Serves historical blocks to Thanos Query via gRPC | Thanos |
| Object Storage Reader (`thanosStoreGatewayObjectStorageReader`) | Loads blocks from GCS object storage | Thanos |

### Thanos Compact (`thanosCompact`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Compactor (`thanosCompactCompactor`) | Compacts and down-samples metric blocks | Thanos |
| Object Storage Writer (`thanosCompactObjectStorageWriter`) | Writes compacted blocks back to GCS | Thanos |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `promScraper` | `blackboxProbeHandler` | Scrapes probe results | HTTP |
| `promRemoteWriter` | `thanosReceiveReceiver` | Remote writes samples | HTTP |
| `prometheusConveyor` | `prometheusServer` | Federates metrics | HTTP |
| `thanosReceive` | `thanosObjectStorage` | Writes metric blocks | GCS API |
| `thanosCompact` | `thanosObjectStorage` | Compacts blocks | GCS API |
| `thanosStoreGateway` | `thanosObjectStorage` | Reads historical blocks | GCS API |
| `thanosQueryFrontendService` | `thanosQueryEngine` | Forwards queries | HTTP |
| `grafanaDatasourceProxy` | `thanosQueryFrontendService` | Runs dashboard queries | HTTP |
| `thanosQueryEngine` | `thanosStoreGatewayStoreApi` | Fetches historical blocks | gRPC |
| `thanosQueryEngine` | `thanosReceiveStoreApi` | Fetches recent blocks | gRPC |

## Architecture Diagram References

- System context: `contexts-gcp-prometheus`
- Container: `containers-gcp-prometheus`
- Component: `components-gcp-prometheus`
