---
service: "coupons_bi_airflow"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumCouponsBiAirflow"
  containers: [continuumCouponsBiAirflowDags]
---

# Architecture Context

## System Context

coupons_bi_airflow sits within the Continuum platform as a data engineering service owned by the Coupons BI domain. It operates entirely within the GCP ecosystem (Cloud Composer, BigQuery, GCS, Secret Manager) and has no inbound connections from other Groupon services. Its role in the broader architecture is as a data producer: it pulls from 10 external marketing and analytics APIs and writes structured datasets into BigQuery and Teradata, where they are consumed by BI analysts and reporting tools. All architecture model relations for this service are currently stub-only in the central Structurizr workspace.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Coupons BI Airflow DAGs | `continuumCouponsBiAirflowDags` | Scheduler / Batch | Python, Apache Airflow on GCP Cloud Composer | managed | 56+ DAGs orchestrating data ingestion, transformation, and load pipelines for Coupons BI |

## Components by Container

### Coupons BI Airflow DAGs (`continuumCouponsBiAirflowDags`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| GA4 ingestion DAGs | Extract GA4 web analytics data and load to BigQuery | Python, google-analytics-data v1beta |
| Affiliate API ingestion DAGs | Extract AffJet and CJ affiliate performance data and load to BigQuery | Python, REST HTTP |
| Search API ingestion DAGs | Extract AccuRanker and Search Console ranking data and load to BigQuery | Python, REST HTTP |
| Ads ingestion DAGs | Extract Google Ads and Bing Ads campaign metrics and load to BigQuery | Python, REST SDK |
| Ad Manager ingestion DAGs | Extract Google Ad Manager delivery data and load to BigQuery | Python, REST SDK |
| CrUX ingestion DAGs | Extract Chrome UX Report Core Web Vitals and load to BigQuery | Python, REST HTTP |
| Google Sheets ingestion DAGs | Read reference and configuration data from Google Sheets | Python, REST SDK |
| Dimensioning reference load DAGs | Load dimensional reference tables into Teradata | Python, teradatasql |
| GCS landing tasks | Stage raw API responses as intermediate files | Python, google-cloud-storage |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsBiAirflowDags` | GA4 API | Fetches web analytics report data | REST SDK (google-analytics-data v1beta) |
| `continuumCouponsBiAirflowDags` | Google Ads API | Fetches paid search campaign metrics | REST SDK |
| `continuumCouponsBiAirflowDags` | Bing Ads API | Fetches Bing paid search metrics | REST SDK |
| `continuumCouponsBiAirflowDags` | AccuRanker API | Fetches organic keyword rankings | REST |
| `continuumCouponsBiAirflowDags` | AffJet API | Fetches affiliate network metrics | REST |
| `continuumCouponsBiAirflowDags` | CJ API | Fetches commission and click data | REST |
| `continuumCouponsBiAirflowDags` | Search Console API | Fetches organic search performance data | REST SDK |
| `continuumCouponsBiAirflowDags` | Google Ad Manager API | Fetches display ad delivery data | REST SDK |
| `continuumCouponsBiAirflowDags` | CrUX API | Fetches Core Web Vitals field data | REST |
| `continuumCouponsBiAirflowDags` | Google Sheets API | Reads reference/config spreadsheets | REST SDK |
| `continuumCouponsBiAirflowDags` | GCS | Lands raw API responses | GCP SDK |
| `continuumCouponsBiAirflowDags` | BigQuery | Writes transformed pipeline output | GCP SDK |
| `continuumCouponsBiAirflowDags` | Teradata | Writes dimensional reference data | teradatasql |
| `continuumCouponsBiAirflowDags` | GCP Secret Manager | Retrieves API credentials at runtime | GCP SDK |

## Architecture Diagram References

- System context: `contexts-continuumCouponsBiAirflow`
- Container: `containers-continuumCouponsBiAirflow`
- Component: `components-continuumCouponsBiAirflowDags`

> Note: All architecture model relations for this service are currently stub-only in the central Structurizr workspace (`continuumCouponsBiAirflowDags`).
