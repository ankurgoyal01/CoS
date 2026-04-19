---
service: "lgtm"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "tempoTraceStorage"
    type: "gcs"
    purpose: "Durable block storage for distributed trace data per environment and region"
---

# Data Stores

## Overview

LGTM's primary data store is Google Cloud Storage (GCS), used by Grafana Tempo as its persistent trace block backend. Tempo writes and compacts trace blocks to GCS buckets, with one bucket per deployment environment and region. There is no relational database, cache, or other data store owned by this service.

## Stores

### Tempo Trace Storage — GCS (`tempoTraceStorage`)

| Property | Value |
|----------|-------|
| Type | gcs (Google Cloud Storage) |
| Architecture ref | `tempoTraceStorage` |
| Purpose | Persistent block storage for distributed trace data written and queried by Grafana Tempo components |
| Ownership | owned |
| Migrations path | Not applicable (object store, no schema migrations) |

#### GCS Buckets by Environment

| Bucket Name | Environment | Region |
|-------------|-------------|--------|
| `con-stable-usc1-tempo` | staging | us-central1 |
| `con-stable-euw1-tempo-emea` | staging | europe-west1 |
| `con-prod-usc1-tempo` | production | us-central1 |
| `con-grp-tempo-prod-9957` | production | europe-west1 |

#### Key Entities

| Entity / Object Type | Purpose | Key Fields |
|----------------------|---------|-----------|
| Trace blocks | Immutable compressed trace data blocks written by Tempo ingesters and compacted by the compactor | block ID, trace IDs, start/end time |
| Block metadata | Index metadata for locating traces within blocks | block ID, tenant, time range |

#### Access Patterns

- **Read**: Grafana Tempo querier and query-frontend read trace blocks from GCS when serving search and trace detail requests initiated by Grafana dashboards.
- **Write**: Tempo ingesters flush completed trace blocks to GCS after the block time window closes. The compactor reads and rewrites blocks to GCS during compaction.
- **Indexes**: Tempo maintains an in-memory and GCS-backed block index; individual block metadata files are stored alongside blocks in GCS.

#### GCS Service Account Authentication

| Environment | GCP Service Account |
|-------------|---------------------|
| staging | `con-sa-tempo@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com` |
| production | `con-sa-tempo@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com` |

Authentication is configured via GKE Workload Identity using the `iam.gke.io/gcp-service-account` annotation on the Tempo Kubernetes service account.

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-memory cache layer is explicitly configured in the Helm values for this deployment.

## Data Flows

Instrumented workloads push OTLP traces to the OTel Collector, which forwards them via OTLP/HTTP to the Tempo Gateway. The Tempo distributor fans out spans to ingesters, which hold data in memory until a block is sealed. Sealed blocks are flushed to the GCS bucket for the relevant environment and region. The Tempo compactor periodically merges and compacts blocks in GCS to optimise storage and query efficiency. When Grafana queries for traces, the Tempo query-frontend routes requests to the querier, which fetches relevant blocks from GCS and returns spans.
