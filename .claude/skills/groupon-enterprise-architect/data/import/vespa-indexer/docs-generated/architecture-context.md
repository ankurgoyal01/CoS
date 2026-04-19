---
service: "vespa-indexer"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumVespaIndexerService", "continuumVespaIndexerCronJobs"]
---

# Architecture Context

## System Context

Vespa Indexer sits within the Continuum platform as the write-side bridge between Groupon's deal data systems and the Vespa search cluster. It pulls deal information from three upstream sources — GCS-hosted MDS feed files, the MDS REST API (`continuumMarketingDealService`), and the Groupon MessageBus — and writes normalised, enriched documents into `vespaCluster`. ML feature signals are sourced from `bigQuery` and merged into documents either during full refresh or via a lightweight feature-only scheduled job. Kubernetes CronJobs (`continuumVespaIndexerCronJobs`) trigger the two scheduled refresh workflows by calling HTTP endpoints on the service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Vespa Indexer Service | `continuumVespaIndexerService` | Service | Python/FastAPI | 0.118.0 | FastAPI service that ingests deal and option data from MDS feeds, MDS REST, and MessageBus to index documents in Vespa and refresh ML features |
| Vespa Indexer CronJobs | `continuumVespaIndexerCronJobs` | Scheduled Job | Kubernetes | - | Scheduled jobs that trigger refresh endpoints on the service |

## Components by Container

### Vespa Indexer Service (`continuumVespaIndexerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiApplication` | Application wiring for routes, middleware, and metrics | FastAPI |
| `healthEndpoint` | Health check endpoint for Kubernetes probes | FastAPI route |
| `indexingEndpoints` | Manual indexing of deal UUIDs on demand | FastAPI route |
| `schedulerEndpoints` | CronJob-triggered deal and feature refresh endpoints | FastAPI route |
| `dealUpdateListener` | Background asyncio task that starts and maintains MessageBus consumption | asyncio task |
| `indexDealsByUuidsUseCase` | Fetches deals by UUIDs from MDS REST and indexes their options | Python use case |
| `refreshFromFeedUseCase` | Reads deal UUIDs from GCS feed, fetches from MDS REST, indexes to Vespa | Python use case |
| `refreshFeaturesUseCase` | Streams ML features from BigQuery and partially updates Vespa documents | Python use case |
| `consumeDealUpdatesUseCase` | Consumes deal update events from MessageBus and indexes changes to Vespa | Python use case |
| `searchIndexAdapter` | Implements `SearchIndex` interface using `VespaClient`; transforms and writes documents | Adapter |
| `dealFeedAdapter` | Implements `DealFeedProvider` by streaming GCS gzip feed files line-by-line | Adapter |
| `featureProviderAdapter` | Implements `FeatureProvider` by querying BigQuery feature tables | Adapter |
| `dealUpdateAdapter` | Implements `DealUpdateProvider` by subscribing to MessageBus via STOMP | Adapter |
| `mdsRestAdapter` | Implements `DealProvider` by calling MDS REST API | Adapter |
| `bigQueryDealOptionEnricher` | Enriches deal options with ML feature data from BigQuery | Enricher |
| `vespaClient` | Low-level Vespa HTTP API client (pyvespa) | pyvespa |
| `gcsClient` | Low-level GCS client for streaming feed blobs | google-cloud-storage |
| `bigQueryClient` | Low-level BigQuery client for feature queries | google-cloud-bigquery |
| `mdsRestClient` | HTTP client for MDS REST API calls | httpx |
| `mbusDealUpdateClient` | MessageBus STOMP consumer client with ACK/NACK support | stomp.py |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumVespaIndexerService` | `vespaCluster` | Indexes deal and option documents | HTTP (pyvespa) |
| `continuumVespaIndexerService` | `cloudPlatform` | Reads MDS feed files | GCS SDK |
| `continuumVespaIndexerService` | `bigQuery` | Queries ML feature datasets | BigQuery SDK |
| `continuumVespaIndexerService` | `continuumMarketingDealService` | Fetches deal and option data by UUID | REST (httpx) |
| `continuumVespaIndexerService` | `messageBus` | Consumes deal update messages | STOMP |
| `continuumVespaIndexerCronJobs` | `continuumVespaIndexerService` | Triggers scheduler endpoints | HTTP POST |

## Architecture Diagram References

- Component: `components-vespa-indexer`
- Dynamic view (deal updates): `dynamic-vespa-indexer-deal-updates`
- Dynamic view (refresh from feed): `dynamic-vespa-indexer-refresh-from-feed`
