---
service: "mds-feed-job"
title: "Transformer Pipeline Execution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "transformer-pipeline-execution"
flow_type: batch
trigger: "Internal — invoked by feedOrchestrator after feed definition is loaded"
participants:
  - "transformerPipeline"
  - "externalApiAdapters"
  - "publishingAndValidation"
architecture_ref: "dynamic-mds-feed-job-feed-generation"
---

# Transformer Pipeline Execution

## Summary

Transformer Pipeline Execution is the core data processing step of a feed run. The `transformerPipeline` component reads MDS deal snapshot data from GCS/HDFS via Spark, then applies an ordered sequence of transformer and UDF (User-Defined Function) chains configured per feed type. Enrichment data is fetched from external APIs via `externalApiAdapters` during transformation. The final transformed dataset is handed to `publishingAndValidation` for output.

## Trigger

- **Type**: internal (invoked programmatically)
- **Source**: `feedOrchestrator` after feed definition is successfully loaded
- **Frequency**: Once per feed batch run; the pipeline executes sequentially per feed type

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transformer Pipeline | Reads snapshots, applies transformer chains, produces output dataset | `transformerPipeline` |
| External API Adapters | Supplies enrichment data fetched from upstream services during transformation | `externalApiAdapters` |
| GCS / HDFS | Source of MDS deal snapshot input data | `continuumMdsFeedJob` (storage) |
| Publishing and Validation | Receives final transformed dataset for validation and publishing | `publishingAndValidation` |

## Steps

1. **Receive transformer execution request**: `feedOrchestrator` passes feed definition (transformer chain configuration) and Spark context to `transformerPipeline`.
   - From: `feedOrchestrator`
   - To: `transformerPipeline`
   - Protocol: direct (in-process)

2. **Read MDS snapshot**: `transformerPipeline` reads the partitioned MDS deal snapshot dataset from GCS/HDFS via Spark (Hive metastore or direct path).
   - From: `transformerPipeline`
   - To: GCS / HDFS
   - Protocol: GCS SDK / Hadoop HDFS

3. **Apply initial schema and filter transformers**: First-stage transformers filter, cast, and normalize raw snapshot fields to the feed schema.
   - From: `transformerPipeline`
   - To: Spark dataset (in-memory)
   - Protocol: direct (Spark DataFrame operations)

4. **Fetch enrichment data**: For each enrichment-dependent transformer, `transformerPipeline` calls `externalApiAdapters` to retrieve data from upstream services. See [External API Enrichment](external-api-enrichment.md).
   - From: `transformerPipeline`
   - To: `externalApiAdapters`
   - Protocol: direct (in-process) → HTTPS/JSON to upstream services

5. **Apply enrichment transformers**: Enrichment data (pricing, taxonomy, merchant, inventory, VAT, gift-booster) is joined or applied to the Spark dataset via UDFs or DataFrame operations.
   - From: `transformerPipeline`
   - To: Spark dataset
   - Protocol: direct (Spark UDF / join operations)

6. **Apply locale and language transformers**: Locale-specific transformers apply currency formatting, unit conversion, and field mapping for the target feed locale. For multi-language feeds, translation is triggered. See [Multi-Language Translation](multi-language-translation.md).
   - From: `transformerPipeline`
   - To: Spark dataset / `externalApiAdapters`
   - Protocol: direct / HTTPS (Google Translate)

7. **Apply output format transformers**: Final transformers format the dataset to the target feed schema (CSV columns, XML elements, field truncation, encoding).
   - From: `transformerPipeline`
   - To: Spark dataset
   - Protocol: direct (Spark operations)

8. **Hand off transformed dataset**: `transformerPipeline` passes the finalized Spark dataset to `publishingAndValidation`.
   - From: `transformerPipeline`
   - To: `publishingAndValidation`
   - Protocol: direct (Spark dataset reference)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Snapshot partition not found | Spark read throws exception; propagated to orchestrator | Batch fails; no output produced |
| Enrichment API call fails after retries | Failsafe exhausts retries; transformer step throws exception | Batch fails; partial dataset discarded |
| UDF execution error | Spark task fails and retries per Spark max retry config | If retries exhausted, stage fails and batch fails |
| Schema mismatch in snapshot | Transformer fails on field access; exception propagated | Batch fails with schema error |
| Empty dataset after filtering | Empty DataFrame passed to publishing | Feed output file written as empty; validation flags zero records |

## Sequence Diagram

```
feedOrchestrator    -> transformerPipeline : Start pipeline (feed config, Spark context)
transformerPipeline -> GCS/HDFS           : Read MDS snapshot (partitioned by date/division)
GCS/HDFS           --> transformerPipeline : Spark DataFrame (raw deal records)
transformerPipeline -> transformerPipeline  : Apply schema/filter transformers
transformerPipeline -> externalApiAdapters  : Fetch enrichment data (pricing, taxonomy, etc.)
externalApiAdapters --> transformerPipeline : Enrichment datasets
transformerPipeline -> transformerPipeline  : Apply enrichment transformers (join/UDF)
transformerPipeline -> transformerPipeline  : Apply locale + format transformers
transformerPipeline --> publishingAndValidation : Transformed dataset
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Related flows: [Feed Job Orchestration](feed-job-orchestration.md), [External API Enrichment](external-api-enrichment.md), [Multi-Language Translation](multi-language-translation.md), [Feed Output Validation and Publishing](feed-output-validation-publishing.md)
