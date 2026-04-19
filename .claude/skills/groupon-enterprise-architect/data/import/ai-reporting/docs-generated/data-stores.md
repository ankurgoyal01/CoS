---
service: "ai-reporting"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumAiReportingMySql"
    type: "mysql"
    purpose: "Transactional store for campaigns, payments, configs, audiences, and reporting metadata"
  - id: "continuumAiReportingHive"
    type: "hive"
    purpose: "Analytics warehouse for audience and advisor feeds"
  - id: "continuumAiReportingBigQuery"
    type: "bigquery"
    purpose: "Analytical dataset for CitrusAd reporting and wallet analytics"
  - id: "continuumAiReportingGcs"
    type: "gcs"
    purpose: "Bucket storage for CitrusAd feeds, search term files, and downloaded reports"
---

# Data Stores

## Overview

AI Reporting uses a four-tier storage strategy: MySQL for all transactional state (campaigns, wallets, audiences, configurations), Hive for large-scale analytics queries (audience and advisor datasets), BigQuery for CitrusAd-specific analytical workloads (billing reconciliation, wallet analytics), and GCS as the file exchange layer between the service and CitrusAd for feed ingestion and report downloads.

## Stores

### AI Reporting MySQL (`continuumAiReportingMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumAiReportingMySql` |
| Purpose | Transactional store for campaigns, payments, configs, audiences, and reporting metadata |
| Ownership | owned |
| Migrations path | > No evidence found in inventory — consult service owner |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Campaigns | Stores Sponsored Listing campaign state and parameters | campaign ID, merchant ID, budget, status, subtype, CitrusAd campaign ID |
| Payments / Wallet Ledger | Records wallet top-ups, spend deductions, refunds, and balances | merchant ID, transaction type, amount, timestamp, order reference |
| CitrusAd Campaign Data | Stores CitrusAd-specific campaign sync state and budgets | CitrusAd campaign ID, CPC, search terms, sync status |
| Audiences | Tracks audience membership deltas and history | audience ID, merchant ID, member count, last sync timestamp |
| Feed Configurations | Feed generation metadata and run state | feed type, last run, file path, status |
| Free Credits | Credit issuances, balances, and expiration tracking | merchant ID, credit amount, expiry date, notified flag |
| Reconciliation Records | Billing exception records from CitrusAd report imports | report date, expected spend, actual spend, delta, resolution status |
| Search Term Rules | CPC overrides and search term allowlist/blocklist per campaign | campaign ID, term, CPC override, active flag |

#### Access Patterns

- **Read**: Campaign state reads on every dashboard request; wallet balance reads on every merchant session; audience delta reads on scheduled sync jobs
- **Write**: Campaign writes on lifecycle events (create/edit/pause/deactivate); wallet ledger writes on every top-up, refund, or spend reconciliation; audience table writes on scheduled audience refresh jobs
- **Indexes**: Campaign ID and merchant ID are primary lookup keys; feed run state queried by type and timestamp for scheduler deduplication

---

### AI Reporting Hive (`continuumAiReportingHive`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `continuumAiReportingHive` |
| Purpose | Analytics warehouse used for audience and advisor feeds |
| Ownership | shared |
| Migrations path | > Not applicable — Hive tables managed via `continuumAiReportingService_hiveAnalytics` executor |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Audience source tables | Raw audience segment data consumed by the Audience Service | audience segment ID, member identifiers, effective date |
| Merchant advisor datasets | Deal insight and recommendation data imported by Merchant Advisor Client | merchant ID, deal ID, advice type, score |

#### Access Patterns

- **Read**: Hive JDBC queries executed by `continuumAiReportingService_hiveAnalytics` for audience deltas and advisor feed import jobs
- **Write**: Hive table creation managed by the scheduler; Hive materializations optionally uploaded to GCS by `continuumAiReportingService_hiveAnalytics`
- **Indexes**: Not applicable — Hive uses partition-based access on date and segment fields

---

### AI Reporting BigQuery (`continuumAiReportingBigQuery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `continuumAiReportingBigQuery` |
| Purpose | Analytical dataset for CitrusAd reporting and wallet analytics |
| Ownership | owned |
| Migrations path | > Not applicable — dataset schema managed via BigQuery SDK |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| CitrusAd reconciled metrics | Billing-reconciled spend and impression data loaded after report import | campaign ID, date, impressions, clicks, spend, reconciled_spend |
| Wallet analytics | Aggregated wallet balance and transaction analytics for dashboards | merchant ID, date, balance, top-up total, spend total |

#### Access Patterns

- **Read**: `continuumAiReportingService_reportsService` runs BigQuery analytics queries to serve dashboard requests
- **Write**: `continuumAiReportingService_citrusAdReportsImportService` loads reconciled metrics into BigQuery after each report download cycle
- **Indexes**: Not applicable — BigQuery uses columnar partitioning on date fields

---

### AI Reporting GCS (`continuumAiReportingGcs`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `continuumAiReportingGcs` |
| Purpose | Bucket storage for CitrusAd feeds, search term files, and downloaded reports |
| Ownership | owned |
| Migrations path | > Not applicable — object storage |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Customer feed files | Customer data feed uploaded for CitrusAd ingestion | file path, generation timestamp, merchant scope |
| Order feed files | Order data feed uploaded for CitrusAd ingestion | file path, generation timestamp, order date range |
| Team feed files | CitrusAd team membership feed | file path, generation timestamp |
| Search term files | Search term analytics and CPC override files | file path, campaign ID, date |
| CitrusAd report files | Downloaded CitrusAd billing/performance report files for reconciliation | file path, report date, file type |

#### Access Patterns

- **Read**: `continuumAiReportingService_citrusAdReportsImportService` and `continuumAiReportingService_searchTermsFeedService` download files from GCS for processing
- **Write**: `continuumAiReportingService_citrusAdFeedService` writes generated customer/order/team feeds; `continuumAiReportingService_hiveAnalytics` uploads Hive materializations when needed
- **Indexes**: Not applicable — GCS uses object path prefixes for logical separation by feed type and date

---

## Caches

> No evidence found for explicit cache configuration (Redis, Memcached, or in-memory) in the available DSL inventory.

## Data Flows

1. **Campaign state**: REST API writes to `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`; CitrusAd sync jobs read MySQL and push to CitrusAd via `continuumAiReportingService_citrusAdApiClient`
2. **Feed transport**: Scheduler triggers `continuumAiReportingService_citrusAdFeedService`, which generates feed files, uploads to `continuumAiReportingGcs`, and notifies CitrusAd
3. **Report reconciliation**: Scheduler triggers `continuumAiReportingService_citrusAdReportsImportService`, which downloads report files from `continuumAiReportingGcs`, loads metrics to `continuumAiReportingBigQuery`, and reconciles billing back to `continuumAiReportingMySql`
4. **Audience sync**: Scheduler triggers `continuumAiReportingService_audienceService`, which reads from `continuumAiReportingHive`, computes deltas, persists to `continuumAiReportingMySql`, and syncs to `continuumAudienceManagementService`
