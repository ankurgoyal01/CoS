---
service: "coupons_bi_airflow"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Data Engineering / Business Intelligence"
platform: "GCP Cloud Composer"
team: "Coupons BI"
status: active
tech_stack:
  language: "Python"
  language_version: "3.x"
  framework: "Apache Airflow"
  framework_version: "latest (Cloud Composer managed)"
  runtime: "GCP Cloud Composer"
  runtime_version: "managed"
  build_tool: "pip"
  package_manager: "pip"
---

# Coupons BI Airflow Overview

## Purpose

coupons_bi_airflow is the data pipeline orchestration layer for the Coupons Business Intelligence domain. It operates 56+ Apache Airflow DAGs on GCP Cloud Composer to extract data from external marketing, affiliate, and search APIs, transform it, and load it into Teradata and BigQuery for analytical consumption. The service exists to centralize and automate BI data acquisition that feeds reporting and performance measurement for the Groupon Coupons product.

## Scope

### In scope

- Scheduling and executing batch data extraction DAGs against external marketing APIs (GA4, Google Ads, Bing Ads, AccuRanker, AffJet, CJ, Search Console, Google Ad Manager, CrUX API, Google Sheets)
- Landing raw API responses to GCS as an intermediate staging zone
- Loading and transforming data into BigQuery and Teradata
- Managing dimensional reference data loads for BI reporting
- Retrieving API credentials and secrets from GCP Secret Manager at DAG runtime

### Out of scope

- Serving BI reports or dashboards to end users
- Real-time or streaming data ingestion (all pipelines are batch/scheduled)
- Managing the BigQuery or Teradata schema migrations directly (schema changes are applied externally)
- Application-level business logic outside of pipeline orchestration

## Domain Context

- **Business domain**: Data Engineering / Business Intelligence
- **Platform**: GCP Cloud Composer
- **Upstream consumers**: BI analysts and reporting tools consuming BigQuery and Teradata datasets
- **Downstream dependencies**: GA4 API, Google Ads API, Bing Ads API, AccuRanker API, AffJet API, CJ (Commission Junction) API, Search Console API, Google Ad Manager API, CrUX API, Google Sheets API, GCS, BigQuery, Teradata, GCP Secret Manager

## Stakeholders

| Role | Description |
|------|-------------|
| Coupons BI Engineers | Develop, maintain, and deploy DAGs |
| BI Analysts | Consumers of the data produced by these pipelines |
| Data Platform | Manages Cloud Composer environment and underlying infrastructure |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.x | DAG source files |
| Framework | Apache Airflow | Cloud Composer managed | DAG definitions |
| Runtime | GCP Cloud Composer | managed | Deployment environment |
| Build tool | pip | — | requirements.txt |
| Package manager | pip | — | requirements.txt |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| apache-airflow | Cloud Composer managed | scheduling | DAG orchestration engine |
| teradatasql | latest | db-client | Connects DAGs to Teradata data warehouse |
| google-cloud-bigquery | latest | db-client | Reads and writes BigQuery datasets |
| google-cloud-storage | latest | db-client | Lands raw API responses to GCS buckets |
| google-analytics-data | v1beta | http-framework | Fetches GA4 report data |
| google-cloud-secret-manager | latest | auth | Retrieves API keys and credentials at runtime |
| pandas | latest | serialization | In-memory data transformation between API response and load targets |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
