---
service: "vespa-indexer"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

Vespa Indexer depends on four external systems and one internal Groupon service. All dependencies are write-side (the service pushes to Vespa) or read-side (the service pulls from GCS, BigQuery, MDS REST, and MessageBus). There are no synchronous callers of this service's core logic — only Kubernetes CronJobs and operators use the HTTP trigger endpoints.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Vespa Cluster | HTTP (pyvespa) | Primary write target — all deal option documents are indexed here | yes | `vespaCluster` |
| Google Cloud Storage | GCS SDK | Reads gzipped MDS feed files containing deal UUIDs | yes | `cloudPlatform` |
| Google BigQuery | BigQuery SDK | Reads ML ranking feature tables | yes | `bigQuery` |
| Groupon MessageBus | STOMP | Consumes real-time deal change events | yes | `messageBus` |

### Vespa Cluster Detail

- **Protocol**: HTTP via `pyvespa` 0.61.0
- **Base URL / SDK**: Configured via `VESPA_URL` (default: `http://localhost:8080`)
- **Auth**: Optional bearer token via `VESPA_TOKEN`; optional mTLS via `VESPA_CERT_PATH` / `VESPA_KEY_PATH`
- **Purpose**: Index full deal option documents and perform partial feature updates; health check via `is_healthy()`
- **Failure mode**: Indexing tasks log exceptions and continue; the background consumer NACKs failed messages for MessageBus redelivery
- **Circuit breaker**: No evidence found in codebase

### Google Cloud Storage Detail

- **Protocol**: GCS Python SDK (`google-cloud-storage` 2.10.0)
- **Base URL / SDK**: GCS bucket configured via `GCP_BUCKET_NAME` (default: `test-bucket`); project via `GCP_PROJECT_ID`
- **Auth**: Service account credentials via `GCP_CREDENTIALS_PATH` or Application Default Credentials
- **Purpose**: Download gzipped MDS feed file (`mds_feeds/vespa_ai_US.gz`, configurable via `MDS_FEED_FILE_NAME`) to extract deal UUIDs for scheduled refresh
- **Failure mode**: Feed download failure aborts the scheduled deal refresh job; error is logged and job ends
- **Circuit breaker**: No evidence found in codebase

### Google BigQuery Detail

- **Protocol**: BigQuery Python SDK (`google-cloud-bigquery` 3.13.0)
- **Base URL / SDK**: Project configured via `BIGQUERY_PROJECT_ID`; optional credentials via `BIGQUERY_CREDENTIALS_PATH`
- **Auth**: Service account or Application Default Credentials
- **Purpose**: Query deal feature table, option feature table, distance bucket table, and category feature table to enrich Vespa documents with ML ranking signals
- **Failure mode**: Feature refresh job failure is logged; deal documents already indexed may have stale or absent feature values
- **Circuit breaker**: No evidence found in codebase

### Groupon MessageBus Detail

- **Protocol**: STOMP (`stomp.py` 8.2.0)
- **Base URL / SDK**: Host via `MBUS_HOST` (default: `localhost`); port via `MBUS_PORT` (default: `61613`); SSL via `MBUS_USE_SSL`
- **Auth**: Username via `MBUS_USERNAME`; password via `MBUS_PASSWORD`
- **Purpose**: Subscribe to `jms.topic.mars.mds.genericchange` for real-time deal create/update events; ACK on success, NACK on failure
- **Failure mode**: NACK triggers MessageBus broker redelivery; connection loss causes background consumer loop to restart
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MDS REST API (`continuumMarketingDealService`) | REST (httpx 0.25.2) | Fetches full deal and option data by UUID during scheduled refresh and on-demand indexing | `continuumMarketingDealService` |

### MDS REST API Detail

- **Protocol**: REST over HTTPS
- **Base URL**: Configured via `MDS_REST_API_URL` (default: `https://mds.groupondev.com`); client ID via `MDS_REST_CLIENT_ID` (default: `vespa-indexer`)
- **Auth**: Client ID passed as query parameter (`client=vespa-indexer`)
- **Endpoint pattern**: `GET /deals?client=<id>&uuids=<uuids>&fields=<fields>` — up to `MDS_MAX_UUIDS_PER_REQUEST` (default 50) UUIDs per request
- **Purpose**: Source of authoritative deal and option records; used during full refresh and manual indexing
- **Timeout**: `MDS_REST_TIMEOUT_SECONDS` (default: 30 seconds)
- **Retries**: `MDS_REST_MAX_RETRIES` (default: 3)
- **Failure mode**: Failed batches are logged; remaining batches continue processing

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Kubernetes CronJobs (`continuumVespaIndexerCronJobs`) | HTTP POST | Trigger deal refresh (`/scheduler/refresh-deals`) and feature refresh (`/scheduler/refresh-features`) on schedule |
| Operators / developers | HTTP POST | Trigger on-demand indexing via `/indexing/index-deals` |

> Upstream consumers of the Vespa search index itself (i.e., services querying Vespa for search results) are tracked in the central architecture model and are out of scope for this service's documentation.

## Dependency Health

- Vespa health is checked on demand via `GET /grpn/health`, which calls `vespa_client.is_healthy()`.
- GCS, BigQuery, and MessageBus dependencies have no built-in health check probes in this service; their availability is inferred from successful job execution.
- Prometheus metrics track MessageBus messages received, processed, acked, and nacked; Vespa indexing duration; and MDS REST API call counts. See [Runbook](runbook.md) for monitoring details.
