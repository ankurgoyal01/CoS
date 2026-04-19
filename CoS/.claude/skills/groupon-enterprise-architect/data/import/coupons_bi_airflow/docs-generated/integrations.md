---
service: "coupons_bi_airflow"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 10
internal_count: 0
---

# Integrations

## Overview

coupons_bi_airflow integrates with 10 external marketing, analytics, and search APIs to extract data for BI pipelines. All integrations are outbound — the service calls external APIs on scheduled intervals and writes results to GCS, BigQuery, or Teradata. There are no internal Groupon service dependencies.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GA4 (Google Analytics Data API) | REST SDK (google-analytics-data v1beta) | Ingest web analytics and conversion metrics | yes | `continuumCouponsBiAirflowDags` |
| Google Ads | REST SDK | Ingest paid search campaign performance metrics | yes | `continuumCouponsBiAirflowDags` |
| Bing Ads | REST SDK | Ingest Bing paid search campaign performance metrics | yes | `continuumCouponsBiAirflowDags` |
| AccuRanker | REST | Ingest organic keyword ranking data | yes | `continuumCouponsBiAirflowDags` |
| AffJet | REST | Ingest affiliate network performance data | yes | `continuumCouponsBiAirflowDags` |
| CJ (Commission Junction) | REST | Ingest affiliate commission and click data | yes | `continuumCouponsBiAirflowDags` |
| Google Search Console | REST SDK | Ingest organic search impression and click data | yes | `continuumCouponsBiAirflowDags` |
| Google Ad Manager | REST SDK | Ingest display ad delivery and revenue data | yes | `continuumCouponsBiAirflowDags` |
| CrUX API (Chrome UX Report) | REST | Ingest Core Web Vitals and field experience metrics | no | `continuumCouponsBiAirflowDags` |
| Google Sheets | REST SDK | Read configuration and reference data from managed spreadsheets | no | `continuumCouponsBiAirflowDags` |

### GA4 (Google Analytics Data API) Detail

- **Protocol**: REST SDK — `google-analytics-data` v1beta
- **Base URL / SDK**: `google-analytics-data` Python client library
- **Auth**: Service account credentials retrieved from GCP Secret Manager
- **Purpose**: Extracts web analytics metrics (sessions, conversions, revenue) for Coupons properties and loads them into BigQuery
- **Failure mode**: DAG task fails and retries per Airflow retry policy; downstream BI reports show stale data
- **Circuit breaker**: No — Airflow retry mechanism handles transient failures

### Google Ads Detail

- **Protocol**: REST SDK — Google Ads API Python client
- **Base URL / SDK**: Google Ads API Python client
- **Auth**: OAuth2 credentials retrieved from GCP Secret Manager
- **Purpose**: Extracts paid search campaign performance metrics (impressions, clicks, spend, conversions) and loads them into BigQuery
- **Failure mode**: DAG task fails and retries; pipeline halts for the affected date partition
- **Circuit breaker**: No

### Bing Ads Detail

- **Protocol**: REST SDK — Bing Ads API
- **Base URL / SDK**: Bing Ads API Python SDK
- **Auth**: OAuth2 credentials retrieved from GCP Secret Manager
- **Purpose**: Extracts Bing paid search performance metrics and loads them into BigQuery
- **Failure mode**: DAG task fails and retries; affected date partition skipped until next run
- **Circuit breaker**: No

### AccuRanker Detail

- **Protocol**: REST
- **Base URL / SDK**: AccuRanker API
- **Auth**: API key retrieved from GCP Secret Manager
- **Purpose**: Retrieves organic keyword ranking positions to track SEO performance for Coupons pages
- **Failure mode**: DAG task fails; ranking data unavailable for the scheduled period
- **Circuit breaker**: No

### AffJet Detail

- **Protocol**: REST
- **Base URL / SDK**: AffJet API
- **Auth**: API key retrieved from GCP Secret Manager
- **Purpose**: Ingests affiliate network performance metrics for CPA and revenue attribution reporting
- **Failure mode**: DAG task fails and retries
- **Circuit breaker**: No

### CJ (Commission Junction) Detail

- **Protocol**: REST
- **Base URL / SDK**: CJ API
- **Auth**: API key retrieved from GCP Secret Manager
- **Purpose**: Retrieves affiliate commission, click, and order data for Coupons affiliate reporting
- **Failure mode**: DAG task fails; affiliate data unavailable for the period
- **Circuit breaker**: No

### Google Search Console Detail

- **Protocol**: REST SDK
- **Base URL / SDK**: Google Search Console API Python client
- **Auth**: Service account credentials retrieved from GCP Secret Manager
- **Purpose**: Extracts organic search impressions, clicks, CTR, and position data for Coupons URLs
- **Failure mode**: DAG task fails; organic search data unavailable for the period
- **Circuit breaker**: No

### Google Ad Manager Detail

- **Protocol**: REST SDK
- **Base URL / SDK**: Google Ad Manager API Python client
- **Auth**: Service account credentials retrieved from GCP Secret Manager
- **Purpose**: Extracts display ad delivery, impressions, and revenue data for Coupons ad inventory
- **Failure mode**: DAG task fails; ad revenue reporting shows stale data
- **Circuit breaker**: No

### CrUX API Detail

- **Protocol**: REST
- **Base URL / SDK**: Chrome UX Report API
- **Auth**: API key retrieved from GCP Secret Manager
- **Purpose**: Ingests Core Web Vitals and real-user performance field data for Coupons pages
- **Failure mode**: Non-critical; DAG task fails silently with retry; performance data gap in reporting
- **Circuit breaker**: No

### Google Sheets Detail

- **Protocol**: REST SDK — Google Sheets API
- **Base URL / SDK**: Google Sheets API Python client
- **Auth**: Service account credentials retrieved from GCP Secret Manager
- **Purpose**: Reads configuration data, reference mappings, or manually maintained lookup tables managed in Google Sheets by BI analysts
- **Failure mode**: DAG task fails if required sheet is inaccessible; reference loads stall
- **Circuit breaker**: No

## Internal Dependencies

> No evidence found — coupons_bi_airflow has no internal Groupon service dependencies.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

All external API dependencies are reached over HTTPS. Credentials are retrieved from GCP Secret Manager at task runtime. Failure handling relies on Airflow's built-in task retry mechanism (configured per DAG). There are no circuit breakers or fallback strategies implemented at the integration layer. Failed DAG runs surface in the Airflow UI and trigger alerts via Cloud Composer monitoring.
