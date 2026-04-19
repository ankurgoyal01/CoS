---
service: "coupons_bi_airflow"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Coupons BI Airflow.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [GA4 Ingestion](ga4-ingestion.md) | scheduled | Airflow cron schedule | Extracts GA4 web analytics report data and loads it into BigQuery |
| [Affiliate API Ingestion](affiliate-api-ingestion.md) | scheduled | Airflow cron schedule | Extracts AffJet and CJ affiliate performance data and loads it into BigQuery |
| [Search API Ingestion](search-api-ingestion.md) | scheduled | Airflow cron schedule | Extracts AccuRanker and Google Search Console ranking data and loads it into BigQuery |
| [Dimensioning Reference Loads](dimensioning-reference-loads.md) | scheduled | Airflow cron schedule | Loads dimensional reference and lookup tables into Teradata |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

All flows in coupons_bi_airflow are self-contained batch pipelines. They do not span other Groupon internal services. Upstream data consumers (BI analysts, reporting tools) access the output datasets directly in BigQuery and Teradata outside the scope of these flows.
