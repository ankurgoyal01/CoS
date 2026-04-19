---
service: "s2s"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumS2sPostgres"
    type: "postgresql"
    purpose: "Operational store for consent cache, partner click IDs, debug events, grouped purchases, retries, and delayed event tracking"
  - id: "continuumS2sTeradata"
    type: "teradata"
    purpose: "Enterprise data warehouse for customer info backfill and AES retry data"
  - id: "continuumS2sCerebroDb"
    type: "postgresql"
    purpose: "Reference data for country codes and GP ratios"
  - id: "continuumS2sBigQuery"
    type: "bigquery"
    purpose: "Analytical tables for booster ROI, financial metrics, and BI extracts"
---

# Data Stores

## Overview

S2S uses four data stores with distinct roles: a primary operational Postgres database for transient state and caching, a Teradata EDW for customer data backfill, a Cerebro reference Postgres for IV calculation reference data, and BigQuery for analytical financial data used in ROI reporting. The service accesses all stores via JDBI or vendor-specific clients; no store is exclusively owned by S2S — all are shared or external.

## Stores

### S2S Postgres (`continuumS2sPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumS2sPostgres` |
| Purpose | Operational store: consent cache, partner click IDs, debug events, grouped purchases, retries, delayed event tracking, booster history |
| Ownership | owned |
| Migrations path | > No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Consent cache | Caches resolved consent decisions to reduce Consent Service load | customer ID, consent state, TTL |
| Partner click IDs | Stores partner attribution click identifiers for IV/GP computation | partner, click ID, customer ID, timestamp |
| Delayed events | Persists events that failed partner API dispatch for replay | event payload, partner, failure reason, retry count |
| Grouped purchases | Batches grouped purchase events for consent filter processing | group key, event batch, processing state |
| Booster history | Tracks historical booster processing state | deal ID, booster status, updated at |
| MDS retry records | Stores failed MDS API calls for scheduled retry | deal ID, retry payload, failure count |

#### Access Patterns

- **Read**: Consent cache lookups per event; click ID resolution during IV calculation; delayed event replay on schedule
- **Write**: Consent cache population; click ID insertion; delayed event persistence on partner API failure; grouped purchase batch writes
- **Indexes**: > No evidence found of specific index definitions in the architecture model

---

### Teradata EDW (`continuumS2sTeradata`)

| Property | Value |
|----------|-------|
| Type | Teradata |
| Architecture ref | `continuumS2sTeradata` |
| Purpose | Enterprise data warehouse for customer info backfill and AES retry data |
| Ownership | shared |
| Migrations path | > Not applicable — external EDW |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Customer info | Hashed customer PII for partner event enrichment | customer ID, hashed email, hashed phone |
| AES retry data | Records requiring AES-keyed retry processing | event reference, retry metadata |

#### Access Patterns

- **Read**: Batch reads during scheduled Quartz jobs (`/jobs/edw/customerInfo`, `/jobs/edw/aesRetry`) to backfill customer info and process AES retries
- **Write**: > Not applicable — S2S reads from EDW only
- **Indexes**: > Not applicable — EDW query patterns managed by data warehouse team

---

### Cerebro DB (`continuumS2sCerebroDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumS2sCerebroDb` |
| Purpose | Reference data source for country codes and GP ratios used in IV calculations |
| Ownership | shared |
| Migrations path | > Not applicable — reference database owned by another team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Country codes | Maps country identifiers for IV calculation context | country code, country name |
| GP ratios | Gross profit ratios used in IV/GP value computation | deal type, region, GP ratio |

#### Access Patterns

- **Read**: Low-frequency lookups during IV calculation; data likely cached in-process after initial reads
- **Write**: > Not applicable — Cerebro DB is read-only from S2S perspective
- **Indexes**: > No evidence found

---

### BigQuery Financial Tables (`continuumS2sBigQuery`)

| Property | Value |
|----------|-------|
| Type | BigQuery |
| Architecture ref | `continuumS2sBigQuery` |
| Purpose | Analytical tables for booster ROI, financial metrics, and BI extracts |
| Ownership | shared |
| Migrations path | > Not applicable — analytical tables managed externally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Booster ROI tables | Financial performance data for booster campaign ROI computation | deal ID, revenue, cost, ROI |
| Financial metrics | Metrics used for Google Ads automation proposals and Sheets exports | campaign, financial KPIs |

#### Access Patterns

- **Read**: Batch reads by `continuumS2sService_roiDataService` during Google Ads automation jobs and booster datapoint enrichment
- **Write**: > Not applicable — S2S reads from BigQuery only
- **Indexes**: > Not applicable — BigQuery managed externally

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Consent decision cache | In-memory (Cache2k 2.1.1) | Caches consent decisions to reduce per-event Consent Service calls | > No evidence found of specific TTL |
| Partner click ID cache | In-memory + Postgres-backed | Stores partner click identifiers for attribution lookup | > No evidence found of specific TTL |

## Data Flows

- Janus Kafka events trigger consent and IV enrichment, reading from `continuumS2sPostgres` (click IDs, consent cache) and `continuumS2sCerebroDb` (GP ratios, country codes).
- Scheduled Quartz jobs pull customer info from `continuumS2sTeradata` and write enriched hashed PII back to `continuumS2sPostgres` for use in partner event payloads.
- `continuumS2sService_roiDataService` reads from `continuumS2sBigQuery` to enrich DataBreaker datapoint events and generate Google Ads/Sheets automation outputs.
- No CDC or ETL pipelines are defined — data flows are application-driven via JDBI and BigQuery API calls.
