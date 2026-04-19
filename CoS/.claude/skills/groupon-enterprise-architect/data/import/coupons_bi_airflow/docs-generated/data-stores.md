---
service: "coupons_bi_airflow"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "teradata"
    type: "teradata"
    purpose: "Enterprise data warehouse — primary analytical store for Coupons BI"
  - id: "bigquery"
    type: "bigquery"
    purpose: "Cloud analytical warehouse — target for GA4, Ads, and affiliate pipeline loads"
  - id: "gcs"
    type: "object-storage"
    purpose: "Landing zone for raw API responses before transformation and load"
  - id: "secretManager"
    type: "secrets-store"
    purpose: "Secure storage of API credentials and secrets retrieved at DAG runtime"
---

# Data Stores

## Overview

coupons_bi_airflow reads from and writes to four data stores. GCS acts as a raw landing zone where API responses are staged before being loaded into BigQuery or Teradata. BigQuery serves as the cloud analytical warehouse for GA4, Ads, and affiliate data. Teradata is the on-premises enterprise warehouse that receives dimensioning and reference data loads. GCP Secret Manager provides credential retrieval for all external API integrations.

## Stores

### Teradata (`teradata`)

| Property | Value |
|----------|-------|
| Type | teradata |
| Architecture ref | `continuumCouponsBiAirflowDags` |
| Purpose | Enterprise data warehouse — primary analytical store for Coupons BI dimensional and fact data |
| Ownership | shared |
| Migrations path | Managed externally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Dimensional reference tables | Provide lookup and dimension data for BI reporting | Varies per domain |
| Fact tables | Store aggregated metrics from affiliate, ads, and search pipelines | date, source, metric values |

#### Access Patterns

- **Read**: DAGs query Teradata to validate existing data before incremental loads
- **Write**: DAGs perform bulk inserts and upserts of transformed pipeline output
- **Indexes**: Managed externally by the data warehouse team

---

### BigQuery (`bigquery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `continuumCouponsBiAirflowDags` |
| Purpose | Cloud analytical warehouse — target for GA4, Google Ads, Bing Ads, and affiliate pipeline outputs |
| Ownership | shared |
| Migrations path | Managed externally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| GA4 report tables | Store GA4 traffic and conversion metrics | date, dimension, metric |
| Ads performance tables | Store Google Ads and Bing Ads campaign metrics | date, campaign_id, impressions, clicks, spend |
| Affiliate data tables | Store CJ and AffJet commission and click data | date, affiliate_id, merchant_id |
| Search ranking tables | Store AccuRanker and Search Console ranking data | date, keyword, position, url |

#### Access Patterns

- **Read**: DAGs check for existing partitions to support idempotent incremental loads
- **Write**: DAGs write transformed API responses using `google-cloud-bigquery` insert or load jobs
- **Indexes**: Partitioned by date; clustering varies per table

---

### GCS — Landing Zone (`gcs`)

| Property | Value |
|----------|-------|
| Type | object-storage (Google Cloud Storage) |
| Architecture ref | `continuumCouponsBiAirflowDags` |
| Purpose | Intermediate landing zone — raw API responses staged here before transformation and downstream load |
| Ownership | shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Raw API response files | Store unprocessed JSON/CSV responses from marketing and analytics APIs | pipeline name, date partition, file format |

#### Access Patterns

- **Read**: Transformation tasks read staged files from GCS to build DataFrames for loading
- **Write**: Extraction tasks write raw API responses to GCS using `google-cloud-storage`
- **Indexes**: Not applicable — object storage with path-based partitioning

---

### GCP Secret Manager (`secretManager`)

| Property | Value |
|----------|-------|
| Type | secrets-store (GCP Secret Manager) |
| Architecture ref | `continuumCouponsBiAirflowDags` |
| Purpose | Secure storage and retrieval of API keys, OAuth tokens, and service account credentials used by DAGs |
| Ownership | shared |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| API credential secrets | Keys and tokens for GA4, Google Ads, Bing Ads, AccuRanker, AffJet, CJ, and other integrations | secret_name, version |

#### Access Patterns

- **Read**: DAGs retrieve secrets at task runtime via `google-cloud-secret-manager` client
- **Write**: Secrets are managed by engineers through GCP Console or CLI — not written by DAGs
- **Indexes**: Not applicable

## Caches

> No evidence found — coupons_bi_airflow does not use a cache layer.

## Data Flows

Raw API data flows through the following pipeline pattern:

1. Extraction tasks call external marketing/analytics APIs and write raw responses to GCS.
2. Transformation tasks read from GCS, apply pandas-based transformations, and produce structured datasets.
3. Load tasks write structured datasets to BigQuery (for cloud analytics) and/or Teradata (for enterprise warehouse consumption).
4. Dimensional reference DAGs load lookup and reference tables directly into Teradata.
