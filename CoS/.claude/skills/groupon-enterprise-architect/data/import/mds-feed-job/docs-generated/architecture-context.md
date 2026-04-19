---
service: "mds-feed-job"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMdsFeedJob]
---

# Architecture Context

## System Context

MDS Feed Job (`continuumMdsFeedJob`) is a Spark batch container within the Continuum platform. It does not expose any API surface; instead it is triggered by external schedulers or Livy job submissions. It reads input data from distributed storage (GCS/HDFS MDS snapshots), enriches it via calls to 11 internal and external services, and writes processed feed files back to GCS staging. It reports lifecycle state back to `continuumMarketingDealService` and operational metrics to InfluxDB. It sits at the data-out boundary of the Continuum commerce platform, publishing structured product and deal feeds to marketing channels.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MDS Feed Job | `continuumMdsFeedJob` | Spark batch job | Java, Apache Spark | 3.5.1 | Reads MDS snapshots, applies transformer pipelines, validates outputs, and publishes partner/ads/search feeds |

## Components by Container

### MDS Feed Job (`continuumMdsFeedJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `feedOrchestrator` | Bootstraps job configuration, manages batch lifecycle transitions, and controls the Spark execution flow | Java |
| `transformerPipeline` | Executes ordered transformer and UDF chains against Spark datasets to produce feed outputs | Java, Apache Spark |
| `externalApiAdapters` | Retrofit/HTTP clients for feed, taxonomy, pricing, inventory, merchant, and partner APIs | Java, Retrofit2, OkHttp |
| `publishingAndValidation` | Runs feed and metric validations, publishes output files, and updates feed/batch status | Java, Spark SQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMdsFeedJob` | `continuumMarketingDealService` | Loads feed definitions, updates batch lifecycle, and triggers uploads | HTTPS/JSON |
| `continuumMdsFeedJob` | `continuumTaxonomyService` | Reads taxonomy/category mappings for feed transformations | HTTPS/JSON |
| `continuumMdsFeedJob` | `continuumDealCatalogService` | Fetches localized deal catalog data | HTTPS/JSON |
| `continuumMdsFeedJob` | `continuumM3MerchantService` | Resolves merchant and place metadata for appointment and feed transforms | HTTPS/JSON |
| `continuumMdsFeedJob` | `continuumPricingService` | Requests dynamic and localized prices | HTTPS/JSON |
| `continuumMdsFeedJob` | `continuumTravelInventoryService` | Reads dated travel inventory details | HTTPS/JSON |
| `continuumMdsFeedJob` | `continuumVoucherInventoryService` | Reads voucher inventory details | HTTPS/JSON |
| `continuumMdsFeedJob` | `continuumThirdPartyInventoryService` | Reads TPIS availability data for TTD feeds | HTTPS/JSON |
| `continuumMdsFeedJob` | `bigQuery` | Reads gift-booster enrichment signals | BigQuery API |
| `continuumMdsFeedJob` | `edw` | Reads SEM source datasets for enrichment and filtering | JDBC/Teradata |
| `continuumMdsFeedJob` | `salesForce` | Queries VAT metadata for Salesforce VAT transformers | HTTPS/REST |
| `feedOrchestrator` | `transformerPipeline` | Starts transformer execution for feed runs | direct |
| `feedOrchestrator` | `externalApiAdapters` | Loads feed definitions and batch state before execution | direct |
| `transformerPipeline` | `externalApiAdapters` | Fetches enrichment data during transformations | direct |
| `transformerPipeline` | `publishingAndValidation` | Hands off transformed dataset for validation and publish | direct |
| `publishingAndValidation` | `externalApiAdapters` | Publishes metrics/feed status and triggers upload workflows | direct |

## Architecture Diagram References

- Container: `containers-mds-feed-job`
- Component: `components-mds-feed-job`
- Dynamic (feed generation flow): `dynamic-mds-feed-job-feed-generation`
