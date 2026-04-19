---
service: "gcp-aiaas-cloud-functions"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAiaasPostgres"
    type: "postgresql"
    purpose: "Persists scraped merchant page text and matched InferPDS service records for AIaaS functions"
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Read-only supply dataset for PDS priority queries"
---

# Data Stores

## Overview

The AIaaS platform owns one PostgreSQL database (`continuumAiaasPostgres`) that stores scraped merchant web content and matched PDS service records. It also reads from a shared BigQuery dataset for PDS priority ranking. All other persistence (CRM data, ML model artifacts) is delegated to Salesforce and Vertex AI respectively, which are external systems.

## Stores

### AIaaS PostgreSQL Database (`continuumAiaasPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumAiaasPostgres` |
| Purpose | Stores scraped merchant page text used by AIDG and InferPDS functions; persists matched InferPDS taxonomy service records per merchant account |
| Ownership | owned |
| Migrations path | No migration files found in repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `aidg.inferpds_scraped_data` | Stores scraped page content per merchant account | `account_id`, `page_text`, `url`, `text`, `method`, `needs_playwright`, `scraped_at` |
| `aidg.inferpds_services` | Stores matched PDS taxonomy services per merchant account | `account_id`, `extracted_service`, `extracted_price`, `extracted_description`, `extracted_category`, `source_url`, `source_urls` (JSONB), `service_name`, `similarity_score`, `taxonomy_service_id`, `category`, `header`, `source`, `count`, `updated_at` |

#### Access Patterns

- **Read**: AIDG function reads the most recent `page_text` for an `account_id` from `aidg.inferpds_scraped_data` ordered by `scraped_at DESC`. InferPDS Cloud Run API reads all service rows and scraped pages for an `account_id` ordered by `updated_at DESC` / `scraped_at DESC`.
- **Write**: InferPDS Cloud Run API writes extracted services to `aidg.inferpds_services` and scraped page content to `aidg.inferpds_scraped_data` after each successful extraction run.
- **Indexes**: No index definitions found in repository; ordering by `scraped_at DESC NULLS LAST` and `updated_at DESC NULLS LAST` implies indexes on those timestamp columns are expected.

**Connection details** (from environment variables):
- Host: `POSTGRES_HOST` (default: `aidg-service-ro-na-staging-db.gds.stable.gcp.groupondev.com`)
- Port: `POSTGRES_PORT` (default: `5432`)
- Database: `POSTGRES_DATABASE` / `DAAS_APP_DATABASE` (default: `aidg_stg`)
- User: `POSTGRES_USER` / `DAAS_DBA_USER`
- Password: `POSTGRES_PASSWORD` / `DAAS_DBA_PASSWORD`
- Schema: `PG_SCHEMA` (default: `aidg`)

---

### BigQuery Supply Dataset (External Read-Only)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery` (external stub) |
| Purpose | Read-only supply dataset queried by the PDS Priority function to return ranked PDS records |
| Ownership | external (shared Groupon data platform) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `prj-grp-dataview-prod-1ff9.supply.acc_information_pds` | Current PDS priority records for supply accounts | `account_id`, `city`, `country`, `consolidated_city`, `pds_cat_name`, `pds_cat_id`, `merchant_potential`, `customer_percentile_bucket`, `sl_eligible`, `tg`, `load_date` |

#### Access Patterns

- **Read**: PDS Priority function queries the latest partition (`WHERE load_date = (SELECT MAX(load_date) ...)`) with one or more filter conditions. Results are returned as a JSON array with keys converted to camelCase.
- **Write**: Not applicable — this function only reads from BigQuery.
- **Indexes**: BigQuery partitioned by `load_date`; the function always queries the latest partition.

**GCP Project**: `prj-grp-aiaas-prod-0052` (BigQuery client project). Dataset project: `prj-grp-dataview-prod-1ff9`.

## Caches

> No evidence found in codebase. The InferPDS Cloud Run API uses an in-memory embedding cache (Python `pickle`) for OpenAI embeddings within a single request lifecycle, but this is not a persistent cache store.

## Data Flows

- Scraped merchant content is written to `aidg.inferpds_scraped_data` by the InferPDS Cloud Run API after each website scraping run.
- The AIDG function reads the same scraped content from `aidg.inferpds_scraped_data` to provide merchant context for AI deal generation — creating a producer/consumer dependency between the InferPDS and AIDG functions via the shared PostgreSQL database.
- Matched PDS services are persisted to `aidg.inferpds_services` and can be read back on subsequent calls to avoid re-scraping (cache-hit path).
- BigQuery data flows are read-only — the `acc_information_pds` table is populated by a separate supply data pipeline (not owned by this service).
