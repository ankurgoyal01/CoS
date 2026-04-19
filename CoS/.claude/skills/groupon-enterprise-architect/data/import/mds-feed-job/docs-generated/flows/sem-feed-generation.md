---
service: "mds-feed-job"
title: "SEM Feed Generation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "sem-feed-generation"
flow_type: batch
trigger: "Scheduler — Livy job submission with SEM feed type argument"
participants:
  - "feedOrchestrator"
  - "transformerPipeline"
  - "externalApiAdapters"
  - "publishingAndValidation"
  - "edw"
architecture_ref: "dynamic-mds-feed-job-feed-generation"
---

# SEM Feed Generation

## Summary

SEM (Search Engine Marketing) Feed Generation is a specialised feed batch run that reads SEM-specific source datasets from the Enterprise Data Warehouse (Teradata EDW) rather than — or in addition to — MDS snapshots. The flow applies SEM-specific transformer chains to produce keyword, campaign, or product-targeting feed data for Google Ads. It follows the same orchestration lifecycle as a standard feed run but with EDW as a primary data source and SEM-specific transformer configuration.

## Trigger

- **Type**: schedule
- **Source**: External scheduler submits Livy job with SEM feed type argument
- **Frequency**: Daily or per SEM campaign update schedule

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Feed Orchestrator | Loads SEM feed definition and bootstraps Spark execution | `feedOrchestrator` |
| Transformer Pipeline | Applies SEM-specific transformer and UDF chains | `transformerPipeline` |
| External API Adapters | Reads SEM datasets from EDW via JDBC; calls enrichment APIs | `externalApiAdapters` |
| Publishing and Validation | Validates and publishes SEM feed output | `publishingAndValidation` |
| EDW (Teradata) | Source of SEM keyword, campaign, and deal mapping datasets | `edw` |

## Steps

1. **Receive SEM job submission**: Scheduler submits Livy job with feed type = SEM and run parameters.
   - From: `external-scheduler`
   - To: `feedOrchestrator`
   - Protocol: Livy REST / Spark application args

2. **Load SEM feed definition and batch state**: `feedOrchestrator` calls `externalApiAdapters` to fetch SEM feed configuration from Marketing Deal Service.
   - From: `feedOrchestrator`
   - To: `externalApiAdapters` → `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

3. **Read SEM source datasets from EDW**: `externalApiAdapters` executes JDBC queries against Teradata EDW to read SEM keyword, campaign, and deal-to-keyword mapping datasets.
   - From: `externalApiAdapters`
   - To: `edw`
   - Protocol: JDBC/Teradata (driver 17.20)

4. **Load SEM datasets into Spark**: EDW result sets are loaded into Spark DataFrames for pipeline processing.
   - From: `externalApiAdapters`
   - To: `transformerPipeline`
   - Protocol: direct (in-process Spark DataFrames)

5. **Apply SEM transformer chain**: `transformerPipeline` applies SEM-specific transformers: keyword normalization, bid mapping, deal-to-keyword association, category filtering, and de-duplication.
   - From: `transformerPipeline`
   - To: Spark dataset
   - Protocol: direct (Spark operations)

6. **Enrich with deal catalog and pricing**: For deal-linked SEM feed types, `transformerPipeline` calls `externalApiAdapters` to fetch current deal catalog and pricing data.
   - From: `transformerPipeline`
   - To: `externalApiAdapters` → `continuumDealCatalogService`, `continuumPricingService`
   - Protocol: HTTPS/JSON

7. **Apply output format transformers**: Format SEM output to Google Ads feed schema (CSV or API payload format).
   - From: `transformerPipeline`
   - To: Spark dataset
   - Protocol: direct

8. **Validate SEM feed output**: `publishingAndValidation` validates SEM-specific rules (minimum keyword count, bid value ranges, required fields for Google Ads compliance).
   - From: `publishingAndValidation`
   - To: Spark dataset
   - Protocol: direct (Spark SQL)

9. **Publish SEM feed to GCS and Google Ads**: `publishingAndValidation` writes SEM feed files to GCS staging and calls `externalApiAdapters` to upload to Google Ads.
   - From: `publishingAndValidation`
   - To: GCS / `externalApiAdapters` → Google Ads API
   - Protocol: GCS SDK / HTTPS

10. **Update batch status**: Batch lifecycle updated in Marketing Deal Service.
    - From: `externalApiAdapters`
    - To: `continuumMarketingDealService`
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EDW JDBC connection fails | Failsafe retry; if exhausted, batch fails | SEM feed not generated; batch marked failed |
| EDW query returns empty result | Empty DataFrame processed; validation catches zero records | Batch marked failed; alert triggered |
| Google Ads upload fails | Failsafe retry; if exhausted, batch marked failed | SEM data not delivered to Google Ads for this run |
| Pricing API fails during enrichment | Failsafe retry; if exhausted, SEM enrichment step fails | Batch fails; re-submission required |

## Sequence Diagram

```
Scheduler        -> feedOrchestrator         : Submit SEM job (feed_type=SEM, run_date)
feedOrchestrator -> externalApiAdapters       : Load SEM feed definition
externalApiAdapters -> continuumMarketingDealService : GET /feed-definition (SEM)
feedOrchestrator -> transformerPipeline       : Start SEM transformer execution
externalApiAdapters -> edw                   : JDBC query SEM datasets
edw             --> externalApiAdapters       : SEM keyword/campaign data
externalApiAdapters -> continuumDealCatalogService : GET /catalog/deals (SEM-linked)
externalApiAdapters -> continuumPricingService : GET /prices
externalApiAdapters --> transformerPipeline   : SEM datasets + enrichment
transformerPipeline -> transformerPipeline    : Apply SEM transformer chain
transformerPipeline --> publishingAndValidation : SEM output dataset
publishingAndValidation -> publishingAndValidation : Validate SEM rules
publishingAndValidation -> GCS               : Write SEM feed file
publishingAndValidation -> externalApiAdapters : Trigger Google Ads upload
externalApiAdapters -> GoogleAds             : Upload SEM feed
externalApiAdapters -> continuumMarketingDealService : POST /batch/complete
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Related flows: [Feed Job Orchestration](feed-job-orchestration.md), [Transformer Pipeline Execution](transformer-pipeline-execution.md), [Feed Output Validation and Publishing](feed-output-validation-publishing.md)
